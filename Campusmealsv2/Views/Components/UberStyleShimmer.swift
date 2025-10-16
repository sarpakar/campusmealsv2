//
//  UberStyleShimmer.swift
//  Campusmealsv2
//
//  100% Uber Eats skeleton shimmer loading effect
//  Wave animation with gradient overlay
//

import SwiftUI

// MARK: - Uber-Style Shimmer Effect
struct UberShimmer: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geometry in
                    LinearGradient(
                        gradient: Gradient(stops: [
                            .init(color: Color.white.opacity(0.0), location: 0.0),
                            .init(color: Color.white.opacity(0.3), location: 0.4),
                            .init(color: Color.white.opacity(0.6), location: 0.5),
                            .init(color: Color.white.opacity(0.3), location: 0.6),
                            .init(color: Color.white.opacity(0.0), location: 1.0)
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .rotationEffect(.degrees(0))
                    .offset(x: phase)
                    .frame(width: geometry.size.width * 2)
                }
                .clipped()
            )
            .onAppear {
                withAnimation(
                    Animation.linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                ) {
                    phase = UIScreen.main.bounds.width * 2
                }
            }
    }
}

extension View {
    func uberShimmer() -> some View {
        self.modifier(UberShimmer())
    }
}

// MARK: - Uber-Style Recommendation Card Skeleton
struct UberRecommendationSkeleton: View {
    var body: some View {
        VStack(spacing: 0) {
            // Hero image skeleton
            Rectangle()
                .fill(Color(.systemGray6))
                .frame(height: 180)
                .cornerRadius(12, corners: [.topLeft, .topRight])
                .uberShimmer()

            // Content area
            VStack(alignment: .leading, spacing: 12) {
                // Restaurant name
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                        .frame(width: 140, height: 20)
                        .uberShimmer()

                    Spacer()

                    // Rating skeleton
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 20)
                        .uberShimmer()
                }

                // Cuisine + Distance
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 80, height: 14)
                        .uberShimmer()

                    Circle()
                        .fill(Color(.systemGray6))
                        .frame(width: 4, height: 4)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 14)
                        .uberShimmer()
                }

                // Match percentage bar
                HStack(spacing: 8) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemGray6))
                        .frame(width: 100, height: 16)
                        .uberShimmer()

                    Spacer()
                }

                // Tags row
                HStack(spacing: 8) {
                    ForEach(0..<3, id: \.self) { _ in
                        Capsule()
                            .fill(Color(.systemGray6))
                            .frame(width: CGFloat.random(in: 60...90), height: 26)
                            .uberShimmer()
                    }
                    Spacer()
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

// MARK: - Uber-Style List Item Skeleton (Compact)
struct UberListItemSkeleton: View {
    var body: some View {
        HStack(spacing: 14) {
            // Image skeleton
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(width: 70, height: 70)
                .uberShimmer()

            VStack(alignment: .leading, spacing: 8) {
                // Name
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 140, height: 16)
                    .uberShimmer()

                // Details
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(.systemGray6))
                    .frame(width: 180, height: 12)
                    .uberShimmer()

                // Badges
                HStack(spacing: 6) {
                    Capsule()
                        .fill(Color(.systemGray6))
                        .frame(width: 60, height: 20)
                        .uberShimmer()

                    Capsule()
                        .fill(Color(.systemGray6))
                        .frame(width: 50, height: 20)
                        .uberShimmer()
                }
            }

            Spacer()

            // Arrow
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 24, height: 24)
                .uberShimmer()
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

// MARK: - Uber-Style Search Bar Skeleton
struct UberSearchBarSkeleton: View {
    var body: some View {
        HStack(spacing: 12) {
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
                .frame(width: 24, height: 24)
                .uberShimmer()

            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
                .frame(height: 20)
                .uberShimmer()
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 2)
        )
    }
}

// MARK: - Uber-Style Category Pills Skeleton
struct UberCategoryPillsSkeleton: View {
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(0..<5, id: \.self) { _ in
                    Capsule()
                        .fill(Color(.systemGray6))
                        .frame(width: CGFloat.random(in: 80...120), height: 36)
                        .uberShimmer()
                }
            }
            .padding(.horizontal, 18)
        }
    }
}

// MARK: - Uber-Style Hero Banner Skeleton
struct UberHeroBannerSkeleton: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Title
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray6))
                .frame(width: 200, height: 28)
                .uberShimmer()

            // Subtitle
            RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 280, height: 16)
                .uberShimmer()

            // Image
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
                .frame(height: 180)
                .uberShimmer()

            // Action button
            RoundedRectangle(cornerRadius: 10)
                .fill(Color(.systemGray6))
                .frame(height: 50)
                .uberShimmer()
        }
        .padding(18)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.08), radius: 12, x: 0, y: 4)
        )
    }
}

// MARK: - Preview
#Preview {
    VStack(spacing: 20) {
        UberSearchBarSkeleton()

        UberCategoryPillsSkeleton()

        UberRecommendationSkeleton()

        UberListItemSkeleton()

        UberHeroBannerSkeleton()
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
