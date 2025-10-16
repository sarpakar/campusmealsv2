//
//  SocialMediaDeepLinkService.swift
//  Campusmealsv2
//
//  Created by sarp akar on 11/10/2025.
//
//  Apple-quality service for opening social media content in native apps
//  Handles TikTok, Instagram, and YouTube deep linking with intelligent fallbacks
//

import Foundation
import UIKit

@MainActor
class SocialMediaDeepLinkService {
    static let shared = SocialMediaDeepLinkService()

    private init() {}

    // MARK: - Public API

    /// Opens a social video, attempting native app first, then falling back to web
    /// - Parameters:
    ///   - video: The social video to open
    ///   - presentingViewController: The view controller to present alerts from
    func openVideo(_ video: SocialVideo, from presentingViewController: UIViewController?) async {
        switch video.platform {
        case .tiktok:
            await openTikTok(video: video, from: presentingViewController)
        case .instagram:
            await openInstagram(video: video, from: presentingViewController)
        case .youtube:
            await openYouTube(video: video, from: presentingViewController)
        }
    }

    // MARK: - TikTok Deep Linking

    private func openTikTok(video: SocialVideo, from presentingViewController: UIViewController?) async {
        // Extract video ID from URL
        guard let videoId = extractTikTokVideoId(from: video.videoURL) else {
            print("❌ Failed to extract TikTok video ID from: \(video.videoURL)")
            await openInBrowser(url: video.videoURL)
            return
        }

        // Try multiple TikTok deep link formats
        let deepLinks = [
            "snssdk1233://aweme/detail/\(videoId)",  // Primary TikTok international
            "tiktok://video/\(videoId)",              // Alternative format
            "musically://video/\(videoId)"            // TikTok US format
        ]

        // Check if TikTok app is installed
        let isTikTokInstalled = deepLinks.contains { urlString in
            guard let url = URL(string: urlString) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }

        if isTikTokInstalled {
            // Open in TikTok app
            for deepLinkString in deepLinks {
                if let deepLinkURL = URL(string: deepLinkString),
                   UIApplication.shared.canOpenURL(deepLinkURL) {
                    print("✅ Opening TikTok video \(videoId) in native app")
                    await UIApplication.shared.open(deepLinkURL)
                    return
                }
            }
        }

        // Fallback: Open in Safari (better than in-app WebView)
        print("⚠️ TikTok app not installed, opening in Safari")
        await openInBrowser(url: video.videoURL)
    }

    // MARK: - Instagram Deep Linking

    private func openInstagram(video: SocialVideo, from presentingViewController: UIViewController?) async {
        // Extract video ID from URL
        guard let videoId = extractInstagramVideoId(from: video.videoURL) else {
            print("❌ Failed to extract Instagram video ID from: \(video.videoURL)")
            await openInBrowser(url: video.videoURL)
            return
        }

        // Instagram deep link formats
        let deepLinks = [
            "instagram://media?id=\(videoId)",
            "instagram://reel?id=\(videoId)"
        ]

        // Check if Instagram app is installed
        if let deepLinkString = deepLinks.first,
           let deepLinkURL = URL(string: deepLinkString),
           UIApplication.shared.canOpenURL(deepLinkURL) {
            print("✅ Opening Instagram reel \(videoId) in native app")
            await UIApplication.shared.open(deepLinkURL)
            return
        }

        // Fallback: Open in Safari
        print("⚠️ Instagram app not installed, opening in Safari")
        await openInBrowser(url: video.videoURL)
    }

    // MARK: - YouTube Deep Linking

    private func openYouTube(video: SocialVideo, from presentingViewController: UIViewController?) async {
        // Extract video ID from URL
        guard let videoId = extractYouTubeVideoId(from: video.videoURL) else {
            print("❌ Failed to extract YouTube video ID from: \(video.videoURL)")
            await openInBrowser(url: video.videoURL)
            return
        }

        // YouTube deep link
        let deepLinkString = "youtube://watch?v=\(videoId)"

        // Check if YouTube app is installed
        if let deepLinkURL = URL(string: deepLinkString),
           UIApplication.shared.canOpenURL(deepLinkURL) {
            print("✅ Opening YouTube video \(videoId) in native app")
            await UIApplication.shared.open(deepLinkURL)
            return
        }

        // Fallback: Open in Safari
        print("⚠️ YouTube app not installed, opening in Safari")
        await openInBrowser(url: video.videoURL)
    }

    // MARK: - Helper Methods

    private func openInBrowser(url: String) async {
        guard let webURL = URL(string: url) else {
            print("❌ Invalid URL: \(url)")
            return
        }

        await UIApplication.shared.open(webURL)
    }

    /// Extract TikTok video ID from various URL formats
    /// Supports: https://www.tiktok.com/@user/video/7234567890
    ///           https://vm.tiktok.com/ZMhQqXYZ/
    private func extractTikTokVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        // Format 1: Standard format (@user/video/ID)
        let pathComponents = url.pathComponents
        if let videoIndex = pathComponents.firstIndex(of: "video"),
           videoIndex + 1 < pathComponents.count {
            return pathComponents[videoIndex + 1]
        }

        // Format 2: Short link (vm.tiktok.com)
        if url.host?.contains("vm.tiktok.com") == true {
            // The short code is in the path
            let shortCode = url.lastPathComponent
            return shortCode
        }

        return nil
    }

    /// Extract Instagram video ID from URL
    /// Supports: https://www.instagram.com/reel/ABC123/
    ///           https://www.instagram.com/p/ABC123/
    private func extractInstagramVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        let pathComponents = url.pathComponents
        if let reelIndex = pathComponents.firstIndex(where: { $0 == "reel" || $0 == "p" }),
           reelIndex + 1 < pathComponents.count {
            return pathComponents[reelIndex + 1]
        }

        return nil
    }

    /// Extract YouTube video ID from URL
    /// Supports: https://www.youtube.com/watch?v=VIDEO_ID
    ///           https://youtu.be/VIDEO_ID
    private func extractYouTubeVideoId(from urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        // Short format: youtu.be/VIDEO_ID
        if url.host?.contains("youtu.be") == true {
            return url.lastPathComponent
        }

        // Standard format: youtube.com/watch?v=VIDEO_ID
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoId
        }

        return nil
    }

    // MARK: - App Availability Check

    /// Check if a social media app is installed
    func isAppInstalled(for platform: SocialPlatform) -> Bool {
        let urlSchemes: [String]

        switch platform {
        case .tiktok:
            urlSchemes = ["snssdk1233://", "tiktok://", "musically://"]
        case .instagram:
            urlSchemes = ["instagram://"]
        case .youtube:
            urlSchemes = ["youtube://"]
        }

        for scheme in urlSchemes {
            if let url = URL(string: scheme),
               UIApplication.shared.canOpenURL(url) {
                return true
            }
        }

        return false
    }

    /// Get user-friendly app name
    func appName(for platform: SocialPlatform) -> String {
        switch platform {
        case .tiktok: return "TikTok"
        case .instagram: return "Instagram"
        case .youtube: return "YouTube"
        }
    }
}
