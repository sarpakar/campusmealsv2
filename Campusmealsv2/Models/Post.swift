//
//  Post.swift
//  Campusmealsv2
//
//  Created by sarp akar on 03/10/2025.
//

import Foundation
import FirebaseFirestore

struct Post: Identifiable, Codable, Equatable {
    @DocumentID var id: String?

    static func == (lhs: Post, rhs: Post) -> Bool {
        lhs.id == rhs.id
    }
    var userId: String
    var userName: String
    var userPhotoURL: String?
    var timestamp: Date
    var location: String // "East Village, NYC"

    // Restaurant/Meal info
    var restaurantName: String?
    var restaurantRating: Double?
    var mealType: MealType // breakfast, lunch, dinner, snack, meal_prep

    // Photos
    var foodPhotos: [String] // Array of image URLs
    var selfiePhotoURL: String? // BeReal style selfie

    // Content
    var notes: String // User's review/description
    var dietTags: [DietTag] // Healthy, High Protein, Vegan, etc.

    // Nutrition (optional)
    var nutritionInfo: PostNutritionInfo?

    // Social
    var likes: Int
    var comments: Int
    var bookmarks: Int
    var isLikedByCurrentUser: Bool?
    var isBookmarkedByCurrentUser: Bool?

    // Engagement metrics (for recommendation algorithm)
    var viewCount: Int?
    var likeCount: Int?
    var commentCount: Int?
    var shareCount: Int?
    var bookmarkCount: Int?
    var engagementScore: Double?

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case userName = "user_name"
        case userPhotoURL = "user_photo_url"
        case timestamp
        case location
        case restaurantName = "restaurant_name"
        case restaurantRating = "restaurant_rating"
        case mealType = "meal_type"
        case foodPhotos = "food_photos"
        case selfiePhotoURL = "selfie_photo_url"
        case notes
        case dietTags = "diet_tags"
        case nutritionInfo = "nutrition_info"
        case likes
        case comments
        case bookmarks
        case isLikedByCurrentUser = "is_liked_by_current_user"
        case isBookmarkedByCurrentUser = "is_bookmarked_by_current_user"
        case viewCount = "view_count"
        case likeCount = "like_count"
        case commentCount = "comment_count"
        case shareCount = "share_count"
        case bookmarkCount = "bookmark_count"
        case engagementScore = "engagement_score"
    }
}

enum MealType: String, Codable {
    case breakfast = "Breakfast"
    case lunch = "Lunch"
    case dinner = "Dinner"
    case snack = "Snack"
    case mealPrep = "Meal Prep"
}

enum DietTag: String, Codable, CaseIterable {
    case healthy = "Healthy"
    case highProtein = "High Protein"
    case lowCarb = "Low Carb"
    case vegan = "Vegan"
    case vegetarian = "Vegetarian"
    case glutenFree = "Gluten Free"
    case keto = "Keto"
    case paleo = "Paleo"
    case wholesome = "Wholesome"
    case balanced = "Balanced"

    var emoji: String {
        switch self {
        case .healthy: return "🥗"
        case .highProtein: return "💪"
        case .lowCarb: return "🥑"
        case .vegan: return "🌱"
        case .vegetarian: return "🥬"
        case .glutenFree: return "🌾"
        case .keto: return "🥓"
        case .paleo: return "🍖"
        case .wholesome: return "✨"
        case .balanced: return "⚖️"
        }
    }

    var color: String {
        switch self {
        case .healthy, .balanced: return "green"
        case .highProtein: return "blue"
        case .lowCarb, .keto: return "orange"
        case .vegan, .vegetarian: return "mint"
        case .glutenFree: return "yellow"
        case .paleo: return "brown"
        case .wholesome: return "purple"
        }
    }
}

struct PostNutritionInfo: Codable {
    var calories: Int
    var protein: String
    var carbs: String
    var fat: String
    var fiber: String?
}

enum FeedFilter: String, CaseIterable {
    case nearby = "Recs Nearby"
    case trending = "Trending"
    case friends = "Friend recs"

    var icon: String {
        switch self {
        case .nearby: return "location.fill"
        case .trending: return "chart.line.uptrend.xyaxis"
        case .friends: return "person.2.fill"
        }
    }
}
