//
//  Colors.swift
//  Campus Meals Design System
//
//  Gen Z Color Palette — Instagram-worthy, TikTok-energy
//

import SwiftUI

extension Color {
    // MARK: - Primary Palette (Main Character Energy)

    /// Hot Pink - Excitement, confidence, "main character energy"
    /// Use for: CTAs, featured spots, viral content
    static let brandHotPink = Color(hex: "#FF6B9D")

    /// Coral - Warmth, hunger, social connection
    /// Use for: Food photos, warm moments, golden hour vibes
    static let brandCoral = Color(hex: "#FFA06B")

    /// Golden Hour - Optimism, discovery, magic moments
    /// Use for: Success states, achievements, special features
    static let brandGolden = Color(hex: "#FFD56B")

    /// Electric Purple - Mystery, luxury, night-life
    /// Use for: Premium spots, evening features, "unhinged" energy
    static let brandPurple = Color(hex: "#A06BFF")

    /// Midnight Black - Authority, sophistication, timeless
    /// Use for: Search bars, primary buttons, structure
    static let brandBlack = Color(hex: "#000000")

    /// Soft White - Clean canvas, breathing room
    /// Use for: Backgrounds, cards, letting content pop
    static let brandWhite = Color(hex: "#F8F8F8")

    // MARK: - Secondary Palette (Supporting Cast)

    /// Warm Gray - Friendly, doesn't compete
    /// Use for: Secondary text, metadata, subtle elements
    static let brandGray = Color(hex: "#9B9B9B")

    /// Light Gray - Subtle backgrounds
    /// Use for: Loading states, disabled states
    static let brandLightGray = Color(hex: "#F0F0F0")

    // MARK: - Category Colors (Emoji Energy)

    /// 🍕 Pizza & Italian
    static let categoryRed = Color(hex: "#FF4B4B")

    /// 🥗 Healthy & Salads
    static let categoryGreen = Color(hex: "#4BFF4B")

    /// ⭐ Popular & Trending
    static let categoryYellow = Color(hex: "#FFD700")

    /// 🍱 Asian Cuisine
    static let categoryBlue = Color(hex: "#4B9FFF")

    /// 🍰 Desserts & Sweets
    static let categoryPurple = Color(hex: "#9F4BFF")

    // MARK: - Gradients (The Dopamine Hits)

    /// Sunset Gradient - Golden hour magic
    /// Use for: Onboarding, hero moments, special CTAs
    static let sunsetGradient = LinearGradient(
        colors: [brandHotPink, brandCoral, brandGolden, brandPurple],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
    )

    /// Dark Gradient - Sleek, mysterious
    /// Use for: Dark mode overlays, premium features
    static let darkGradient = LinearGradient(
        colors: [Color(hex: "#1A1A1A"), Color(hex: "#000000")],
        startPoint: .top,
        endPoint: .bottom
    )

    /// Photo Overlay Gradient - Makes text readable
    /// Use for: Text on photos, card overlays
    static let photoOverlayGradient = LinearGradient(
        colors: [Color.black.opacity(0.6), Color.clear],
        startPoint: .bottom,
        endPoint: .center
    )

    // MARK: - Dark Mode (Gen Z Default)

    /// True black for OLED screens
    static let darkBackground = Color(hex: "#121212")

    /// Slightly lighter for cards
    static let darkCard = Color(hex: "#1E1E1E")

    /// Dark mode secondary text
    static let darkSecondary = Color(hex: "#ABABAB")

    // MARK: - Semantic Colors

    /// Success - Positive actions
    static let success = Color(hex: "#4BFF4B")
    static let successGreen = Color(hex: "#4BFF4B")

    /// Warning - Caution states
    static let warning = Color(hex: "#FFD700")
    static let warningYellow = Color(hex: "#FFD700")

    /// Error - Destructive actions
    static let error = Color(hex: "#FF4B4B")
    static let errorRed = Color(hex: "#FF4B4B")

    // MARK: - Helper: Hex to Color
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
