//
//  GenZCards.swift
//  Campusmealsv2
//
//  Gen Z-optimized card components
//  Follows Corner iOS design patterns with Apple polish
//

import SwiftUI

// MARK: - Restaurant Card
// Main restaurant discovery card with photo, name, metadata
// Used in: Feed, Search Results, Collections
struct RestaurantCard: View {
    let imageURL: String?
    let name: String
    let cuisine: String?
    let distance: String?
    let rating: Double?
    let priceLevel: String?
    let isOpen: Bool
    let action: () -> Void

    @State private var imageLoaded = false

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            VStack(alignment: .leading, spacing: Spacing.sm) {
                // Hero Image
                restaurantImage

                // Content
                VStack(alignment: .leading, spacing: Spacing.xs) {
                    // Restaurant Name
                    Text(name)
                        .font(.heading2)
                        .foregroundColor(.brandBlack)
                        .lineLimit(1)

                    // Metadata Row
                    HStack(spacing: Spacing.xs) {
                        if let cuisine = cuisine {
                            Text(cuisine)
                                .font(.caption)
                                .foregroundColor(.brandGray)
                        }

                        if let cuisine = cuisine, distance != nil {
                            Text("•")
                                .foregroundColor(.brandGray)
                        }

                        if let distance = distance {
                            Text(distance)
                                .font(.caption)
                                .foregroundColor(.brandGray)
                        }

                        Spacer()

                        // Open/Closed Badge
                        openStatusBadge
                    }

                    // Rating & Price
                    if rating != nil || priceLevel != nil {
                        HStack(spacing: Spacing.sm) {
                            if let rating = rating {
                                HStack(spacing: 4) {
                                    Image(systemName: "star.fill")
                                        .font(.caption)
                                        .foregroundColor(.brandGolden)
                                    Text(String(format: "%.1f", rating))
                                        .font(.labelSmall)
                                        .foregroundColor(.brandBlack)
                                }
                            }

                            if let priceLevel = priceLevel {
                                Text(priceLevel)
                                    .font(.labelSmall)
                                    .foregroundColor(.brandGray)
                            }
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .background(Color.white)
            .cornerRadius(Spacing.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        }
        .buttonStyle(CardButtonStyle())
    }

    private var restaurantImage: some View {
        Group {
            if let imageURL = imageURL, !imageURL.isEmpty {
                AsyncImage(url: URL(string: imageURL)) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 200)
                            .clipped()
                            .onAppear {
                                withAnimation(.springSmooth) {
                                    imageLoaded = true
                                }
                            }
                    case .failure(_):
                        placeholderImage
                    case .empty:
                        placeholderImage
                            .shimmer()
                    @unknown default:
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        }
        .frame(height: 200)
        .background(Color.brandLightGray)
        .cornerRadius(Spacing.cardCornerRadius, corners: [.topLeft, .topRight])
    }

    private var placeholderImage: some View {
        ZStack {
            Color.brandLightGray
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.brandGray.opacity(0.3))
        }
    }

    private var openStatusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(isOpen ? Color.green : Color.red)
                .frame(width: 6, height: 6)
            Text(isOpen ? "Open" : "Closed")
                .font(.caption)
                .foregroundColor(isOpen ? .green : .red)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(isOpen ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
        )
    }
}

// MARK: - Compact Restaurant Card
// Smaller card for lists/grids
struct CompactRestaurantCard: View {
    let imageURL: String?
    let name: String
    let cuisine: String?
    let distance: String?
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            HStack(spacing: Spacing.md) {
                // Thumbnail
                Group {
                    if let imageURL = imageURL, !imageURL.isEmpty {
                        AsyncImage(url: URL(string: imageURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.brandLightGray
                                .shimmer()
                        }
                    } else {
                        ZStack {
                            Color.brandLightGray
                            Image(systemName: "fork.knife")
                                .foregroundColor(.brandGray.opacity(0.3))
                        }
                    }
                }
                .frame(width: 60, height: 60)
                .cornerRadius(12)

                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(name)
                        .font(.body)
                        .foregroundColor(.brandBlack)
                        .lineLimit(1)

                    HStack(spacing: 8) {
                        if let cuisine = cuisine {
                            Text(cuisine)
                                .font(.caption)
                                .foregroundColor(.brandGray)
                        }

                        if let distance = distance {
                            Text("• \(distance)")
                                .font(.caption)
                                .foregroundColor(.brandGray)
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.caption)
                    .foregroundColor(.brandGray)
            }
            .padding(Spacing.md)
            .background(Color.white)
            .cornerRadius(Spacing.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.05), radius: 4)
        }
        .buttonStyle(CardButtonStyle())
    }
}

