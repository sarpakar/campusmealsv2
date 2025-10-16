//
//  RecommendationEngine.swift
//  Campusmealsv2
//
//  2025-grade recommendation system
//  Multi-signal ranking inspired by Uber Eats, DoorDash, Instagram
//

import Foundation
import CoreLocation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class RecommendationEngine: ObservableObject {
    static let shared = RecommendationEngine()

    @Published var recommendations: [RecommendationResult] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private var userPreferences: FoodUserPreferences?

    // Cache with key-based invalidation
    private var recommendationCache: [String: [RecommendationResult]] = [:]
    private var cacheTimestamps: [String: Date] = [:]
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    private init() {
        print("🎯 RecommendationEngine initialized")
    }

    // MARK: - Cache Management

    func clearCache() {
        recommendationCache.removeAll()
        cacheTimestamps.removeAll()
        print("🗑️ Recommendation cache cleared")
    }

    // MARK: - Main Recommendation Function
    func generateRecommendations(
        vendors: [Vendor],
        userLocation: CLLocation,
        context: RecommendationContext
    ) async -> [RecommendationResult] {

        // Create cache key based on vendor IDs and context
        let vendorIds = vendors.map { $0.id ?? "" }.sorted().joined()
        let cacheKey = "\(vendorIds)_\(context.mealPeriod.rawValue)"

        // Check cache
        if let cachedResults = recommendationCache[cacheKey],
           let cacheTime = cacheTimestamps[cacheKey],
           Date().timeIntervalSince(cacheTime) < cacheValidityDuration {
            print("📦 Using cached recommendations for: \(context.mealPeriod.rawValue)")
            return cachedResults
        }

        print("\n🎯 Generating fresh recommendations...")
        print("   Context: \(context.timeOfDay.rawValue), \(context.mealPeriod.rawValue)")
        print("   Vendors: \(vendors.count)")
        print("   Cache Key: \(cacheKey.prefix(50))...")

        isLoading = true

        // Load user preferences
        await loadUserPreferences()

        // Score each vendor
        var scoredVendors: [(vendor: Vendor, score: RecommendationScore)] = []

        for vendor in vendors {
            let score = await calculateScore(
                for: vendor,
                userLocation: userLocation,
                context: context
            )
            scoredVendors.append((vendor, score))
        }

        // Debug: Show top 3 scores before sorting
        print("\n📊 Score Breakdown (before sorting):")
        for (index, pair) in scoredVendors.prefix(3).enumerated() {
            print("   \(index + 1). \(pair.vendor.name)")
            print("      Total: \(String(format: "%.1f", pair.score.totalScore))")
            print("      Person: \(String(format: "%.1f", pair.score.personalizationScore))")
            print("      Quality: \(String(format: "%.1f", pair.score.qualityScore))")
            print("      Proximity: \(String(format: "%.1f", pair.score.proximityScore))")
            print("      Context: \(String(format: "%.1f", pair.score.contextScore))")
        }

        // Sort by total score
        scoredVendors.sort { $0.score.totalScore > $1.score.totalScore }

        // Create recommendation results
        let results = scoredVendors.prefix(20).map { vendorPair in
            createRecommendationResult(
                vendor: vendorPair.vendor,
                score: vendorPair.score,
                userLocation: userLocation
            )
        }

        // Cache results with key
        recommendationCache[cacheKey] = results
        cacheTimestamps[cacheKey] = Date()

        isLoading = false
        recommendations = results

        print("✅ Generated \(results.count) recommendations")
        if let top = results.first {
            print("   Top: \(top.vendor.name) - Score: \(Int(top.matchScore))%")
        }

        return results
    }

    // MARK: - Multi-Signal Scoring (Uber Eats-style)
    private func calculateScore(
        for vendor: Vendor,
        userLocation: CLLocation,
        context: RecommendationContext
    ) async -> RecommendationScore {

        let vendorLocation = CLLocation(
            latitude: vendor.latitude,
            longitude: vendor.longitude
        )
        let distance = userLocation.distance(from: vendorLocation)

        // 1. Personalization Score (25%)
        let personalizationScore = calculatePersonalizationScore(vendor: vendor)

        // 2. Quality Score (20%)
        let qualityScore = calculateQualityScore(vendor: vendor)

        // 3. Distance/Proximity Score (15%)
        let proximityScore = calculateProximityScore(distance: distance)

        // 4. Context Score (15%) - Time of day, weather, etc.
        let contextScore = calculateContextScore(vendor: vendor, context: context)

        // 5. Social Proof Score (10%)
        let socialScore = calculateSocialScore(vendor: vendor)

        // 6. Freshness Score (8%) - New restaurants, trending
        let freshnessScore = calculateFreshnessScore(vendor: vendor)

        // 7. Business Health Score (7%) - Availability, prep time
        let businessScore = calculateBusinessHealthScore(vendor: vendor)

        // Weighted total
        let totalScore = (
            personalizationScore * 0.25 +
            qualityScore * 0.20 +
            proximityScore * 0.15 +
            contextScore * 0.15 +
            socialScore * 0.10 +
            freshnessScore * 0.08 +
            businessScore * 0.07
        )

        return RecommendationScore(
            totalScore: totalScore,
            personalizationScore: personalizationScore,
            qualityScore: qualityScore,
            proximityScore: proximityScore,
            contextScore: contextScore,
            socialScore: socialScore,
            freshnessScore: freshnessScore,
            businessScore: businessScore
        )
    }

    // MARK: - Individual Score Calculations

    private func calculatePersonalizationScore(vendor: Vendor) -> Double {
        guard let prefs = userPreferences else {
            // No preferences = neutral base score
            return 50.0
        }

        var score = 30.0 // Lower base to allow differentiation

        // Cuisine preference (strong signal)
        if let cuisine = vendor.cuisine {
            if prefs.favoriteCuisines.contains(cuisine) {
                score += 50.0 // Major boost for favorite cuisine
            } else {
                // Partial match for similar cuisines
                let cuisineLower = cuisine.lowercased()
                for favCuisine in prefs.favoriteCuisines {
                    if cuisineLower.contains(favCuisine.lowercased()) ||
                       favCuisine.lowercased().contains(cuisineLower) {
                        score += 25.0
                        break
                    }
                }
            }
        }

        // Price preference (moderate signal)
        let vendorPriceLevel = vendor.priceRange.count // $ = 1, $$ = 2, etc.
        if vendorPriceLevel == prefs.preferredPriceLevel {
            score += 15.0 // Exact match
        } else if abs(vendorPriceLevel - prefs.preferredPriceLevel) == 1 {
            score += 8.0 // Close match
        } else if abs(vendorPriceLevel - prefs.preferredPriceLevel) >= 2 {
            score -= 5.0 // Penalty for very different price
        }

        // Dietary tags (if we had them)
        if !prefs.dietaryTags.isEmpty {
            score += 5.0 // Small boost for having preferences
        }

        return max(0, min(score, 100.0))
    }

    private func calculateQualityScore(vendor: Vendor) -> Double {
        // Rating weighted by review count
        let ratingScore = (vendor.rating / 5.0) * 60.0

        // Review count score (logarithmic scale)
        let reviewScore = min(log10(Double(vendor.reviewCount) + 1) / 4.0, 1.0) * 40.0

        return ratingScore + reviewScore
    }

    private func calculateProximityScore(distance: Double) -> Double {
        // Perfect score < 200m, decreases as distance increases
        let meters = distance

        if meters < 200 {
            return 100.0
        } else if meters < 500 {
            return 90.0
        } else if meters < 1000 {
            return 70.0
        } else if meters < 2000 {
            return 50.0
        } else if meters < 3000 {
            return 30.0
        } else {
            return 10.0
        }
    }

    private func calculateContextScore(vendor: Vendor, context: RecommendationContext) -> Double {
        var score = 30.0 // Lower base score to differentiate better

        // Time-based scoring with stronger weights
        switch context.mealPeriod {
        case .breakfast:
            if vendor.category == .cafes {
                score += 50.0 // Strong boost for cafes at breakfast
            } else if vendor.cuisine?.lowercased().contains("breakfast") == true {
                score += 40.0
            } else if vendor.cuisine?.lowercased().contains("coffee") == true {
                score += 35.0
            } else if vendor.category == .restaurants {
                score += 10.0 // Small boost for restaurants
            }
        case .lunch:
            if vendor.category == .restaurants {
                score += 40.0
            }
            if vendor.cuisine?.lowercased().contains("salad") == true ||
               vendor.cuisine?.lowercased().contains("healthy") == true {
                score += 20.0
            }
        case .dinner:
            if vendor.category == .restaurants {
                score += 50.0
            }
        case .lateNight:
            // Prefer 24/7 places or known late-night spots
            if vendor.isOpen {
                score += 40.0
            }
        }

        // Grocery stores score lower except for grocery searches
        if vendor.category == .groceries {
            score -= 20.0 // Penalty for non-grocery searches
        }

        return max(0, min(score, 100.0))
    }

    private func calculateSocialScore(vendor: Vendor) -> Double {
        // Friends activity (if available)
        if let friendsActivity = vendor.friendsActivity {
            let friendScore = min(Double(friendsActivity.totalFriendsLoved) * 20.0, 60.0)
            return friendScore + 40.0 // Base score
        }

        // Popularity fallback
        return min(Double(vendor.reviewCount) / 100.0, 100.0)
    }

    private func calculateFreshnessScore(vendor: Vendor) -> Double {
        // Check if vendor has "New" badge
        if vendor.badges?.contains(where: { $0.type == .new }) == true {
            return 100.0
        }

        // Check if trending
        if vendor.badges?.contains(where: { $0.type == .trending }) == true {
            return 80.0
        }

        // Default score based on review count recency
        return 50.0
    }

    private func calculateBusinessHealthScore(vendor: Vendor) -> Double {
        var score = 50.0

        // Open status
        if vendor.isOpen {
            score += 30.0
        } else {
            return 0.0 // Don't recommend closed restaurants
        }

        // Free delivery
        if vendor.deliveryFee == 0 {
            score += 20.0
        }

        return min(score, 100.0)
    }

    // MARK: - Create Recommendation Result

    private func createRecommendationResult(
        vendor: Vendor,
        score: RecommendationScore,
        userLocation: CLLocation
    ) -> RecommendationResult {

        let vendorLocation = CLLocation(latitude: vendor.latitude, longitude: vendor.longitude)
        let distance = userLocation.distance(from: vendorLocation)

        // Calculate walking time (avg speed: 1.4 m/s)
        let walkingTimeMinutes = Int((distance / 1.4) / 60)

        // Format distance
        let distanceFormatted: String
        if distance < 1000 {
            distanceFormatted = "\(Int(distance)) m"
        } else {
            distanceFormatted = String(format: "%.1f mi", distance / 1609.34)
        }

        // Generate match reason
        let matchReason = generateMatchReason(vendor: vendor, score: score)

        // Get social proof
        let socialProof = vendor.friendsActivity?.recentVisits.map { $0.friendName } ?? []

        return RecommendationResult(
            vendor: vendor,
            matchScore: score.totalScore,
            walkingTime: "\(walkingTimeMinutes) min",
            distance: distanceFormatted,
            matchReason: matchReason,
            socialProof: socialProof,
            scoreBreakdown: score
        )
    }

    private func generateMatchReason(vendor: Vendor, score: RecommendationScore) -> String {
        var reasons: [String] = []

        if score.personalizationScore > 70 {
            if let cuisine = vendor.cuisine {
                reasons.append("Matches your \(cuisine.lowercased()) preferences")
            }
        }

        if score.proximityScore > 80 {
            reasons.append("Very close to you")
        }

        if score.qualityScore > 85 {
            reasons.append("Highly rated by customers")
        }

        if score.socialScore > 70 {
            reasons.append("Loved by your friends")
        }

        return reasons.first ?? "Great option for you"
    }

    // MARK: - Load User Preferences

    private func loadUserPreferences() async {
        guard let userId = Auth.auth().currentUser?.uid else {
            // Use default preferences
            userPreferences = FoodUserPreferences.default
            return
        }

        do {
            let doc = try await db.collection("users").document(userId).collection("preferences").document("food").getDocument()

            if doc.exists {
                userPreferences = try doc.data(as: FoodUserPreferences.self)
                print("✅ Loaded user preferences")
            } else {
                userPreferences = FoodUserPreferences.default
                print("⚠️ No preferences found, using defaults")
            }
        } catch {
            print("❌ Error loading preferences: \(error.localizedDescription)")
            userPreferences = FoodUserPreferences.default
        }
    }
}

