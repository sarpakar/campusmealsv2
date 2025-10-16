//
//  RecommendationCard.swift
//  Campusmealsv2
//
//  Uber Eats-style recommendation card with match score and routing
//

import SwiftUI
import MapKit

struct RecommendationCard: View {
    let vendor: Vendor
    let matchScore: Double
    let walkingTime: String
    let distance: String
    let matchReason: String
    let socialProof: [String] // Friend names who loved this

    @State private var imageLoaded = false
    @State private var showNavigationSheet = false
    @StateObject private var navigationService = NavigationService.shared

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        VStack(spacing: 0) {
            // Hero Image
            ZStack(alignment: .topTrailing) {
                AsyncImage(url: URL(string: vendor.finalImageURL)) { phase in
                    switch phase {
                    case .empty:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(height: 180)
                            .clipped()
                            .onAppear {
                                withAnimation(.easeIn(duration: 0.3)) {
                                    imageLoaded = true
                                }
                            }
                    case .failure:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                            .overlay(
                                Image(systemName: "photo")
                                    .font(.system(size: 40))
                                    .foregroundColor(.gray)
                            )
                    @unknown default:
                        Rectangle()
                            .fill(Color(.systemGray6))
                            .frame(height: 180)
                    }
                }
                .cornerRadius(12, corners: [.topLeft, .topRight])

                // Match Score Badge (Top Right)
                HStack(spacing: 4) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(Int(matchScore))% match")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(matchScoreColor(matchScore))
                        .shadow(color: Color.black.opacity(0.2), radius: 4, x: 0, y: 2)
                )
                .padding(12)
            }

            // Content Area
            VStack(alignment: .leading, spacing: 12) {
                // Restaurant Name + Rating
                HStack(spacing: 8) {
                    Text(vendor.name)
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.black)
                        .lineLimit(1)

                    Spacer()

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.orange)

                        Text(String(format: "%.1f", vendor.rating))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.black)
                    }
                }

                // Cuisine + Distance + Time
                HStack(spacing: 6) {
                    if let cuisine = vendor.cuisine {
                        Text(cuisine)
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }

                    Circle()
                        .fill(Color.gray)
                        .frame(width: 3, height: 3)

                    Text(distance)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)

                    Circle()
                        .fill(Color.gray)
                        .frame(width: 3, height: 3)

                    Text(vendor.priceRange)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                }

                // Match Reason
                Text(matchReason)
                    .font(.system(size: 13))
                    .foregroundColor(citiBikeBlue)
                    .lineLimit(2)

                // Social Proof (Friends)
                if !socialProof.isEmpty {
                    HStack(spacing: 6) {
                        // Friend avatars
                        HStack(spacing: -8) {
                            ForEach(socialProof.prefix(3), id: \.self) { friendName in
                                Circle()
                                    .fill(friendColor(for: friendName))
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Text(String(friendName.prefix(1)))
                                            .font(.system(size: 11, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.white, lineWidth: 2)
                                    )
                            }
                        }

                        Text("\(socialProof.count) friend\(socialProof.count == 1 ? "" : "s") loved this")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                    }
                    .padding(.vertical, 6)
                }

                // Tags Row
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        // Walking Time Tag
                        HStack(spacing: 4) {
                            Image(systemName: "figure.walk")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(citiBikeBlue)

                            Text(walkingTime)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(citiBikeBlue)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(citiBikeBlue.opacity(0.1))
                        )

                        // Delivery Fee Tag
                        if vendor.deliveryFee == 0 {
                            HStack(spacing: 4) {
                                Image(systemName: "dollarsign.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.green)

                                Text("Free delivery")
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.green)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(
                                Capsule()
                                    .fill(Color.green.opacity(0.1))
                            )
                        }

                        // Additional Tags
                        ForEach(vendor.tags.prefix(2), id: \.self) { tag in
                            Text(tag)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(
                                    Capsule()
                                        .fill(Color(.systemGray6))
                                )
                        }
                    }
                }

                // Get Directions Button
                Button(action: {
                    showNavigationSheet = true
                }) {
                    HStack {
                        Image(systemName: "location.fill")
                            .font(.system(size: 16, weight: .semibold))

                        Text("Get Directions")
                            .font(.system(size: 16, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.black)
                    )
                }
            }
            .padding(16)
        }
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
        .scaleEffect(imageLoaded ? 1.0 : 0.95)
        .opacity(imageLoaded ? 1.0 : 0.0)
        .sheet(isPresented: $showNavigationSheet) {
            NavigationOptionsSheet(
                vendor: vendor,
                onAppSelected: { app in
                    let destination = CLLocationCoordinate2D(latitude: vendor.latitude, longitude: vendor.longitude)
                    navigationService.openNavigation(to: destination, destinationName: vendor.name, using: app)
                    showNavigationSheet = false
                }
            )
            .presentationDetents([.height(280)])
            .presentationDragIndicator(.visible)
        }
    }

    // MARK: - Helpers

    private func matchScoreColor(_ score: Double) -> Color {
        if score >= 90 {
            return Color.green
        } else if score >= 75 {
            return citiBikeBlue
        } else {
            return Color.orange
        }
    }

    private func friendColor(for name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .pink, .orange, .green, .red, .indigo]
        let index = abs(name.hashValue) % colors.count
        return colors[index]
    }
}

