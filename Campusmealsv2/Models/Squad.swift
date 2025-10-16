//
//  Squad.swift
//  Campusmealsv2
//
//  Squad Up & Eat - Match System Models
//

import Foundation
import FirebaseFirestore

// MARK: - Match Models

struct Match: Codable, Identifiable {
    @DocumentID var id: String?
    var creatorId: String
    var restaurantId: String
    var restaurantName: String
    var restaurantImageURL: String?
    var scheduledTime: Date
    var squadSize: Int // 2-10 people
    var challengeType: ChallengeType
    var participants: [String] = [] // User IDs
    var invites: [String] = [] // Invite IDs
    var status: MatchStatus = .pending
    var checkIns: [String] = [] // User IDs who checked in
    var results: MatchResults?
    var discountPercent: Int = 20
    var xpReward: Int = 50
    var createdAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case creatorId = "creator_id"
        case restaurantId = "restaurant_id"
        case restaurantName = "restaurant_name"
        case restaurantImageURL = "restaurant_image_url"
        case scheduledTime = "scheduled_time"
        case squadSize = "squad_size"
        case challengeType = "challenge_type"
        case participants
        case invites
        case status
        case checkIns = "check_ins"
        case results
        case discountPercent = "discount_percent"
        case xpReward = "xp_reward"
        case createdAt = "created_at"
    }
}

enum MatchStatus: String, Codable {
    case pending = "pending"
    case confirmed = "confirmed"
    case inProgress = "in_progress"
    case completed = "completed"
    case cancelled = "cancelled"
}

enum ChallengeType: String, Codable, CaseIterable, Identifiable {
    case casual = "Squad Hangout"
    case spicyChallenge = "Spicy Challenge"
    case dessertRoulette = "Dessert Roulette"
    case aestheticPhoto = "Best Photo Contest"
    case speedRun = "Speed Eating"
    case newPlace = "First Timer"
    case lateNight = "Midnight Munchies"
    case brunchClub = "Brunch Squad"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .casual: return "person.3.fill"
        case .spicyChallenge: return "flame.fill"
        case .dessertRoulette: return "birthday.cake.fill"
        case .aestheticPhoto: return "camera.fill"
        case .speedRun: return "timer"
        case .newPlace: return "sparkles"
        case .lateNight: return "moon.stars.fill"
        case .brunchClub: return "cup.and.saucer.fill"
        }
    }

    var description: String {
        switch self {
        case .casual: return "Just vibes, no competition"
        case .spicyChallenge: return "Who can handle the heat?"
        case .dessertRoulette: return "Try a random dessert"
        case .aestheticPhoto: return "Best food pic wins"
        case .speedRun: return "Fastest eater wins"
        case .newPlace: return "Explore somewhere new"
        case .lateNight: return "Late night food run"
        case .brunchClub: return "Weekend brunch vibes"
        }
    }
}

struct MatchResults: Codable {
    var challengeWinnerId: String?
    var winnerName: String?
    var totalXPAwarded: Int
    var photoCount: Int = 0
    var vibeRating: Double = 0.0
    var completedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case challengeWinnerId = "challenge_winner_id"
        case winnerName = "winner_name"
        case totalXPAwarded = "total_xp_awarded"
        case photoCount = "photo_count"
        case vibeRating = "vibe_rating"
        case completedAt = "completed_at"
    }
}

// MARK: - Match Invite Models

struct MatchInvite: Codable, Identifiable {
    @DocumentID var id: String?
    var matchId: String
    var inviterId: String
    var inviterName: String
    var inviteeId: String
    var inviteeName: String
    var status: InviteStatus = .pending
    var createdAt: Date = Date()
    var respondedAt: Date?

    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case inviterId = "inviter_id"
        case inviterName = "inviter_name"
        case inviteeId = "invitee_id"
        case inviteeName = "invitee_name"
        case status
        case createdAt = "created_at"
        case respondedAt = "responded_at"
    }
}

enum InviteStatus: String, Codable {
    case pending = "pending"
    case accepted = "accepted"
    case declined = "declined"
    case expired = "expired"
}

// MARK: - Episode Models

