//
//  FridgeView.swift
//  Campusmealsv2
//
//  Created by Claude on 04/10/2025.
//

import SwiftUI

struct FridgeView: View {
    @Environment(\.dismiss) var dismiss
    @State private var detectedItems: [DetectedFridgeItem] = []
    @State private var selectedItem: DetectedFridgeItem?
    @State private var isAnalyzing = false
    @State private var showRecipes = false
    @State private var isLoadingRecipes = false
    @State private var recipes: [Recipe] = []
    @State private var selectedRecipe: Recipe?
    @State private var isLoadingRecipeDetail = false

    // Cache the analysis results
    @AppStorage("cachedFridgeItems") private var cachedItemsData: Data = Data()
    @AppStorage("fridgeLastAnalyzed") private var lastAnalyzedTimestamp: Double = 0

    // Cache recipe suggestions
    @AppStorage("cachedRecipes") private var cachedRecipesData: Data = Data()
    @AppStorage("recipesLastGenerated") private var recipesLastGenerated: Double = 0

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Full-screen fridge image with proper constraints
                Image("fridge")
                    .resizable()
                    .scaledToFill()
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .clipped()
                    .ignoresSafeArea()
                    .overlay(
                        // Tap zones overlay (adjusted for scaledToFill crop)
                        tapZonesOverlay(geometry: geometry)
                    )

                // Overlay UI - EXACT structure as HomeScreen
                VStack(spacing: 0) {
                    // Top Search Bar equivalent (positioned lower like HomeScreen)
                    topBar
                        .padding(.top, max(geometry.safeAreaInsets.top, 50))

                    Spacer()

                    // Bottom Card equivalent
                    bottomCard
                }
                .ignoresSafeArea(edges: .bottom)

                // Ingredient card popup (same transition as VendorDetailCard)
                if let item = selectedItem {
                    ingredientCardPopup(item: item)
                        .transition(.move(edge: .bottom))
                        .zIndex(1)
                }