// MARK: - Models

struct RecommendationResult: Identifiable {
    let id = UUID()
    let vendor: Vendor
    let matchScore: Double
    let walkingTime: String
    let distance: String
    let matchReason: String
    let socialProof: [String]
    let scoreBreakdown: RecommendationScore
}

struct RecommendationScore {
    let totalScore: Double
    let personalizationScore: Double
    let qualityScore: Double
    let proximityScore: Double
    let contextScore: Double
    let socialScore: Double
    let freshnessScore: Double
    let businessScore: Double
}

struct RecommendationContext {
    let timeOfDay: TimeOfDay
    let mealPeriod: MealPeriod
    let weatherCondition: WeatherCondition?

    enum TimeOfDay: String {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"
    }

    enum MealPeriod: String {
        case breakfast = "Breakfast"
        case lunch = "Lunch"
        case dinner = "Dinner"
        case lateNight = "Late Night"
    }

    enum WeatherCondition: String {
        case sunny = "Sunny"
        case rainy = "Rainy"
        case cold = "Cold"
        case hot = "Hot"
    }

    static var current: RecommendationContext {
        let hour = Calendar.current.component(.hour, from: Date())

        let timeOfDay: TimeOfDay
        let mealPeriod: MealPeriod

        switch hour {
        case 6..<12:
            timeOfDay = .morning
            mealPeriod = .breakfast
        case 12..<17:
            timeOfDay = .afternoon
            mealPeriod = .lunch
        case 17..<21:
            timeOfDay = .evening
            mealPeriod = .dinner
        default:
            timeOfDay = .night
            mealPeriod = .lateNight
        }

        return RecommendationContext(
            timeOfDay: timeOfDay,
            mealPeriod: mealPeriod,
            weatherCondition: nil
        )
    }
}

struct FoodUserPreferences: Codable {
    var favoriteCuisines: [String]
    var preferredPriceLevel: Int // 1-4
    var dietaryTags: [String]
    var avgOrderValue: Double

    static var `default`: FoodUserPreferences {
        FoodUserPreferences(
            favoriteCuisines: [],
            preferredPriceLevel: 2, // $$
            dietaryTags: [],
            avgOrderValue: 15.0
        )
    }
}
