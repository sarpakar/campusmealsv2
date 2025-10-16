//

//  FoodIntentSearchView.swift
//  Campusmealsv2
//
//  Food search UI - Citi Bike R1 inspired design
//

import SwiftUI
import CoreLocation

struct FoodIntentSearchView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var searchService = FoodSearchService.shared
    @StateObject private var locationManager = LocationManager.shared
    @StateObject private var geminiParser = GeminiSearchParser.shared

    @State private var searchText = ""
    @State private var isParsing = false
    @FocusState private var isSearchFocused: Bool

    var onIntentSelected: ((FoodIntent) -> Void)?

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    // Curated suggestions matching Citi Bike style
    private let curatedSuggestions: [(emoji: String, title: String, subtitle: String, intent: FoodIntent)] = [
        ("☕️", "Best coffee near me", "Cafes & Coffee shops", FoodIntent(displayText: "Best coffee near me", emoji: "☕️", searchType: .coffee, filters: SearchFilters(maxDistance: 1000, minRating: 4.0))),
        ("🌹", "Date night spots", "Romantic restaurants", FoodIntent(displayText: "Romantic dinner spots", emoji: "🌹", searchType: .custom, filters: SearchFilters(maxDistance: 2000, minRating: 4.5, category: "romantic"))),
        ("📚", "Best study cafes", "Quiet & wifi-friendly", FoodIntent(displayText: "Best study cafes", emoji: "📚", searchType: .coffee, filters: SearchFilters(maxDistance: 1500, minRating: 4.0))),
        ("💪", "High protein meals", "Post-workout food", FoodIntent(displayText: "High protein near me", emoji: "💪", searchType: .highProtein, filters: SearchFilters(maxDistance: 1500))),
        ("⚡", "Quick breakfast", "Fast & nearby", FoodIntent(displayText: "Quick breakfast", emoji: "⚡", searchType: .quickBreakfast, filters: SearchFilters(maxDistance: 800))),
        ("🥗", "Healthy lunch", "Fresh & nutritious", FoodIntent(displayText: "Healthy lunch", emoji: "🥗", searchType: .healthyLunch, filters: SearchFilters(maxDistance: 1200))),
        ("🛒", "Cheap groceries", "Budget-friendly stores", FoodIntent(displayText: "Cheap groceries near me", emoji: "🛒", searchType: .groceries, filters: SearchFilters(maxDistance: 2000, maxPrice: 50))),
        ("🍕", "Late night eats", "Open now", FoodIntent(displayText: "Late night food", emoji: "🍕", searchType: .custom, filters: SearchFilters(maxDistance: 2000)))
    ]

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top bar - Citi Bike style
                topBar

                // Search box - Citi Bike R1 style
                searchBox
                    .padding(.horizontal, 16)
                    .padding(.top, 20)

                // Curated suggestions list
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(curatedSuggestions, id: \.title) { suggestion in
                            CuratedSuggestionRow(
                                emoji: suggestion.emoji,
                                title: suggestion.title,
                                subtitle: suggestion.subtitle
                            ) {
                                performSearch(suggestion.intent)
                            }

                            if suggestion.title != curatedSuggestions.last?.title {
                                Divider()
                                    .padding(.leading, 68)
                            }
                        }
                    }
                    .padding(.top, 24)
                }
            }
        }
    }

    // MARK: - Top Bar (Citi Bike R1 Style)

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
            }

            Spacer()

            Text("Search")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            Button(action: {}) {
                Image(systemName: "checkmark")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(citiBikeBlue)
                    .opacity(0) // Hidden but keeps symmetry
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Search Box (Citi Bike R1 Style)

    private var searchBox: some View {
        VStack(spacing: 0) {
            HStack(spacing: 14) {
                // Circle indicator (like R1's blue dot)
                ZStack {
                    Circle()
                        .strokeBorder(Color(.systemGray3), lineWidth: 2)
                        .frame(width: 20, height: 20)

                    Circle()
                        .fill(citiBikeBlue)
                        .frame(width: 10, height: 10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("What are you craving?")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(.systemGray))

                    TextField("Search for food", text: $searchText)
                        .font(.system(size: 18))
                        .foregroundColor(.black)
                        .focused($isSearchFocused)
                        .disabled(isParsing)
                        .onSubmit {
                            if !searchText.isEmpty {
                                performCustomSearch(searchText)
                            }
                        }
                }

                if isParsing {
                    ProgressView()
                        .scaleEffect(0.9)
                } else if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 20))
                            .foregroundColor(Color(.systemGray3))
                    }
                }
            }
            .padding(18)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color(.systemGray4), lineWidth: 1)
                    .background(RoundedRectangle(cornerRadius: 12).fill(Color.white))
            )

            // AI parsing indicator
            if isParsing {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 12))
                        .foregroundColor(citiBikeBlue)

                    Text("Finding best matches...")
                        .font(.system(size: 13))
                        .foregroundColor(Color(.systemGray))
                }
                .padding(.top, 10)
            }
        }
    }

    // MARK: - Search Actions

    private func performSearch(_ intent: FoodIntent) {
        onIntentSelected?(intent)
        dismiss()
    }

    private func performCustomSearch(_ query: String) {
        print("🔍 Custom search: '\(query)'")
        isParsing = true

        Task {
            do {
                // Use Gemini to parse the natural language query
                let parsedIntent = try await geminiParser.parseSearchQuery(query)

                await MainActor.run {
                    isParsing = false

                    // Convert to FoodIntent
                    let foodIntent = parsedIntent.toFoodIntent()
                    print("✅ Parsed intent: \(foodIntent.displayText)")

                    onIntentSelected?(foodIntent)
                    dismiss()
                }
            } catch {
                print("❌ Parse error: \(error.localizedDescription)")

                await MainActor.run {
                    isParsing = false

                    // Fallback: use query as-is
                    let fallbackIntent = FoodIntent(
                        displayText: query,
                        emoji: "🔍",
                        searchType: .custom,
                        filters: SearchFilters(maxDistance: 2000)
                    )

                    onIntentSelected?(fallbackIntent)
                    dismiss()
                }
            }
        }
    }
}

// MARK: - Curated Suggestion Row (Citi Bike R1 Style)

struct CuratedSuggestionRow: View {
    let emoji: String
    let title: String
    let subtitle: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Emoji in circle (like R1 location pin)
                ZStack {
                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 44, height: 44)

                    Text(emoji)
                        .font(.system(size: 22))
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(.black)

                    Text(subtitle)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(Color(.systemGray3))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color.white)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    FoodIntentSearchView()
}
