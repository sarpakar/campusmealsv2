//
//  MealPlanService.swift
//  Campusmealsv2
//
//  Service for managing meal plans and progress tracking
//

import Foundation
import FirebaseFirestore
import Combine

@MainActor
class MealPlanService: ObservableObject {
    static let shared = MealPlanService()

    @Published var weeklyPlans: [DailyMealPlan] = []
    @Published var currentWeekProgress: WeeklyProgress?
    @Published var isLoading = false

    private let db = Firestore.firestore()
    private let calendar = Calendar.current

    private init() {
        // Generate sample data for demo
        generateSampleWeeklyPlans()
    }

    // MARK: - Public Methods

    func loadWeeklyPlans() async {
        isLoading = true

        // In production, fetch from Firebase
        // For now, use sample data
        generateSampleWeeklyPlans()

        isLoading = false
    }

    func getMealPlan(for date: Date) -> DailyMealPlan? {
        return weeklyPlans.first { calendar.isDate($0.date, inSameDayAs: date) }
    }

    func logMeal(_ meal: MealSlot, for date: Date) async {
        guard let index = weeklyPlans.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) else {
            return
        }

        var plan = weeklyPlans[index]

        // Update the appropriate meal slot
        switch meal.mealType {
        case .breakfast:
            plan.breakfast = meal
        case .lunch:
            plan.lunch = meal
        case .dinner:
            plan.dinner = meal
        case .snack:
            plan.snacks.append(meal)
        }

        weeklyPlans[index] = plan

        // In production, save to Firebase
        await saveMealPlan(plan)
    }

    func completeMeal(mealType: MealSlot.MealType, for date: Date) async {
        guard let index = weeklyPlans.firstIndex(where: { calendar.isDate($0.date, inSameDayAs: date) }) else {
            return
        }

        var plan = weeklyPlans[index]

        switch mealType {
        case .breakfast:
            plan.breakfast?.isCompleted = true
            plan.breakfast?.completedAt = Date()
        case .lunch:
            plan.lunch?.isCompleted = true
            plan.lunch?.completedAt = Date()
        case .dinner:
            plan.dinner?.isCompleted = true
            plan.dinner?.completedAt = Date()
        case .snack:
            if !plan.snacks.isEmpty {
                plan.snacks[0].isCompleted = true
                plan.snacks[0].completedAt = Date()
            }
        }

        weeklyPlans[index] = plan
        await saveMealPlan(plan)
    }

    // MARK: - Private Methods

    private func saveMealPlan(_ plan: DailyMealPlan) async {
        // In production, save to Firestore
        // For demo, just update local state
        print("✅ Meal plan saved for \(plan.date)")
    }

    // MARK: - Sample Data Generation

    private func generateSampleWeeklyPlans() {
        let today = Date()
        let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!

        weeklyPlans = []

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else { continue }

            let isBeforeToday = date < today
            let isToday = calendar.isDate(date, inSameDayAs: today)

            var plan = DailyMealPlan(
                date: date,
                userId: "demo-user",
                calorieGoal: 2000,
                proteinGoal: 150,
                carbsGoal: 250,
                fatsGoal: 65
            )

            // Generate sample meals for past days and today
            if isBeforeToday || isToday {
                plan.breakfast = MealSlot(
                    mealType: .breakfast,
                    vendorName: generateRandomVendor(),
                    itemName: generateRandomBreakfast(),
                    calories: Int.random(in: 350...550),
                    protein: Int.random(in: 20...35),
                    carbs: Int.random(in: 40...60),
                    fats: Int.random(in: 15...25),
                    isCompleted: isBeforeToday || (isToday && calendar.component(.hour, from: Date()) >= 9),
                    completedAt: isBeforeToday ? date : (isToday ? Date() : nil)
                )

                if calendar.component(.hour, from: Date()) >= 12 || isBeforeToday {
                    plan.lunch = MealSlot(
                        mealType: .lunch,
                        vendorName: generateRandomVendor(),
                        itemName: generateRandomLunch(),
                        calories: Int.random(in: 500...750),
                        protein: Int.random(in: 30...50),
                        carbs: Int.random(in: 60...90),
                        fats: Int.random(in: 20...35),
                        isCompleted: isBeforeToday || (isToday && calendar.component(.hour, from: Date()) >= 14),
                        completedAt: isBeforeToday ? date : (isToday ? Date() : nil)
                    )
                }

                if calendar.component(.hour, from: Date()) >= 18 || isBeforeToday {
                    plan.dinner = MealSlot(
                        mealType: .dinner,
                        vendorName: generateRandomVendor(),
                        itemName: generateRandomDinner(),
                        calories: Int.random(in: 600...850),
                        protein: Int.random(in: 35...55),
                        carbs: Int.random(in: 70...100),
                        fats: Int.random(in: 25...40),
                        isCompleted: isBeforeToday,
                        completedAt: isBeforeToday ? date : nil
                    )
                }

                // Add occasional snack
                if Bool.random() {
                    plan.snacks.append(MealSlot(
                        mealType: .snack,
                        vendorName: nil,
                        itemName: generateRandomSnack(),
                        calories: Int.random(in: 100...250),
                        protein: Int.random(in: 5...15),
                        carbs: Int.random(in: 15...30),
                        fats: Int.random(in: 5...12),
                        isCompleted: isBeforeToday,
                        completedAt: isBeforeToday ? date : nil
                    ))
                }
            }

            weeklyPlans.append(plan)
        }

        // Calculate weekly progress
        let monday = weekStart
        currentWeekProgress = WeeklyProgress(
            weekStart: monday,
            userId: "demo-user",
            dailyPlans: weeklyPlans
        )
    }

    // MARK: - Random Data Generators

    private func generateRandomVendor() -> String {
        let vendors = [
            "Starbucks", "Chipotle", "Sweetgreen", "Trader Joe's",
            "Dig Inn", "Just Salad", "Pret A Manger", "Shake Shack",
            "Joe's Pizza", "Bagel Boss", "Blue Stone Lane"
        ]
        return vendors.randomElement() ?? "Local Cafe"
    }

    private func generateRandomBreakfast() -> String {
        let items = [
            "Avocado Toast with Eggs",
            "Greek Yogurt Bowl",
            "Breakfast Burrito",
            "Oatmeal with Berries",
            "Egg White Sandwich",
            "Acai Bowl",
            "Protein Pancakes",
            "Everything Bagel with Cream Cheese"
        ]
        return items.randomElement() ?? "Breakfast"
    }

    private func generateRandomLunch() -> String {
        let items = [
            "Chicken Caesar Salad",
            "Burrito Bowl",
            "Grilled Chicken Sandwich",
            "Quinoa Power Bowl",
            "Turkey & Avocado Wrap",
            "Kale Caesar with Salmon",
            "Mediterranean Bowl",
            "Chicken Parm Sandwich"
        ]
        return items.randomElement() ?? "Lunch"
    }

    private func generateRandomDinner() -> String {
        let items = [
            "Grilled Salmon with Vegetables",
            "Chicken Teriyaki Bowl",
            "Steak Burrito",
            "Margherita Pizza",
            "Pad Thai",
            "Chicken Parm with Pasta",
            "Sushi Platter",
            "Fish Tacos"
        ]
        return items.randomElement() ?? "Dinner"
    }

    private func generateRandomSnack() -> String {
        let items = [
            "Protein Bar",
            "Apple with Almond Butter",
            "Greek Yogurt",
            "Mixed Nuts",
            "Hummus & Veggies",
            "Protein Shake",
            "Rice Cakes with PB",
            "Trail Mix"
        ]
        return items.randomElement() ?? "Snack"
    }
}
