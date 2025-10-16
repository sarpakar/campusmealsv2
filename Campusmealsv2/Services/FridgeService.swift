//
//  FridgeService.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation

@MainActor
class FridgeService: ObservableObject {
    static let shared = FridgeService()

    @Published var items: [FridgeItem] = []
    @Published var isLoading = false

    private init() {
        loadFridgeItems()
    }

    func loadFridgeItems() {
        // Sample items matching the fridge image
        items = [
            // Top Shelf - Left Oranges
            FridgeItem(
                id: "orange1",
                name: "Oranges",
                category: .fruit,
                quantity: "6 oranges",
                expiryDays: 5,
                imageURL: "https://images.unsplash.com/photo-1547514701-42782101795e?w=400",
                position: ItemPosition(shelf: 1, zone: 1, x: 0.05, y: 0.12, width: 0.25, height: 0.18),
                nutritionInfo: NutritionInfo(calories: 62, protein: "1.2g", carbs: "15g", fat: "0.2g"),
                recipeSuggestions: ["Orange Juice", "Fruit Salad", "Orange Chicken"]
            ),

            // Top Shelf - Right Oranges
            FridgeItem(
                id: "orange2",
                name: "Oranges",
                category: .fruit,
                quantity: "8 oranges",
                expiryDays: 5,
                imageURL: "https://images.unsplash.com/photo-1547514701-42782101795e?w=400",
                position: ItemPosition(shelf: 1, zone: 2, x: 0.35, y: 0.12, width: 0.30, height: 0.18),
                nutritionInfo: NutritionInfo(calories: 62, protein: "1.2g", carbs: "15g", fat: "0.2g"),
                recipeSuggestions: ["Orange Smoothie", "Marmalade", "Citrus Salad"]
            ),

            // Top Shelf - Eggs (right side)
            FridgeItem(
                id: "eggs1",
                name: "Eggs",
                category: .dairy,
                quantity: "6 eggs",
                expiryDays: 12,
                imageURL: "https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400",
                position: ItemPosition(shelf: 1, zone: 3, x: 0.70, y: 0.12, width: 0.25, height: 0.18),
                nutritionInfo: NutritionInfo(calories: 72, protein: "6g", carbs: "0.4g", fat: "5g"),
                recipeSuggestions: ["Scrambled Eggs", "Omelette", "Fried Rice"]
            ),

            // Middle Shelf - Jam (left)
            FridgeItem(
                id: "jam1",
                name: "Apricot Jam",
                category: .condiment,
                quantity: "300g jar",
                expiryDays: 45,
                imageURL: "https://images.unsplash.com/photo-1599490659213-e2b9527bd1f5?w=400",
                position: ItemPosition(shelf: 2, zone: 1, x: 0.05, y: 0.38, width: 0.15, height: 0.20),
                nutritionInfo: NutritionInfo(calories: 56, protein: "0.1g", carbs: "14g", fat: "0g"),
                recipeSuggestions: ["Toast with Jam", "Yogurt Parfait", "Jam Cookies"]
            ),

            // Middle Shelf - Meat/Steak (center) - MAIN ITEM!
            FridgeItem(
                id: "steak1",
                name: "Ribeye Steak",
                category: .meat,
                quantity: "500g",
                expiryDays: 2,
                imageURL: "https://images.unsplash.com/photo-1603073301036-9b4d4d0eed7e?w=400",
                position: ItemPosition(shelf: 2, zone: 2, x: 0.25, y: 0.38, width: 0.35, height: 0.20),
                nutritionInfo: NutritionInfo(calories: 291, protein: "25g", carbs: "0g", fat: "21g"),
                recipeSuggestions: ["Grilled Steak", "Steak Fajitas", "Beef Stir Fry", "Steak Sandwich"]
            ),

            // Middle Shelf - Milk (right)
            FridgeItem(
                id: "milk1",
                name: "Whole Milk",
                category: .dairy,
                quantity: "1 gallon",
                expiryDays: 4,
                imageURL: "https://images.unsplash.com/photo-1550583724-b2692b85b150?w=400",
                position: ItemPosition(shelf: 2, zone: 3, x: 0.65, y: 0.38, width: 0.18, height: 0.25),
                nutritionInfo: NutritionInfo(calories: 149, protein: "8g", carbs: "12g", fat: "8g"),
                recipeSuggestions: ["Smoothie", "Cereal", "Hot Chocolate", "Pancakes"]
            ),

            // Bottom Shelf - Oranges (left)
            FridgeItem(
                id: "orange3",
                name: "Oranges",
                category: .fruit,
                quantity: "4 oranges",
                expiryDays: 6,
                imageURL: "https://images.unsplash.com/photo-1547514701-42782101795e?w=400",
                position: ItemPosition(shelf: 3, zone: 1, x: 0.05, y: 0.68, width: 0.20, height: 0.15),
                nutritionInfo: NutritionInfo(calories: 62, protein: "1.2g", carbs: "15g", fat: "0.2g"),
                recipeSuggestions: ["Fresh Juice", "Orange Zest", "Vitamin C Boost"]
            ),

            // Bottom Shelf - Egg Carton (center-right)
            FridgeItem(
                id: "eggs2",
                name: "Eggs",
                category: .dairy,
                quantity: "12 eggs",
                expiryDays: 14,
                imageURL: "https://images.unsplash.com/photo-1582722872445-44dc5f7e3c8f?w=400",
                position: ItemPosition(shelf: 3, zone: 2, x: 0.40, y: 0.70, width: 0.25, height: 0.18),
                nutritionInfo: NutritionInfo(calories: 72, protein: "6g", carbs: "0.4g", fat: "5g"),
                recipeSuggestions: ["Hard Boiled Eggs", "Egg Salad", "Baking"]
            )
        ]
    }

    func getItem(by id: String) -> FridgeItem? {
        return items.first { $0.id == id }
    }
}
