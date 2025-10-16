//
//  GoogleSearchService.swift
//  Campusmealsv2
//
//  Google Custom Search API service for finding TikTok videos
//  Automatically discovers videos for any restaurant
//

import Foundation

@MainActor
class GoogleSearchService {
    static let shared = GoogleSearchService()

    private init() {}

    // MARK: - Configuration

    // TODO: Add your Google API Key to GenerativeAI-Info.plist
    private let apiKey = "YOUR_GOOGLE_API_KEY_HERE"

    // Search Engine ID - Configured and ready!
    private let searchEngineID = "8195c0dbb07694294"

    // MARK: - Public API

    /// Search Google for TikTok videos about a restaurant
    /// Returns array of TikTok video URLs
    func searchTikTokVideos(for restaurantName: String, location: String = "NYC") async -> [String] {
        // Build search query
        let query = "site:tiktok.com \(restaurantName) \(location) food review"

        print("🔍 Searching Google for: \(query)")

        do {
            let results = await performGoogleSearch(query: query)
            let tiktokURLs = extractTikTokURLs(from: results)

            print("✅ Found \(tiktokURLs.count) TikTok videos for \(restaurantName)")
            return Array(tiktokURLs.prefix(3)) // Return top 3

        } catch {
            print("❌ Google Search failed: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Google Search Implementation

    private func performGoogleSearch(query: String) async -> [SearchResult] {
        // If Search Engine ID not configured, return empty (will use fallback)
        guard searchEngineID != "YOUR_SEARCH_ENGINE_ID_HERE" else {
            print("⚠️ Google Search Engine ID not configured")
            print("   Using fallback video database instead")
            return []
        }

        // Build Google Custom Search API URL
        var components = URLComponents(string: "https://www.googleapis.com/customsearch/v1")!
        components.queryItems = [
            URLQueryItem(name: "key", value: apiKey),
            URLQueryItem(name: "cx", value: searchEngineID),
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "num", value: "10") // Get 10 results
        ]

        guard let url = components.url else {
            print("❌ Failed to build search URL")
            return []
        }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)

            // Check HTTP response
            if let httpResponse = response as? HTTPURLResponse {
                print("📡 Google Search API Response: \(httpResponse.statusCode)")

                if httpResponse.statusCode != 200 {
                    if let errorString = String(data: data, encoding: .utf8) {
                        print("❌ API Error Response: \(errorString)")
                    }
                    return []
                }
            }

            // Parse JSON response
            let searchResponse = try JSONDecoder().decode(GoogleSearchResponse.self, from: data)

            print("✅ Retrieved \(searchResponse.items?.count ?? 0) search results")
            return searchResponse.items ?? []

        } catch {
            print("❌ Google Search error: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - URL Extraction

    private func extractTikTokURLs(from results: [SearchResult]) -> [String] {
        var urls: [String] = []

        for result in results {
            // Check if URL is a valid TikTok video URL
            if let url = result.link,
               url.contains("tiktok.com"),
               (url.contains("/video/") || url.contains("/@")) {

                // Clean up URL (remove query parameters, etc.)
                if let cleanURL = cleanTikTokURL(url) {
                    urls.append(cleanURL)
                    print("   📹 Found: \(result.title ?? "Untitled")")
                }
            }
        }

        return urls
    }

    private func cleanTikTokURL(_ urlString: String) -> String? {
        guard let url = URL(string: urlString) else { return nil }

        // Remove query parameters for cleaner URLs
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.query = nil
        components?.fragment = nil

        return components?.url?.absoluteString
    }
}

// MARK: - Response Models

struct GoogleSearchResponse: Codable {
    let items: [SearchResult]?
    let searchInformation: SearchInformation?
}

struct SearchResult: Codable {
    let title: String?
    let link: String?
    let snippet: String?
    let displayLink: String?
}

struct SearchInformation: Codable {
    let totalResults: String?
    let searchTime: Double?
}
