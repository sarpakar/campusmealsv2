//
//  GenZNavigation.swift
//  Campusmealsv2
//
//  Gen Z-optimized navigation components
//  Tab bars, nav bars, bottom sheets
//

import SwiftUI

// MARK: - Tab Bar
// Custom tab bar with Gen Z styling and haptics
struct GenZTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [TabItem]

    struct TabItem: Identifiable {
        let id = UUID()
        let icon: String
        let selectedIcon: String
        let label: String
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.springBouncy) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                            .font(.system(size: 24))
                            .foregroundColor(selectedTab == index ? .brandBlack : .brandGray)
                            .scaleEffect(selectedTab == index ? 1.1 : 1.0)

                        Text(tabs[index].label)
                            .font(.caption2)
                            .foregroundColor(selectedTab == index ? .brandBlack : .brandGray)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.sm)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.sm)
        .padding(.bottom, Spacing.md)
        .background(
            Color.white
                .shadow(color: Color.black.opacity(0.05), radius: 8, y: -2)
        )
    }
}

// MARK: - Floating Tab Bar
// Floating tab bar with rounded corners (Instagram style)
struct FloatingTabBar: View {
    @Binding var selectedTab: Int
    let tabs: [GenZTabBar.TabItem]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(tabs.indices, id: \.self) { index in
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.springBouncy) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon)
                            .font(.system(size: 22))
                            .foregroundColor(selectedTab == index ? .white : .brandGray)

                        Text(tabs[index].label)
                            .font(.caption2)
                            .foregroundColor(selectedTab == index ? .white : .brandGray)
                            .fontWeight(selectedTab == index ? .semibold : .regular)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, Spacing.md)
                    .background(
                        selectedTab == index
                            ? Color.brandBlack
                            : Color.clear
                    )
                    .cornerRadius(Spacing.cardCornerRadius)
                }
            }
        }
        .padding(Spacing.xs)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.15), radius: 12)
        )
        .padding(.horizontal, Spacing.lg)
        .padding(.bottom, Spacing.lg)
    }
}

// MARK: - Navigation Bar
// Custom navigation bar with back button and actions
struct GenZNavigationBar: View {
    let title: String
    let showBackButton: Bool
    let onBack: (() -> Void)?
    let actions: [NavAction]

    struct NavAction: Identifiable {
        let id = UUID()
        let icon: String
        let action: () -> Void
    }

    init(
        title: String,
        showBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        actions: [NavAction] = []
    ) {
        self.title = title
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.actions = actions
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Back Button
            if showBackButton {
                Button(action: {
                    HapticFeedback.light()
                    onBack?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.brandBlack)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.white)
                                .shadow(color: Color.black.opacity(0.1), radius: 4)
                        )
                }
            }

            // Title
            Text(title)
                .font(.heading2)
                .foregroundColor(.brandBlack)
                .lineLimit(1)

            Spacer()

            // Actions
            HStack(spacing: Spacing.sm) {
                ForEach(actions) { action in
                    Button(action: {
                        HapticFeedback.light()
                        action.action()
                    }) {
                        Image(systemName: action.icon)
                            .font(.title3)
                            .foregroundColor(.brandBlack)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.white)
                                    .shadow(color: Color.black.opacity(0.1), radius: 4)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(Color.white.opacity(0.95))
    }
}

// MARK: - Transparent Navigation Bar
// Transparent overlay nav bar (for image backgrounds)
struct TransparentNavBar: View {
    let showBackButton: Bool
    let onBack: (() -> Void)?
    let actions: [GenZNavigationBar.NavAction]

