//
//  FoodIntent.swift
//  Campusmealsv2
//
//  Simple food discovery models
//

import Foundation
import CoreLocation

// User's search intent
struct FoodIntent: Identifiable, Codable {
    var id = UUID()
    var displayText: String          // "Best coffee near me"
    var emoji: String                // "☕"
    var searchType: SearchType
    var filters: SearchFilters
}

enum SearchType: String, Codable {
    case coffee = "coffee"
    case highProtein = "high_protein"
    case groceries = "groceries"
    case quickBreakfast = "quick_breakfast"
    case healthyLunch = "healthy_lunch"
    case custom = "custom"
}

struct SearchFilters: Codable {
    var maxDistance: Double = 2000   // meters (2km default)
    var maxPrice: Double? = nil
    var minRating: Double? = nil
    var category: String? = nil      // "coffee", "protein", etc
    var keywords: [String] = []
}

// Search result with optimization data
struct FoodResult: Identifiable {
    var id = UUID()
    var vendor: Vendor
    var menuItem: MenuItem?          // nil for general vendor results
    var distance: Double             // meters
    var walkTime: Int                // minutes
    var matchScore: Double           // 0-100 simple score
    var matchReason: String          // "High protein · 10 min walk · $30"
}

// Quick suggestions for home screen
struct QuickSuggestion: Identifiable {
    var id = UUID()
    var emoji: String
    var text: String
    var intent: FoodIntent
}
