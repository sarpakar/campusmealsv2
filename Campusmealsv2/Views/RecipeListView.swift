//
//  RecipeListView.swift
//  Campusmealsv2
//
//  Created by Claude on 04/10/2025.
//

import SwiftUI

struct RecipeListView: View {
    @Environment(\.dismiss) var dismiss
    let fridgeItems: [DetectedFridgeItem]

    @State private var recipes: [Recipe] = []
    @State private var isLoading = true
    @State private var selectedRecipe: Recipe?
    @State private var showCards = false

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        ZStack {
            // Background
            Color(UIColor.systemGroupedBackground)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                topBar

                if isLoading {
                    loadingView
                } else {
                    // Recipe List (Uber-style)
                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 16) {
                            // Header
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Recipe suggestions")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.black)

                                Text("Based on what's in your fridge")
                                    .font(.system(size: 17))
                                    .foregroundColor(.gray)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 20)
                            .padding(.top, 16)

                            // Recipe Cards (with staggered Uber-style animation)
                            ForEach(Array(recipes.enumerated()), id: \.element.id) { index, recipe in
                                RecipeCard(recipe: recipe)
                                    .padding(.horizontal, 16)
                                    .opacity(showCards ? 1 : 0)
                                    .offset(y: showCards ? 0 : 50)
                                    .animation(
                                        .spring(response: 0.6, dampingFraction: 0.8)
                                            .delay(Double(index) * 0.1),
                                        value: showCards
                                    )
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                            selectedRecipe = recipe
                                        }
                                    }
                            }
                        }
                        .padding(.bottom, 120) // Space for bottom button
                    }

                    // Bottom CTA Button (Uber-style with slide-up animation)
                    if let recommended = recipes.first(where: { $0.isRecommended }) {
                        bottomButton(recipe: recommended)
                            .opacity(showCards ? 1 : 0)
                            .offset(y: showCards ? 0 : 100)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: showCards)
                    }
                }
            }
        }
        .onAppear {
            Task {
                await loadRecipes()
            }
        }
        .sheet(item: $selectedRecipe) { recipe in
            RecipeDetailView(recipe: recipe)
        }
    }

    // MARK: - Top Bar
    private var topBar: some View {
        HStack(spacing: 12) {
            // Back Button
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
            }

            Spacer()

            Text("AI Recipes")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)

            Spacer()

            // Placeholder for balance
            Circle()
                .fill(Color.clear)
                .frame(width: 40, height: 40)
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
        .background(Color(UIColor.systemGroupedBackground))
    }

    // MARK: - Loading View (Uber-style skeleton)
    private var loadingView: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 16) {
                // Header
                VStack(alignment: .leading, spacing: 8) {
                    Text("Recipe suggestions")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)

                    Text("Based on what's in your fridge")
                        .font(.system(size: 17))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 16)

                // Skeleton Cards (3 loading cards like Uber)
                ForEach(0..<3, id: \.self) { _ in
                    SkeletonRecipeCard()
                        .padding(.horizontal, 16)
                }
            }
            .padding(.bottom, 120)
        }
    }

    // MARK: - Bottom Button
    private func bottomButton(recipe: Recipe) -> some View {
        VStack(spacing: 0) {
            Spacer()

            Button(action: {
                selectedRecipe = recipe
            }) {
                HStack {
                    Spacer()
                    Text("Cook \(recipe.name)")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.white)
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(Color.black)
                .cornerRadius(12)
                .padding(.horizontal, 16)
                .padding(.bottom, 34)
            }
            .shadow(color: Color.black.opacity(0.2), radius: 16, x: 0, y: -4)
        }
        .ignoresSafeArea(edges: .bottom)
    }

    // MARK: - Load Recipes
    private func loadRecipes() async {
        do {
            let generated = try await GeminiVisionService.shared.generateRecipes(from: fridgeItems)
            await MainActor.run {
                recipes = generated
                isLoading = false
                print("✅ Loaded \(generated.count) recipes")

                // Trigger Uber-style staggered animations
                withAnimation {
                    showCards = true
                }
            }
        } catch {
            print("❌ Failed to generate recipes: \(error.localizedDescription)")
            await MainActor.run {
                isLoading = false
            }
        }
    }
}

