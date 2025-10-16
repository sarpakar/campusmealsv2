//
//  GenZInputs.swift
//  Campusmealsv2
//
//  Gen Z-optimized input components
//  Black pill search bar (Spotify/Apple Music style)
//  Follows Corner iOS design patterns
//

import SwiftUI

// MARK: - Search Bar
// Black pill-shaped search bar (Corner iOS / Spotify style)
// Used in: Main feed, Map view, Discovery
struct GenZSearchBar: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void
    let onCancel: (() -> Void)?

    @FocusState private var isFocused: Bool
    @State private var showCancelButton = false

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Search Input
            HStack(spacing: Spacing.sm) {
                // Search Icon
                Image(systemName: "magnifyingglass")
                    .font(.body)
                    .foregroundColor(.white.opacity(0.7))

                // Text Field
                TextField(placeholder, text: $text)
                    .font(.body)
                    .foregroundColor(.white)
                    .accentColor(.brandHotPink)
                    .focused($isFocused)
                    .submitLabel(.search)
                    .onSubmit {
                        HapticFeedback.light()
                        onSubmit()
                    }
                    .onChange(of: isFocused) { focused in
                        withAnimation(.springSmooth) {
                            showCancelButton = focused
                        }
                    }

                // Clear Button
                if !text.isEmpty {
                    Button(action: {
                        HapticFeedback.selection()
                        text = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.body)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .padding(.horizontal, Spacing.lg)
            .padding(.vertical, Spacing.md)
            .background(
                Capsule()
                    .fill(Color.brandBlack)
            )

            // Cancel Button (appears when focused)
            if showCancelButton {
                Button(action: {
                    HapticFeedback.light()
                    text = ""
                    isFocused = false
                    onCancel?()
                }) {
                    Text("Cancel")
                        .font(.body)
                        .foregroundColor(.brandBlack)
                }
                .transition(.move(edge: .trailing).combined(with: .opacity))
            }
        }
        .animation(.springSmooth, value: showCancelButton)
        .animation(.springSmooth, value: text.isEmpty)
    }
}

// MARK: - Light Search Bar
// White background variant for dark backgrounds
struct GenZSearchBarLight: View {
    @Binding var text: String
    let placeholder: String
    let onSubmit: () -> Void

    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(spacing: Spacing.sm) {
            // Search Icon
            Image(systemName: "magnifyingglass")
                .font(.body)
                .foregroundColor(.brandGray)

            // Text Field
            TextField(placeholder, text: $text)
                .font(.body)
                .foregroundColor(.brandBlack)
                .accentColor(.brandHotPink)
                .focused($isFocused)
                .submitLabel(.search)
                .onSubmit {
                    HapticFeedback.light()
                    onSubmit()
                }

            // Clear Button
            if !text.isEmpty {
                Button(action: {
                    HapticFeedback.selection()
                    text = ""
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.body)
                        .foregroundColor(.brandGray)
                }
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, Spacing.lg)
        .padding(.vertical, Spacing.md)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8)
        )
        .animation(.springSmooth, value: text.isEmpty)
    }
}

// MARK: - Text Field
// Standard text input field
struct GenZTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String?
    let keyboardType: UIKeyboardType
    let isSecure: Bool

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String,
        icon: String? = nil,
        keyboardType: UIKeyboardType = .default,
        isSecure: Bool = false
    ) {
        self._text = text
        self.placeholder = placeholder
        self.icon = icon
        self.keyboardType = keyboardType
        self.isSecure = isSecure
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            // Icon
            if let icon = icon {
                Image(systemName: icon)
                    .font(.body)
                    .foregroundColor(isFocused ? .brandHotPink : .brandGray)
                    .frame(width: 20)
            }

            // Input
            Group {
                if isSecure {
                    SecureField(placeholder, text: $text)
                } else {
                    TextField(placeholder, text: $text)
                }
            }
            .font(.body)
            .foregroundColor(.brandBlack)
            .accentColor(.brandHotPink)
            .keyboardType(keyboardType)
            .focused($isFocused)
        }
        .padding(Spacing.lg)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                        .stroke(
                            isFocused ? Color.brandHotPink : Color.brandLightGray,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .animation(.springSmooth, value: isFocused)
    }
}

// MARK: - Text Area
// Multi-line text input
struct GenZTextArea: View {
    @Binding var text: String
    let placeholder: String
    let minHeight: CGFloat

    @FocusState private var isFocused: Bool

    init(
        text: Binding<String>,
        placeholder: String,
        minHeight: CGFloat = 120
    ) {
        self._text = text
        self.placeholder = placeholder
        self.minHeight = minHeight
    }

    var body: some View {
        ZStack(alignment: .topLeading) {
            // Placeholder
            if text.isEmpty {
                Text(placeholder)
                    .font(.body)
                    .foregroundColor(.brandGray)
                    .padding(.horizontal, Spacing.lg)
                    .padding(.vertical, Spacing.lg + 8) // +8 to match TextEditor padding
            }

            // Text Editor
            TextEditor(text: $text)
                .font(.body)
                .foregroundColor(.brandBlack)
                .focused($isFocused)
                .scrollContentBackground(.hidden)
                .padding(Spacing.md)
        }
        .frame(minHeight: minHeight)
        .background(
            RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                .fill(Color.white)
                .overlay(
                    RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                        .stroke(
                            isFocused ? Color.brandHotPink : Color.brandLightGray,
                            lineWidth: isFocused ? 2 : 1
                        )
                )
        )
        .animation(.springSmooth, value: isFocused)
    }
}

