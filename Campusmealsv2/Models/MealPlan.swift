//
//  MealPlan.swift
//  Campusmealsv2
//
//  Meal planning and progress tracking models
//

import Foundation
import FirebaseFirestore

// MARK: - Daily Meal Plan

struct DailyMealPlan: Identifiable, Codable {
    var id: String = UUID().uuidString
    var date: Date
    var userId: String

    // Meal slots
    var breakfast: MealSlot?
    var lunch: MealSlot?
    var dinner: MealSlot?
    var snacks: [MealSlot] = []

    // Goals
    var calorieGoal: Int = 2000
    var proteinGoal: Int = 150 // grams
    var carbsGoal: Int = 250
    var fatsGoal: Int = 65

    // Computed properties
    var totalCalories: Int {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        let snackCalories = snacks.reduce(0) { $0 + $1.calories }
        return meals.reduce(snackCalories) { $0 + $1.calories }
    }

    var totalProtein: Int {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        let snackProtein = snacks.reduce(0) { $0 + $1.protein }
        return meals.reduce(snackProtein) { $0 + $1.protein }
    }

    var totalCarbs: Int {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        let snackCarbs = snacks.reduce(0) { $0 + $1.carbs }
        return meals.reduce(snackCarbs) { $0 + $1.carbs }
    }

    var totalFats: Int {
        let meals = [breakfast, lunch, dinner].compactMap { $0 }
        let snackFats = snacks.reduce(0) { $0 + $1.fats }
        return meals.reduce(snackFats) { $0 + $1.fats }
    }

    var completedMeals: Int {
        var count = 0
        if breakfast?.isCompleted == true { count += 1 }
        if lunch?.isCompleted == true { count += 1 }
        if dinner?.isCompleted == true { count += 1 }
        return count
    }

    var isOnTrack: Bool {
        // On track if:
        // 1. Completed expected meals for time of day
        // 2. Within 10% of calorie goal
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: Date())

        var expectedMeals = 0
        if hour >= 9 { expectedMeals += 1 } // Breakfast by 9am
        if hour >= 14 { expectedMeals += 1 } // Lunch by 2pm
        if hour >= 19 { expectedMeals += 1 } // Dinner by 7pm

        let mealsCompleted = completedMeals >= expectedMeals
        let caloriesOnTrack = abs(totalCalories - calorieGoal) <= calorieGoal / 10

        return mealsCompleted && caloriesOnTrack
    }

    var calorieProgress: Double {
        return min(Double(totalCalories) / Double(calorieGoal), 1.0)
    }

    var proteinProgress: Double {
        return min(Double(totalProtein) / Double(proteinGoal), 1.0)
    }
}

// MARK: - Meal Slot

struct MealSlot: Identifiable, Codable {
    var id: String = UUID().uuidString
    var mealType: MealType
    var vendorName: String?
    var itemName: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fats: Int
    var isCompleted: Bool = false
    var completedAt: Date?
    var plannedTime: Date?

    enum MealType: String, Codable {
        case breakfast
        case lunch
        case dinner
        case snack

        var icon: String {
            switch self {
            case .breakfast: return "sunrise.fill"
            case .lunch: return "sun.max.fill"
            case .dinner: return "moon.stars.fill"
            case .snack: return "leaf.fill"
            }
        }

        var displayName: String {
            switch self {
            case .breakfast: return "Breakfast"
            case .lunch: return "Lunch"
            case .dinner: return "Dinner"
            case .snack: return "Snack"
            }
        }
    }
}

// MARK: - Weekly Progress

struct WeeklyProgress: Identifiable {
    var id: String = UUID().uuidString
    var weekStart: Date
    var userId: String
    var dailyPlans: [DailyMealPlan] = []

    // Computed
    var daysOnTrack: Int {
        dailyPlans.filter { $0.isOnTrack }.count
    }

    var weeklyStreak: Int {
        var streak = 0
        for plan in dailyPlans.sorted(by: { $0.date < $1.date }) {
            if plan.isOnTrack {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    var averageCalories: Int {
        guard !dailyPlans.isEmpty else { return 0 }
        return dailyPlans.reduce(0) { $0 + $1.totalCalories } / dailyPlans.count
    }
}

// MARK: - Firestore Extensions

extension DailyMealPlan {
    static func from(document: DocumentSnapshot) -> DailyMealPlan? {
        guard let data = try? document.data(as: DailyMealPlan.self) else {
            return nil
        }
        return data
    }
}
