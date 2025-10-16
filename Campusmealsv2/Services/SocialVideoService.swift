//
//  SocialVideoService.swift
//  Campusmealsv2
//
//  Service to fetch real video metadata, thumbnails, and embeddings from social platforms
//  Apple-quality implementation with proper error handling
//

import Foundation

@MainActor
class SocialVideoService {
    static let shared = SocialVideoService()

    private init() {}

    // MARK: - Public API

    /// Fetch video metadata from URL (TikTok, Instagram, YouTube)
    /// Returns SocialVideo with real thumbnail and embed URL
    func fetchVideoMetadata(from url: String) async throws -> SocialVideo {
        guard let videoURL = URL(string: url) else {
            throw VideoServiceError.invalidURL
        }

        let platform = detectPlatform(from: videoURL)

        switch platform {
        case .tiktok:
            return try await fetchTikTokVideo(url: videoURL)
        case .instagram:
            return try await fetchInstagramVideo(url: videoURL)
        case .youtube:
            return try await fetchYouTubeVideo(url: videoURL)
        }
    }

    // MARK: - Platform Detection

    private func detectPlatform(from url: URL) -> SocialPlatform {
        let host = url.host?.lowercased() ?? ""

        if host.contains("tiktok.com") {
            return .tiktok
        } else if host.contains("instagram.com") {
            return .instagram
        } else if host.contains("youtube.com") || host.contains("youtu.be") {
            return .youtube
        }

        return .youtube // Default fallback
    }

    // MARK: - TikTok

    /// Fetch TikTok video using oEmbed API
    /// Endpoint: https://www.tiktok.com/oembed?url={video_url}
    private func fetchTikTokVideo(url: URL) async throws -> SocialVideo {
        let videoId = extractTikTokVideoId(from: url)

        // Build oEmbed URL
        var components = URLComponents(string: "https://www.tiktok.com/oembed")!
        components.queryItems = [URLQueryItem(name: "url", value: url.absoluteString)]

        guard let oembedURL = components.url else {
            throw VideoServiceError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: oembedURL)

            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📱 TikTok oEmbed Response:")
                print(jsonString)
            }

            let response = try JSONDecoder().decode(TikTokOEmbedResponse.self, from: data)

            // Extract thumbnail from HTML if not provided directly
            var thumbnailURL = response.thumbnailUrl
            if thumbnailURL == nil {
                // Try to extract thumbnail from the HTML embed code
                thumbnailURL = extractThumbnailFromHTML(response.html)
            }

            print("✅ TikTok video loaded: \(response.title)")
            print("   Thumbnail URL: \(thumbnailURL ?? "none")")

