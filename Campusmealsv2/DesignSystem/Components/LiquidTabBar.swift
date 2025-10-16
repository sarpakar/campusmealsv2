//
//  LiquidTabBar.swift
//  Campusmealsv2
//
//  Modern bottom tab bar with liquid glass effect
//  Inspired by Instagram, TikTok, and iOS design
//

import SwiftUI

// MARK: - Tab Item Definition
enum TabItem: String, CaseIterable {
    case browse = "browse"
    case social = "social"
    case ai = "ai"
    case fridge = "fridge"
    case metrics = "metrics"

    var icon: String {
        switch self {
        case .browse: return "house.fill"
        case .social: return "person.2.fill"
        case .ai: return "sparkles"
        case .fridge: return "refrigerator.fill"
        case .metrics: return "chart.bar.fill"
        }
    }

    var color: Color {
        switch self {
        case .browse: return Color.white
        case .social: return Color.white
        case .ai: return Color.white
        case .fridge: return Color.white
        case .metrics: return Color.white
        }
    }
}

// MARK: - Liquid Glass Tab Bar
struct LiquidTabBar: View {
    @Binding var selectedTab: TabItem

    var body: some View {
        HStack(spacing: 0) {
            ForEach(TabItem.allCases, id: \.self) { tab in
                TabButton(
                    tab: tab,
                    selectedTab: $selectedTab
                )
            }
        }
        .frame(height: 49)
        // Liquid Glass effect - standard material picks up automatically
        .background(.bar)
        .shadow(color: Color.black.opacity(0.12), radius: 12, x: 0, y: -6)
        .shadow(color: Color.black.opacity(0.08), radius: 4, x: 0, y: -2)
    }
}

// MARK: - Tab Button (Industry Standard)
private struct TabButton: View {
    let tab: TabItem
    @Binding var selectedTab: TabItem

    var isSelected: Bool {
        selectedTab == tab
    }

    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedTab = tab
            }

            let impact = UIImpactFeedbackGenerator(style: .light)
            impact.impactOccurred()
        }) {
            VStack(spacing: 0) {
                Spacer()

                // Icon - Industry standard 24pt
                Image(systemName: tab.icon)
                    .font(.system(size: 24, weight: .regular))
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(isSelected ? Color.primary : Color.primary.opacity(0.5))
                    .frame(height: 24) // Optical balance

                Spacer()
            }
            .frame(maxWidth: .infinity)
            .frame(height: 49)
            .contentShape(Rectangle())
        }
        .buttonStyle(PlainButtonStyle())
    }
}



// MARK: - Preview
#Preview {
    VStack {
        Spacer()

        LiquidTabBar(selectedTab: .constant(.browse))
    }
    .background(
        LinearGradient(
            colors: [Color.purple.opacity(0.3), Color.blue.opacity(0.3)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    )
}
