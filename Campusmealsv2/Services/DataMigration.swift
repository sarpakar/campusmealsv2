//
//  DataMigration.swift
//  Campusmealsv2
//
//  Utilities to fix existing data issues
//

import Foundation
import FirebaseFirestore
import FirebaseStorage

@MainActor
class DataMigration {
    static let shared = DataMigration()
    private let db = Firestore.firestore()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Fix Malformed Firebase Storage URLs
    func fixMalformedImageURLs() async {
        print("🔧 Starting URL migration...")

        do {
            // Get all posts
            let snapshot = try await db.collection("posts").getDocuments()

            print("📊 Found \(snapshot.documents.count) posts to check")

            var fixedCount = 0
            var errorCount = 0

            for document in snapshot.documents {
                do {
                    var data = document.data()

                    // Fix foodPhotos array
                    if var foodPhotos = data["food_photos"] as? [String] {
                        var needsUpdate = false
                        let fixedPhotos = foodPhotos.map { url -> String in
                            var fixed = url

                            // Fix :443 port in googleapis.com URLs
                            if fixed.contains("firebasestorage.googleapis.com:443") {
                                needsUpdate = true
                                fixed = fixed.replacingOccurrences(
                                    of: "firebasestorage.googleapis.com:443",
                                    with: "firebasestorage.googleapis.com"
                                )
                            }

                            // Fix :443 port in .app URLs
                            if fixed.contains("firebasestorage.app:443") {
                                needsUpdate = true
                                fixed = fixed.replacingOccurrences(
                                    of: "firebasestorage.app:443",
                                    with: "firebasestorage.app"
                                )
                            }

                            // Fix malformed goog/eapis.com URLs
                            if fixed.contains("firebasestorage.goog/eapis.com") {
                                needsUpdate = true
                                fixed = fixed.replacingOccurrences(
                                    of: "firebasestorage.goog/eapis.com:443",
                                    with: "firebasestorage.googleapis.com"
                                )
                                fixed = fixed.replacingOccurrences(
                                    of: "firebasestorage.goog/eapis.com",
                                    with: "firebasestorage.googleapis.com"
                                )
                            }

                            return fixed
                        }

                        if needsUpdate {
                            try await document.reference.updateData([
                                "food_photos": fixedPhotos
                            ])
                            fixedCount += 1
                            print("✅ Fixed URLs for post: \(document.documentID)")
                        }
                    }

                    // Fix selfiePhotoURL
                    if var selfieURL = data["selfie_photo_url"] as? String {
                        var needsUpdate = false
                        var fixedURL = selfieURL

                        // Fix :443 port in googleapis.com URLs
                        if fixedURL.contains("firebasestorage.googleapis.com:443") {
                            needsUpdate = true
                            fixedURL = fixedURL.replacingOccurrences(
                                of: "firebasestorage.googleapis.com:443",
                                with: "firebasestorage.googleapis.com"
                            )
                        }

                        // Fix :443 port in .app URLs
                        if fixedURL.contains("firebasestorage.app:443") {
                            needsUpdate = true
                            fixedURL = fixedURL.replacingOccurrences(
                                of: "firebasestorage.app:443",
                                with: "firebasestorage.app"
                            )
                        }

                        // Fix malformed goog/eapis.com URLs
                        if fixedURL.contains("firebasestorage.goog/eapis.com") {
                            needsUpdate = true
                            fixedURL = fixedURL.replacingOccurrences(
                                of: "firebasestorage.goog/eapis.com:443",
                                with: "firebasestorage.googleapis.com"
                            )
                            fixedURL = fixedURL.replacingOccurrences(
                                of: "firebasestorage.goog/eapis.com",
                                with: "firebasestorage.googleapis.com"
                            )
                        }

                        if needsUpdate {
                            try await document.reference.updateData([
                                "selfie_photo_url": fixedURL
                            ])
                            fixedCount += 1
                            print("✅ Fixed selfie URL for post: \(document.documentID)")
                        }
                    }

                } catch {
                    errorCount += 1
                    print("❌ Error fixing post \(document.documentID): \(error)")
                }
            }

            print("✅ Migration complete - Fixed: \(fixedCount), Errors: \(errorCount)")

        } catch {
            print("❌ Migration failed: \(error)")
        }
    }

