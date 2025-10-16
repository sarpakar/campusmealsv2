//
//  PostCard.swift
//  Campusmealsv2
//
//  Created by sarp akar on 03/10/2025.
//

import SwiftUI
import MapKit

struct PostCard: View {
    let post: Post

    @State private var currentPhotoIndex = 0
    @State private var isLiked: Bool
    @State private var isBookmarked: Bool
    @State private var showIngredientAnalysis = false
    @State private var analyzedIngredients = ""
    @State private var isAnalyzing = false
    @State private var foodCenterPosition: (x: CGFloat, y: CGFloat) = (0.5, 0.45)
    @State private var viewStartTime = Date()
    @State private var showDeleteAlert = false
    @State private var restaurantPhotos: [String] = []

    init(post: Post) {
        self.post = post
        _isLiked = State(initialValue: post.isLikedByCurrentUser ?? false)
        _isBookmarked = State(initialValue: post.isBookmarkedByCurrentUser ?? false)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack(spacing: 12) {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 44, height: 44)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .frame(width: 41, height: 41)
                            .overlay(
                                Text(String(post.userName.prefix(1)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.purple)
                            )
                    )

                VStack(alignment: .leading, spacing: 3) {
                    Text(post.userName)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.black)

                    HStack(spacing: 4) {
                        if let restaurant = post.restaurantName {
                            Image(systemName: "fork.knife")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.systemGray))
                            Text(restaurant)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.black)
                            if let rating = post.restaurantRating {
                                Text("•")
                                    .foregroundColor(Color(.systemGray))
                                Image(systemName: "star.fill")
                                    .font(.system(size: 10))
                                    .foregroundColor(.orange)
                                Text(String(format: "%.1f", rating))
                                    .font(.system(size: 13))
                                    .foregroundColor(Color(.systemGray))
                            }
                        } else {
                            Image(systemName: "mappin.circle.fill")
                                .font(.system(size: 12))
                                .foregroundColor(Color(.systemGray))
                            Text(post.location)
                                .font(.system(size: 13))
                                .foregroundColor(Color(.systemGray))
                        }
                    }
                }
                Spacer()
            }
            .padding(.horizontal, 18)

            // Photo - from Firebase
            ZStack {
                if let firstPhotoURL = post.foodPhotos.first {
                    // Fix Firebase Storage URL by removing :443 port (industry standard)
                    let cleanedURL = firstPhotoURL.replacingOccurrences(of: ":443", with: "")

                    AsyncImage(url: URL(string: cleanedURL)) { phase in
                        switch phase {
                        case .empty:
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    ProgressView()
                                )
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        case .failure(let error):
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay(
                                    VStack(spacing: 8) {
                                        Image(systemName: "exclamationmark.triangle")
                                            .font(.system(size: 30))
                                            .foregroundColor(.orange)
                                        Text("Failed to load image")
                                            .font(.caption)
                                            .foregroundColor(.gray)
                                        Text(cleanedURL)
                                            .font(.system(size: 8))
                                            .foregroundColor(.red)
                                            .lineLimit(2)
                                    }
                                    .padding()
                                )
                                .onAppear {
                                    print("❌ ========================================")
                                    print("❌ IMAGE LOAD FAILED")
                                    print("   Post ID: \(post.id ?? "unknown")")
                                    print("   Original URL: \(firstPhotoURL)")
                                    print("   Cleaned URL: \(cleanedURL)")
                                    print("   Error: \(error)")
                                    print("   Error Description: \(error.localizedDescription)")
                                    print("❌ ========================================")
                                }
                        @unknown default:
                            Rectangle()
                                .fill(Color(.systemGray6))
                                .frame(height: 360)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    }
                    .onTapGesture {
                        analyzeImage()
                    }
                } else {
                    Rectangle()
                        .fill(Color(.systemGray6))
                        .frame(height: 360)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            Text("No image URL")
                                .font(.caption)
                                .foregroundColor(.gray)
                        )
                }

                if isAnalyzing {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.black.opacity(0.6))
                        .frame(height: 360)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                }

                // Ingredient Pills Overlay - SCATTERED ON FOOD IMAGE
                if showIngredientAnalysis && !analyzedIngredients.isEmpty {
                    ingredientPillsScattered
                        .transition(.opacity)
                }
            }
            .padding(.horizontal, 18)

            // Notes
            Text(post.notes)
                .font(.system(size: 15))
                .foregroundColor(.black)
                .lineSpacing(4)
                .padding(.horizontal, 18)

            // Actions
            HStack(spacing: 24) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 24))
                        .foregroundColor(isLiked ? .red : .black)
                }

                Button(action: {}) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }

                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isBookmarked.toggle()
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 24))
                        .foregroundColor(.black)
                }
            }
            .padding(.horizontal, 18)
        }
        .padding(.vertical, 18)
        .background(Color.white)
        .onAppear {
            viewStartTime = Date()

            // Mark as shown for diversity tracking
            if let postId = post.id {
                RankingService.shared.markAsShown(postId: postId)
            }
        }
        .onDisappear {
            // Track view duration (Instagram/TikTok style)
            let duration = Date().timeIntervalSince(viewStartTime)
            if duration > 0.5, let postId = post.id {  // Only count if viewed > 0.5s
                Task {
                    await EngagementTracker.shared.trackView(postId: postId, duration: duration)
                }
            }
        }
    }

    // MARK: - Analyze Image
    private func analyzeImage() {
        guard let firstPhotoURL = post.foodPhotos.first else {
            print("No valid image URL")
            return
        }

        // Fix Firebase Storage URL by removing :443 port
        let cleanedURL = firstPhotoURL.replacingOccurrences(of: ":443", with: "")
        guard let url = URL(string: cleanedURL) else {
            print("Invalid URL after cleaning")
            return
        }

        isAnalyzing = true

        Task {
            do {
                // Download image from Firebase URL
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else {
                    throw NSError(domain: "PostCard", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to decode image"])
                }

                let result = try await GeminiVisionService.shared.analyzeFood(image: image)
                await MainActor.run {
                    analyzedIngredients = result
                    showIngredientAnalysis = true
                    isAnalyzing = false
                }
            } catch {
                await MainActor.run {
                    analyzedIngredients = "Failed to analyze image: \(error.localizedDescription)"
                    showIngredientAnalysis = true
                    isAnalyzing = false
                }
                print("Error analyzing image: \(error)")
            }
        }
    }

    // MARK: - Ingredient Pills SCATTERED AROUND DETECTED FOOD
    private var ingredientPillsScattered: some View {
        let ingredients = parseGeminiIngredients(analyzedIngredients)

        return ZStack {
            // Close button - top right corner
            VStack {
                HStack {
                    Spacer()
                    Button(action: {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                            showIngredientAnalysis = false
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.3), radius: 4, x: 0, y: 2)
                    }
                    .padding(12)
                }
                Spacer()
            }

            // Pills scattered AROUND the detected food location
            ForEach(Array(ingredients.enumerated()), id: \.offset) { index, ingredient in
                ScatteredIngredientPill(
                    name: ingredient.name,
                    emoji: ingredient.emoji,
                    index: index,
                    totalCount: ingredients.count,
                    imageHeight: 360,
                    foodCenter: foodCenterPosition
                )
            }
        }
        .frame(height: 360)
    }

    // Parse Gemini API comma-separated response
    private func parseGeminiIngredients(_ text: String) -> [(name: String, emoji: String)] {
        // Gemini returns: "Pasta, Tomatoes, Garlic, Olive Oil, Basil"
        let ingredientNames = text
            .components(separatedBy: CharacterSet(charactersIn: ","))
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        return ingredientNames.map { name in
            (name: name, emoji: getEmojiForIngredient(name))
        }
    }

    // Smart emoji mapping for ingredients
    private func getEmojiForIngredient(_ ingredient: String) -> String {
        let lowercased = ingredient.lowercased()

        // Proteins
        if lowercased.contains("chicken") { return "🍗" }
        if lowercased.contains("beef") || lowercased.contains("steak") { return "🥩" }
        if lowercased.contains("pork") || lowercased.contains("bacon") { return "🥓" }
        if lowercased.contains("fish") || lowercased.contains("salmon") { return "🐟" }
        if lowercased.contains("shrimp") || lowercased.contains("prawn") { return "🦐" }
        if lowercased.contains("egg") { return "🥚" }

        // Vegetables
        if lowercased.contains("tomato") { return "🍅" }
        if lowercased.contains("lettuce") || lowercased.contains("salad") { return "🥬" }
        if lowercased.contains("carrot") { return "🥕" }
        if lowercased.contains("broccoli") { return "🥦" }
        if lowercased.contains("pepper") { return "🫑" }
        if lowercased.contains("onion") { return "🧅" }
        if lowercased.contains("garlic") { return "🧄" }
        if lowercased.contains("potato") { return "🥔" }
        if lowercased.contains("mushroom") { return "🍄" }
        if lowercased.contains("corn") { return "🌽" }
        if lowercased.contains("avocado") { return "🥑" }
        if lowercased.contains("spinach") { return "🥬" }

        // Carbs & Grains
        if lowercased.contains("pasta") || lowercased.contains("spaghetti") || lowercased.contains("noodle") { return "🍝" }
        if lowercased.contains("rice") { return "🍚" }
        if lowercased.contains("bread") { return "🍞" }
        if lowercased.contains("tortilla") { return "🫓" }

        // Dairy
        if lowercased.contains("cheese") || lowercased.contains("parmesan") || lowercased.contains("mozzarella") { return "🧀" }
        if lowercased.contains("milk") { return "🥛" }
        if lowercased.contains("butter") { return "🧈" }
        if lowercased.contains("cream") { return "🥛" }

        // Fruits
        if lowercased.contains("lemon") { return "🍋" }
        if lowercased.contains("lime") { return "🍋" }
        if lowercased.contains("orange") { return "🍊" }
        if lowercased.contains("apple") { return "🍎" }
        if lowercased.contains("banana") { return "🍌" }
        if lowercased.contains("strawberr") { return "🍓" }

        // Herbs & Seasonings
        if lowercased.contains("basil") { return "🌿" }
        if lowercased.contains("parsley") || lowercased.contains("cilantro") { return "🌿" }
        if lowercased.contains("salt") { return "🧂" }
        if lowercased.contains("chili") || lowercased.contains("spice") { return "🌶️" }

        // Oils & Liquids
        if lowercased.contains("olive oil") || lowercased.contains("oil") { return "🫒" }
        if lowercased.contains("wine") { return "🍷" }
        if lowercased.contains("sauce") { return "🥫" }

        // Default
        return "🍽️"
    }

    // MARK: - AI Recommendations
    private var aiRecommendations: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(red: 0.6, green: 0.4, blue: 0.9))

                Text("Based on your preferences, get it from Trader Joe's today")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.black)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    IngredientCircle(name: "Parmesan", emoji: "🧀")
                    IngredientCircle(name: "Tomatoes", emoji: "🍅")
                    IngredientCircle(name: "Pasta", emoji: "🍝")
                    IngredientCircle(name: "Basil", emoji: "🌿")
                    IngredientCircle(name: "Olive Oil", emoji: "🫒")
                    IngredientCircle(name: "Garlic", emoji: "🧄")
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.97, green: 0.96, blue: 0.99))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.purple.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Header
    private var header: some View {
        HStack(spacing: 12) {
            // Profile Picture
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 48, height: 48)

                Circle()
                    .fill(Color.white)
                    .frame(width: 45, height: 45)

                Circle()
                    .fill(userColor(for: post.userName))
                    .frame(width: 42, height: 42)
                    .overlay(
                        Text(String(post.userName.prefix(1)).uppercased())
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(post.userName)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 4) {
                    Image(systemName: "mappin.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.gray)

                    Text(post.location)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)

                    Text("•")
                        .foregroundColor(.gray)

                    Text(timeAgo)
                        .font(.system(size: 13))
                        .foregroundColor(.gray)
                }
            }

            Spacer()

            Button(action: {}) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.gray)
                    .rotationEffect(.degrees(90))
            }
        }
    }

    // MARK: - Restaurant Info
    private func restaurantInfo(name: String, rating: Double) -> some View {
        HStack(spacing: 8) {
            Text("\(post.userName.split(separator: " ").first ?? "") ranked")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.gray)

            Text(name)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            ZStack {
                Circle()
                    .stroke(Color.green.opacity(0.2), lineWidth: 3)
                    .frame(width: 48, height: 48)

                Circle()
                    .trim(from: 0, to: CGFloat(rating / 10.0))
                    .stroke(Color.green, style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .frame(width: 48, height: 48)
                    .rotationEffect(.degrees(-90))

                Text(String(format: "%.1f", rating))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.green)
            }
        }
        .padding(.vertical, 8)
    }

    // MARK: - Photo Layout (BeReal Style - Dual Camera)
    private var photoCarousel: some View {
        ZStack(alignment: .topLeading) {
            // Main photo (back camera - meal)
            AsyncImage(url: URL(string: post.foodPhotos.first ?? "")) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color(.systemGray6))
            }
            .frame(height: 400)
            .clipShape(RoundedRectangle(cornerRadius: 16))

            // Selfie inset (top left - BeReal style)
            if let selfie = post.selfiePhotoURL {
                AsyncImage(url: URL(string: selfie)) { image in
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                } placeholder: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(userColor(for: post.userName))

                        Text(String(post.userName.prefix(1)).uppercased())
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                }
                .frame(width: 100, height: 130)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.black, lineWidth: 3)
                )
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
                .padding(12)
            }

            // Additional photos indicator
            if post.foodPhotos.count > 1 {
                HStack(spacing: 4) {
                    ForEach(0..<min(post.foodPhotos.count, 3), id: \.self) { index in
                        Circle()
                            .fill(index == 0 ? Color.white : Color.white.opacity(0.5))
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(8)
                .background(
                    Capsule()
                        .fill(Color.black.opacity(0.3))
                        .blur(radius: 4)
                )
                .padding(.bottom, 12)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
            }
        }
        .frame(height: 400)
    }

    // MARK: - Diet Tags
    private var dietTags: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(post.dietTags, id: \.self) { tag in
                    HStack(spacing: 4) {
                        Text(tag.emoji)
                            .font(.system(size: 12))

                        Text(tag.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(tagColor(for: tag))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(tagColor(for: tag).opacity(0.12))
                    )
                }
            }
        }
    }

    // MARK: - Notes
    private var notes: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Notes:")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(post.notes)
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray6))
                .lineSpacing(5)
        }
    }

    // MARK: - Nutrition Info
    private func nutritionInfo(_ nutrition: PostNutritionInfo) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Nutrition")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            HStack(spacing: 16) {
                NutritionBadge(label: "Cal", value: "\(nutrition.calories)", color: .orange)
                NutritionBadge(label: "Protein", value: nutrition.protein, color: .blue)
                NutritionBadge(label: "Carbs", value: nutrition.carbs, color: .green)
                NutritionBadge(label: "Fat", value: nutrition.fat, color: .purple)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .strokeBorder(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Social Actions
    private var socialActions: some View {
        VStack(spacing: 14) {
            // Stats
            HStack(spacing: 16) {
                Text("\(post.likes) likes")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Text("View \(post.comments) comments")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)

                Spacer()

                Text("\(post.bookmarks) bookmarks")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
            }

            Divider()
                .background(Color.white.opacity(0.1))

            // Action Buttons
            HStack(spacing: 24) {
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isLiked.toggle()
                    }
                }) {
                    Image(systemName: isLiked ? "heart.fill" : "heart")
                        .font(.system(size: 26))
                        .foregroundColor(isLiked ? .red : .white)
                }

                Button(action: {}) {
                    Image(systemName: "bubble.right")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }

                Button(action: {}) {
                    Image(systemName: "paperplane")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }

                Spacer()

                Button(action: {}) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }

                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        isBookmarked.toggle()
                    }
                }) {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 26))
                        .foregroundColor(.white)
                }
            }
        }
    }

    // MARK: - Timestamp
    private var timestamp: some View {
        Text(formattedDate)
            .font(.system(size: 13))
            .foregroundColor(.gray)
    }

    // MARK: - Helpers
    private var timeAgo: String {
        let interval = Date().timeIntervalSince(post.timestamp)
        let hours = Int(interval / 3600)
        if hours < 24 {
            return "\(hours)h ago"
        } else {
            let days = hours / 24
            return "\(days)d ago"
        }
    }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d"
        return formatter.string(from: post.timestamp)
    }

    private func userColor(for name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }

    private func tagColor(for tag: DietTag) -> Color {
        switch tag.color {
        case "green": return .green
        case "blue": return .blue
        case "orange": return .orange
        case "mint": return .mint
        case "yellow": return .yellow
        case "brown": return .brown
        case "purple": return .purple
        default: return .gray
        }
    }
}

