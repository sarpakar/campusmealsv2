//
//  Animations.swift
//  Campus Meals Design System
//
//  TikTok-energy animations — Fast, smooth, delightful
//

import SwiftUI

// MARK: - Animation Presets

extension Animation {
    /// Instant feedback - Button presses (0.1s)
    static let instant = Animation.easeOut(duration: Spacing.animationInstant)

    /// Quick transition - Shows responsiveness (0.25s)
    static let quick = Animation.easeInOut(duration: Spacing.animationQuick)

    /// Standard transition - Most UI changes (0.4s)
    static let standard = Animation.easeInOut(duration: Spacing.animationStandard)

    /// Smooth transition - Page changes (0.6s)
    static let smooth = Animation.easeInOut(duration: Spacing.animationSmooth)

    /// Spring animation - Natural, bouncy (Gen Z loves this)
    static let springBouncy = Animation.spring(response: 0.3, dampingFraction: 0.6)

    /// Spring animation - Smooth, elegant
    static let springSmooth = Animation.spring(response: 0.5, dampingFraction: 0.8)

    /// Spring animation - Dramatic entrance
    static let springDramatic = Animation.spring(response: 0.7, dampingFraction: 0.7)
}

// MARK: - Shimmer Loading Effect (Instagram/TikTok Standard)

struct ShimmerModifier: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    colors: [
                        Color.white.opacity(0),
                        Color.white.opacity(0.3),
                        Color.white.opacity(0)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .mask(content)
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    phase = UIScreen.main.bounds.width
                }
            }
    }
}

extension View {
    /// Apply shimmer loading effect
    /// Use for: Skeleton loaders, loading states
    func shimmer() -> some View {
        self.modifier(ShimmerModifier())
    }
}

// MARK: - Button Press Animation

struct ButtonPressModifier: ViewModifier {
    @Binding var isPressed: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPressed ? 0.95 : 1.0)
            .opacity(isPressed ? 0.8 : 1.0)
            .animation(.springBouncy, value: isPressed)
    }
}

extension View {
    /// Apply button press feedback
    /// Use for: All tappable elements
    func buttonPressAnimation(isPressed: Binding<Bool>) -> some View {
        self.modifier(ButtonPressModifier(isPressed: isPressed))
    }
}

// MARK: - Card Appear Animation (Staggered)

struct CardAppearModifier: ViewModifier {
    let index: Int
    @State private var appeared = false

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 20)
            .onAppear {
                withAnimation(.springSmooth.delay(Double(index) * 0.1)) {
                    appeared = true
                }
            }
    }
}

extension View {
    /// Staggered card appearance animation
    /// Use for: Restaurant cards, list items
    /// - Parameter index: Position in list (for stagger effect)
    func cardAppear(index: Int) -> some View {
        self.modifier(CardAppearModifier(index: index))
    }
}

// MARK: - Pulse Animation (Subtle Attention)

struct PulseModifier: ViewModifier {
    @State private var isPulsing = false

    func body(content: Content) -> some View {
        content
            .scaleEffect(isPulsing ? 1.05 : 1.0)
            .opacity(isPulsing ? 0.8 : 1.0)
            .onAppear {
                withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                    isPulsing = true
                }
            }
    }
}

extension View {
    /// Subtle pulse animation
    /// Use for: "Search here" button, notifications
    func pulse() -> some View {
        self.modifier(PulseModifier())
    }
}

// MARK: - Slide In/Out Transitions

extension AnyTransition {
    /// Slide from bottom with fade
    /// Use for: Bottom sheets, modals
    static var slideFromBottom: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .bottom).combined(with: .opacity),
            removal: .move(edge: .bottom).combined(with: .opacity)
        )
    }

    /// Slide from trailing with fade (Instagram story-style)
    /// Use for: Page transitions, detail views
    static var slideFromTrailing: AnyTransition {
        .asymmetric(
            insertion: .move(edge: .trailing).combined(with: .opacity),
            removal: .move(edge: .leading).combined(with: .opacity)
        )
    }

    /// Scale and fade (dramatic entrance)
    /// Use for: Alerts, success messages
    static var scaleAndFade: AnyTransition {
        .scale(scale: 0.8).combined(with: .opacity)
    }
}

// MARK: - Confetti Effect (Success Moments)

struct ConfettiView: View {
    let particleCount = 80
    @State private var animate = false

