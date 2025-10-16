//
//  VendorCard.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//  Refactored with Gen Z Design System
//

import SwiftUI

struct VendorCard: View {
    let vendor: Vendor
    let userLatitude: Double
    let userLongitude: Double

    @State private var imageLoaded = false

    var body: some View {
        ZStack {
            // Background with hero image and gradient
            vendorImageWithOverlay
                .clipShape(RoundedRectangle(cornerRadius: 24))

            // Content overlay with vertical spacing
            VStack(alignment: .leading, spacing: 0) {
                // Top section with trending badge
                HStack {
                    trendingBadge
                    Spacer()
                }
                .padding(20)

                Spacer()

                // Bottom content section with dark gradient background
                VStack(alignment: .leading, spacing: 12) {
                    // Vendor Name - Large, bold Korean/aesthetic style
                    Text(vendor.name)
                        .font(.custom("HelveticaNeue-Bold", size: 28))
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)

                    // Tags with aesthetic pill style
                    if !vendor.tags.isEmpty || vendor.cuisine != nil {
                        HStack(spacing: 8) {
                            // Cuisine first
                            if let cuisine = vendor.cuisine {
                                aestheticPill(text: cuisine.lowercased())
                            }

                            // Then tags
                            ForEach(vendor.tags.prefix(2), id: \.self) { tag in
                                aestheticPill(text: tag.lowercased())
                            }
                        }
                    }

                    // Instagram-style timestamp
                    HStack(spacing: 6) {
                        Image(systemName: "photo.circle.fill")
                            .font(.custom("HelveticaNeue-Medium", size: 14))
                            .foregroundColor(.white.opacity(0.9))

                        Text("saved from instagram")
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(.white.opacity(0.9))

                        Text("•")
                            .foregroundColor(.white.opacity(0.6))

                        Text(vendor.deliveryTime)
                            .font(.custom("HelveticaNeue", size: 13))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    .padding(.top, 4)

                    // Social proof row (avatars + actions)
                    HStack(spacing: 16) {
                        // Overlapping friend avatars
                        friendAvatarsStack

                        Spacer()

                        // Action buttons
                        HStack(spacing: 12) {
                            actionButton(icon: "bookmark.fill", text: "want to try")
                            actionButton(icon: "checkmark.circle.fill", text: "visited")
                        }
                    }
                    .padding(.top, 8)
                }
                .padding(20)
                .background(
                    // Extra dark gradient at bottom for readability
                    LinearGradient(
                        colors: [Color.clear, Color.black.opacity(0.7)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
        }
        .frame(height: 500)
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: Color.black.opacity(0.25), radius: 20, x: 0, y: 10)
        .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    // MARK: - Vendor Image with Overlay (Pinterest/Mood Board aesthetic)
    private var vendorImageWithOverlay: some View {
        ZStack {
            // Main food image
            Group {
                if !vendor.finalImageURL.isEmpty {
                    AsyncImage(url: URL(string: vendor.finalImageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(height: 500)
                                .clipped()
                                .scaleEffect(imageLoaded ? 1.0 : 1.1)
                                .onAppear {
                                    withAnimation(.easeOut(duration: 0.6)) {
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

            // Multi-layer gradient for dramatic effect
            ZStack {
                // Top subtle fade
                LinearGradient(
                    colors: [Color.black.opacity(0.3), Color.clear],
                    startPoint: .top,
                    endPoint: .center
                )

                // Bottom strong fade for text readability
                LinearGradient(
                    gradient: Gradient(stops: [
                        .init(color: Color.clear, location: 0.4),
                        .init(color: Color.black.opacity(0.4), location: 0.65),
                        .init(color: Color.black.opacity(0.8), location: 0.9),
                        .init(color: Color.black.opacity(0.9), location: 1.0)
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )

                // Vignette effect for mood
                RadialGradient(
                    colors: [Color.clear, Color.black.opacity(0.15)],
                    center: .center,
                    startRadius: 100,
                    endRadius: 350
                )
            }
        }
        .frame(height: 500)
    }

    // MARK: - Trending Badge (Pinterest style)
    private var trendingBadge: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(Color(red: 1.0, green: 0.27, blue: 0.27))
                .frame(width: 10, height: 10)
                .shadow(color: Color.red.opacity(0.6), radius: 4)

            Text("trending")
                .font(.custom("HelveticaNeue-Medium", size: 14))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 9)
        .background(
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.75))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
                    .blur(radius: 0.5)

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.15), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.4), radius: 8, x: 0, y: 4)
    }

    // MARK: - Aesthetic Pill (like coolmeal card)
    private func aestheticPill(text: String) -> some View {
        Text(text)
            .font(.custom("HelveticaNeue-Medium", size: 13))
            .foregroundColor(.white.opacity(0.95))
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.4))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                    )
                    .blur(radius: 0.3)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
    }

    // MARK: - Friend Avatars Stack (overlapping circles)
    private var friendAvatarsStack: some View {
        HStack(spacing: 0) {
            ForEach(0..<3, id: \.self) { index in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [friendColors[index], friendColors[index].opacity(0.7)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .strokeBorder(Color.white, lineWidth: 2.5)
                    )
                    .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                    .offset(x: CGFloat(index) * -10)
                    .zIndex(Double(3 - index))
            }

            Text("31")
                .font(.custom("HelveticaNeue-Bold", size: 14))
                .foregroundColor(.white)
                .padding(.leading, -6)
                .shadow(color: Color.black.opacity(0.3), radius: 2)
        }
    }

    // MARK: - Action Button (coolmeal style)
    private func actionButton(icon: String, text: String) -> some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.custom("HelveticaNeue-Medium", size: 14))
            Text(text)
                .font(.custom("HelveticaNeue", size: 13))
        }
        .foregroundColor(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(
            ZStack {
                Capsule()
                    .fill(Color.black.opacity(0.6))
                    .overlay(
                        Capsule()
                            .strokeBorder(Color.white.opacity(0.25), lineWidth: 0.5)
                    )

                Capsule()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.1), Color.clear],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
            }
        )
        .shadow(color: Color.black.opacity(0.25), radius: 4, x: 0, y: 2)
    }

    private var friendColors: [Color] {
        [.blue, .purple, .pink]
    }

    private var placeholderImage: some View {
        ZStack {
            Color.brandLightGray
            Image(systemName: "fork.knife")
                .font(.system(size: 40))
                .foregroundColor(.brandGray.opacity(0.3))
        }
    }
}

