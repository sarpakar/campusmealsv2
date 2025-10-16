//
//  GenZButton.swift
//  Campus Meals Design System
//
//  Button components optimized for Gen Z interaction patterns
//

import SwiftUI

// MARK: - Primary Button (The Main Character)

struct PrimaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                }

                Text(title)
                    .buttonTextStyle()
            }
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.minTapTarget)
            .background(Color.brandBlack)
            .foregroundColor(.white)
            .cornerRadius(Spacing.buttonCornerRadius)
        }
        .buttonPressAnimation(isPressed: $isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Secondary Button (The Supporting Role)

struct SecondaryButton: View {
    let title: String
    let icon: String?
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, icon: String? = nil, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: 8) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .medium))
                }

                Text(title)
                    .font(.label)
            }
            .frame(maxWidth: .infinity)
            .frame(height: Spacing.minTapTarget)
            .background(Color.white)
            .foregroundColor(.brandBlack)
            .overlay(
                RoundedRectangle(cornerRadius: Spacing.buttonCornerRadius)
                    .stroke(Color.brandGray.opacity(0.3), lineWidth: 1.5)
            )
            .cornerRadius(Spacing.buttonCornerRadius)
        }
        .buttonPressAnimation(isPressed: $isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Pill Button (Category Filters)

struct PillButton: View {
    let title: String
    let icon: String?
    let isSelected: Bool
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, icon: String? = nil, isSelected: Bool = false, action: @escaping () -> Void) {
        self.title = title
        self.icon = icon
        self.isSelected = isSelected
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            HStack(spacing: 6) {
                if let icon = icon {
                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .medium))
                }

                Text(title)
                    .font(.labelSmall)
                    .fontWeight(.medium)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(isSelected ? Color.brandBlack : Color.white)
            .foregroundColor(isSelected ? .white : .brandBlack)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.brandGray.opacity(0.2), lineWidth: isSelected ? 0 : 1)
            )
        }
        .buttonPressAnimation(isPressed: $isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .animation(.springBouncy, value: isSelected)
    }
}

// MARK: - Icon Button (Minimal Actions)

struct IconButton: View {
    let icon: String
    let size: CGFloat
    let action: () -> Void

    @State private var isPressed = false

    init(icon: String, size: CGFloat = 44, action: @escaping () -> Void) {
        self.icon = icon
        self.size = size
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            Image(systemName: icon)
                .font(.system(size: size * 0.5, weight: .semibold))
                .foregroundColor(.brandBlack)
                .frame(width: size, height: size)
                .background(Color.white)
                .cornerRadius(size / 2)
                .shadow(
                    color: Color.black.opacity(Spacing.shadowMedium.opacity),
                    radius: Spacing.shadowMedium.radius,
                    x: 0,
                    y: 2
                )
        }
        .buttonPressAnimation(isPressed: $isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Floating Action Button (Power Move)

struct FloatingActionButton: View {
    let icon: String
    let label: String
    let action: () -> Void

    @State private var isPressed = false

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))

                Text(label)
                    .font(.labelLarge)
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .frame(height: 56)
            .background(
                Capsule()
                    .fill(Color.brandBlack.opacity(0.9))
            )
            .shadow(
                color: Color.black.opacity(0.2),
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .buttonPressAnimation(isPressed: $isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Gradient Button (Hero CTA)

struct GradientButton: View {
    let title: String
    let gradient: LinearGradient
    let action: () -> Void

    @State private var isPressed = false

    init(_ title: String, gradient: LinearGradient = Color.sunsetGradient, action: @escaping () -> Void) {
        self.title = title
        self.gradient = gradient
        self.action = action
    }

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            Text(title)
                .buttonTextStyle()
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(gradient)
                .cornerRadius(Spacing.buttonCornerRadius)
                .shadow(
                    color: Color.brandHotPink.opacity(0.3),
                    radius: 12,
                    x: 0,
                    y: 6
                )
        }
        .buttonPressAnimation(isPressed: $isPressed)
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
    }
}

// MARK: - Toggle Button (Binary Choice)

struct ToggleButton: View {
    let leftTitle: String
    let rightTitle: String
    @Binding var isRightSelected: Bool
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            // Left option
            Button(action: {
                if isRightSelected {
                    isRightSelected = false
                    HapticFeedback.selection()
                    action()
                }
            }) {
                Text(leftTitle)
                    .font(.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(isRightSelected ? .brandGray : .white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(isRightSelected ? Color.clear : Color.brandBlack)
                    .cornerRadius(18, corners: [.topLeft, .bottomLeft])
            }

            // Right option
            Button(action: {
                if !isRightSelected {
                    isRightSelected = true
                    HapticFeedback.selection()
                    action()
                }
            }) {
                Text(rightTitle)
                    .font(.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundColor(isRightSelected ? .white : .brandGray)
                    .frame(maxWidth: .infinity)
                    .frame(height: 36)
                    .background(isRightSelected ? Color.brandBlack : Color.clear)
                    .cornerRadius(18, corners: [.topRight, .bottomRight])
            }
        }
        .background(Color.brandWhite)
        .cornerRadius(18)
        .overlay(
            RoundedRectangle(cornerRadius: 18)
                .stroke(Color.brandGray.opacity(0.2), lineWidth: 1)
        )
        .animation(.springBouncy, value: isRightSelected)
    }
}

// MARK: - Helper: Custom Corner Radius

// MARK: - Preview

struct ButtonPreviews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            PrimaryButton("Continue", icon: "arrow.right") {}

            SecondaryButton("Learn More", icon: "info.circle") {}

            HStack {
                PillButton("🍕 Pizza", isSelected: true) {}
                PillButton("☕ Café", isSelected: false) {}
                PillButton("🍺 Bar", isSelected: false) {}
            }

            IconButton(icon: "arrow.left") {}

            FloatingActionButton(icon: "arrow.clockwise", label: "search here") {}

            GradientButton("Get Started") {}

            ToggleButton(leftTitle: "Delivery", rightTitle: "Pickup", isRightSelected: .constant(false)) {}
        }
        .padding()
        .background(Color(white: 0.95))
    }
}
