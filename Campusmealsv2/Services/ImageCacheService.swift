//
//  ImageCacheService.swift
//  Campusmealsv2
//
//  Professional image caching service following industry standards
//

import Foundation
import SwiftUI
import UIKit

/// Professional image cache service using NSCache for memory management
class ImageCacheService: ObservableObject {
    static let shared = ImageCacheService()

    private let cache = NSCache<NSString, UIImage>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL

    private init() {
        // Set up disk cache directory
        let paths = fileManager.urls(for: .cachesDirectory, in: .userDomainMask)
        cacheDirectory = paths[0].appendingPathComponent("ImageCache")

        // Create cache directory if needed
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)

        // Configure memory cache
        cache.countLimit = 100 // Max 100 images in memory
        cache.totalCostLimit = 50 * 1024 * 1024 // 50 MB memory limit
    }

    /// Get cached image or download if needed
    func getImage(for urlString: String) async -> UIImage? {
        let cacheKey = NSString(string: urlString)

        // 1. Check memory cache
        if let cachedImage = cache.object(forKey: cacheKey) {
            return cachedImage
        }

        // 2. Check disk cache
        if let diskImage = loadFromDisk(urlString: urlString) {
            cache.setObject(diskImage, forKey: cacheKey)
            return diskImage
        }

        // 3. Download from network
        guard let url = URL(string: urlString) else { return nil }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            guard let image = UIImage(data: data) else { return nil }

            // Save to both caches
            cache.setObject(image, forKey: cacheKey)
            saveToDisk(image: image, urlString: urlString)

            return image
        } catch {
            print("⚠️ Failed to download image: \(error.localizedDescription)")
            return nil
        }
    }

    /// Load image from disk cache
    private func loadFromDisk(urlString: String) -> UIImage? {
        let filename = urlString.sha256Hash()
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard let data = try? Data(contentsOf: fileURL),
              let image = UIImage(data: data) else {
            return nil
        }

        return image
    }

    /// Save image to disk cache
    private func saveToDisk(image: UIImage, urlString: String) {
        let filename = urlString.sha256Hash()
        let fileURL = cacheDirectory.appendingPathComponent(filename)

        guard let data = image.jpegData(compressionQuality: 0.8) else { return }
        try? data.write(to: fileURL)
    }

    /// Clear all caches
    func clearCache() {
        cache.removeAllObjects()
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
}

// MARK: - String Extension for Cache Keys
extension String {
    func sha256Hash() -> String {
        // Simple hash for filenames (you can use CryptoKit for production)
        return String(self.hashValue)
    }
}

// MARK: - Cached Image View
struct CachedAsyncImage<Content: View, Placeholder: View>: View {
    let urlString: String
    let content: (Image) -> Content
    let placeholder: () -> Placeholder

    @State private var uiImage: UIImage?
    @State private var isLoading = false

    init(
        urlString: String,
        @ViewBuilder content: @escaping (Image) -> Content,
        @ViewBuilder placeholder: @escaping () -> Placeholder
    ) {
        self.urlString = urlString
        self.content = content
        self.placeholder = placeholder
    }

    var body: some View {
        Group {
            if let uiImage = uiImage {
                content(Image(uiImage: uiImage))
            } else {
                placeholder()
            }
        }
        .task {
            guard !isLoading else { return }
            isLoading = true

            if let image = await ImageCacheService.shared.getImage(for: urlString) {
                uiImage = image
            }

            isLoading = false
        }
    }
}
