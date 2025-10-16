//
//  WeeklyProgressView.swift
//  Campusmealsv2
//
//  Weekly meal plan progress tracker
//

import SwiftUI

struct WeeklyProgressView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var mealPlanService = MealPlanService.shared
    @State private var selectedDayIndex = 0

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    // Generate week days starting from Monday
    private var weekDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday == 1 ? -6 : 2 - weekday) // Adjust for Monday start
        let monday = calendar.date(byAdding: .day, value: daysFromMonday, to: today)!

        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: monday)! }
    }

    private var todayIndex: Int {
        let calendar = Calendar.current
        let today = Date()
        return weekDays.firstIndex { calendar.isDate($0, inSameDayAs: today) } ?? 0
    }

    var body: some View {
        ZStack {
            Color.white.ignoresSafeArea()

            VStack(spacing: 0) {
                // Top Bar
                topBar

                // Instagram Stories-style week indicator
                weekIndicator
                    .padding(.horizontal, 16)
                    .padding(.top, 16)

                // Daily progress cards (swipeable)
                TabView(selection: $selectedDayIndex) {
                    ForEach(0..<7, id: \.self) { index in
                        DailyProgressCard(
                            date: weekDays[index],
                            mealPlan: mealPlanService.getMealPlan(for: weekDays[index]),
                            isToday: index == todayIndex,
                            citiBikeBlue: citiBikeBlue
                        )
                        .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .animation(.spring(response: 0.4, dampingFraction: 0.8), value: selectedDayIndex)

                // Bottom action bar
                bottomActionBar
            }
        }
        .task {
            selectedDayIndex = todayIndex
            await mealPlanService.loadWeeklyPlans()
        }
    }

    // MARK: - Top Bar

    private var topBar: some View {
        HStack {
            Button(action: { dismiss() }) {
                Image(systemName: "xmark")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
            }

            Spacer()

            Text("My Progress")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.black)

            Spacer()

            Button(action: {}) {
                Image(systemName: "calendar")
                    .font(.system(size: 22, weight: .medium))
                    .foregroundColor(.black)
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Week Indicator

    private var weekIndicator: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                VStack(spacing: 8) {
                    // Day letter
                    Text(dayLetter(for: weekDays[index]))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(index == selectedDayIndex ? .black : Color(.systemGray))

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 2)
                                .fill(Color(.systemGray6))
                                .frame(height: 3)

                            if let plan = mealPlanService.getMealPlan(for: weekDays[index]) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(plan.isOnTrack ? citiBikeBlue : Color(.systemGray3))
                                    .frame(width: geometry.size.width * plan.calorieProgress, height: 3)
                            }
                        }
                    }
                    .frame(height: 3)

                    // Day number
                    Text("\(dayNumber(for: weekDays[index]))")
                        .font(.system(size: 12, weight: index == todayIndex ? .bold : .regular))
                        .foregroundColor(index == todayIndex ? .white : .black)
                        .frame(width: 30, height: 30)
                        .background(
                            Circle()
                                .fill(index == todayIndex ? citiBikeBlue : Color.clear)
                        )
                }
                .onTapGesture {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                        selectedDayIndex = index
                    }
                }
            }
        }
    }

    // MARK: - Bottom Action Bar

    private var bottomActionBar: some View {
        Button(action: {}) {
            HStack(spacing: 8) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 18, weight: .semibold))
                Text("Log Meal")
                    .font(.system(size: 17, weight: .semibold))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(citiBikeBlue)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }

    // MARK: - Helpers

    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return String(formatter.string(from: date).prefix(1))
    }

    private func dayNumber(for date: Date) -> Int {
        Calendar.current.component(.day, from: date)
    }
}

// MARK: - Daily Progress Card

struct DailyProgressCard: View {
    let date: Date
    let mealPlan: DailyMealPlan?
    let isToday: Bool
    let citiBikeBlue: Color

    private var plan: DailyMealPlan {
        mealPlan ?? DailyMealPlan(date: date, userId: "")
    }

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Date header
                dateHeader

                // Calorie Progress
                calorieProgressCard

                // Meal slots
                mealSlotsSection