// MARK: - Tag Input
// Add/remove tags (hashtags, categories)
struct GenZTagInput: View {
    @Binding var tags: [String]
    @State private var inputText = ""
    let placeholder: String
    let maxTags: Int

    init(
        tags: Binding<[String]>,
        placeholder: String = "Add tag...",
        maxTags: Int = 10
    ) {
        self._tags = tags
        self.placeholder = placeholder
        self.maxTags = maxTags
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.md) {
            // Existing Tags
            if !tags.isEmpty {
                // Use standard HStack wrapped in ScrollView for tag display
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: Spacing.sm) {
                        ForEach(tags, id: \.self) { tag in
                            TagChip(
                                text: tag,
                                onRemove: {
                                    removeTag(tag)
                                }
                            )
                        }
                    }
                }
            }

            // Input Field
            if tags.count < maxTags {
                HStack {
                    TextField(placeholder, text: $inputText)
                        .font(.body)
                        .foregroundColor(.brandBlack)
                        .submitLabel(.done)
                        .onSubmit {
                            addTag()
                        }

                    if !inputText.isEmpty {
                        Button(action: addTag) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.brandHotPink)
                        }
                    }
                }
                .padding(Spacing.md)
                .background(
                    RoundedRectangle(cornerRadius: Spacing.cardCornerRadius)
                        .fill(Color.brandLightGray.opacity(0.3))
                )
            }
        }
    }

    private func addTag() {
        let trimmed = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              !tags.contains(trimmed),
              tags.count < maxTags else {
            return
        }

        HapticFeedback.success()
        withAnimation(.springBouncy) {
            tags.append(trimmed)
            inputText = ""
        }
    }

    private func removeTag(_ tag: String) {
        HapticFeedback.selection()
        withAnimation(.springBouncy) {
            tags.removeAll { $0 == tag }
        }
    }
}

// MARK: - Tag Chip
// Individual tag with remove button
struct TagChip: View {
    let text: String
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: Spacing.xs) {
            Text(text)
                .font(.labelSmall)
                .foregroundColor(.white)

            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.xs)
        .background(
            Capsule()
                .fill(Color.brandBlack)
        )
    }
}

// MARK: - Slider Input
// Custom slider with Gen Z styling
struct GenZSlider: View {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let step: Double
    let label: String
    let unit: String

    init(
        value: Binding<Double>,
        in range: ClosedRange<Double>,
        step: Double = 1,
        label: String,
        unit: String = ""
    ) {
        self._value = value
        self.range = range
        self.step = step
        self.label = label
        self.unit = unit
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Label & Value
            HStack {
                Text(label)
                    .font(.labelSmall)
                    .foregroundColor(.brandGray)

                Spacer()

                Text("\(Int(value))\(unit)")
                    .font(.labelSmall)
                    .foregroundColor(.brandBlack)
                    .fontWeight(.semibold)
            }

            // Slider
            Slider(
                value: $value,
                in: range,
                step: step
            )
            .accentColor(.brandHotPink)
            .onChange(of: value) { _ in
                HapticFeedback.selection()
            }
        }
    }
}

// MARK: - Toggle Switch
// Gen Z styled toggle
struct GenZToggle: View {
    @Binding var isOn: Bool
    let label: String
    let description: String?

    init(
        isOn: Binding<Bool>,
        label: String,
        description: String? = nil
    ) {
        self._isOn = isOn
        self.label = label
        self.description = description
    }

    var body: some View {
        HStack(spacing: Spacing.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(label)
                    .font(.body)
                    .foregroundColor(.brandBlack)

                if let description = description {
                    Text(description)
                        .font(.caption)
                        .foregroundColor(.brandGray)
                }
            }

            Spacer()

            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(.brandHotPink)
                .onChange(of: isOn) { _ in
                    HapticFeedback.selection()
                }
        }
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(Spacing.cardCornerRadius)
    }
}

// MARK: - Picker / Selector
// Segmented control style picker
struct GenZPicker: View {
    @Binding var selection: String
    let options: [String]

    var body: some View {
        HStack(spacing: 0) {
            ForEach(options, id: \.self) { option in
                Button(action: {
                    HapticFeedback.selection()
                    withAnimation(.springBouncy) {
                        selection = option
                    }
                }) {
                    Text(option)
                        .font(.labelSmall)
                        .foregroundColor(selection == option ? .white : .brandBlack)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, Spacing.md)
                        .background(
                            selection == option
                                ? Color.brandBlack
                                : Color.clear
                        )
                }
            }
        }
        .background(Color.brandLightGray.opacity(0.3))
        .cornerRadius(Spacing.buttonCornerRadius)
    }
}

// Note: FlowLayout removed - using ScrollView + HStack for tag display instead
// This avoids Layout protocol complexity while maintaining good UX