    // MARK: - Add Engagement Fields to Existing Posts
    func addEngagementFieldsToExistingPosts() async {
        print("🔧 Adding engagement fields to existing posts...")

        do {
            let snapshot = try await db.collection("posts").getDocuments()

            print("📊 Found \(snapshot.documents.count) posts to update")

            var updatedCount = 0

            for document in snapshot.documents {
                do {
                    // Add missing engagement fields with default values
                    try await document.reference.setData([
                        "view_count": 0,
                        "like_count": 0,
                        "comment_count": 0,
                        "share_count": 0,
                        "bookmark_count": 0,
                        "engagement_score": 0.0
                    ], merge: true)

                    updatedCount += 1

                    if updatedCount % 10 == 0 {
                        print("📊 Updated \(updatedCount) posts...")
                    }

                } catch {
                    print("❌ Error updating post \(document.documentID): \(error)")
                }
            }

            print("✅ Migration complete - Updated: \(updatedCount) posts")

        } catch {
            print("❌ Migration failed: \(error)")
        }
    }

    // MARK: - Regenerate Download URLs from Storage
    func regenerateDownloadURLs() async {
        print("🔧 Regenerating download URLs from Firebase Storage...")

        do {
            let snapshot = try await db.collection("posts").getDocuments()
            print("📊 Found \(snapshot.documents.count) posts to process")

            var fixedCount = 0
            var errorCount = 0

            for document in snapshot.documents {
                do {
                    var needsUpdate = false
                    var data = document.data()

                    // Regenerate food_photos URLs
                    if let foodPhotos = data["food_photos"] as? [String] {
                        var newURLs: [String] = []

                        for urlString in foodPhotos {
                            // Extract path from URL
                            if let path = extractStoragePath(from: urlString) {
                                print("🔄 Regenerating URL for path: \(path)")

                                // Get fresh download URL from Storage
                                let ref = storage.reference().child(path)

                                do {
                                    let newURL = try await ref.downloadURL()
                                    newURLs.append(newURL.absoluteString)
                                    needsUpdate = true
                                    print("   ✅ New URL: \(newURL.absoluteString)")
                                } catch {
                                    print("   ❌ Failed to get URL: \(error.localizedDescription)")
                                    // Keep old URL if regeneration fails
                                    newURLs.append(urlString)
                                }
                            } else {
                                // Can't extract path, keep old URL
                                newURLs.append(urlString)
                            }
                        }

                        if needsUpdate && !newURLs.isEmpty {
                            try await document.reference.updateData([
                                "food_photos": newURLs
                            ])
                            fixedCount += 1
                            print("✅ Updated post: \(document.documentID)")
                        }
                    }

                } catch {
                    errorCount += 1
                    print("❌ Error processing post \(document.documentID): \(error)")
                }
            }

            print("✅ Regeneration complete - Updated: \(fixedCount), Errors: \(errorCount)")

        } catch {
            print("❌ Regeneration failed: \(error)")
        }
    }

    // MARK: - Extract Storage Path from URL
    private func extractStoragePath(from urlString: String) -> String? {
        // Handle both URL formats:
        // https://firebasestorage.googleapis.com/v0/b/BUCKET/o/PATH?...
        // https://BUCKET.firebasestorage.app/v0/b/BUCKET/o/PATH?...

        guard let url = URL(string: urlString) else { return nil }

        // Look for pattern: /o/PATH
        if let range = urlString.range(of: "/o/") {
            var path = String(urlString[range.upperBound...])

            // Remove query parameters
            if let queryIndex = path.firstIndex(of: "?") {
                path = String(path[..<queryIndex])
            }

            // URL decode (e.g., %2F → /)
            path = path.removingPercentEncoding ?? path

            return path
        }

        return nil
    }

    // MARK: - Run All Migrations
    func runAllMigrations() async {
        print("🚀 Running all migrations...")

        await fixMalformedImageURLs()
        await addEngagementFieldsToExistingPosts()
        await regenerateDownloadURLs()  // NEW: Regenerate all URLs

        print("✅ All migrations complete!")
    }
}
