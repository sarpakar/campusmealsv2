//
//  EngagementTracker.swift
//  Campusmealsv2
//
//  Instagram/TikTok-grade engagement tracking
//  Tracks views, likes, comments, shares for recommendation algorithm
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

@MainActor
class EngagementTracker: ObservableObject {
    static let shared = EngagementTracker()

    private let db = Firestore.firestore()
    private var pendingEvents: [EngagementEvent] = []
    private var flushTimer: Timer?

    private init() {
        // Batch write events every 5 seconds for efficiency
        startBatchTimer()
    }

    // MARK: - Track View (TikTok/Instagram style)
    func trackView(postId: String, duration: TimeInterval) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        guard duration > 0.5 else { return }  // Minimum 0.5s view

        print("👁️ View tracked - postId: \(postId), duration: \(duration)s")

        // Queue event for batch processing
        let event = EngagementEvent(
            postId: postId,
            userId: userId,
            type: .view,
            metadata: ["duration": duration]
        )
        pendingEvents.append(event)
    }

    // MARK: - Track Engagement (Likes, Comments, Shares, Saves)
    func trackEngagement(postId: String, type: EngagementType) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }

        print("💫 Engagement tracked - postId: \(postId), type: \(type)")

        let event = EngagementEvent(
            postId: postId,
            userId: userId,
            type: type,
            metadata: [:]
        )

        // Immediate write for user actions (likes, comments)
        await processEvent(event)
    }

    // MARK: - Process Single Event
    private func processEvent(_ event: EngagementEvent) async {
        do {
            let postRef = db.collection("posts").document(event.postId)

            // Update post metrics based on type
            switch event.type {
            case .view:
                try await postRef.updateData([
                    "viewCount": FieldValue.increment(Int64(1))
                ])

            case .like:
                try await postRef.updateData([
                    "likeCount": FieldValue.increment(Int64(1)),
                    "engagementScore": FieldValue.increment(Int64(1))
                ])

            case .comment:
                try await postRef.updateData([
                    "commentCount": FieldValue.increment(Int64(1)),
                    "engagementScore": FieldValue.increment(Int64(3))  // Comments worth 3x
                ])

            case .share:
                try await postRef.updateData([
                    "shareCount": FieldValue.increment(Int64(1)),
                    "engagementScore": FieldValue.increment(Int64(5))  // Shares worth 5x
                ])

            case .save:
                try await postRef.updateData([
                    "bookmarkCount": FieldValue.increment(Int64(1)),
                    "engagementScore": FieldValue.increment(Int64(4))  // Saves worth 4x
                ])

            case .unlike:
                try await postRef.updateData([
                    "likeCount": FieldValue.increment(Int64(-1)),
                    "engagementScore": FieldValue.increment(Int64(-1))
                ])
            }

            print("✅ Event processed successfully")

        } catch {
            print("❌ Failed to process engagement event: \(error)")
        }
    }

    // MARK: - Batch Processing
    private func startBatchTimer() {
        flushTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                await self?.flushPendingEvents()
            }
        }
    }

    private func flushPendingEvents() async {
        guard !pendingEvents.isEmpty else { return }

        print("📦 Flushing \(pendingEvents.count) pending events...")

        let eventsToProcess = pendingEvents
        pendingEvents = []

        for event in eventsToProcess {
            await processEvent(event)
        }
    }
}

// MARK: - Models
struct EngagementEvent {
    let postId: String
    let userId: String
    let type: EngagementType
    let metadata: [String: Any]
    let timestamp: Date = Date()
}

enum EngagementType {
    case view
    case like
    case unlike
    case comment
    case share
    case save
}
