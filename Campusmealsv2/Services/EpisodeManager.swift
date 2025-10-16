
//  EpisodeManager.swift
//  Campusmealsv2
//
//  Episode CRUD operations
//

import Foundation
import FirebaseFirestore

class EpisodeManager: ObservableObject {
    static let shared = EpisodeManager()
    private let db = Firestore.firestore()

    @Published var episodes: [Episode] = []

    private init() {}

    // MARK: - Create

    func createEpisode(_ episode: Episode) async throws {
        guard let episodeId = episode.id else {
            throw NSError(domain: "EpisodeManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Episode ID is required"])
        }

        try db.collection("episodes").document(episodeId).setData(from: episode)
        print("✅ Episode created: \(episodeId)")
    }

    // MARK: - Read

    func fetchEpisode(_ episodeId: String) async throws -> Episode {
        let document = try await db.collection("episodes").document(episodeId).getDocument()
        guard let episode = try? document.data(as: Episode.self) else {
            throw NSError(domain: "EpisodeManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode episode"])
        }
        return episode
    }

    func fetchEpisodes(for userId: String, limit: Int = 20) async throws -> [Episode] {
        let snapshot = try await db.collection("episodes")
            .whereField("participant_ids", arrayContains: userId)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Episode.self) }
    }

    func fetchFriendEpisodes(friendIds: [String], limit: Int = 50) async throws -> [Episode] {
        guard !friendIds.isEmpty else { return [] }

        // Include current user's episodes
        let snapshot = try await db.collection("episodes")
            .whereField("creator_id", in: friendIds)
            .order(by: "created_at", descending: true)
            .limit(to: limit)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: Episode.self) }
    }

    // MARK: - Update

    func addReaction(_ episodeId: String, reaction: String) async throws {
        try await db.collection("episodes").document(episodeId).updateData([
            "reactions.\(reaction)": FieldValue.increment(Int64(1))
        ])
        print("✅ Added reaction \(reaction) to episode \(episodeId)")
    }

    func incrementViewCount(_ episodeId: String) async throws {
        try await db.collection("episodes").document(episodeId).updateData([
            "view_count": FieldValue.increment(Int64(1))
        ])
    }

    func addDramaMoment(_ episodeId: String, moment: DramaMoment) async throws {
        try await db.collection("episodes").document(episodeId).updateData([
            "drama_moments": FieldValue.arrayUnion([try Firestore.Encoder().encode(moment)])
        ])
        print("✅ Added drama moment to episode \(episodeId)")
    }

    // MARK: - Delete

    func deleteEpisode(_ episodeId: String) async throws {
        try await db.collection("episodes").document(episodeId).delete()
        print("✅ Episode deleted: \(episodeId)")
    }

    // MARK: - Real-time Listener

    func listenToFeed(friendIds: [String], completion: @escaping ([Episode]) -> Void) -> ListenerRegistration {
        guard !friendIds.isEmpty else {
            completion([])
            return db.collection("episodes").limit(to: 1).addSnapshotListener { _, _ in }
        }

        return db.collection("episodes")
            .whereField("creator_id", in: Array(friendIds.prefix(30))) // Firestore limit
            .order(by: "created_at", descending: true)
            .limit(to: 50)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching episodes: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }

                let episodes = documents.compactMap { try? $0.data(as: Episode.self) }
                completion(episodes)
            }
    }
}
