//
//  VendorDetailCard.swift
//  Campusmealsv2
//
//  iOS 26 MapKit Place Card Style - Discovery View
//

import SwiftUI
import MapKit
import FirebaseFirestore

struct VendorDetailCard: View {
    let vendor: Vendor
    let menuItems: [MenuItem]
    let onClose: () -> Void
    let onViewFullMenu: () -> Void

    @State private var offset: CGFloat = 0
    @State private var showNavigationSheet = false
    @State private var loadedVideos: [SocialVideo] = []
    @State private var isLoadingVideos = true
    @StateObject private var navigationService = NavigationService.shared

    var body: some View {
        VStack(spacing: 0) {
            // Drag Handle
            Capsule()
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Main Content
                        VStack(spacing: 24) {
                            // Place Name & Info
                            placeHeaderSection

                            // Quick Actions (iOS 26 Style)
                            quickActionsGrid

                            // Social Videos Section (Always show)
                            socialVideosSection

                            // Primary Actions
                            actionButtonsSection
                        }
                        .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 40)
                }
        }
        .background(.ultraThinMaterial)
        .offset(y: offset)
        .gesture(
            DragGesture()
                .onChanged { value in
                    if value.translation.height > 0 {
                        offset = value.translation.height
                    }
                }
                .onEnded { value in
                    if value.translation.height > 100 {
                        onClose()
                    } else {
                        withAnimation(.spring(response: 0.3)) {
                            offset = 0
                        }
                    }
                }
        )
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
        .task {
            await fetchVideosFromFirestore()
        }
    }

    // MARK: - Place Header (iOS 26 Style)
    private var placeHeaderSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Place Name
            Text(vendor.name)
                .font(.system(size: 26, weight: .bold))
                .foregroundStyle(.primary)

            // Metadata Row
            HStack(spacing: 6) {
                // Rating
                HStack(spacing: 3) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.yellow)
                    Text(String(format: "%.1f", vendor.rating))
                        .font(.system(size: 15, weight: .medium))
                }

                Text("•")
                    .foregroundStyle(.secondary)

                // Cuisine
                if let cuisine = vendor.cuisine {
                    Text(cuisine)
                        .font(.system(size: 15))
                        .foregroundStyle(.secondary)
                }

                Text("•")
                    .foregroundStyle(.secondary)

                // Price
                Text(vendor.priceRange)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.secondary)

                Spacer()

                // Status Badge
                statusBadge
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Status Badge
    private var statusBadge: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(vendor.isOpen ? Color.green : Color.red)
                .frame(width: 8, height: 8)

            Text(vendor.isOpen ? "Open" : "Closed")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(vendor.isOpen ? .green : .red)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(.thinMaterial, in: Capsule())
    }

    // MARK: - Quick Actions Grid (iOS 26 Style)
    private var quickActionsGrid: some View {
        HStack(spacing: 12) {
            // Directions
            QuickActionButton(
                icon: "arrow.triangle.turn.up.right.diamond.fill",
                label: "Directions",
                isPrimary: true
            ) {
                showNavigationSheet = true
            }

            // Share
            QuickActionButton(
                icon: "square.and.arrow.up",
                label: "Share"
            ) {
                // Share action
            }

            // Save
            QuickActionButton(
                icon: "heart",
                label: "Save"
            ) {
                // Save action
            }

            // More
            QuickActionButton(
                icon: "ellipsis",
                label: "More"
            ) {
                // More options
            }
        }
    }

    // MARK: - Fetch Videos from Firestore
    private func fetchVideosFromFirestore() async {
        let db = Firestore.firestore()

        do {
            // Get all restaurant_videos documents
            let snapshot = try await db.collection("restaurant_videos")
                .limit(to: 10)
                .getDocuments()

            guard !snapshot.documents.isEmpty else {
                await MainActor.run {
                    self.loadedVideos = []
                    self.isLoadingVideos = false
                }
                return
            }

            // Get the first document's videos array
            guard let doc = snapshot.documents.first,
                  let videosArray = doc.data()["videos"] as? [[String: Any]] else {
                await MainActor.run {
                    self.loadedVideos = []
                    self.isLoadingVideos = false
                }
                return
            }

            // Parse videos from array
            let videos = videosArray.compactMap { videoData -> SocialVideo? in
                guard let platform = videoData["platform"] as? String,
                      let url = videoData["url"] as? String,
                      let videoId = videoData["video_id"] as? String else {
                    return nil
                }

                let socialPlatform: SocialPlatform = {
                    switch platform.lowercased() {
                    case "tiktok": return .tiktok
                    case "instagram": return .instagram
                    case "youtube": return .youtube
                    default: return .tiktok
                    }
                }()

                return SocialVideo(
                    id: videoId,
                    platform: socialPlatform,
                    videoURL: url,
                    thumbnailURL: videoData["thumbnail_url"] as? String,
                    title: videoData["title"] as? String,
                    views: videoData["views"] as? Int,
                    embedURL: url
                )
            }

            // Update UI with first 3 videos
            let finalVideos = Array(videos.prefix(3))

            await MainActor.run {
                self.loadedVideos = finalVideos
                self.isLoadingVideos = false
            }

        } catch {
            await MainActor.run {
                self.loadedVideos = []
                self.isLoadingVideos = false
            }
        }
    }

    // MARK: - Social Videos Section
    private var socialVideosSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Social")
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.primary)

            if isLoadingVideos {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<3, id: \.self) { _ in
                            SkeletonVideoCard()
                        }
                    }
                }
            } else if !loadedVideos.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(loadedVideos.prefix(3)) { video in
                            SocialVideoCard(video: video)
                                .onTapGesture {
                                    if let url = URL(string: video.videoURL) {
                                        UIApplication.shared.open(url)
                                    }
                                }
                        }
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Action Buttons
    private var actionButtonsSection: some View {
        VStack(spacing: 12) {
            // View Menu (Primary)
            Button {
                onViewFullMenu()
            } label: {
                HStack {
                    Image(systemName: "menucard")
                        .font(.system(size: 16, weight: .semibold))
                    Text("View Full Menu")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 12))
            }

            // Order Now (Secondary)
            Button {
                // Order action
            } label: {
                HStack {
                    Image(systemName: "basket")
                        .font(.system(size: 16, weight: .semibold))
                    Text("Order for Delivery")
                        .font(.system(size: 17, weight: .semibold))
                }
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(Color(.systemGray6), in: RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

// MARK: - Quick Action Button (iOS 26 Style)
struct QuickActionButton: View {
    let icon: String
    let label: String
    var isPrimary: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(isPrimary ? .white : Color.accentColor)
                    .frame(width: 44, height: 44)
                    .background(
                        isPrimary ? Color.accentColor : Color(.systemGray5),
                        in: Circle()
                    )

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Info Row Component
struct InfoRow: View {
    let icon: String
    let iconColor: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundStyle(iconColor)
                .frame(width: 28)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)

                Text(detail)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
    }
}

// MARK: - Social Video Card
struct SocialVideoCard: View {
    let video: SocialVideo

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video Thumbnail
            Group {
                if let thumbnailURL = video.thumbnailURL, !thumbnailURL.isEmpty {
                    // Fix Firebase Storage URL by removing :443 port (same fix as social feed)
                    let cleanedURL = thumbnailURL.replacingOccurrences(of: ":443", with: "")
                    let _ = print("🖼️ Loading thumbnail: \(cleanedURL)")

                    AsyncImage(url: URL(string: cleanedURL)) { phase in
                        switch phase {
                        case .empty:
                            ShimmerView()
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .onAppear {
                                    print("✅ Thumbnail loaded successfully")
                                }
                        case .failure(let error):
                            placeholderThumbnail
                                .onAppear {
                                    print("❌ Thumbnail failed to load: \(error)")
                                }
                        @unknown default:
                            placeholderThumbnail
                        }
                    }
                } else {
                    // No thumbnail URL - show placeholder
                    let _ = print("⚠️ No thumbnail URL for video: \(video.id)")
                    placeholderThumbnail
                }
            }
            .frame(width: 120, height: 160)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                // Platform Badge
                VStack {
                    HStack {
                        Spacer()
                        platformBadge
                            .padding(6)
                    }
                    Spacer()
                }
            )
            .overlay(
                // Play Icon
                Image(systemName: "play.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 4)
            )

            // Video Info
            VStack(alignment: .leading, spacing: 4) {
                if let title = video.title {
                    Text(title)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.primary)
                        .lineLimit(2)
                }

                if let views = video.views {
                    HStack(spacing: 4) {
                        Image(systemName: "eye.fill")
                            .font(.system(size: 10))
                        Text(formatViews(views))
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .frame(width: 120)
            .padding(.top, 8)
        }
    }

    private var placeholderThumbnail: some View {
        Rectangle()
            .fill(Color(.systemGray6))
            .overlay(
                Image(systemName: "play.rectangle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(.secondary)
            )
    }

    private var platformBadge: some View {
        Group {
            switch video.platform {
            case .tiktok:
                Image(systemName: "music.note")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.black, in: Circle())
            case .instagram:
                Image(systemName: "camera.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(
                        LinearGradient(
                            colors: [.purple, .pink, .orange],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        in: Circle()
                    )
            case .youtube:
                Image(systemName: "play.fill")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white)
                    .padding(4)
                    .background(.red, in: Circle())
            }
        }
    }

    private func formatViews(_ views: Int) -> String {
        if views >= 1_000_000 {
            return String(format: "%.1fM", Double(views) / 1_000_000)
        } else if views >= 1_000 {
            return String(format: "%.1fK", Double(views) / 1_000)
        } else {
            return "\(views)"
        }
    }
}

// MARK: - Skeleton Video Card (Loading State)
struct SkeletonVideoCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Video Thumbnail Skeleton
            ShimmerView()
                .frame(width: 120, height: 160)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            // Video Info Skeleton
            VStack(alignment: .leading, spacing: 4) {
                ShimmerView()
                    .frame(width: 100, height: 12)
                    .cornerRadius(4)

                ShimmerView()
                    .frame(width: 60, height: 10)
                    .cornerRadius(4)
            }
            .frame(width: 120)
            .padding(.top, 8)
        }
    }
}