    init(
        showBackButton: Bool = true,
        onBack: (() -> Void)? = nil,
        actions: [GenZNavigationBar.NavAction] = []
    ) {
        self.showBackButton = showBackButton
        self.onBack = onBack
        self.actions = actions
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Back Button
            if showBackButton {
                Button(action: {
                    HapticFeedback.light()
                    onBack?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3)
                        .foregroundColor(.white)
                        .frame(width: 40, height: 40)
                        .background(
                            Circle()
                                .fill(Color.black.opacity(0.5))
                                .blur(radius: 10)
                        )
                }
            }

            Spacer()

            // Actions
            HStack(spacing: Spacing.sm) {
                ForEach(actions) { action in
                    Button(action: {
                        HapticFeedback.light()
                        action.action()
                    }) {
                        Image(systemName: action.icon)
                            .font(.title3)
                            .foregroundColor(.white)
                            .frame(width: 40, height: 40)
                            .background(
                                Circle()
                                    .fill(Color.black.opacity(0.5))
                                    .blur(radius: 10)
                            )
                    }
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.top, Spacing.xxl + Spacing.md) // Status bar + padding
        .padding(.bottom, Spacing.md)
    }
}

// MARK: - Bottom Sheet
// Draggable bottom sheet (Maps, Filters)
struct GenZBottomSheet<Content: View>: View {
    @Binding var isPresented: Bool
    let detents: [PresentationDetent]
    let showHandle: Bool
    let content: Content

    init(
        isPresented: Binding<Bool>,
        detents: [PresentationDetent] = [.medium, .large],
        showHandle: Bool = true,
        @ViewBuilder content: () -> Content
    ) {
        self._isPresented = isPresented
        self.detents = detents
        self.showHandle = showHandle
        self.content = content()
    }

    var body: some View {
        ZStack {
            if isPresented {
                // Background Overlay
                Color.black
                    .opacity(0.3)
                    .ignoresSafeArea()
                    .onTapGesture {
                        HapticFeedback.light()
                        withAnimation(.springSmooth) {
                            isPresented = false
                        }
                    }

                // Bottom Sheet
                VStack(spacing: 0) {
                    if showHandle {
                        // Drag Handle
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.brandGray.opacity(0.3))
                            .frame(width: 40, height: 5)
                            .padding(.top, Spacing.md)
                    }

                    // Content
                    content
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .background(
                    Color.white
                        .cornerRadius(24, corners: [.topLeft, .topRight])
                )
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.springSmooth, value: isPresented)
    }
}

// MARK: - Section Header
// Section headers with optional action button
struct SectionHeader: View {
    let title: String
    let subtitle: String?
    let actionTitle: String?
    let action: (() -> Void)?

    init(
        title: String,
        subtitle: String? = nil,
        actionTitle: String? = nil,
        action: (() -> Void)? = nil
    ) {
        self.title = title
        self.subtitle = subtitle
        self.actionTitle = actionTitle
        self.action = action
    }

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.heading2)
                    .foregroundColor(.brandBlack)

                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.brandGray)
                }
            }

            Spacer()

            if let actionTitle = actionTitle, let action = action {
                Button(action: {
                    HapticFeedback.light()
                    action()
                }) {
                    Text(actionTitle)
                        .font(.labelSmall)
                        .foregroundColor(.brandHotPink)
                }
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
    }
}

// MARK: - Breadcrumb Navigation
// Step indicator / breadcrumb
struct Breadcrumb: View {
    let steps: [String]
    let currentStep: Int

    var body: some View {
        HStack(spacing: Spacing.sm) {
            ForEach(steps.indices, id: \.self) { index in
                HStack(spacing: Spacing.sm) {
                    // Step Circle
                    ZStack {
                        Circle()
                            .fill(index <= currentStep ? Color.brandBlack : Color.brandLightGray)
                            .frame(width: 32, height: 32)

                        if index < currentStep {
                            Image(systemName: "checkmark")
                                .font(.caption)
                                .foregroundColor(.white)
                        } else {
                            Text("\(index + 1)")
                                .font(.caption)
                                .foregroundColor(index == currentStep ? .white : .brandGray)
                        }
                    }

                    // Step Label
                    if index == currentStep {
                        Text(steps[index])
                            .font(.labelSmall)
                            .foregroundColor(.brandBlack)
                            .transition(.scale.combined(with: .opacity))
                    }

                    // Connector Line
                    if index < steps.count - 1 {
                        Rectangle()
                            .fill(index < currentStep ? Color.brandBlack : Color.brandLightGray)
                            .frame(width: 20, height: 2)
                    }
                }
            }
        }
        .animation(.springBouncy, value: currentStep)
    }
}