            return SocialVideo(
                id: videoId,
                platform: .tiktok,
                videoURL: url.absoluteString,
                thumbnailURL: thumbnailURL,
                title: response.title,
                views: nil,
                embedURL: url.absoluteString
            )
        } catch {
            print("⚠️ TikTok oEmbed failed: \(error.localizedDescription)")
            print("   URL attempted: \(oembedURL.absoluteString)")
            return createFallbackTikTokVideo(url: url, videoId: videoId)
        }
    }

    private func extractTikTokVideoId(from url: URL) -> String {
        // Extract from URL like: https://www.tiktok.com/@user/video/7234567890
        let pathComponents = url.pathComponents
        if let videoIndex = pathComponents.firstIndex(of: "video"),
           videoIndex + 1 < pathComponents.count {
            let videoId = pathComponents[videoIndex + 1]
            // Remove any query parameters or trailing slashes
            return videoId.components(separatedBy: "?").first ?? videoId
        }

        // Handle short URLs like vm.tiktok.com
        if url.host?.contains("vm.tiktok.com") == true {
            return url.lastPathComponent
        }

        return UUID().uuidString
    }

    /// Extract thumbnail URL from TikTok oEmbed HTML response
    private func extractThumbnailFromHTML(_ html: String) -> String? {
        // TikTok embed HTML contains data-video-id and other attributes
        // Look for common thumbnail patterns in the HTML

        // Pattern 1: Look for style="background-image:url(...)
        if let range = html.range(of: "background-image:url\\(([^)]+)\\)", options: .regularExpression) {
            let match = String(html[range])
            if let urlRange = match.range(of: "https://[^)]+") {
                return String(match[urlRange])
            }
        }

        // Pattern 2: Look for poster attribute
        if let range = html.range(of: "poster=\"([^\"]+)\"", options: .regularExpression) {
            let match = String(html[range])
            if let urlRange = match.range(of: "https://[^\"]+") {
                return String(match[urlRange])
            }
        }

        return nil
    }

    private func createFallbackTikTokVideo(url: URL, videoId: String) -> SocialVideo {
        return SocialVideo(
            id: videoId,
            platform: .tiktok,
            videoURL: url.absoluteString,
            thumbnailURL: nil, // Will use platform gradient background
            title: "TikTok Video",
            views: nil,
            embedURL: url.absoluteString
        )
    }

    // MARK: - Instagram

    /// Fetch Instagram video using oEmbed API
    /// Note: Instagram oEmbed requires Facebook access token for reliable use
    /// Endpoint: https://graph.facebook.com/v18.0/instagram_oembed?url={url}
    private func fetchInstagramVideo(url: URL) async throws -> SocialVideo {
        let videoId = extractInstagramVideoId(from: url)

        // Try public oEmbed endpoint (may have limitations)
        var components = URLComponents(string: "https://graph.facebook.com/v18.0/instagram_oembed")!
        components.queryItems = [
            URLQueryItem(name: "url", value: url.absoluteString),
            URLQueryItem(name: "maxwidth", value: "320")
        ]

        guard let oembedURL = components.url else {
            throw VideoServiceError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: oembedURL)

            // Debug: Print raw response
            if let jsonString = String(data: data, encoding: .utf8) {
                print("📸 Instagram oEmbed Response:")
                print(jsonString)
            }

            let response = try JSONDecoder().decode(InstagramOEmbedResponse.self, from: data)

            print("✅ Instagram video loaded: \(response.title ?? "Instagram Reel")")
            print("   Thumbnail URL: \(response.thumbnailUrl ?? "none")")

            return SocialVideo(
                id: videoId,
                platform: .instagram,
                videoURL: url.absoluteString,
                thumbnailURL: response.thumbnailUrl,
                title: response.title ?? "Instagram Reel",
                views: nil,
                embedURL: url.absoluteString
            )
        } catch {
            print("⚠️ Instagram oEmbed failed: \(error.localizedDescription)")
            print("   URL attempted: \(oembedURL.absoluteString)")
            return createFallbackInstagramVideo(url: url, videoId: videoId)
        }
    }

    private func extractInstagramVideoId(from url: URL) -> String {
        // Extract from URL like: https://www.instagram.com/reel/ABC123/ or /p/ABC123/
        let pathComponents = url.pathComponents
        if let reelIndex = pathComponents.firstIndex(where: { $0 == "reel" || $0 == "p" }),
           reelIndex + 1 < pathComponents.count {
            return pathComponents[reelIndex + 1]
        }
        return UUID().uuidString
    }

    private func createFallbackInstagramVideo(url: URL, videoId: String) -> SocialVideo {
        return SocialVideo(
            id: videoId,
            platform: .instagram,
            videoURL: url.absoluteString,
            thumbnailURL: nil, // Will use platform icon
            title: "Instagram Reel",
            views: nil,
            embedURL: url.absoluteString // Use original URL
        )
    }

    // MARK: - YouTube

    /// Fetch YouTube video using Data API v3
    /// Endpoint: https://www.googleapis.com/youtube/v3/videos?part=snippet,statistics
    private func fetchYouTubeVideo(url: URL) async throws -> SocialVideo {
        let videoId = extractYouTubeVideoId(from: url)
        let apiKey = "AIzaSyB6GvIr0em_xyPExHyz3T4G9gh0cK-fNts" // Your existing Google API key

        // Build YouTube Data API URL
        var components = URLComponents(string: "https://www.googleapis.com/youtube/v3/videos")!
        components.queryItems = [
            URLQueryItem(name: "part", value: "snippet,statistics"),
            URLQueryItem(name: "id", value: videoId),
            URLQueryItem(name: "key", value: apiKey)
        ]

        guard let apiURL = components.url else {
            throw VideoServiceError.invalidURL
        }

        do {
            let (data, _) = try await URLSession.shared.data(from: apiURL)
            let response = try JSONDecoder().decode(YouTubeAPIResponse.self, from: data)

            guard let video = response.items.first else {
                throw VideoServiceError.videoNotFound
            }

            // YouTube provides multiple thumbnail sizes
            let thumbnailURL = video.snippet.thumbnails.high?.url
                ?? video.snippet.thumbnails.medium?.url
                ?? video.snippet.thumbnails.default.url

            let viewCount = Int(video.statistics.viewCount) ?? 0

            print("✅ YouTube video loaded: \(video.snippet.title)")
            print("   Video ID: \(videoId)")
            print("   Thumbnail: \(thumbnailURL)")
            print("   Views: \(viewCount)")

            return SocialVideo(
                id: videoId,
                platform: .youtube,
                videoURL: url.absoluteString,
                thumbnailURL: thumbnailURL,
                title: video.snippet.title,
                views: viewCount,
                embedURL: "https://www.youtube.com/embed/\(videoId)?autoplay=0&rel=0"
            )
        } catch {
            print("⚠️ YouTube API failed: \(error), using fallback")
            return createFallbackYouTubeVideo(url: url, videoId: videoId)
        }
    }

    private func extractYouTubeVideoId(from url: URL) -> String {
        // Extract from various YouTube URL formats:
        // https://www.youtube.com/watch?v=VIDEO_ID
        // https://youtu.be/VIDEO_ID

        if url.host?.contains("youtu.be") == true {
            // Short format: youtu.be/VIDEO_ID
            return url.lastPathComponent
        }

        // Standard format: youtube.com/watch?v=VIDEO_ID
        if let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
           let videoId = components.queryItems?.first(where: { $0.name == "v" })?.value {
            return videoId
        }

        return UUID().uuidString
    }

    private func createFallbackYouTubeVideo(url: URL, videoId: String) -> SocialVideo {
        // YouTube has predictable thumbnail URLs - try multiple quality options
        // maxresdefault.jpg (1920x1080) - not always available
        // sddefault.jpg (640x480) - standard quality
        // hqdefault.jpg (480x360) - high quality, always available
        // mqdefault.jpg (320x180) - medium quality
        // default.jpg (120x90) - low quality

        let thumbnailURL = "https://img.youtube.com/vi/\(videoId)/hqdefault.jpg"

        print("⚠️ Using YouTube fallback")
        print("   Video ID: \(videoId)")
        print("   Thumbnail: \(thumbnailURL)")

        return SocialVideo(
            id: videoId,
            platform: .youtube,
            videoURL: url.absoluteString,
            thumbnailURL: thumbnailURL,
            title: "YouTube Video",
            views: nil,
            embedURL: "https://www.youtube.com/embed/\(videoId)?autoplay=0&rel=0"
        )
    }
}

