//
//  UserProfile.swift
//  Campusmealsv2
//
//  User Profile with Gamification
//

import Foundation
import FirebaseFirestore

struct UserProfile: Codable, Identifiable {
    @DocumentID var id: String?
    var phoneNumber: String
    var name: String?
    var email: String?
    var photoURL: String?

    // Gamification fields
    var totalXP: Int = 0
    var level: Int = 1
    var characterType: CharacterType?
    var restaurantPoints: [String: Int] = [:] // restaurantId: points
    var badges: [Badge] = []
    var friends: [String] = [] // User IDs
    var squads: [String] = [] // Match IDs where user is participant
    var completedMatches: Int = 0
    var matchesWon: Int = 0
    var episodesCreated: Int = 0
    var totalReactions: Int = 0

    // Settings
    var notificationsEnabled: Bool = true
    var fcmToken: String?

    var createdAt: Date = Date()
    var lastActive: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case phoneNumber = "phone_number"
        case name
        case email
        case photoURL = "photo_url"
        case totalXP = "total_xp"
        case level
        case characterType = "character_type"
        case restaurantPoints = "restaurant_points"
        case badges
        case friends
        case squads
        case completedMatches = "completed_matches"
        case matchesWon = "matches_won"
        case episodesCreated = "episodes_created"
        case totalReactions = "total_reactions"
        case notificationsEnabled = "notifications_enabled"
        case fcmToken = "fcm_token"
        case createdAt = "created_at"
        case lastActive = "last_active"
    }

    // MARK: - Computed Properties

    var nextLevelXP: Int {
        return level * 1000
    }

    var xpProgress: Double {
        let currentLevelXP = (level - 1) * 1000
        let nextLevel = nextLevelXP
        let progress = Double(totalXP - currentLevelXP) / Double(nextLevel - currentLevelXP)
        return max(0, min(1, progress))
    }

    var currentLevelXP: Int {
        return (level - 1) * 1000
    }

    var displayName: String {
        return name ?? phoneNumber
    }
}

// MARK: - Character Types

enum CharacterType: String, Codable, CaseIterable {
    case fearlessChallenger = "The Fearless Challenger"
    case squadCatalyst = "The Squad Catalyst"
    case photoArtist = "The Photo Artist"
    case vibeCreator = "The Vibe Creator"
    case loyalist = "The Loyalist"
    case explorer = "The Explorer"
    case dramatist = "The Dramatist"
    case competitive = "The Competitor"

    var icon: String {
        switch self {
        case .fearlessChallenger: return "flame.fill"
        case .squadCatalyst: return "person.3.fill"
        case .photoArtist: return "camera.fill"
        case .vibeCreator: return "sparkles"
        case .loyalist: return "heart.fill"
        case .explorer: return "map.fill"
        case .dramatist: return "theatermasks.fill"
        case .competitive: return "trophy.fill"
        }
    }

    var description: String {
        switch self {
        case .fearlessChallenger:
            return "You never back down from a spicy challenge"
        case .squadCatalyst:
            return "You're the glue that brings everyone together"
        case .photoArtist:
            return "Your food pics are always Instagram-worthy"
        case .vibeCreator:
            return "You set the mood for every hangout"
        case .loyalist:
            return "You have your go-to spots and stick to them"
        case .explorer:
            return "Always trying new places and cuisines"
        case .dramatist:
            return "Your episodes are full of iconic moments"
        case .competitive:
            return "You play to win every challenge"
        }
    }
}

// MARK: - Badges

struct Badge: Codable, Identifiable {
    var id: String = UUID().uuidString
    var name: String
    var icon: String
    var rarity: BadgeRarity
    var earnedAt: Date = Date()
    var description: String

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case icon
        case rarity
        case earnedAt = "earned_at"
        case description
    }
}

enum BadgeRarity: String, Codable {
    case common = "Common"
    case rare = "Rare"
    case epic = "Epic"
    case legendary = "Legendary"

    var color: String {
        switch self {
        case .common: return "#9E9E9E"
        case .rare: return "#2196F3"
        case .epic: return "#9C27B0"
        case .legendary: return "#FF9800"
        }
    }
}
