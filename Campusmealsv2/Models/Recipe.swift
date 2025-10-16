//
//  Recipe.swift
//  Campusmealsv2
//
//  Created by Claude on 04/10/2025.
//

import Foundation

struct Recipe: Identifiable, Codable, Hashable {
    let id: String
    let name: String // e.g., "Steak & Eggs Breakfast"
    let description: String // e.g., "Protein-packed morning meal"
    let emojiCombo: String // e.g., "🥩🍳"
    let cookTime: String // e.g., "15 min"
    let protein: String // e.g., "42g"
    let calories: String // e.g., "520 cal"
    let difficulty: String // e.g., "Easy", "Medium", "Hard"
    let mealType: String // e.g., "Breakfast", "Lunch", "Dinner"
    let ingredients: [String] // List of ingredients needed
    let instructions: [String] // Step-by-step cooking instructions
    let isRecommended: Bool // Highlight as recommended (first card with border)

    init(id: String = UUID().uuidString,
         name: String,
         description: String,
         emojiCombo: String,
         cookTime: String,
         protein: String,
         calories: String,
         difficulty: String = "Medium",
         mealType: String,
         ingredients: [String],
         instructions: [String],
         isRecommended: Bool = false) {
        self.id = id
        self.name = name
        self.description = description
        self.emojiCombo = emojiCombo
        self.cookTime = cookTime
        self.protein = protein
        self.calories = calories
        self.difficulty = difficulty
        self.mealType = mealType
        self.ingredients = ingredients
        self.instructions = instructions
        self.isRecommended = isRecommended
    }
}
