//
//  Spacing.swift
//  Campus Meals Design System
//
//  8-Point Grid System — Apple-level precision
//

import SwiftUI

/// Design System Spacing Constants
/// Based on 8-point grid for pixel-perfect alignment
struct Spacing {
    // MARK: - Core Spacing Values

    /// 4pt - Tight spacing between related elements
    /// Example: Icon + text, tag padding
    static let xs: CGFloat = 4

    /// 8pt - Related items, minimal separation
    /// Example: Text line spacing, small gaps
    static let sm: CGFloat = 8

    /// 12pt - Comfortable element spacing
    /// Example: Between card elements
    static let md: CGFloat = 12

    /// 16pt - Standard padding, section spacing
    /// Example: Card padding, horizontal margins
    static let lg: CGFloat = 16

    /// 24pt - Major sections, breathing room
    /// Example: Between content sections
    static let xl: CGFloat = 24

    /// 32pt - Page margins, major separations
    /// Example: Screen edges, hero spacing
    static let xxl: CGFloat = 32

    /// 40pt - Extra large gaps
    /// Example: Bottom safe area padding
    static let xxxl: CGFloat = 40

    // MARK: - Component Specific

    /// Search bar height - Perfect tap target
    static let searchBarHeight: CGFloat = 52

    /// Card corner radius - Soft, modern
    static let cardCornerRadius: CGFloat = 16

    /// Button corner radius - Friendly pills
    static let buttonCornerRadius: CGFloat = 24

    /// Tag corner radius - Small pills
    static let tagCornerRadius: CGFloat = 12

    /// Minimum tap target - Accessibility standard
    static let minTapTarget: CGFloat = 44

    /// Floating button size - Thumb-friendly
    static let floatingButtonSize: CGFloat = 56

    /// Profile avatar size - Small
    static let avatarSmall: CGFloat = 32

    /// Profile avatar size - Medium
    static let avatarMedium: CGFloat = 48

    /// Profile avatar size - Large
    static let avatarLarge: CGFloat = 64

    // MARK: - Shadows

    /// Light shadow - Subtle depth
    static let shadowLight = (radius: CGFloat(4), opacity: Double(0.06))

    /// Medium shadow - Cards, buttons
    static let shadowMedium = (radius: CGFloat(8), opacity: Double(0.10))

    /// Heavy shadow - Modals, overlays
    static let shadowHeavy = (radius: CGFloat(16), opacity: Double(0.15))

    // MARK: - Animation Durations

    /// Instant feedback - Button presses
    static let animationInstant: Double = 0.1

    /// Quick transition - Shows responsiveness
    static let animationQuick: Double = 0.25

    /// Standard transition - Most UI changes
    static let animationStandard: Double = 0.4

    /// Smooth transition - Page changes
    static let animationSmooth: Double = 0.6

    /// Dramatic transition - Hero moments
    static let animationDramatic: Double = 1.0
}

// MARK: - Layout Constants

struct Layout {
    // MARK: - Screen Dimensions

    /// Standard screen edge insets
    static let screenEdgePadding: CGFloat = 16

    /// Safe area bottom padding (for home indicator)
    static let safeAreaBottom: CGFloat = 34

    /// Navigation bar height (standard)
    static let navBarHeight: CGFloat = 44

    /// Tab bar height
    static let tabBarHeight: CGFloat = 80

    // MARK: - Card Dimensions

    /// Restaurant card width (for horizontal scroll)
    static let cardWidth: CGFloat = UIScreen.main.bounds.width - 32

    /// Restaurant card image height (16:9 ratio)
    static let cardImageHeight: CGFloat = 200

    /// Small card height (for grids)
    static let cardSmallHeight: CGFloat = 120

    // MARK: - Grid System

    /// 2-column grid spacing
    static let gridSpacing2Column: CGFloat = 12

    /// 3-column grid spacing
    static let gridSpacing3Column: CGFloat = 8

    // MARK: - Thumb Zone Optimization

    /// Bottom 1/3 of screen - Easy to reach
    static let thumbZoneHeight: CGFloat = UIScreen.main.bounds.height / 3

    /// Floating button position from bottom
    static let floatingButtonBottomPadding: CGFloat = 80
}

// MARK: - View Extension for Spacing

extension View {
    /// Apply standard card padding
    func cardPadding() -> some View {
        self.padding(Spacing.lg)
    }

    /// Apply standard card style
    func cardStyle() -> some View {
        self
            .background(Color.white)
            .cornerRadius(Spacing.cardCornerRadius)
            .shadow(
                color: Color.black.opacity(Spacing.shadowMedium.opacity),
                radius: Spacing.shadowMedium.radius,
                x: 0,
                y: 2
            )
    }

    /// Apply screen edge padding
    func screenPadding() -> some View {
        self.padding(.horizontal, Layout.screenEdgePadding)
    }

    /// Apply section spacing
    func sectionSpacing() -> some View {
        self.padding(.vertical, Spacing.xl)
    }
}

// MARK: - Spacing Guidelines

/*
 THE 8-POINT GRID SYSTEM:

 WHY 8 POINTS?
 - Divides evenly on all screen densities (1x, 2x, 3x)
 - Apple uses it internally (iOS HIG)
 - Creates visual rhythm and consistency
 - Easy mental math (8, 16, 24, 32...)

 USAGE RULES:

 1. ALWAYS USE MULTIPLES OF 4
    ✅ 4, 8, 12, 16, 20, 24, 28, 32...
    ❌ 5, 10, 15, 25, 30...

 2. PREFER MULTIPLES OF 8
    - Most spacing should be 8, 16, 24, 32
    - Use 4, 12, 20 for fine-tuning only

 3. COMPONENT ALIGNMENT
    - All elements should align to the 8pt grid
    - Heights and widths should be multiples of 8
    - Exception: Text (uses built-in line height)

 4. PADDING HIERARCHY
    - Inner padding (card content): 16pt
    - Section spacing: 24pt
    - Screen edges: 16pt
    - Major sections: 32pt

 5. TAP TARGETS
    - Minimum 44x44pt (Apple HIG)
    - Prefer 48x48pt or larger
    - Add invisible padding if visual element is smaller

 GEN Z SPACING PRINCIPLES:

 1. BREATHING ROOM
    - Don't cram everything together
    - White space = premium feel
    - Cards should float, not stack tightly

 2. THUMB-FIRST DESIGN
    - Bottom 1/3 of screen = easy reach
    - Top corners = hard to reach
    - Primary actions in thumb zone

 3. VISUAL RHYTHM
    - Consistent spacing = professional
    - Inconsistent spacing = amateur
    - Gen Z can spot sloppy design instantly

 4. MOBILE-FIRST
    - Design for iPhone first, iPad second
    - Assume one-handed use
    - No tiny buttons
*/
