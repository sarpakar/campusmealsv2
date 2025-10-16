//
//  FridgeItem.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation

enum FoodCategory: String, Codable, CaseIterable {
    case fruit = "Fruit"
    case vegetable = "Vegetable"
    case meat = "Meat"
    case dairy = "Dairy"
    case condiment = "Condiment"
    case beverage = "Beverage"
    case other = "Other"
}

struct FridgeItem: Identifiable, Codable {
    var id: String
    var name: String
    var category: FoodCategory
    var quantity: String // "6 oranges", "1 bottle", "500g"
    var expiryDays: Int // Days until expiry
    var imageURL: String
    var position: ItemPosition // Position on fridge for tap zones
    var nutritionInfo: NutritionInfo?
    var recipeSuggestions: [String] // Recipe names that use this item
    var isExpiringSoon: Bool {
        return expiryDays <= 3
    }

    var expiryText: String {
        if expiryDays < 0 {
            return "Expired \(abs(expiryDays)) days ago"
        } else if expiryDays == 0 {
            return "Expires today"
        } else if expiryDays == 1 {
            return "Expires tomorrow"
        } else {
            return "Expires in \(expiryDays) days"
        }
    }

    var categoryIcon: String {
        switch category {
        case .fruit:
            return "leaf.fill"
        case .vegetable:
            return "carrot.fill"
        case .meat:
            return "fork.knife"
        case .dairy:
            return "drop.fill"
        case .condiment:
            return "bottle.fill"
        case .beverage:
            return "cup.and.saucer.fill"
        case .other:
            return "cube.fill"
        }
    }
}

struct ItemPosition: Codable {
    var shelf: Int // 1 = top, 2 = middle, 3 = bottom
    var zone: Int // Left to right position
    var x: CGFloat // Relative X position (0-1)
    var y: CGFloat // Relative Y position (0-1)
    var width: CGFloat // Relative width
    var height: CGFloat // Relative height
}

struct NutritionInfo: Codable {
    var calories: Int
    var protein: String
    var carbs: String
    var fat: String
}