// MARK: - Video Card
// TikTok-style video card with thumbnail, creator, likes
struct VideoCard: View {
    let thumbnailURL: String?
    let videoURL: String
    let creator: String
    let platform: String // "tiktok", "instagram", "youtube"
    let likes: Int?
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.medium()
            action()
        }) {
            ZStack(alignment: .bottomLeading) {
                // Video Thumbnail
                Group {
                    if let thumbnailURL = thumbnailURL, !thumbnailURL.isEmpty {
                        AsyncImage(url: URL(string: thumbnailURL)) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Color.black
                                .shimmer()
                        }
                    } else {
                        Color.black
                    }
                }
                .frame(height: 280)
                .clipped()

                // Gradient Overlay
                LinearGradient(
                    colors: [.clear, .black.opacity(0.7)],
                    startPoint: .center,
                    endPoint: .bottom
                )

                // Play Button
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.3))
                        .frame(width: 60, height: 60)

                    Image(systemName: "play.fill")
                        .font(.title2)
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                // Bottom Info
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        // Platform Icon
                        platformIcon

                        Text(creator)
                            .font(.labelSmall)
                            .foregroundColor(.white)

                        Spacer()

                        // Likes
                        if let likes = likes {
                            HStack(spacing: 4) {
                                Image(systemName: "heart.fill")
                                    .font(.caption)
                                Text(formatNumber(likes))
                                    .font(.caption)
                            }
                            .foregroundColor(.white)
                        }
                    }
                }
                .padding(Spacing.md)
            }
            .cornerRadius(Spacing.cardCornerRadius)
            .shadow(color: Color.black.opacity(0.15), radius: 8)
        }
        .buttonStyle(CardButtonStyle())
    }

    private var platformIcon: some View {
        Group {
            switch platform.lowercased() {
            case "tiktok":
                Image(systemName: "music.note")
                    .foregroundColor(.white)
            case "instagram":
                Image(systemName: "camera.fill")
                    .foregroundColor(.white)
            case "youtube":
                Image(systemName: "play.rectangle.fill")
                    .foregroundColor(.white)
            default:
                Image(systemName: "video.fill")
                    .foregroundColor(.white)
            }
        }
        .font(.caption)
    }

    private func formatNumber(_ number: Int) -> String {
        if number >= 1_000_000 {
            return String(format: "%.1fM", Double(number) / 1_000_000)
        } else if number >= 1_000 {
            return String(format: "%.1fK", Double(number) / 1_000)
        } else {
            return "\(number)"
        }
    }
}

// MARK: - Category Card
// Pills/badges for filtering and navigation
struct CategoryCard: View {
    let emoji: String
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.selection()
            action()
        }) {
            VStack(spacing: Spacing.xs) {
                // Emoji Circle
                ZStack {
                    Circle()
                        .fill(isSelected ? Color.brandBlack : Color.white)
                        .frame(width: 64, height: 64)
                        .shadow(color: Color.black.opacity(isSelected ? 0.15 : 0.08), radius: 8)

                    Text(emoji)
                        .font(.system(size: 32))
                }

                // Title
                Text(title)
                    .font(.caption)
                    .foregroundColor(isSelected ? .brandBlack : .brandGray)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(width: 80)
        }
        .animation(.springBouncy, value: isSelected)
    }
}

// MARK: - Photo Grid Card
// Instagram-style photo grid (2x2 or 3x3)
struct PhotoGridCard: View {
    let photos: [String] // URLs
    let maxPhotos: Int = 4
    let action: () -> Void

    var body: some View {
        Button(action: {
            HapticFeedback.light()
            action()
        }) {
            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 4),
                GridItem(.flexible(), spacing: 4)
            ], spacing: 4) {
                ForEach(photos.prefix(maxPhotos).indices, id: \.self) { index in
                    photoCell(url: photos[index], index: index)
                }
            }
            .cornerRadius(Spacing.cardCornerRadius)
        }
    }

    private func photoCell(url: String, index: Int) -> some View {
        ZStack {
            AsyncImage(url: URL(string: url)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Color.brandLightGray
                    .shimmer()
            }
            .frame(height: 120)
            .clipped()

            // "+N more" overlay on last photo
            if index == maxPhotos - 1 && photos.count > maxPhotos {
                ZStack {
                    Color.black.opacity(0.6)
                    Text("+\(photos.count - maxPhotos)")
                        .font(.heading2)
                        .foregroundColor(.white)
                }
            }
        }
    }
}

// MARK: - Stat Card
// Quick stats display (followers, likes, views)
struct StatCard: View {
    let value: String
    let label: String
    let icon: String?

    var body: some View {
        VStack(spacing: Spacing.xs) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(.brandHotPink)
            }

            Text(value)
                .font(.heading1)
                .foregroundColor(.brandBlack)

            Text(label)
                .font(.caption)
                .foregroundColor(.brandGray)
        }
        .frame(maxWidth: .infinity)
        .padding(Spacing.lg)
        .background(Color.white)
        .cornerRadius(Spacing.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
    }
}

// MARK: - Loading Card Skeleton
// Shimmer loading state for cards
struct CardSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Spacing.sm) {
            // Image skeleton
            Rectangle()
                .fill(Color.brandLightGray)
                .frame(height: 200)
                .cornerRadius(Spacing.cardCornerRadius, corners: [.topLeft, .topRight])

            VStack(alignment: .leading, spacing: Spacing.xs) {
                // Title skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandLightGray)
                    .frame(width: 180, height: 20)

                // Subtitle skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.brandLightGray)
                    .frame(width: 120, height: 14)
            }
            .padding(Spacing.md)
        }
        .background(Color.white)
        .cornerRadius(Spacing.cardCornerRadius)
        .shadow(color: Color.black.opacity(0.05), radius: 4)
        .shimmer()
    }
}

// MARK: - Helper: Card Button Style
// Subtle scale effect on press
struct CardButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.springBouncy, value: configuration.isPressed)
    }
}

// MARK: - Helper: Rounded Corners Extension
extension View {
    func cornerRadius(_ radius: CGFloat, corners: UIRectCorner) -> some View {
        clipShape(RoundedCorner(radius: radius, corners: corners))
    }
}

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}