// MARK: - Scattered Ingredient Pill (Positioned AROUND detected food)
struct ScatteredIngredientPill: View {
    let name: String
    let emoji: String
    let index: Int
    let totalCount: Int
    let imageHeight: CGFloat
    let foodCenter: (x: CGFloat, y: CGFloat)

    @State private var appeared = false

    // Simple circular scatter around food center
    private var position: (x: CGFloat, y: CGFloat) {
        // Distribute pills in a circle around the food
        let angleStep = (2 * .pi) / CGFloat(max(totalCount, 1))
        let angle = angleStep * CGFloat(index)

        // Radius from food center (20-35% of image)
        let radius: CGFloat = 0.25 + CGFloat.random(in: 0...0.1)

        // Calculate position around food center
        let offsetX = cos(angle) * radius
        let offsetY = sin(angle) * radius

        let finalX = foodCenter.x + offsetX
        let finalY = foodCenter.y + offsetY

        // Clamp to image bounds (10% - 90%)
        let clampedX = min(max(finalX, 0.1), 0.9)
        let clampedY = min(max(finalY, 0.1), 0.9)

        return (x: clampedX, y: clampedY)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 18))

            Text(name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
        )
        .position(
            x: UIScreen.main.bounds.width * position.x,
            y: imageHeight * position.y
        )
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(
                .spring(response: 0.6, dampingFraction: 0.7)
                .delay(Double(index) * 0.1)
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Ingredient Pill ON Image (White pill for dark overlay)
struct IngredientPillOnImage: View {
    let name: String
    let emoji: String
    let index: Int
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 18))

            Text(name)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.3), radius: 8, x: 0, y: 4)
        )
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.08)
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Ingredient Pill (Animated White Bubble)
struct IngredientPill: View {
    let name: String
    let emoji: String
    let index: Int
    @State private var appeared = false

