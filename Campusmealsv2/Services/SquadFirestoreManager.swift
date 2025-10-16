//
//  SquadFirestoreManager.swift
//  Campusmealsv2
//
//  Firebase operations for Squad Up & Eat system
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

class SquadFirestoreManager: ObservableObject {
    static let shared = SquadFirestoreManager()
    private let db = Firestore.firestore()

    // MARK: - Match Operations

    func createMatch(_ match: Match) async throws {
        guard let matchId = match.id else {
            throw NSError(domain: "SquadFirestore", code: 1, userInfo: [NSLocalizedDescriptionKey: "Match ID is required"])
        }

        try db.collection("matches").document(matchId).setData(from: match)
        print("✅ Match created: \(matchId)")
    }

    func fetchMatch(_ matchId: String) async throws -> Match {
        let document = try await db.collection("matches").document(matchId).getDocument()
        guard let match = try? document.data(as: Match.self) else {
            throw NSError(domain: "SquadFirestore", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to decode match"])
        }
        return match
    }

    func updateMatchStatus(_ matchId: String, status: MatchStatus) async throws {
        try await db.collection("matches").document(matchId).updateData([
            "status": status.rawValue
        ])
        print("✅ Match status updated to: \(status.rawValue)")
    }

    func addParticipant(_ userId: String, to matchId: String) async throws {
        try await db.collection("matches").document(matchId).updateData([
            "participants": FieldValue.arrayUnion([userId])
        ])
        print("✅ Added participant \(userId) to match \(matchId)")
    }

    func checkIn(_ userId: String, for matchId: String) async throws {
        try await db.collection("matches").document(matchId).updateData([
            "check_ins": FieldValue.arrayUnion([userId])
        ])

        // Award check-in bonus XP immediately
        try await awardXP(userId, amount: 50, reason: "Checked in at restaurant")

        print("✅ User \(userId) checked in to match \(matchId)")
    }

    func completeMatch(_ matchId: String, results: MatchResults) async throws {
        try await db.collection("matches").document(matchId).updateData([
            "status": MatchStatus.completed.rawValue,
            "results": try Firestore.Encoder().encode(results)
        ])
        print("✅ Match \(matchId) completed")
    }

    // MARK: - Invite Operations

    func sendInvite(_ invite: MatchInvite) async throws {
        guard let inviteId = invite.id else {
            throw NSError(domain: "SquadFirestore", code: 3, userInfo: [NSLocalizedDescriptionKey: "Invite ID is required"])
        }

        // Create invite document
        let inviteRef = db.collection("matches")
            .document(invite.matchId)
            .collection("invites")
            .document(inviteId)

        try inviteRef.setData(from: invite)

        // Add invite ID to match
        try await db.collection("matches").document(invite.matchId).updateData([
            "invites": FieldValue.arrayUnion([inviteId])
        ])

        print("✅ Invite sent: \(inviteId)")
    }

    func acceptInvite(_ invite: MatchInvite) async throws {
        guard let inviteId = invite.id else {
            throw NSError(domain: "SquadFirestore", code: 4, userInfo: [NSLocalizedDescriptionKey: "Invite ID is required"])
        }

        // Update invite status
        try await db.collection("matches")
            .document(invite.matchId)
            .collection("invites")
            .document(inviteId)
            .updateData([
                "status": InviteStatus.accepted.rawValue,
                "responded_at": Timestamp(date: Date())
            ])

        // Add user to match participants
        try await addParticipant(invite.inviteeId, to: invite.matchId)

        print("✅ Invite accepted: \(inviteId)")
    }

    func declineInvite(_ invite: MatchInvite) async throws {
        guard let inviteId = invite.id else {
            throw NSError(domain: "SquadFirestore", code: 5, userInfo: [NSLocalizedDescriptionKey: "Invite ID is required"])
        }

        try await db.collection("matches")
            .document(invite.matchId)
            .collection("invites")
            .document(inviteId)
            .updateData([
                "status": InviteStatus.declined.rawValue,
                "responded_at": Timestamp(date: Date())
            ])

        print("✅ Invite declined: \(inviteId)")
    }

    func fetchInvitesForUser(_ userId: String) async throws -> [MatchInvite] {
        let snapshot = try await db.collectionGroup("invites")
            .whereField("invitee_id", isEqualTo: userId)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .order(by: "created_at", descending: true)
            .getDocuments()

        return snapshot.documents.compactMap { try? $0.data(as: MatchInvite.self) }
    }

    // MARK: - User Profile Operations

    func createUserProfile(_ profile: UserProfile) async throws {
        guard let userId = profile.id else {
            throw NSError(domain: "SquadFirestore", code: 6, userInfo: [NSLocalizedDescriptionKey: "User ID is required"])
        }

        try db.collection("users").document(userId).setData(from: profile)
        print("✅ User profile created: \(userId)")
    }

    func fetchUserProfile(_ userId: String) async throws -> UserProfile {
        let document = try await db.collection("users").document(userId).getDocument()
        guard let profile = try? document.data(as: UserProfile.self) else {
            throw NSError(domain: "SquadFirestore", code: 7, userInfo: [NSLocalizedDescriptionKey: "Failed to decode user profile"])
        }
        return profile
    }

    func updateFCMToken(_ token: String, for userId: String) async throws {
        try await db.collection("users").document(userId).updateData([
            "fcm_token": token
        ])
        print("✅ FCM token updated for user \(userId)")
    }

    func awardXP(_ userId: String, amount: Int, reason: String) async throws {
        try await db.runTransaction { (transaction, errorPointer) -> Any? in
            let userRef = self.db.collection("users").document(userId)
            let userDoc: DocumentSnapshot

            do {
                userDoc = try transaction.getDocument(userRef)
            } catch let error as NSError {
                errorPointer?.pointee = error
                return nil
            }

            guard let currentXP = userDoc.data()?["total_xp"] as? Int else {
                let error = NSError(domain: "SquadFirestore", code: 8, userInfo: [NSLocalizedDescriptionKey: "Failed to get current XP"])
                errorPointer?.pointee = error
                return nil
            }

            let currentLevel = userDoc.data()?["level"] as? Int ?? 1
            let newXP = currentXP + amount
            let newLevel = (newXP / 1000) + 1

            transaction.updateData([
                "total_xp": newXP,
                "level": newLevel
            ], forDocument: userRef)

            print("✅ Awarded \(amount) XP to user \(userId) for: \(reason)")
            if newLevel > currentLevel {
                print("🎉 Level up! User is now level \(newLevel)")
            }

            return nil
        }
    }

    func awardRestaurantPoints(_ userId: String, restaurantId: String, points: Int) async throws {
        try await db.collection("users").document(userId).updateData([
            "restaurant_points.\(restaurantId)": FieldValue.increment(Int64(points))
        ])
        print("✅ Awarded \(points) points at restaurant \(restaurantId) to user \(userId)")
    }

    // MARK: - Friend Operations

    func addFriend(_ userId: String, friendId: String) async throws {
        // Add friend to both users (bidirectional)
        let batch = db.batch()

        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "friends": FieldValue.arrayUnion([friendId])
        ], forDocument: userRef)