// MARK: - Error Types

enum VideoServiceError: LocalizedError {
    case invalidURL
    case videoNotFound
    case apiError(String)
    case unsupportedPlatform

    var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid video URL"
        case .videoNotFound:
            return "Video not found"
        case .apiError(let message):
            return "API Error: \(message)"
        case .unsupportedPlatform:
            return "Unsupported platform"
        }
    }
}

// MARK: - API Response Models

// TikTok oEmbed Response
private struct TikTokOEmbedResponse: Codable {
    let version: String
    let type: String
    let title: String
    let authorName: String
    let thumbnailUrl: String?  // Optional since TikTok may not always provide it
    let thumbnailWidth: Int?
    let thumbnailHeight: Int?
    let html: String

    enum CodingKeys: String, CodingKey {
        case version, type, title
        case authorName = "author_name"
        case thumbnailUrl = "thumbnail_url"
        case thumbnailWidth = "thumbnail_width"
        case thumbnailHeight = "thumbnail_height"
        case html
    }
}

// Instagram oEmbed Response
private struct InstagramOEmbedResponse: Codable {
    let version: String
    let title: String?
    let authorName: String?
    let thumbnailUrl: String?
    let html: String?

    enum CodingKeys: String, CodingKey {
        case version, title
        case authorName = "author_name"
        case thumbnailUrl = "thumbnail_url"
        case html
    }
}

// YouTube Data API Response
private struct YouTubeAPIResponse: Codable {
    let items: [YouTubeVideo]
}

private struct YouTubeVideo: Codable {
    let id: String
    let snippet: YouTubeSnippet
    let statistics: YouTubeStatistics
}

private struct YouTubeSnippet: Codable {
    let title: String
    let description: String
    let thumbnails: YouTubeThumbnails
}

private struct YouTubeThumbnails: Codable {
    let `default`: YouTubeThumbnail
    let medium: YouTubeThumbnail?
    let high: YouTubeThumbnail?
    let standard: YouTubeThumbnail?
    let maxres: YouTubeThumbnail?
}

private struct YouTubeThumbnail: Codable {
    let url: String
    let width: Int?
    let height: Int?
}

private struct YouTubeStatistics: Codable {
    let viewCount: String
    let likeCount: String?
    let commentCount: String?
}