// MARK: - Pill Navigation
// Horizontal scrolling pill navigation (categories)
struct PillNavigation: View {
    @Binding var selectedCategory: String
    let categories: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: Spacing.sm) {
                ForEach(categories, id: \.self) { category in
                    Button(action: {
                        HapticFeedback.selection()
                        withAnimation(.springBouncy) {
                            selectedCategory = category
                        }
                    }) {
                        Text(category)
                            .font(.labelSmall)
                            .foregroundColor(selectedCategory == category ? .white : .brandBlack)
                            .padding(.horizontal, Spacing.lg)
                            .padding(.vertical, Spacing.sm)
                            .background(
                                Capsule()
                                    .fill(selectedCategory == category ? Color.brandBlack : Color.white)
                                    .shadow(
                                        color: Color.black.opacity(selectedCategory == category ? 0.15 : 0.05),
                                        radius: selectedCategory == category ? 8 : 4
                                    )
                            )
                    }
                }
            }
            .padding(.horizontal, Spacing.lg)
        }
    }
}

// MARK: - Alert / Toast
// Toast notification (success, error, info)
struct GenZToast: View {
    let message: String
    let icon: String?
    let type: ToastType

    enum ToastType {
        case success
        case error
        case info

        var backgroundColor: Color {
            switch self {
            case .success: return .green
            case .error: return .red
            case .info: return .brandBlack
            }
        }

        var defaultIcon: String {
            switch self {
            case .success: return "checkmark.circle.fill"
            case .error: return "xmark.circle.fill"
            case .info: return "info.circle.fill"
            }
        }
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            Image(systemName: icon ?? type.defaultIcon)
                .font(.title3)
                .foregroundColor(.white)

            Text(message)
                .font(.body)
                .foregroundColor(.white)

            Spacer()
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(type.backgroundColor)
                .shadow(color: Color.black.opacity(0.2), radius: 12)
        )
        .padding(.horizontal, Spacing.lg)
        .transition(.move(edge: .top).combined(with: .opacity))
    }
}

// MARK: - Action Sheet Menu
// Bottom action menu
struct GenZActionSheet: View {
    @Binding var isPresented: Bool
    let title: String?
    let actions: [ActionItem]

    struct ActionItem: Identifiable {
        let id = UUID()
        let title: String
        let icon: String
        let style: Style
        let action: () -> Void

        enum Style {
            case `default`
            case destructive
            case cancel
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Title
            if let title = title {
                Text(title)
                    .font(.heading3)
                    .foregroundColor(.brandBlack)
                    .padding(Spacing.lg)
            }

            Divider()

            // Actions
            ForEach(actions) { action in
                Button(action: {
                    HapticFeedback.light()
                    action.action()
                    withAnimation(.springSmooth) {
                        isPresented = false
                    }
                }) {
                    HStack(spacing: Spacing.md) {
                        Image(systemName: action.icon)
                            .font(.title3)
                            .foregroundColor(actionColor(for: action.style))
                            .frame(width: 24)

                        Text(action.title)
                            .font(.body)
                            .foregroundColor(actionColor(for: action.style))

                        Spacer()
                    }
                    .padding(Spacing.lg)
                    .background(Color.white)
                }

                if action.id != actions.last?.id {
                    Divider()
                }
            }
        }
        .background(Color.white)
        .cornerRadius(24, corners: [.topLeft, .topRight])
    }

    private func actionColor(for style: ActionItem.Style) -> Color {
        switch style {
        case .default: return .brandBlack
        case .destructive: return .red
        case .cancel: return .brandGray
        }
    }
}

// MARK: - Progress Bar
// Linear progress indicator
struct GenZProgressBar: View {
    let progress: Double // 0.0 to 1.0
    let showPercentage: Bool

    init(progress: Double, showPercentage: Bool = true) {
        self.progress = min(max(progress, 0), 1)
        self.showPercentage = showPercentage
    }

    var body: some View {
        VStack(spacing: Spacing.xs) {
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.brandLightGray)

                    // Progress
                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [Color.brandHotPink, Color.brandPurple],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress)
                }
            }
            .frame(height: 8)

            if showPercentage {
                Text("\(Int(progress * 100))%")
                    .font(.caption)
                    .foregroundColor(.brandGray)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
    }
}