// MARK: - Skeleton Card (Modern 2024 style)
struct SkeletonRecipeCard: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        HStack(spacing: 16) {
            // Emoji placeholder with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(UIColor.systemGray5), Color(UIColor.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 80, height: 80)
                .overlay(
                    Circle()
                        .stroke(Color(UIColor.systemGray4).opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                // Title placeholder
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(UIColor.systemGray5), Color(UIColor.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 200, height: 18)

                // Stats placeholder
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(UIColor.systemGray6), Color(UIColor.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 140, height: 14)
            }

            Spacer()
        }
        .padding(16)
        .frame(height: 112)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 8, x: 0, y: 2)
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Recipe Card (Uber-style - MINIMAL with EMOJI PHOTO)
struct RecipeCard: View {
    let recipe: Recipe
    @State private var isPressed = false

    var body: some View {
        HStack(spacing: 16) {
            // Emoji as Photo (same as skeleton)
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.gray.opacity(0.1), Color.gray.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                Text(recipe.emojiCombo)
                    .font(.system(size: 48))
            }
            .frame(width: 80, height: 80)

            // Recipe Info (MINIMAL TEXT - same spacing as skeleton)
            VStack(alignment: .leading, spacing: 6) {
                Text(recipe.name)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                // Stats ONLY
                HStack(spacing: 8) {
                    Text(recipe.cookTime)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Text("•")
                        .foregroundColor(.gray)

                    Text(recipe.protein)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }
            }

            Spacer()
        }
        .padding(16)
        .frame(height: 112) // SAME height as skeleton
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(
                            recipe.isRecommended ? Color.black : Color.clear,
                            lineWidth: recipe.isRecommended ? 2 : 0
                        )
                )
                .shadow(
                    color: Color.black.opacity(isPressed ? 0.15 : 0.06),
                    radius: isPressed ? 12 : 8,
                    x: 0,
                    y: isPressed ? 4 : 2
                )
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.25, dampingFraction: 0.75), value: isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Recipe Detail View (Placeholder)
struct RecipeDetailView: View {
    @Environment(\.dismiss) var dismiss
    let recipe: Recipe

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Header
                    VStack(alignment: .leading, spacing: 12) {
                        Text(recipe.emojiCombo)
                            .font(.system(size: 72))

                        Text(recipe.name)
                            .font(.system(size: 28, weight: .bold))

                        Text(recipe.description)
                            .font(.system(size: 17))
                            .foregroundColor(.gray)

                        HStack(spacing: 20) {
                            StatBadge(icon: "clock", value: recipe.cookTime)
                            StatBadge(icon: "flame", value: recipe.protein)
                            StatBadge(icon: "chart.bar", value: recipe.calories)
                            StatBadge(icon: "star", value: recipe.difficulty)
                        }
                    }

                    Divider()

                    // Ingredients
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Ingredients")
                            .font(.system(size: 22, weight: .bold))

                        ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                            HStack(alignment: .top, spacing: 8) {
                                Text("•")
                                Text(ingredient)
                                    .font(.system(size: 16))
                            }
                        }
                    }

                    Divider()

                    // Instructions
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Instructions")
                            .font(.system(size: 22, weight: .bold))

                        ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                            HStack(alignment: .top, spacing: 12) {
                                Text("\(index + 1).")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.blue)

                                Text(instruction)
                                    .font(.system(size: 16))
                            }
                        }
                    }
                }
                .padding(20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    RecipeListView(fridgeItems: [
        DetectedFridgeItem(name: "Steak", quantity: "8 oz", position: TapZonePosition(x: 0.1, y: 0.1, width: 0.2, height: 0.2), emoji: "🥩"),
        DetectedFridgeItem(name: "Oranges", quantity: "6 oranges", position: TapZonePosition(x: 0.3, y: 0.3, width: 0.2, height: 0.2), emoji: "🍊")
    ])
}
