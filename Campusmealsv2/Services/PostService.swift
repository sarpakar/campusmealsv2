//
//  PostService.swift - SIMPLE VERSION
//  Campusmealsv2
//
//  Simple: Just fetch ALL posts and display them. No cache, no complexity.
//

import Foundation
import FirebaseFirestore
import FirebaseStorage
import FirebaseAuth
import UIKit

@MainActor
class PostService: ObservableObject {
    static let shared = PostService()

    @Published var posts: [Post] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    var currentUserId: String? {
        Auth.auth().currentUser?.uid
    }

    // Cache
    private var cachedPosts: [Post] = []
    private var lastFetchTime: Date?
    private let cacheValidityDuration: TimeInterval = 300 // 5 minutes

    // Pagination
    private var lastDocument: DocumentSnapshot?
    private var hasMorePosts = true
    private let postsPerPage = 20

    private init() {
        print("🚀 PostService initialized")
    }

    // MARK: - Fetch Posts with Caching
    func fetchAllPosts(forceRefresh: Bool = false) async {
        // Check cache first
        if !forceRefresh,
           let lastFetch = lastFetchTime,
           Date().timeIntervalSince(lastFetch) < cacheValidityDuration,
           !cachedPosts.isEmpty {
            print("📦 Using cached posts (\(cachedPosts.count) posts)")
            self.posts = cachedPosts
            return
        }

        print("\n📱 Fetching posts from Firebase...")
        isLoading = true
        errorMessage = nil

        do {
            // Get posts with pagination
            let snapshot = try await db.collection("posts")
                .order(by: "timestamp", descending: true)
                .limit(to: 50) // Initial load: 50 posts
                .getDocuments()

            print("🔍 Firebase returned \(snapshot.documents.count) posts")

            // Decode all posts
            let allPosts = snapshot.documents.compactMap { doc -> Post? in
                do {
                    return try doc.data(as: Post.self)
                } catch {
                    print("❌ Failed to decode post \(doc.documentID): \(error.localizedDescription)")
                    return nil
                }
            }

            print("✅ Successfully decoded \(allPosts.count) posts")

            // Update cache
            cachedPosts = allPosts
            lastFetchTime = Date()
            lastDocument = snapshot.documents.last

            // Update UI
            self.posts = allPosts
            isLoading = false

            print("✅ Posts displayed in feed\n")

        } catch {
            print("❌ Error fetching posts: \(error.localizedDescription)")
            errorMessage = "Failed to load posts. Please try again."
            isLoading = false

            // Use cached posts as fallback
            if !cachedPosts.isEmpty {
                print("⚠️ Using cached posts as fallback")
                self.posts = cachedPosts
            }
        }
    }

    // MARK: - Load More Posts (Pagination)
    func loadMorePosts() async {
        guard !isLoading, hasMorePosts, let last = lastDocument else { return }

        print("📄 Loading more posts...")
        isLoading = true

        do {
            let snapshot = try await db.collection("posts")
                .order(by: "timestamp", descending: true)
                .start(afterDocument: last)
                .limit(to: postsPerPage)
                .getDocuments()

            if snapshot.documents.isEmpty {
                hasMorePosts = false
                isLoading = false
                print("✅ No more posts to load")
                return
            }

            let newPosts = snapshot.documents.compactMap { doc -> Post? in
                try? doc.data(as: Post.self)
            }

            // Append to existing posts
            cachedPosts.append(contentsOf: newPosts)
            posts.append(contentsOf: newPosts)
            lastDocument = snapshot.documents.last
            isLoading = false

            print("✅ Loaded \(newPosts.count) more posts")

        } catch {
            print("❌ Error loading more posts: \(error.localizedDescription)")
            errorMessage = "Failed to load more posts"
            isLoading = false
        }
    }

    // MARK: - Feed Type Enum
    enum FeedType {
        case explore
        case following
        case profile
    }

