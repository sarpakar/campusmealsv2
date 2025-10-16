//
//  Typography.swift
//  Campus Meals Design System
//
//  Gen Z Typography — Bold, scannable, confident
//

import SwiftUI

extension Font {
    // MARK: - Display Fonts (Hero Moments)

    /// Extra Large Display - Onboarding, splash screens
    /// Example: "CORNER"
    static let displayXL = Font.system(size: 40, weight: .heavy, design: .rounded)

    /// Large Display - Page titles, major headings
    /// Example: "find your place"
    static let displayLarge = Font.system(size: 32, weight: .bold, design: .rounded)

    /// Medium Display - Section headers
    static let displayMedium = Font.system(size: 28, weight: .semibold, design: .rounded)

    // MARK: - Heading Fonts (Hierarchy)

    /// H1 - Restaurant names, main content
    static let heading1 = Font.system(size: 24, weight: .bold)

    /// H2 - Section titles, category names
    static let heading2 = Font.system(size: 20, weight: .semibold)

    /// H3 - Subheadings, card titles
    static let heading3 = Font.system(size: 18, weight: .semibold)

    /// H4 - Small headings, labels
    static let heading4 = Font.system(size: 16, weight: .medium)

    // MARK: - Body Fonts (Readable Content)

    /// Body Large - Descriptions, main text
    static let bodyLarge = Font.system(size: 17, weight: .regular)

    /// Body - Default text size
    static let body = Font.system(size: 15, weight: .regular)

    /// Body Small - Secondary information
    static let bodySmall = Font.system(size: 13, weight: .regular)

    // MARK: - Label Fonts (Metadata)

    /// Label Large - Button text, important labels
    static let labelLarge = Font.system(size: 16, weight: .semibold)

    /// Label - Standard labels, tags
    static let label = Font.system(size: 14, weight: .medium)

    /// Label Small - Tiny labels, fine print
    static let labelSmall = Font.system(size: 12, weight: .medium)

    // MARK: - Caption Fonts (Minimal Text)

    /// Caption - Distance, time, metadata
    static let caption = Font.system(size: 13, weight: .regular)

    /// Caption Small - Timestamps, very small details
    static let captionSmall = Font.system(size: 11, weight: .regular)
}

// MARK: - Text Style Modifiers

extension Text {
    /// Restaurant name style - Bold, confident
    func restaurantNameStyle() -> some View {
        self
            .font(.heading1)
            .foregroundColor(.primary)
            .lineLimit(2)
            .minimumScaleFactor(0.8)
    }

    /// Metadata style - Gray, small, scannable
    /// Example: "5 min · $$ · 4.8★"
    func metadataStyle() -> some View {
        self
            .font(.caption)
            .foregroundColor(.brandGray)
    }

    /// Category tag style - Pill-shaped labels
    func categoryTagStyle() -> some View {
        self
            .font(.labelSmall)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(Color.brandWhite)
            .foregroundColor(.brandBlack)
            .cornerRadius(12)
    }

    /// Price indicator style - Dollar signs
    func priceStyle() -> some View {
        self
            .font(.label)
            .fontWeight(.semibold)
            .foregroundColor(.brandGray)
    }

    /// Rating style - Stars and numbers
    func ratingStyle() -> some View {
        self
            .font(.label)
            .fontWeight(.medium)
            .foregroundColor(.categoryYellow)
    }

    /// Distance style - Walk time indicator
    func distanceStyle() -> some View {
        self
            .font(.labelSmall)
            .fontWeight(.bold)
            .foregroundColor(.white)
    }

    /// Button text style - CTAs, primary actions
    func buttonTextStyle() -> some View {
        self
            .font(.labelLarge)
            .fontWeight(.semibold)
            .tracking(0.5)
    }

    /// Search placeholder style - Minimal, casual
    func searchPlaceholderStyle() -> some View {
        self
            .font(.body)
            .foregroundColor(.white.opacity(0.6))
    }
}

// MARK: - Typography Guidelines

/*
 GEN Z TYPOGRAPHY RULES:

 1. BOLD IS YOUR FRIEND
    - Headlines should scream confidence
    - Use .semibold minimum for anything important
    - .regular only for long-form reading

 2. SENTENCE CASE > TITLE CASE
    - "find your place" not "Find Your Place"
    - Feels conversational, less corporate
    - Exception: Restaurant names (respect branding)

 3. LINE HEIGHT = 1.4
    - Built into SF Pro Display
    - Don't adjust unless absolutely necessary
    - Breathing room = easier processing

 4. NEVER USE MORE THAN 2 FONT FAMILIES
    - SF Pro for 95% of interface
    - SF Pro Rounded for personality moments (onboarding)
    - Consistency = professional

 5. TRUNCATION OVER WRAPPING
    - 2 line max for restaurant names
    - 1 line for tags and metadata
    - Gen Z scans, doesn't read walls of text

 6. EMOJIS ARE PUNCTUATION
    - 🔥 Strategic placement
    - Don't overdo it (looks desperate)
    - Native iOS emojis only (no custom)

 ACCESSIBILITY:
 - Support Dynamic Type (iOS Settings)
 - Test with "Larger Accessibility Sizes"
 - Minimum font size: 11pt (anything smaller = unusable)
 - High contrast ratios (4.5:1 minimum)
*/