                // Recipe detail popup
                if let recipe = selectedRecipe {
                    recipeDetailPopup(recipe: recipe)
                        .transition(.move(edge: .bottom))
                        .zIndex(2)
                }
            }
        }
        .ignoresSafeArea()
        .onAppear {
            Task {
                await analyzeFridgeInBackground()
            }
        }
    }

    // MARK: - Silent Background Analysis (Powered by Gemini) with Caching
    private func analyzeFridgeInBackground() async {
        // Check if we have cached results (valid for 24 hours)
        let currentTime = Date().timeIntervalSince1970
        let cacheValidDuration: Double = 24 * 60 * 60 // 24 hours

        if currentTime - lastAnalyzedTimestamp < cacheValidDuration, !cachedItemsData.isEmpty {
            // Load from cache
            if let cached = try? JSONDecoder().decode([DetectedFridgeItem].self, from: cachedItemsData) {
                await MainActor.run {
                    detectedItems = cached
                    print("✅ Loaded \(cached.count) items from cache")
                }
                return
            }
        }

        // No cache or expired - analyze with Gemini
        guard let image = UIImage(named: "fridge") else {
            print("❌ Fridge image not found")
            return
        }

        isAnalyzing = true

        do {
            let items = try await GeminiVisionService.shared.analyzeFridge(image: image)

            // Cache the results
            if let encoded = try? JSONEncoder().encode(items) {
                cachedItemsData = encoded
                lastAnalyzedTimestamp = currentTime
            }

            await MainActor.run {
                detectedItems = items
                isAnalyzing = false
                print("✅ Gemini detected \(items.count) items (cached for 24h)")
            }
        } catch {
            print("❌ Fridge analysis failed: \(error.localizedDescription)")
            await MainActor.run {
                isAnalyzing = false
            }
        }
    }

    // Function to clear cache when user updates fridge (call this from camera button)
    private func clearFridgeCache() {
        cachedItemsData = Data()
        lastAnalyzedTimestamp = 0
        detectedItems = []
        print("🗑️ Fridge cache cleared")
    }

    // MARK: - Tap Zones Overlay (Adjusted for scaledToFill crop)
    private func tapZonesOverlay(geometry: GeometryProxy) -> some View {
        // Get the original fridge image to calculate crop offset
        guard let fridgeImage = UIImage(named: "fridge") else {
            return AnyView(EmptyView())
        }

        let imageAspect = fridgeImage.size.width / fridgeImage.size.height
        let viewAspect = geometry.size.width / geometry.size.height

        // Calculate how much is cropped when using scaledToFill
        var cropOffsetX: CGFloat = 0
        var cropOffsetY: CGFloat = 0
        var visibleScale: CGFloat = 1

        if imageAspect > viewAspect {
            // Image is wider - crops left/right
            visibleScale = geometry.size.height / fridgeImage.size.height
            let scaledWidth = fridgeImage.size.width * visibleScale
            cropOffsetX = (scaledWidth - geometry.size.width) / 2
        } else {
            // Image is taller - crops top/bottom
            visibleScale = geometry.size.width / fridgeImage.size.width
            let scaledHeight = fridgeImage.size.height * visibleScale
            cropOffsetY = (scaledHeight - geometry.size.height) / 2
        }

        return AnyView(
            ZStack(alignment: .topLeading) {
                ForEach(detectedItems) { item in
                    // Convert Gemini's normalized coords to actual pixel positions
                    let originalX = item.position.x * fridgeImage.size.width
                    let originalY = item.position.y * fridgeImage.size.height
                    let originalWidth = item.position.width * fridgeImage.size.width
                    let originalHeight = item.position.height * fridgeImage.size.height

                    // Scale to view size and adjust for crop
                    let scaledX = (originalX * visibleScale) - cropOffsetX
                    let scaledY = (originalY * visibleScale) - cropOffsetY
                    let scaledWidth = originalWidth * visibleScale
                    let scaledHeight = originalHeight * visibleScale

                    // Only show if visible in cropped view
                    if scaledX + scaledWidth > 0 && scaledX < geometry.size.width &&
                       scaledY + scaledHeight > 0 && scaledY < geometry.size.height {

                        // Invisible tap zone
                        Color.clear
                            .frame(width: scaledWidth, height: scaledHeight)
                            .contentShape(Rectangle())
                            .offset(x: scaledX, y: scaledY)
                            .onTapGesture {
                                print("🎯 Tapped: \(item.name)")
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedItem = item
                                }
                            }
                    }
                }
            }
            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
        )
    }

    // MARK: - Top Bar (exact copy of searchBar structure)
    private var topBar: some View {
        HStack(spacing: 12) {
            // Close Button (same as menu button)
            Button(action: {
                dismiss()
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                    Image(systemName: "xmark")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.black)
                }
            }

            // Title Bar (same as search bar)
            HStack(spacing: 12) {
                Image(systemName: "refrigerator")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(Color(.systemGray))

                Text("My Fridge")
                    .font(.system(size: 16))
                    .foregroundColor(.black)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)
            )

            // Camera Button (same as location button with matching interaction)
            Button(action: {
                withAnimation(.interpolatingSpring(stiffness: 200, damping: 25)) {
                    // TODO: Open camera
                }
            }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.black.opacity(0.12), radius: 8, x: 0, y: 4)

                    Image(systemName: "camera.fill")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(citiBikeBlue)
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: - Bottom Card (EXPANDABLE for recipes)
    private var bottomCard: some View {
        VStack(spacing: 0) {
            // Home Indicator
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            if !showRecipes {
                // COLLAPSED STATE - Original card
                VStack(spacing: 12) {
                    HStack(alignment: .center, spacing: 12) {
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 6) {
                                Text("🧊")
                                    .font(.system(size: 14))

                                Text("What's inside?")
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.systemGray))
                            }

                            Text("My Fridge")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }

                        Spacer()

                        Button(action: {
                            withAnimation(.interpolatingSpring(stiffness: 200, damping: 25)) {
                                // TODO: Open camera
                            }
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 15, weight: .semibold))

                                Text("Scan AI")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 18)
                            .padding(.vertical, 10)
                            .background(
                                RoundedRectangle(cornerRadius: 22)
                                    .fill(Color.black)
                            )
                        }
                    }

                    Button(action: {
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            showRecipes = true
                        }
                        Task {
                            await loadRecipes()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: "book.fill")
                                .font(.system(size: 15, weight: .semibold))

                            Text("Recipe Suggestions")
                                .font(.system(size: 16, weight: .semibold))

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.black)
                        .padding(.horizontal, 18)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 16)
            } else {
                // EXPANDED STATE - Recipe cards
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 12) {
                        // Header
                        HStack {
                            Text("Recipe Suggestions")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.black)

                            Spacer()

                            // Refresh button
                            Button(action: {
                                Task {
                                    await loadRecipes(forceRefresh: true)
                                }
                            }) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.black)
                            }
                            .disabled(isLoadingRecipes)
                            .opacity(isLoadingRecipes ? 0.3 : 1.0)

                            // Close button
                            Button(action: {
                                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                                    showRecipes = false
                                    recipes = []
                                }
                            }) {
                                Image(systemName: "xmark.circle.fill")
                                    .font(.system(size: 24))
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 8)

                        if isLoadingRecipes {
                            // SKELETON CARDS (3 loading)
                            ForEach(0..<3, id: \.self) { _ in
                                RecipeSkeletonCard()
                                    .padding(.horizontal, 20)
                            }
                        } else {
                            // REAL RECIPE CARDS
                            ForEach(recipes) { recipe in
                                RecipeCardCompact(recipe: recipe) {
                                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                        selectedRecipe = recipe
                                        isLoadingRecipeDetail = true
                                    }
                                }
                                .padding(.horizontal, 20)
                            }
                        }
                    }
                    .padding(.bottom, 20)
                }
                .frame(maxHeight: 400)
            }
        }
        .padding(.bottom, 34)
        .background(
            Color.white
                .cornerRadius(16, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }

    // MARK: - Load Recipes (with caching)
    private func loadRecipes(forceRefresh: Bool = false) async {
        // Check cache first (valid for 24 hours) unless force refresh
        let currentTime = Date().timeIntervalSince1970
        let cacheValidDuration: Double = 24 * 60 * 60

        if !forceRefresh && currentTime - recipesLastGenerated < cacheValidDuration, !cachedRecipesData.isEmpty {
            // Load from cache instantly
            if let cached = try? JSONDecoder().decode([Recipe].self, from: cachedRecipesData) {
                await MainActor.run {
                    recipes = cached
                    isLoadingRecipes = false
                    print("✅ Loaded \(cached.count) recipes from cache")
                }
                return
            }
        }

        // No cache or force refresh - generate fresh
        isLoadingRecipes = true

        do {
            let generated = try await GeminiVisionService.shared.generateRecipes(from: detectedItems)

            // Cache the recipes
            if let encoded = try? JSONEncoder().encode(generated) {
                cachedRecipesData = encoded
                recipesLastGenerated = currentTime
            }

            await MainActor.run {
                recipes = generated
                isLoadingRecipes = false
                print("✅ Generated \(generated.count) recipes (cached for 24h)")
            }
        } catch {
            print("❌ Failed to generate recipes: \(error.localizedDescription)")
            await MainActor.run {
                isLoadingRecipes = false
            }
        }
    }

    // MARK: - Ingredient Card Popup (Matches VendorDetailCard Style)
    private func ingredientCardPopup(item: DetectedFridgeItem) -> some View {
        // Card at bottom (matching VendorDetailCard structure) - no black overlay
        ZStack {
            // Invisible tap area above card to close
            VStack {
                Color.clear
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                            selectedItem = nil
                        }
                    }

                Spacer()
                    .frame(height: UIScreen.main.bounds.height * 0.6)
            }
            .ignoresSafeArea()

            // Card
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Drag Handle (same as VendorDetailCard) - tappable to close
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(.systemGray4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 12)
                        .onTapGesture {
                            withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                selectedItem = nil
                            }
                        }

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Emoji Header (centered)
                            Text(item.emoji)
                                .font(.system(size: 72))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)

                            // Item Info Section
                            VStack(alignment: .leading, spacing: 12) {
                                // Name
                                Text(item.name)
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)

                                // Quantity with icon
                                HStack(spacing: 8) {
                                    Image(systemName: "scalemass")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(citiBikeBlue)

                                    Text(item.quantity)
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(.black)
                                }

                                // Category (if available)
                                if let category = item.category {
                                    HStack(spacing: 8) {
                                        Image(systemName: "tag.fill")
                                            .font(.system(size: 13))
                                            .foregroundColor(.gray)

                                        Text(category)
                                            .font(.system(size: 15))
                                            .foregroundColor(.gray)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            Divider()
                                .padding(.horizontal, 20)
                                .padding(.vertical, 8)

                            // Action Buttons Section
                            VStack(alignment: .leading, spacing: 16) {
                                Text("Quick Actions")
                                    .font(.system(size: 18, weight: .semibold))
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 20)

                                // Find Recipes Button (Primary - matches "View Full Menu")
                                Button(action: {
                                    // TODO: Show recipes with this ingredient
                                }) {
                                    HStack {
                                        Image(systemName: "book.fill")
                                            .font(.system(size: 15, weight: .semibold))

                                        Text("Find Recipes")
                                            .font(.system(size: 17, weight: .semibold))

                                        Spacer()

                                        Image(systemName: "chevron.right")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 14)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.black)
                                    )
                                }
                                .padding(.horizontal, 20)

                                // Add to Shopping List Button (Secondary - matches fridge button style)
                                Button(action: {
                                    // TODO: Add to shopping list
                                }) {
                                    HStack(spacing: 8) {
                                        Image(systemName: "cart.fill")
                                            .font(.system(size: 15, weight: .semibold))

                                        Text("Add to Shopping List")
                                            .font(.system(size: 16, weight: .semibold))

                                        Spacer()

                                        Image(systemName: "plus")
                                            .font(.system(size: 14, weight: .semibold))
                                    }
                                    .foregroundColor(.black)
                                    .padding(.horizontal, 18)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.white)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                                            )
                                    )
                                }
                                .padding(.horizontal, 20)
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.bottom, 34)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.6)
                .background(
                    Color.white
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: -4)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }

    // MARK: - Recipe Detail Popup (On-demand generation)
    private func recipeDetailPopup(recipe: Recipe) -> some View {
        ZStack {
            // Dimmed background
            Color.black.opacity(0.4)
                .ignoresSafeArea()
                .onTapGesture {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                        selectedRecipe = nil
                        isLoadingRecipeDetail = false
                    }
                }

            // Card
            VStack {
                Spacer()

                VStack(spacing: 0) {
                    // Drag Handle
                    RoundedRectangle(cornerRadius: 2.5)
                        .fill(Color(.systemGray4))
                        .frame(width: 36, height: 5)
                        .padding(.top, 8)
                        .padding(.bottom, 12)

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 20) {
                            // Emoji Header (centered)
                            Text(recipe.emojiCombo)
                                .font(.system(size: 72))
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 8)

                            // Recipe Info Section
                            VStack(alignment: .leading, spacing: 12) {
                                // Name
                                Text(recipe.name)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.black)

                                // Description
                                if !recipe.description.isEmpty {
                                    Text(recipe.description)
                                        .font(.system(size: 17))
                                        .foregroundColor(.gray)
                                }

                                // Stats
                                HStack(spacing: 16) {
                                    StatBadge(icon: "clock", value: recipe.cookTime)
                                    StatBadge(icon: "flame", value: recipe.protein)
                                    StatBadge(icon: "chart.bar", value: recipe.calories)
                                }
                            }
                            .padding(.horizontal, 20)

                            Divider()
                                .padding(.horizontal, 20)

                            // Ingredients
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Ingredients")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)

                                ForEach(Array(recipe.ingredients.enumerated()), id: \.offset) { _, ingredient in
                                    HStack(alignment: .top, spacing: 8) {
                                        Text("•")
                                            .foregroundColor(.black)
                                        Text(ingredient)
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            Divider()
                                .padding(.horizontal, 20)

                            // Instructions
                            VStack(alignment: .leading, spacing: 12) {
                                Text("Instructions")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(.black)

                                ForEach(Array(recipe.instructions.enumerated()), id: \.offset) { index, instruction in
                                    HStack(alignment: .top, spacing: 12) {
                                        Text("\(index + 1).")
                                            .font(.system(size: 16, weight: .bold))
                                            .foregroundColor(citiBikeBlue)

                                        Text(instruction)
                                            .font(.system(size: 16))
                                            .foregroundColor(.black)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            // Close button
                            Button(action: {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    selectedRecipe = nil
                                    isLoadingRecipeDetail = false
                                }
                            }) {
                                HStack {
                                    Spacer()
                                    Text("Close")
                                        .font(.system(size: 17, weight: .semibold))
                                        .foregroundColor(.white)
                                    Spacer()
                                }
                                .padding(.vertical, 14)
                                .background(Color.black)
                                .cornerRadius(12)
                            }
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                        }
                        .padding(.bottom, 34)
                    }
                }
                .frame(maxHeight: UIScreen.main.bounds.height * 0.75)
                .background(
                    Color.white
                        .cornerRadius(16, corners: [.topLeft, .topRight])
                        .shadow(color: Color.black.opacity(0.15), radius: 20, x: 0, y: -8)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
    }
}

// MARK: - Recipe Skeleton Card (Modern skeleton - 2024 style)
struct RecipeSkeletonCard: View {
    @State private var opacity: Double = 0.3

    var body: some View {
        HStack(spacing: 12) {
            // Emoji placeholder with gradient
            Circle()
                .fill(
                    LinearGradient(
                        colors: [Color(UIColor.systemGray5), Color(UIColor.systemGray6)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 50, height: 50)
                .overlay(
                    Circle()
                        .stroke(Color(UIColor.systemGray4).opacity(0.3), lineWidth: 1)
                )

            VStack(alignment: .leading, spacing: 6) {
                // Recipe name placeholder with rounded caps
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(UIColor.systemGray5), Color(UIColor.systemGray6)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 180, height: 16)

                // Time placeholder
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color(UIColor.systemGray6), Color(UIColor.systemGray5)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: 80, height: 14)
            }

            Spacer()
        }
        .padding(.horizontal, 18)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
                )
        )
        .opacity(opacity)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                opacity = 1.0
            }
        }
    }
}

// MARK: - Recipe Card Compact (SAME STYLE as Fridge button)
struct RecipeCardCompact: View {
    let recipe: Recipe
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                // Emoji combo with subtle background
                Text(recipe.emojiCombo)
                    .font(.system(size: 32))
                    .frame(width: 50, height: 50)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.gray.opacity(0.08), Color.gray.opacity(0.03)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )

                VStack(alignment: .leading, spacing: 4) {
                    // Recipe name ONLY
                    Text(recipe.name)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    // Cook time ONLY
                    Text(recipe.cookTime)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Stat Badge Component
struct StatBadge: View {
    let icon: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14))
            Text(value)
                .font(.system(size: 14, weight: .medium))
        }
        .foregroundColor(Color(red: 0/255, green: 174/255, blue: 239/255))
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(red: 0/255, green: 174/255, blue: 239/255).opacity(0.1))
        .cornerRadius(8)
    }
}

#Preview {
    FridgeView()
}
