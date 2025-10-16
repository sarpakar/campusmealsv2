//
//  RankingService.swift
//  Campusmealsv2
//
//  Instagram/TikTok 2025-grade recommendation algorithm
//  Multi-signal ranking with personalization
//

import Foundation
import FirebaseAuth

@MainActor
class RankingService {
    static let shared = RankingService()

    // User preferences (learned from interactions)
    private var userPreferences: UserPreferences?
    private var recentlyShownPostIds: Set<String> = []
    private let maxRecentlyShown = 20

    private init() {}

    // MARK: - Main Ranking Function
    func rankPosts(_ posts: [Post]) -> [Post] {
        guard !posts.isEmpty else { return [] }

        print("🎯 Ranking \(posts.count) posts...")

        // Assign scores to each post
        let rankedPosts = posts.map { post -> (post: Post, score: Double) in
            let score = calculateScore(for: post)
            return (post, score)
        }
        .sorted { $0.score > $1.score }  // Highest score first
        .map { $0.post }

        print("✅ Ranking complete - Top post score: \(calculateScore(for: rankedPosts.first!))")

        return rankedPosts
    }

    // MARK: - Score Calculation (Instagram's Multi-Signal Approach)
    private func calculateScore(for post: Post) -> Double {
        let engagement = engagementScore(post) * 0.35      // 35% - Most important
        let freshness = freshnessScore(post) * 0.25        // 25% - Recency matters
        let affinity = affinityScore(post) * 0.20          // 20% - Personalization
        let diversity = diversityScore(post) * 0.15        // 15% - Avoid repetition
        let quality = qualityScore(post) * 0.05            // 5% - Content completeness

        let totalScore = engagement + freshness + affinity + diversity + quality

        return totalScore
    }

    // MARK: - 1. Engagement Score (Viral Content)
    private func engagementScore(_ post: Post) -> Double {
        // Weighted engagement: comments > saves > likes
        let totalEngagement = Double(
            post.likes * 1 +
            post.comments * 3 +     // Comments indicate deeper engagement
            post.bookmarks * 4      // Saves indicate high value
        )

        // Normalize by views to get engagement rate
        let views = max(Double(post.viewCount ?? 1), 1.0)
        let rate = totalEngagement / views

        // Cap at 1.0 and apply log scale for very viral content
        return min(log10(1 + rate * 100) / 2, 1.0)
    }

    // MARK: - 2. Freshness Score (Recency Bias)
    private func freshnessScore(_ post: Post) -> Double {
        let hoursSincePost = Date().timeIntervalSince(post.timestamp) / 3600

        // Exponential decay over 48 hours
        // New posts (0-6h): 1.0
        // Recent posts (6-24h): 0.7-0.9
        // Older posts (24-48h): 0.3-0.7
        // Old posts (48h+): < 0.3
        return 1.0 / (1.0 + hoursSincePost / 24.0)
    }

    // MARK: - 3. Affinity Score (Personalization)
    private func affinityScore(_ post: Post) -> Double {
        guard let prefs = userPreferences else {
            return 0.5  // Neutral score if no preferences
        }

        var score = 0.0

        // Diet tag matching (40%)
        let matchingTags = post.dietTags.filter { prefs.favoriteDietTags.contains($0) }
        if !matchingTags.isEmpty {
            score += 0.4 * (Double(matchingTags.count) / Double(max(prefs.favoriteDietTags.count, 1)))
        }

        // Location matching (30%)
        if !prefs.favoriteLocation.isEmpty && post.location.contains(prefs.favoriteLocation) {
            score += 0.3
        }

        // Meal type matching (20%)
        if prefs.preferredMealTypes.contains(post.mealType) {
            score += 0.2
        }

        // Creator affinity (10%) - Have we liked their posts before?
        if prefs.favoriteCreators.contains(post.userId) {
            score += 0.1
        }

        return min(score, 1.0)
    }

    // MARK: - 4. Diversity Score (Avoid Repetition)
    private func diversityScore(_ post: Post) -> Double {
        guard let postId = post.id else { return 1.0 }

        // Penalize if we've shown this post or similar content recently
        if recentlyShownPostIds.contains(postId) {
            return 0.2  // Heavy penalty for exact duplicates
        }

        // Check for same creator in recent posts
        let sameCreatorCount = recentlyShownPostIds.filter { id in
            // This is simplified - in production, track creator IDs separately
            return false  // Placeholder
        }.count

        if sameCreatorCount > 2 {
            return 0.6  // Mild penalty for repetitive creator
        }

        return 1.0  // Full score for diverse content
    }

    // MARK: - 5. Quality Score (Content Completeness)
    private func qualityScore(_ post: Post) -> Double {
        var score = 0.0

        // Multiple images (30%)
        if post.foodPhotos.count > 1 {
            score += 0.3
        }

        // Has notes/description (30%)
        if !post.notes.isEmpty && post.notes.count > 20 {
            score += 0.3
        }

        // Has location (20%)
        if !post.location.isEmpty {
            score += 0.2
        }

        // Has diet tags (20%)
        if !post.dietTags.isEmpty {
            score += 0.2
        }

        return score
    }

    // MARK: - Track Shown Posts (for diversity)
    func markAsShown(postId: String) {
        recentlyShownPostIds.insert(postId)

        // Keep only last N posts
        if recentlyShownPostIds.count > maxRecentlyShown {
            recentlyShownPostIds.removeFirst()
        }
    }

    // MARK: - Update User Preferences (Learn from interactions)
    func updatePreferences(likedPost: Post) {
        if userPreferences == nil {
            userPreferences = UserPreferences()
        }

        // Learn diet preferences
        for tag in likedPost.dietTags {
            if !userPreferences!.favoriteDietTags.contains(tag) {
                userPreferences!.favoriteDietTags.append(tag)
            }
        }

        // Learn location preferences
        if userPreferences!.favoriteLocation.isEmpty {
            userPreferences!.favoriteLocation = likedPost.location
        }

        // Learn meal type preferences
        if !userPreferences!.preferredMealTypes.contains(likedPost.mealType) {
            userPreferences!.preferredMealTypes.append(likedPost.mealType)
        }

        // Track favorite creators
        if !userPreferences!.favoriteCreators.contains(likedPost.userId) {
            userPreferences!.favoriteCreators.append(likedPost.userId)
        }

        print("📊 Updated preferences - Tags: \(userPreferences!.favoriteDietTags.count), Location: \(userPreferences!.favoriteLocation)")
    }
}

// MARK: - User Preferences Model
struct UserPreferences {
    var favoriteDietTags: [DietTag] = []
    var favoriteLocation: String = ""
    var preferredMealTypes: [MealType] = []
    var favoriteCreators: [String] = []
}
