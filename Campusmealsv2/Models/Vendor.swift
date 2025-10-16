//
//  Vendor.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation
import FirebaseFirestore

enum VendorCategory: String, Codable, CaseIterable {
    case all = "All"
    case restaurants = "Restaurants"
    case groceries = "Groceries"
    case convenience = "Convenience"
    case cafes = "Cafés"
    case desserts = "Desserts"
    case alcohol = "Alcohol"
}

enum WaitStatus: String, Codable {
    case confident = "Confident (No wait)"
    case short = "Short wait (5-10 min)"
    case medium = "Medium wait (15-20 min)"
    case long = "Long wait (30+ min)"

    var color: String {
        switch self {
        case .confident: return "green"
        case .short: return "yellow"
        case .medium: return "orange"
        case .long: return "red"
        }
    }

    var emoji: String {
        switch self {
        case .confident: return "🟢"
        case .short: return "🟡"
        case .medium: return "🟠"
        case .long: return "🔴"
        }
    }
}

enum BadgeType: String, Codable {
    case bestInArea = "Best in Area"
    case comeOnceInAWhile = "Come Once in a While"
    case luckyToEat = "You're Lucky to Eat Here"
    case new = "New"
    case trending = "Trending"
    case hidden = "Hidden Gem"

    var emoji: String {
        switch self {
        case .bestInArea: return "🏆"
        case .comeOnceInAWhile: return "✨"
        case .luckyToEat: return "🍀"
        case .new: return "⭐"
        case .trending: return "🔥"
        case .hidden: return "💎"
        }
    }
}

struct VendorBadge: Codable {
    var type: BadgeType
    var title: String

    init(type: BadgeType) {
        self.type = type
        self.title = type.rawValue
    }
}

struct FriendVisit: Codable {
    var friendName: String
    var daysAgo: Int
    var photoURL: String?
}

struct FriendsActivity: Codable {
    var totalFriendsLoved: Int
    var recentVisits: [FriendVisit]
}

enum SocialPlatform: String, Codable {
    case tiktok = "tiktok"
    case instagram = "instagram"
    case youtube = "youtube"
}

struct SocialVideo: Codable, Identifiable {
    var id: String // Video ID or URL
    var platform: SocialPlatform
    var videoURL: String
    var thumbnailURL: String?
    var title: String?
    var views: Int?
    var embedURL: String // For embedding in WebView
}

struct Vendor: Identifiable, Codable {
    @DocumentID var id: String?
    var name: String
    var category: VendorCategory
    var cuisine: String?
    var imageURL: String  // Computed property will build this from photoReference
    var photoReference: String?  // Google Places photo reference (industry standard)
    var rating: Double
    var reviewCount: Int
    var deliveryTime: String // e.g., "20-30 min"
    var deliveryFee: Double
    var minimumOrder: Double?
    var priceRange: String // "$", "$$", "$$$"
    var latitude: Double
    var longitude: Double
    var address: String
    var isOpen: Bool
    var tags: [String] // ["Fast Delivery", "Free Delivery", "Popular"]

    // Enhanced fields
    var waitStatus: WaitStatus?
    var dietaryHighlights: [String]? // ["Eggs", "Coffee", "Hash Browns"]
    var vibeTraits: [String]? // ["Friendly service", "Good environment", "Fast"]
    var badges: [VendorBadge]?
    var friendsActivity: FriendsActivity?
    var socialVideos: [SocialVideo]? // TikTok, Instagram, YouTube videos

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case category
        case cuisine
        case imageURL = "image_url"
        case photoReference = "photo_reference"
        case rating
        case reviewCount = "review_count"
        case deliveryTime = "delivery_time"
        case deliveryFee = "delivery_fee"
        case minimumOrder = "minimum_order"
        case priceRange = "price_range"
        case latitude
        case longitude
        case address
        case isOpen = "is_open"
        case tags
        case waitStatus = "wait_status"
        case dietaryHighlights = "dietary_highlights"
        case vibeTraits = "vibe_traits"
        case badges
        case friendsActivity = "friends_activity"
        case socialVideos = "restaurant_videos"
    }

    // Initializer
    init(
        id: String? = nil,
        name: String,
        category: VendorCategory,
        cuisine: String? = nil,
        imageURL: String,
        photoReference: String? = nil,
        rating: Double,
        reviewCount: Int,
        deliveryTime: String,
        deliveryFee: Double,
        minimumOrder: Double? = nil,
        priceRange: String,
        latitude: Double,
        longitude: Double,
        address: String,
        isOpen: Bool,
        tags: [String],
        waitStatus: WaitStatus? = nil,
        dietaryHighlights: [String]? = nil,
        vibeTraits: [String]? = nil,
        badges: [VendorBadge]? = nil,
        friendsActivity: FriendsActivity? = nil,
        socialVideos: [SocialVideo]? = nil
    ) {
        self.id = id
        self.name = name
        self.category = category
        self.cuisine = cuisine
        self.imageURL = imageURL
        self.photoReference = photoReference
        self.rating = rating
        self.reviewCount = reviewCount
        self.deliveryTime = deliveryTime
        self.deliveryFee = deliveryFee
        self.minimumOrder = minimumOrder
        self.priceRange = priceRange
        self.latitude = latitude
        self.longitude = longitude
        self.address = address
        self.isOpen = isOpen
        self.tags = tags
        self.waitStatus = waitStatus
        self.dietaryHighlights = dietaryHighlights
        self.vibeTraits = vibeTraits
        self.badges = badges
        self.friendsActivity = friendsActivity
        self.socialVideos = socialVideos
    }

    // Computed property to get the final image URL
    var finalImageURL: String {
        // Simply use imageURL - will contain either Google Places URL or fallback
        return imageURL
    }

    // Calculate distance from user location
    func distance(from userLat: Double, userLon: Double) -> Double {
        let earthRadius = 6371.0 // km
        let dLat = (latitude - userLat) * .pi / 180
        let dLon = (longitude - userLon) * .pi / 180
        let a = sin(dLat/2) * sin(dLat/2) +
                cos(userLat * .pi / 180) * cos(latitude * .pi / 180) *
                sin(dLon/2) * sin(dLon/2)
        let c = 2 * atan2(sqrt(a), sqrt(1-a))
        return earthRadius * c
    }

    func formattedDistance(from userLat: Double, userLon: Double) -> String {
        let dist = distance(from: userLat, userLon: userLon)
        if dist < 1 {
            return String(format: "%.0f m", dist * 1000)
        } else {
            return String(format: "%.1f km", dist)
        }
    }
}
