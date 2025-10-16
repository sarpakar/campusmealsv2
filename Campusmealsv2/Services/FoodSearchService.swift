//
//  FoodSearchService.swift
//  Campusmealsv2
//
//  Advanced food search with Recommendation Engine
//

import Foundation
import CoreLocation

@MainActor
class FoodSearchService: ObservableObject {
    static let shared = FoodSearchService()

    @Published var results: [FoodResult] = []
    @Published var isSearching = false

    private let vendorService = VendorService.shared
    private let recommendationEngine = RecommendationEngine.shared

    private init() {}

    // Advanced search with Recommendation Engine
    func search(intent: FoodIntent, userLocation: CLLocation) async {
        print("🔍 Starting search for: \(intent.displayText)")
        isSearching = true

        // Add shimmer delay for smooth UX (Uber-style)
        try? await Task.sleep(nanoseconds: 800_000_000) // 0.8 second

        // Get all vendors
        let vendors = vendorService.vendors

        // Filter based on intent type
        var filtered: [Vendor] = []

        switch intent.searchType {
        case .coffee:
            filtered = vendors.filter { $0.category == .cafes || $0.cuisine?.lowercased().contains("coffee") == true }
        case .highProtein:
            filtered = vendors.filter { $0.category == .restaurants }
        case .groceries:
            filtered = vendors.filter { $0.category == .groceries }
        case .quickBreakfast:
            filtered = vendors.filter { $0.category == .cafes || $0.category == .restaurants }
        case .healthyLunch:
            filtered = vendors.filter { $0.category == .restaurants }
        case .custom:
            // Smart filtering for custom searches
            filtered = smartFilter(vendors: vendors, query: intent.displayText)
        }

        // Apply price filter if specified
        if let maxPrice = intent.filters.maxPrice {
            filtered = filtered.filter { vendor in
                let avgPrice = averagePrice(for: vendor.priceRange)
                return avgPrice <= maxPrice
            }
        }

        print("   Filtered to \(filtered.count) vendors")

        // Use Recommendation Engine for advanced ranking
        let context = RecommendationContext.current
        let recommendations = await recommendationEngine.generateRecommendations(
            vendors: filtered,
            userLocation: userLocation,
            context: context
        )

        // Convert to FoodResult format
        results = recommendations.map { rec in
            FoodResult(
                vendor: rec.vendor,
                menuItem: nil,
                distance: distanceToMeters(rec.distance),
                walkTime: walkTimeToMinutes(rec.walkingTime),
                matchScore: rec.matchScore,
                matchReason: rec.matchReason
            )
        }

        print("✅ Search complete: \(results.count) results")
        isSearching = false
    }

    // Helper: Convert distance string to meters
    private func distanceToMeters(_ distanceStr: String) -> Double {
        if distanceStr.contains("mi") {
            let value = Double(distanceStr.replacingOccurrences(of: " mi", with: "")) ?? 0
            return value * 1609.34
        } else {
            return Double(distanceStr.replacingOccurrences(of: " m", with: "")) ?? 0
        }
    }

    // Helper: Convert walk time string to minutes
    private func walkTimeToMinutes(_ walkTimeStr: String) -> Int {
        return Int(walkTimeStr.replacingOccurrences(of: " min", with: "")) ?? 0
    }

    // MARK: - Smart Filtering

    private func smartFilter(vendors: [Vendor], query: String) -> [Vendor] {
        let lower = query.lowercased()

        return vendors.filter { vendor in
            // Match cuisine
            if let cuisine = vendor.cuisine, lower.contains(cuisine.lowercased()) {
                return true
            }

            // Match category
            if lower.contains("coffee") || lower.contains("cafe") {
                return vendor.category == .cafes
            }
            if lower.contains("grocery") || lower.contains("groceries") {
                return vendor.category == .groceries
            }

            // Match specific dishes in name/cuisine
            if lower.contains("pizza") {
                return vendor.cuisine?.lowercased().contains("italian") == true ||
                       vendor.name.lowercased().contains("pizza")
            }
            if lower.contains("ramen") || lower.contains("sushi") {
                return vendor.cuisine?.lowercased().contains("japanese") == true
            }
            if lower.contains("burrito") || lower.contains("taco") {
                return vendor.cuisine?.lowercased().contains("mexican") == true
            }
            if lower.contains("burger") {
                return vendor.cuisine?.lowercased().contains("burger") == true ||
                       vendor.cuisine?.lowercased().contains("american") == true
            }
            if lower.contains("salad") || lower.contains("healthy") {
                return vendor.cuisine?.lowercased().contains("salad") == true ||
                       vendor.cuisine?.lowercased().contains("healthy") == true
            }

            // Default: show all restaurants if no specific match
            return vendor.category == .restaurants
        }
    }

    private func averagePrice(for priceRange: String) -> Double {
        switch priceRange.count {
        case 1: return 10.0  // $
        case 2: return 20.0  // $$
        case 3: return 35.0  // $$$
        case 4: return 60.0  // $$$$
        default: return 20.0
        }
    }

    // Quick suggestions for home screen
    func getQuickSuggestions() -> [QuickSuggestion] {
        return [
            QuickSuggestion(
                emoji: "☕",
                text: "Best coffee near me",
                intent: FoodIntent(
                    displayText: "Best coffee near me",
                    emoji: "☕",
                    searchType: .coffee,
                    filters: SearchFilters(maxDistance: 1000, minRating: 4.0)
                )
            ),
            QuickSuggestion(
                emoji: "💪",
                text: "High protein near me",
                intent: FoodIntent(
                    displayText: "High protein near me",
                    emoji: "💪",
                    searchType: .highProtein,
                    filters: SearchFilters(maxDistance: 1500)
                )
            ),
            QuickSuggestion(
                emoji: "🛒",
                text: "Cheap groceries near me",
                intent: FoodIntent(
                    displayText: "Cheap groceries near me",
                    emoji: "🛒",
                    searchType: .groceries,
                    filters: SearchFilters(maxDistance: 2000, maxPrice: 50)
                )
            ),
            QuickSuggestion(
                emoji: "⚡",
                text: "Quick breakfast",
                intent: FoodIntent(
                    displayText: "Quick breakfast",
                    emoji: "⚡",
                    searchType: .quickBreakfast,
                    filters: SearchFilters(maxDistance: 800)
                )
            ),
            QuickSuggestion(
                emoji: "🥗",
                text: "Healthy lunch",
                intent: FoodIntent(
                    displayText: "Healthy lunch",
                    emoji: "🥗",
                    searchType: .healthyLunch,
                    filters: SearchFilters(maxDistance: 1200)
                )
            )
        ]
    }
}