                // Macros
                macroBreakdown
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 40)
        }
    }

    // MARK: - Date Header

    private var dateHeader: some View {
        VStack(spacing: 4) {
            Text(isToday ? "Today" : dateString)
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.black)

            Text(fullDateString)
                .font(.system(size: 15))
                .foregroundColor(Color(.systemGray))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.bottom, 4)
    }

    // MARK: - Calorie Progress Card

    private var calorieProgressCard: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.black)

                    Text("\(plan.totalCalories) / \(plan.calorieGoal)")
                        .font(.system(size: 32, weight: .bold))
                        .foregroundColor(.black)
                }

                Spacer()

                ZStack {
                    Circle()
                        .stroke(Color(.systemGray6), lineWidth: 8)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: plan.calorieProgress)
                        .stroke(citiBikeBlue, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    Text("\(Int(plan.calorieProgress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.black)
                }
            }

            HStack(spacing: 6) {
                Image(systemName: plan.isOnTrack ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                    .font(.system(size: 14))
                    .foregroundColor(plan.isOnTrack ? .green : .orange)

                Text(plan.isOnTrack ? "On track" : "\(3 - plan.completedMeals) meal\(3 - plan.completedMeals == 1 ? "" : "s") remaining")
                    .font(.system(size: 14))
                    .foregroundColor(Color(.systemGray))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
        )
    }

    // MARK: - Meal Slots

    private var mealSlotsSection: some View {
        VStack(spacing: 10) {
            Text("Meals")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            VStack(spacing: 8) {
                MealSlotRow(
                    mealType: .breakfast,
                    slot: plan.breakfast,
                    citiBikeBlue: citiBikeBlue
                )

                MealSlotRow(
                    mealType: .lunch,
                    slot: plan.lunch,
                    citiBikeBlue: citiBikeBlue
                )

                MealSlotRow(
                    mealType: .dinner,
                    slot: plan.dinner,
                    citiBikeBlue: citiBikeBlue
                )

                if !plan.snacks.isEmpty {
                    ForEach(plan.snacks) { snack in
                        MealSlotRow(
                            mealType: .snack,
                            slot: snack,
                            citiBikeBlue: citiBikeBlue
                        )
                    }
                }
            }
        }
    }

    // MARK: - Macro Breakdown

    private var macroBreakdown: some View {
        VStack(spacing: 10) {
            Text("Macros")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.black)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                MacroCard(
                    title: "Protein",
                    current: plan.totalProtein,
                    goal: plan.proteinGoal,
                    unit: "g",
                    color: citiBikeBlue
                )

                MacroCard(
                    title: "Carbs",
                    current: plan.totalCarbs,
                    goal: plan.carbsGoal,
                    unit: "g",
                    color: .orange
                )

                MacroCard(
                    title: "Fats",
                    current: plan.totalFats,
                    goal: plan.fatsGoal,
                    unit: "g",
                    color: .green
                )
            }
        }
    }

    // MARK: - Helpers

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: date)
    }

    private var fullDateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM d, yyyy"
        return formatter.string(from: date)
    }
}

// MARK: - Meal Slot Row

struct MealSlotRow: View {
    let mealType: MealSlot.MealType
    let slot: MealSlot?
    let citiBikeBlue: Color

    var body: some View {
        HStack(spacing: 12) {
            // Icon
            Image(systemName: slot?.isCompleted == true ? "checkmark.circle.fill" : mealType.icon)
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(slot?.isCompleted == true ? .green : Color(.systemGray))
                .frame(width: 24)

            // Meal info
            VStack(alignment: .leading, spacing: 3) {
                Text(mealType.displayName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.black)

                if let slot = slot {
                    Text(slot.itemName)
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray))
                        .lineLimit(1)
                } else {
                    Text("Not logged")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.systemGray2))
                }
            }

            Spacer()

            // Calories
            if let slot = slot {
                Text("\(slot.calories) cal")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.black)
            } else {
                Button(action: {}) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 22))
                        .foregroundColor(citiBikeBlue)
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let title: String
    let current: Int
    let goal: Int
    let unit: String
    let color: Color

    private var progress: Double {
        min(Double(current) / Double(goal), 1.0)
    }

    var body: some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(.systemGray))

            Text("\(current)\(unit)")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.black)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color(.systemGray6))
                        .frame(height: 4)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(color)
                        .frame(width: geometry.size.width * progress, height: 4)
                }
            }
            .frame(height: 4)

            Text("\(goal)\(unit)")
                .font(.system(size: 12))
                .foregroundColor(Color(.systemGray2))
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 10)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.04), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    WeeklyProgressView()
}
