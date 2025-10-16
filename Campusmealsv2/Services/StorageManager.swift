//
//  StorageManager.swift
//  Campusmealsv2
//
//  Firebase Storage for photo uploads
//

import Foundation
import FirebaseStorage
import UIKit

class StorageManager {
    static let shared = StorageManager()
    private let storage = Storage.storage()

    private init() {}

    // MARK: - Episode Photos

    func uploadEpisodePhoto(_ data: Data, matchId: String) async throws -> String {
        let photoId = UUID().uuidString
        let storageRef = storage.reference()
            .child("episodes")
            .child(matchId)
            .child("\(photoId).jpg")

        // Compress image
        guard let image = UIImage(data: data),
              let compressedData = image.jpegData(compressionQuality: 0.7) else {
            throw NSError(domain: "StorageManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(compressedData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        print("✅ Episode photo uploaded: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    func uploadMultipleEpisodePhotos(_ photosData: [Data], matchId: String) async throws -> [String] {
        var urls: [String] = []

        for data in photosData {
            let url = try await uploadEpisodePhoto(data, matchId: matchId)
            urls.append(url)
        }

        return urls
    }

    // MARK: - Profile Photos

    func uploadProfilePhoto(_ data: Data, userId: String) async throws -> String {
        let photoId = UUID().uuidString
        let storageRef = storage.reference()
            .child("profiles")
            .child(userId)
            .child("\(photoId).jpg")

        // Compress image
        guard let image = UIImage(data: data),
              let compressedData = image.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "StorageManager", code: 2, userInfo: [NSLocalizedDescriptionKey: "Failed to compress image"])
        }

        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"

        _ = try await storageRef.putDataAsync(compressedData, metadata: metadata)
        let downloadURL = try await storageRef.downloadURL()

        print("✅ Profile photo uploaded: \(downloadURL.absoluteString)")
        return downloadURL.absoluteString
    }

    // MARK: - Delete Operations

    func deleteEpisodePhotos(matchId: String) async throws {
        let folderRef = storage.reference()
            .child("episodes")
            .child(matchId)

        // List all files
        let result = try await folderRef.listAll()

        // Delete each file
        for item in result.items {
            try await item.delete()
        }

        print("✅ Deleted all photos for match: \(matchId)")
    }

    func deletePhoto(url: String) async throws {
        let storageRef = storage.reference(forURL: url)
        try await storageRef.delete()
        print("✅ Deleted photo: \(url)")
    }
}