    var body: some View {
        HStack(spacing: 6) {
            Text(emoji)
                .font(.system(size: 18))

            Text(name)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.black)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 6, x: 0, y: 2)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.gray.opacity(0.15), lineWidth: 1)
        )
        .scaleEffect(appeared ? 1.0 : 0.3)
        .opacity(appeared ? 1.0 : 0.0)
        .onAppear {
            withAnimation(
                .spring(response: 0.5, dampingFraction: 0.7)
                .delay(Double(index) * 0.08)
            ) {
                appeared = true
            }
        }
    }
}

// MARK: - Ingredient Circle
struct IngredientCircle: View {
    let name: String
    let emoji: String

    var body: some View {
        VStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(Color.white)
                    .frame(width: 68, height: 68)
                    .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)

                Text(emoji)
                    .font(.system(size: 30))
            }

            Text(name)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.black)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(width: 75)
    }
}

// MARK: - Nutrition Badge
struct NutritionBadge: View {
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    PostCard(post: Post(
        userId: "user1",
        userName: "Sarah Chen",
        userPhotoURL: nil,
        timestamp: Date(),
        location: "East Village, NYC",
        restaurantName: "Veselka",
        restaurantRating: 9.2,
        mealType: .breakfast,
        foodPhotos: [
            "https://images.unsplash.com/photo-1525351484163-7529414344d8?w=800"
        ],
        selfiePhotoURL: nil,
        notes: "Best breakfast spot near NYU!",
        dietTags: [.healthy, .highProtein],
        nutritionInfo: PostNutritionInfo(calories: 620, protein: "32g", carbs: "58g", fat: "24g"),
        likes: 214,
        comments: 6,
        bookmarks: 250
    ))
    .padding()
}
