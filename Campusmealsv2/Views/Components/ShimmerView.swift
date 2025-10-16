//
//  ShimmerView.swift
//  Campusmealsv2
//
//  Apple-style skeleton shimmer loading effect
//

import SwiftUI

// MARK: - Shimmer Effect View
struct ShimmerView: View {
    @State private var isAnimating = false

    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color(.systemGray6),
                        Color(.systemGray5),
                        Color(.systemGray6)
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
            .mask(
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.black.opacity(0.3),
                                Color.black,
                                Color.black.opacity(0.3)
                            ],
                            startPoint: isAnimating ? .leading : .init(x: -0.3, y: 0.5),
                            endPoint: isAnimating ? .trailing : .init(x: 0, y: 0.5)
                        )
                    )
            )
            .onAppear {
                withAnimation(.linear(duration: 1.5).repeatForever(autoreverses: false)) {
                    isAnimating = true
                }
            }
    }
}

// MARK: - Skeleton card for loading state
struct SkeletonResultCard: View {
    var body: some View {
        HStack(spacing: 14) {
            // Image skeleton
            ShimmerView()
                .frame(width: 60, height: 60)
                .cornerRadius(10)

            VStack(alignment: .leading, spacing: 8) {
                // Title skeleton
                ShimmerView()
                    .frame(width: 150, height: 16)
                    .cornerRadius(4)

                // Subtitle skeleton
                ShimmerView()
                    .frame(width: 120, height: 12)
                    .cornerRadius(4)

                // Badge skeleton
                ShimmerView()
                    .frame(width: 100, height: 14)
                    .cornerRadius(4)
            }

            Spacer()

            // Distance skeleton
            VStack(alignment: .trailing, spacing: 4) {
                ShimmerView()
                    .frame(width: 40, height: 20)
                    .cornerRadius(4)

                ShimmerView()
                    .frame(width: 50, height: 12)
                    .cornerRadius(4)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    VStack {
        SkeletonResultCard()
        SkeletonResultCard()
        SkeletonResultCard()
    }
    .padding()
}