// MARK: - Compact Recommendation Card (List View)
struct CompactRecommendationCard: View {
    let vendor: Vendor
    let matchScore: Double
    let walkingTime: String
    let distance: String

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        HStack(spacing: 14) {
            // Image
            AsyncImage(url: URL(string: vendor.imageURL)) { phase in
                switch phase {
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 70, height: 70)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                default:
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color(.systemGray6))
                        .frame(width: 70, height: 70)
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                // Name
                Text(vendor.name)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
                    .lineLimit(1)

                // Cuisine + Rating
                HStack(spacing: 6) {
                    if let cuisine = vendor.cuisine {
                        Text(cuisine)
                            .font(.system(size: 13))
                            .foregroundColor(.gray)
                    }

                    Circle()
                        .fill(Color.gray)
                        .frame(width: 3, height: 3)

                    HStack(spacing: 3) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.orange)

                        Text(String(format: "%.1f", vendor.rating))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.black)
                    }
                }

                // Match + Distance
                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Text("\(Int(matchScore))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.green)
                    )

                    HStack(spacing: 4) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 11))
                            .foregroundColor(citiBikeBlue)

                        Text(walkingTime)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(citiBikeBlue)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)
        }
        .padding(14)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 20) {
        RecommendationCard(
            vendor: Vendor(
                id: "1",
                name: "Sweetgreen",
                category: .restaurants,
                cuisine: "Salads & Bowls",
                imageURL: "https://images.unsplash.com/photo-1592396195096-b587692e68d8?ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D&auto=format&fit=crop&q=80&w=2070",
                rating: 4.7,
                reviewCount: 1234,
                deliveryTime: "15-25 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7295,
                longitude: -73.9965,
                address: "Union Square, NYC",
                isOpen: true,
                tags: ["Healthy", "Fast", "Popular"]
            ),
            matchScore: 92,
            walkingTime: "5 min",
            distance: "0.3 mi",
            matchReason: "High protein, fits your healthy preferences",
            socialProof: ["Sarah", "Mike", "Emma"]
        )

        CompactRecommendationCard(
            vendor: Vendor(
                id: "2",
                name: "Dig Inn",
                category: .restaurants,
                cuisine: "American",
                imageURL: "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=800",
                rating: 4.6,
                reviewCount: 892,
                deliveryTime: "20-30 min",
                deliveryFee: 1.99,
                priceRange: "$$",
                latitude: 40.7308,
                longitude: -73.9973,
                address: "NYU Area",
                isOpen: true,
                tags: ["Healthy", "NYU"]
            ),
            matchScore: 87,
            walkingTime: "8 min",
            distance: "0.5 mi"
        )
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}

// MARK: - Navigation Options Sheet

struct NavigationOptionsSheet: View {
    let vendor: Vendor
    let onAppSelected: (NavigationService.MapApp) -> Void

    @StateObject private var navigationService = NavigationService.shared
    @Environment(\.dismiss) var dismiss

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 8) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 40, height: 5)
                    .padding(.top, 8)

                Text("Navigate to \(vendor.name)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.black)
                    .padding(.top, 12)

                Text("\(vendor.address)")
                    .font(.system(size: 14))
                    .foregroundColor(.gray)
                    .lineLimit(1)
                    .padding(.horizontal, 20)
            }
            .padding(.bottom, 24)

            // Map App Options
            VStack(spacing: 12) {
                ForEach(navigationService.availableMapApps()) { app in
                    Button(action: {
                        onAppSelected(app)
                    }) {
                        HStack(spacing: 16) {
                            // App Icon
                            ZStack {
                                Circle()
                                    .fill(Color(red: app.color.red/255, green: app.color.green/255, blue: app.color.blue/255))
                                    .frame(width: 48, height: 48)

                                Image(systemName: app.icon)
                                    .font(.system(size: 20, weight: .semibold))
                                    .foregroundColor(.white)
                            }

                            // App Name
                            VStack(alignment: .leading, spacing: 4) {
                                Text(app.rawValue)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.black)

                                Text("Walking directions")
                                    .font(.system(size: 13))
                                    .foregroundColor(.gray)
                            }

                            Spacer()

                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)
                        }
                        .padding(.horizontal, 20)
                        .padding(.vertical, 12)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)

            Spacer()
        }
        .background(Color.white)
    }
}