        let friendRef = db.collection("users").document(friendId)
        batch.updateData([
            "friends": FieldValue.arrayUnion([userId])
        ], forDocument: friendRef)

        try await batch.commit()
        print("✅ Friendship created between \(userId) and \(friendId)")
    }

    func removeFriend(_ userId: String, friendId: String) async throws {
        let batch = db.batch()

        let userRef = db.collection("users").document(userId)
        batch.updateData([
            "friends": FieldValue.arrayRemove([friendId])
        ], forDocument: userRef)

        let friendRef = db.collection("users").document(friendId)
        batch.updateData([
            "friends": FieldValue.arrayRemove([userId])
        ], forDocument: friendRef)

        try await batch.commit()
        print("✅ Friendship removed between \(userId) and \(friendId)")
    }

    func searchUserByPhoneNumber(_ phoneNumber: String) async throws -> UserProfile? {
        let snapshot = try await db.collection("users")
            .whereField("phone_number", isEqualTo: phoneNumber)
            .limit(to: 1)
            .getDocuments()

        return snapshot.documents.first.flatMap { try? $0.data(as: UserProfile.self) }
    }

    func fetchFriends(_ friendIds: [String]) async throws -> [UserProfile] {
        guard !friendIds.isEmpty else { return [] }

        // Firestore 'in' queries are limited to 30 items
        let chunks = friendIds.chunked(into: 30)
        var allFriends: [UserProfile] = []

        for chunk in chunks {
            let snapshot = try await db.collection("users")
                .whereField(FieldPath.documentID(), in: chunk)
                .getDocuments()

            let friends = snapshot.documents.compactMap { try? $0.data(as: UserProfile.self) }
            allFriends.append(contentsOf: friends)
        }

        return allFriends
    }

    // MARK: - Real-time Listeners

    func listenToMatches(for userId: String, completion: @escaping ([Match]) -> Void) -> ListenerRegistration {
        return db.collection("matches")
            .whereField("participants", arrayContains: userId)
            .order(by: "scheduled_time", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching matches: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }

                let matches = documents.compactMap { try? $0.data(as: Match.self) }
                completion(matches)
            }
    }

    func listenToInvites(for userId: String, completion: @escaping ([MatchInvite]) -> Void) -> ListenerRegistration {
        return db.collectionGroup("invites")
            .whereField("invitee_id", isEqualTo: userId)
            .whereField("status", isEqualTo: InviteStatus.pending.rawValue)
            .order(by: "created_at", descending: true)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    print("❌ Error fetching invites: \(error?.localizedDescription ?? "Unknown")")
                    completion([])
                    return
                }

                let invites = documents.compactMap { try? $0.data(as: MatchInvite.self) }
                completion(invites)
            }
    }
}

// MARK: - Helper Extensions

extension Array {
    func chunked(into size: Int) -> [[Element]] {
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}
