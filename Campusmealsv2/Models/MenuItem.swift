//
//  MenuItem.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation
import FirebaseFirestore

struct MenuItem: Identifiable, Codable {
    @DocumentID var id: String?
    var vendorId: String
    var name: String
    var description: String
    var price: Double
    var imageURL: String
    var category: String // "Entrees", "Sides", "Drinks", etc.
    var isPopular: Bool
    var isNew: Bool
    var likedByFriends: [String] // Friend names who liked this
    var dietaryTags: [String] // ["Vegetarian", "Gluten-Free", "Vegan"]

    enum CodingKeys: String, CodingKey {
        case id
        case vendorId = "vendor_id"
        case name
        case description
        case price
        case imageURL = "image_url"
        case category
        case isPopular = "is_popular"
        case isNew = "is_new"
        case likedByFriends = "liked_by_friends"
        case dietaryTags = "dietary_tags"
    }
}