    // MARK: - Create Post
    func createPost(
        images: [UIImage],
        selfieImage: UIImage?,
        notes: String,
        location: String,
        mealType: MealType,
        dietTags: [DietTag],
        restaurantName: String? = nil,
        restaurantRating: Double? = nil,
        nutritionInfo: PostNutritionInfo? = nil,
        onProgress: @escaping (Double) -> Void
    ) async throws -> Post {

        guard let currentUser = Auth.auth().currentUser else {
            throw NSError(domain: "PostService", code: 401, userInfo: [NSLocalizedDescriptionKey: "User not authenticated"])
        }

        let postId = UUID().uuidString
        let userName = currentUser.phoneNumber ?? "Unknown User"

        // Upload images in parallel
        let totalImages = images.count + (selfieImage != nil ? 1 : 0)
        var completedUploads = 0

        let uploadedImageURLs = try await withThrowingTaskGroup(of: (Int, String).self) { group in
            for (index, image) in images.enumerated() {
                group.addTask {
                    let url = try await self.uploadImage(image, path: "posts/\(postId)/food_\(index).jpg")
                    return (index, url)
                }
            }

            var results: [(Int, String)] = []
            for try await (index, url) in group {
                results.append((index, url))
                completedUploads += 1
                onProgress(Double(completedUploads) / Double(totalImages))
            }

            return results.sorted { $0.0 < $1.0 }.map { $0.1 }
        }

        var uploadedSelfieURL: String?
        if let selfie = selfieImage {
            uploadedSelfieURL = try await uploadImage(selfie, path: "posts/\(postId)/selfie.jpg")
            completedUploads += 1
            onProgress(Double(completedUploads) / Double(totalImages))
        }

        let post = Post(
            id: postId,
            userId: currentUser.uid,
            userName: userName,
            userPhotoURL: currentUser.photoURL?.absoluteString,
            timestamp: Date(),
            location: location,
            restaurantName: restaurantName,
            restaurantRating: restaurantRating,
            mealType: mealType,
            foodPhotos: uploadedImageURLs,
            selfiePhotoURL: uploadedSelfieURL,
            notes: notes,
            dietTags: dietTags,
            nutritionInfo: nutritionInfo,
            likes: 0,
            comments: 0,
            bookmarks: 0,
            isLikedByCurrentUser: false,
            isBookmarkedByCurrentUser: false,
            viewCount: 0,
            likeCount: 0,
            commentCount: 0,
            shareCount: 0,
            bookmarkCount: 0,
            engagementScore: 0
        )

        // Save to Firestore
        print("💾 Saving post to Firestore...")
        do {
            try await db.collection("posts").document(postId).setData(from: post)
            print("✅ Post saved to Firestore: \(postId)")
        } catch {
            print("❌ Failed to save post to Firestore: \(error.localizedDescription)")
            throw error
        }

        // Add to beginning of feed
        posts.insert(post, at: 0)

        return post
    }

    // MARK: - Upload Image (Optimized & Efficient)
    private func uploadImage(_ image: UIImage, path: String) async throws -> String {
        print("📤 Uploading: \(path)")

        // Resize to 1080px max (Instagram standard) - OPTIMIZED
        let resizedImage = resizeImageEfficiently(image, maxDimension: 1080)

        // Use compression quality 0.8 for better file size (was 0.85)
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "PostService", code: 500, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let ref = storage.reference().child(path)
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await ref.putDataAsync(imageData, metadata: metadata)
        let downloadURL = try await ref.downloadURL()

        print("✅ Uploaded: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    private func resizeImage(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Efficient Image Resizing (Optimized for Performance)
    private func resizeImageEfficiently(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let size = image.size

        // No resize needed if already small enough
        guard size.width > maxDimension || size.height > maxDimension else {
            return image
        }

        // Calculate new size maintaining aspect ratio
        let ratio = min(maxDimension / size.width, maxDimension / size.height)
        let newSize = CGSize(width: size.width * ratio, height: size.height * ratio)

        // Use UIGraphicsImageRenderer for better performance (iOS 10+)
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1.0 // Force scale to 1.0 for consistent output
        format.opaque = true // Opaque images render faster

        let renderer = UIGraphicsImageRenderer(size: newSize, format: format)
        return renderer.image { context in
            // Use higher quality interpolation
            context.cgContext.interpolationQuality = .high
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    // MARK: - Delete Post
    func deletePost(postId: String) async throws {
        // Delete from Firestore
        try await db.collection("posts").document(postId).delete()

        // Remove from local array
        await MainActor.run {
            posts.removeAll { $0.id == postId }
            cachedPosts.removeAll { $0.id == postId }
        }

        print("✅ Post deleted: \(postId)")
    }
}