    var body: some View {
        ZStack {
            ForEach(0..<particleCount, id: \.self) { index in
                Circle()
                    .fill(randomColor())
                    .frame(width: CGFloat.random(in: 4...12))
                    .offset(
                        x: animate ? CGFloat.random(in: -200...200) : 0,
                        y: animate ? CGFloat.random(in: -300...300) : 0
                    )
                    .opacity(animate ? 0 : 1)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 2.0)) {
                animate = true
            }
        }
    }

    private func randomColor() -> Color {
        let colors: [Color] = [.brandHotPink, .brandCoral, .brandGolden, .brandPurple]
        return colors.randomElement() ?? .brandHotPink
    }
}

// MARK: - Loading Skeleton Components

struct SkeletonRectangle: View {
    let height: CGFloat
    let cornerRadius: CGFloat

    init(height: CGFloat, cornerRadius: CGFloat = 8) {
        self.height = height
        self.cornerRadius = cornerRadius
    }

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(Color.gray.opacity(0.2))
            .frame(height: height)
            .shimmer()
    }
}

struct SkeletonCircle: View {
    let size: CGFloat

    var body: some View {
        Circle()
            .fill(Color.gray.opacity(0.2))
            .frame(width: size, height: size)
            .shimmer()
    }
}

// MARK: - Haptic Feedback

struct HapticFeedback {
    /// Light impact - Button taps
    static func light() {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }

    /// Medium impact - Selections, toggles
    static func medium() {
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }

    /// Heavy impact - Major actions
    static func heavy() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    /// Success notification
    static func success() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }

    /// Error notification
    static func error() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }

    /// Warning notification
    static func warning() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.warning)
    }

    /// Selection changed
    static func selection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
}

// MARK: - Animation Guidelines

/*
 GEN Z ANIMATION PRINCIPLES:

 1. SPEED MATTERS
    - Never animate longer than 1 second
    - 0.3s is the sweet spot for most transitions
    - Faster = more responsive feeling
    - Rule: If user gets impatient, it's too slow

 2. PHYSICS-BASED (Spring Animations)
    - Gen Z grew up with iPhone
    - Spring animations feel "natural"
    - Use .spring() over .linear or .easeInOut
    - Exception: Shimmers (linear is smoother)

 3. FEEDBACK IS EVERYTHING
    - Button press? Scale down slightly
    - Success? Confetti or checkmark animation
    - Loading? Shimmer skeleton, never blank screen
    - Error? Shake or pulse red

 4. HAPTICS = DELIGHT
    - Light tap for button presses
    - Success for achievements
    - Heavy for major actions
    - Don't overuse (haptic fatigue is real)

 5. STAGGER FOR SOPHISTICATION
    - Cards appear one by one (0.1s delay each)
    - Creates rhythm, feels polished
    - Max 5 cards at a time (performance)

 6. MICRO-INTERACTIONS
    - Every tap should have feedback
    - Hover states on buttons
    - Loading states immediately
    - Smooth transitions between states

 PERFORMANCE RULES:

 - Keep animations under 60fps
 - Use .drawingGroup() for complex animations
 - Avoid animating large images
 - Test on iPhone 12 (lowest common denominator)
 - Profile with Instruments

 TIKTOK-ENERGY CHECKLIST:

 ✅ Does it feel snappy?
 ✅ Would it look good in a screen recording?
 ✅ Does it add delight without slowing things down?
 ✅ Can you show it off to friends?

 WHEN TO SKIP ANIMATIONS:

 - User has "Reduce Motion" enabled (accessibility)
 - Low battery mode
 - App is in background
 - Performance is suffering
*/

// MARK: - Animation Examples

struct AnimationExamples: View {
    @State private var showCard = false
    @State private var isButtonPressed = false
    @State private var showConfetti = false

    var body: some View {
        VStack(spacing: 40) {
            // Example 1: Card Appear
            if showCard {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.brandHotPink)
                    .frame(height: 100)
                    .cardAppear(index: 0)
            }

            // Example 2: Button Press
            Button("Tap me") {
                HapticFeedback.light()
            }
            .buttonPressAnimation(isPressed: $isButtonPressed)

            // Example 3: Shimmer Loading
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.gray.opacity(0.2))
                .frame(height: 60)
                .shimmer()

            // Example 4: Confetti
            Button("Celebrate") {
                showConfetti = true
                HapticFeedback.success()
            }
        }
        .padding()
        .overlay(
            showConfetti ? ConfettiView() : nil
        )
    }
}