struct Episode: Codable, Identifiable {
    @DocumentID var id: String?
    var matchId: String
    var title: String
    var creatorId: String
    var creatorName: String
    var participantIds: [String]
    var photos: [EpisodePhoto]
    var vibe: VibeType
    var vibeRating: Int // 1-5 stars
    var customQuote: String?
    var dramaMoments: [DramaMoment]?
    var reactions: [String: Int] = [:] // "🔥": 5, "😂": 3, etc
    var viewCount: Int = 0
    var createdAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case matchId = "match_id"
        case title
        case creatorId = "creator_id"
        case creatorName = "creator_name"
        case participantIds = "participant_ids"
        case photos
        case vibe
        case vibeRating = "vibe_rating"
        case customQuote = "custom_quote"
        case dramaMoments = "drama_moments"
        case reactions
        case viewCount = "view_count"
        case createdAt = "created_at"
    }
}

struct EpisodePhoto: Codable, Identifiable {
    var id: String = UUID().uuidString
    var photoURL: String
    var uploadedBy: String
    var uploadedAt: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case photoURL = "photo_url"
        case uploadedBy = "uploaded_by"
        case uploadedAt = "uploaded_at"
    }
}

enum VibeType: String, Codable, CaseIterable, Identifiable {
    case chaoticGood = "chaotic good"
    case chillin = "chillin"
    case iconic = "iconic"
    case unhinged = "unhinged"
    case wholesome = "wholesome"
    case dramatic = "dramatic"
    case aesthetic = "aesthetic"
    case legendary = "legendary"

    var id: String { rawValue }

    var emoji: String {
        switch self {
        case .chaoticGood: return "😈✨"
        case .chillin: return "😎🌊"
        case .iconic: return "💅✨"
        case .unhinged: return "🤪🔥"
        case .wholesome: return "🥰💕"
        case .dramatic: return "🎭💔"
        case .aesthetic: return "📸🌸"
        case .legendary: return "🏆👑"
        }
    }
}

struct DramaMoment: Codable, Identifiable {
    var id: String = UUID().uuidString
    var timestamp: Date
    var description: String
    var involvedUserIds: [String]

    enum CodingKeys: String, CodingKey {
        case id
        case timestamp
        case description
        case involvedUserIds = "involved_user_ids"
    }
}

// MARK: - Restaurant Rewards Models

struct RestaurantRewards: Codable {
    var restaurantId: String
    var restaurantName: String
    var userPoints: Int
    var currentTier: RewardTier
    var totalVisits: Int
    var lastVisitDate: Date?
    var pointsHistory: [PointsTransaction] = []

    enum CodingKeys: String, CodingKey {
        case restaurantId = "restaurant_id"
        case restaurantName = "restaurant_name"
        case userPoints = "user_points"
        case currentTier = "current_tier"
        case totalVisits = "total_visits"
        case lastVisitDate = "last_visit_date"
        case pointsHistory = "points_history"
    }
}

enum RewardTier: String, Codable, CaseIterable {
    case bronze = "Bronze"
    case silver = "Silver"
    case gold = "Gold"
    case platinum = "Platinum"

    var minPoints: Int {
        switch self {
        case .bronze: return 0
        case .silver: return 500
        case .gold: return 1000
        case .platinum: return 2500
        }
    }

    var maxPoints: Int {
        switch self {
        case .bronze: return 499
        case .silver: return 999
        case .gold: return 2499
        case .platinum: return Int.max
        }
    }

    var discountPercent: Int {
        switch self {
        case .bronze: return 5
        case .silver: return 10
        case .gold: return 15
        case .platinum: return 20
        }
    }

    var perks: [String] {
        switch self {
        case .bronze:
            return ["5% off all orders", "Birthday reward"]
        case .silver:
            return ["10% off all orders", "Free delivery", "Early access to new items"]
        case .gold:
            return ["15% off all orders", "Free delivery", "Priority support", "Monthly surprise"]
        case .platinum:
            return ["20% off all orders", "Free delivery", "VIP support", "Exclusive events", "Free item monthly"]
        }
    }

    var color: String {
        switch self {
        case .bronze: return "#CD7F32"
        case .silver: return "#C0C0C0"
        case .gold: return "#FFD700"
        case .platinum: return "#E5E4E2"
        }
    }
}

struct PointsTransaction: Codable, Identifiable {
    var id: String = UUID().uuidString
    var points: Int
    var reason: String
    var matchId: String?
    var timestamp: Date = Date()

    enum CodingKeys: String, CodingKey {
        case id
        case points
        case reason
        case matchId = "match_id"
        case timestamp
    }
}
