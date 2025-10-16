//
//  SocialFeedView.swift
//  Campusmealsv2
//
//  Created by sarp akar on 03/10/2025.
//

import SwiftUI
import FirebaseAuth

struct SocialFeedView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var postService = PostService.shared
    @State private var selectedTab: SocialTab = .explore
    @State private var showCreatePost = false
    @State private var showDiscover = false

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    var body: some View {
        NavigationStack {
            ZStack {
                Color.white
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // TikTok-style top navigation
                    tikTokNavigation

                    // Top Bar (X button)
                    topBar

                    // Feed based on selected tab
                    ScrollView(.vertical, showsIndicators: false) {
                        LazyVStack(spacing: 0) {
                            // Error banner
                            if let error = postService.errorMessage {
                                HStack(spacing: 12) {
                                    Image(systemName: "exclamationmark.triangle.fill")
                                        .foregroundColor(.orange)
                                    Text(error)
                                        .font(.system(size: 14))
                                        .foregroundColor(.black)
                                    Spacer()
                                    Button("Retry") {
                                        Task {
                                            await postService.fetchAllPosts(forceRefresh: true)
                                        }
                                    }
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(citiBikeBlue)
                                }
                                .padding()
                                .background(Color.orange.opacity(0.1))
                                .cornerRadius(12)
                                .padding(.horizontal, 18)
                                .padding(.top, 8)
                            }
                            
                            if filteredPosts.isEmpty && !postService.isLoading {
                                VStack(spacing: 16) {
                                    Image(systemName: "photo.on.rectangle.angled")
                                        .font(.system(size: 60))
                                        .foregroundColor(.gray)
                                    
                                    Text(emptyStateText)
                                        .font(.system(size: 20, weight: .semibold))
                                        .foregroundColor(.black)
                                    
                                    Text(emptyStateSubtext)
                                        .font(.system(size: 15))
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.top, 100)
                            } else {
                                ForEach(filteredPosts) { post in
                                    PostCard(post: post)
                                }
                            }
                            
                            if postService.isLoading {
                                ProgressView()
                                    .padding()
                            }
                            


                        }
                        .padding(.top, 16)
                        .padding(.bottom, 100)
                    }
                    .background(Color.white)
                }

            // Bottom buttons (TikTok style) with glass background
         
            }
            .navigationBarHidden(true)
            .task {
                print("🎬 SocialFeedView appeared - Fetching posts")
                await postService.fetchAllPosts(forceRefresh: false)
            }
            .refreshable {
                print("🔄 Pull to refresh - Force refresh")
                await postService.fetchAllPosts(forceRefresh: true)
            }
            .fullScreenCover(isPresented: $showCreatePost) {
                CreatePostView()
            }
        }
    }

    // MARK: - TikTok-Style Navigation
    private var tikTokNavigation: some View {
        HStack(spacing: 16) {
            // Explore Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .explore
                }
            }) {
                VStack(spacing: 4) {
                    Text("Explore")
                        .font(.system(size: 17, weight: selectedTab == .explore ? .bold : .regular))
                        .foregroundColor(.black)

                    if selectedTab == .explore {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 60, height: 2)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 60, height: 2)
                    }
                }
                .frame(minWidth: 70)
            }

            // Following Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .following
                }
            }) {
                VStack(spacing: 4) {
                    Text("Following")
                        .font(.system(size: 17, weight: selectedTab == .following ? .bold : .regular))
                        .foregroundColor(.black)

                    if selectedTab == .following {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 70, height: 2)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 70, height: 2)
                    }
                }
                .frame(minWidth: 80)
            }

            // Profile Tab
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    selectedTab = .profile
                }
            }) {
                VStack(spacing: 4) {
                    Text("Profile")
                        .font(.system(size: 17, weight: selectedTab == .profile ? .bold : .regular))
                        .foregroundColor(.black)

                    if selectedTab == .profile {
                        Rectangle()
                            .fill(Color.black)
                            .frame(width: 55, height: 2)
                    } else {
                        Rectangle()
                            .fill(Color.clear)
                            .frame(width: 55, height: 2)
                    }
                }
                .frame(minWidth: 70)
            }

            Spacer()

            // Close button - aligned with tabs
            Button(action: {
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.black)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 8)
    }

    // MARK: - Top Bar (X button only)
    private var topBar: some View {
        EmptyView()
    }

    // MARK: - Filtered Posts
    private var filteredPosts: [Post] {
        switch selectedTab {
        case .explore:
            // Show all posts ranked by algorithm
            return RankingService.shared.rankPosts(postService.posts)
        case .following:
            // TODO: Filter by following when user relationships are implemented
            // For now, show recent posts
            return postService.posts.sorted { $0.timestamp > $1.timestamp }
        case .profile:
            // Show only current user's posts
            guard let currentUserId = Auth.auth().currentUser?.uid else { return [] }
            return postService.posts.filter { $0.userId == currentUserId }
        }
    }

    // MARK: - Empty State Text
    private var emptyStateText: String {
        switch selectedTab {
        case .explore:
            return "No posts yet"
        case .following:
            return "No posts from people you follow"
        case .profile:
            return "No posts yet"
        }
    }

    private var emptyStateSubtext: String {
        switch selectedTab {
        case .explore:
            return "Be the first to share a meal!"
        case .following:
            return "Follow friends to see their meals!"
        case .profile:
            return "Share your first meal!"
        }
    }

}

// MARK: - Social Tab Enum
enum SocialTab {
    case explore
    case following
    case profile
}

// MARK: - Filter Pill Component (Dark theme)
struct FilterPill: View {
    let filter: FeedFilter
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: filter.icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(filter.rawValue)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundColor(isSelected ? .white : Color(.systemGray2))
            .padding(.horizontal, 20)
            .padding(.vertical, 11)
            .background(
                RoundedRectangle(cornerRadius: 22)
                    .fill(isSelected ? Color(red: 0.2, green: 0.5, blue: 0.6) : Color.white.opacity(0.12))
            )
        }
    }
}

// MARK: - TextField Placeholder Extension
extension View {
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content) -> some View {

        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
}

// MARK: - Feed Tab Enum
enum FeedTab {
    case friends
    case following
    case communities
}

#Preview {
    SocialFeedView()
}
