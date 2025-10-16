//
//  GeminiSearchParser.swift
//  Campusmealsv2
//
//  Super fast Gemini AI parser for natural language food searches
//  "spicy ramen under $15" → structured intent
//

import Foundation

@MainActor
class GeminiSearchParser: ObservableObject {
    static let shared = GeminiSearchParser()

    private let apiKey = APIKey.default
    private let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash-latest:generateContent"

    @Published var isParsing = false

    private init() {}

    // MARK: - Parse Natural Language Query
    func parseSearchQuery(_ query: String) async throws -> ParsedFoodIntent {
        print("🤖 Gemini parsing: '\(query)'")
        isParsing = true
        defer { isParsing = false }

        // Quick timeout for fast UX
        let parseTask = Task {
            return try await performParse(query)
        }

        // 3 second timeout
        do {
            return try await withTimeout(seconds: 3) {
                try await parseTask.value
            }
        } catch {
            print("⚠️ Gemini timeout, using fallback parsing")
            return fallbackParse(query)
        }
    }

    // MARK: - Gemini API Call
    private func performParse(_ query: String) async throws -> ParsedFoodIntent {
        let prompt = """
        Parse this food search query into structured data. Return ONLY valid JSON, no markdown, no explanation.

        Query: "\(query)"

        Extract:
        - cuisine: type of food (e.g., "Italian", "Japanese", "Mexican", "Coffee", "Groceries")
        - dishType: specific dish if mentioned (e.g., "ramen", "pizza", "burger")
        - priceRange: "$", "$$", "$$$", or "$$$$" (infer from words like "cheap", "expensive")
        - maxPrice: number if specific price mentioned (e.g., "under $15" → 15)
        - dietaryNeeds: array of strings (e.g., ["vegan", "gluten-free", "healthy"])
        - attributes: array of descriptive words (e.g., ["spicy", "authentic", "quick"])
        - category: "restaurant", "cafe", "grocery", or "dessert"

        Example query: "spicy ramen under $15"
        Example response:
        {
          "cuisine": "Japanese",
          "dishType": "ramen",
          "priceRange": "$",
          "maxPrice": 15,
          "dietaryNeeds": [],
          "attributes": ["spicy"],
          "category": "restaurant"
        }

        Return ONLY the JSON object, nothing else.
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.1, // Very low for consistent parsing
                "maxOutputTokens": 200
            ]
        ]

        guard let jsonData = try? JSONSerialization.data(withJSONObject: requestBody),
              var request = URL(string: "\(apiURL)?key=\(apiKey)").map({ URLRequest(url: $0) }) else {
            throw NSError(domain: "GeminiSearchParser", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to create request"])
        }

        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiSearchParser", code: -2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        // Parse Gemini response
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiSearchParser", code: -3, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        print("   Gemini response: \(text.prefix(200))...")

        // Extract JSON from text (remove markdown if present)
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let parsedData = cleanedText.data(using: .utf8),
              let parsedIntent = try? JSONDecoder().decode(ParsedFoodIntent.self, from: parsedData) else {
            print("⚠️ Failed to decode JSON, using fallback")
            return fallbackParse(query)
        }

        print("✅ Gemini parsed successfully")
        return parsedIntent
    }

    // MARK: - Fallback Parser (Fast, Rule-Based)
    private func fallbackParse(_ query: String) -> ParsedFoodIntent {
        let lower = query.lowercased()

        var cuisine = "Restaurant"
        var dishType: String? = nil
        var priceRange = "$$"
        var maxPrice: Double? = nil
        var dietaryNeeds: [String] = []
        var attributes: [String] = []
        var category = "restaurant"

        // Cuisine detection
        if lower.contains("coffee") || lower.contains("cafe") {
            cuisine = "Coffee"
            category = "cafe"
        } else if lower.contains("grocery") || lower.contains("groceries") {
            cuisine = "Groceries"
            category = "grocery"
        } else if lower.contains("italian") || lower.contains("pizza") || lower.contains("pasta") {
            cuisine = "Italian"
        } else if lower.contains("japanese") || lower.contains("sushi") || lower.contains("ramen") {
            cuisine = "Japanese"
        } else if lower.contains("mexican") || lower.contains("taco") || lower.contains("burrito") {
            cuisine = "Mexican"
        } else if lower.contains("chinese") {
            cuisine = "Chinese"
        } else if lower.contains("thai") {
            cuisine = "Thai"
        } else if lower.contains("indian") {
            cuisine = "Indian"
        }

        // Dish type
        if lower.contains("ramen") { dishType = "ramen" }
        else if lower.contains("pizza") { dishType = "pizza" }
        else if lower.contains("burger") { dishType = "burger" }
        else if lower.contains("sushi") { dishType = "sushi" }
        else if lower.contains("salad") { dishType = "salad" }

        // Price detection
        if lower.contains("cheap") || lower.contains("budget") || lower.contains("affordable") {
            priceRange = "$"
        } else if lower.contains("expensive") || lower.contains("fancy") || lower.contains("upscale") {
            priceRange = "$$$"
        }

        // Extract price number (e.g., "under $15")
        if let priceMatch = lower.range(of: #"\$?\d+"#, options: .regularExpression) {
            let priceStr = String(lower[priceMatch]).replacingOccurrences(of: "$", with: "")
            maxPrice = Double(priceStr)
        }

        // Dietary needs
        if lower.contains("vegan") { dietaryNeeds.append("vegan") }
        if lower.contains("vegetarian") { dietaryNeeds.append("vegetarian") }
        if lower.contains("gluten-free") || lower.contains("gluten free") { dietaryNeeds.append("gluten-free") }
        if lower.contains("healthy") { dietaryNeeds.append("healthy") }
        if lower.contains("keto") { dietaryNeeds.append("keto") }

        // Attributes
        if lower.contains("spicy") { attributes.append("spicy") }
        if lower.contains("authentic") { attributes.append("authentic") }
        if lower.contains("quick") || lower.contains("fast") { attributes.append("quick") }
        if lower.contains("best") { attributes.append("highly-rated") }

        return ParsedFoodIntent(
            cuisine: cuisine,
            dishType: dishType,
            priceRange: priceRange,
            maxPrice: maxPrice,
            dietaryNeeds: dietaryNeeds,
            attributes: attributes,
            category: category
        )
    }

    // MARK: - Timeout Helper
    private func withTimeout<T>(seconds: TimeInterval, operation: @escaping () async throws -> T) async throws -> T {
        try await withThrowingTaskGroup(of: T.self) { group in
            group.addTask {
                try await operation()
            }

            group.addTask {
                try await Task.sleep(nanoseconds: UInt64(seconds * 1_000_000_000))
                throw TimeoutError()
            }

            let result = try await group.next()!
            group.cancelAll()
            return result
        }
    }
}

// MARK: - Models

struct ParsedFoodIntent: Codable {
    var cuisine: String
    var dishType: String?
    var priceRange: String
    var maxPrice: Double?
    var dietaryNeeds: [String]
    var attributes: [String]
    var category: String

    // Helper to convert to FoodIntent
    func toFoodIntent() -> FoodIntent {
        let displayText = generateDisplayText()
        let searchType: SearchType = determineSearchType()
        let filters = SearchFilters(
            maxDistance: 2000,
            maxPrice: maxPrice,
            minRating: 4.0,
            category: category
        )

        return FoodIntent(
            displayText: displayText,
            emoji: getEmoji(),
            searchType: searchType,
            filters: filters
        )
    }

    private func generateDisplayText() -> String {
        var parts: [String] = []

        if !attributes.isEmpty {
            parts.append(attributes.joined(separator: " "))
        }

        if let dish = dishType {
            parts.append(dish)
        } else {
            parts.append(cuisine.lowercased())
        }

        if let price = maxPrice {
            parts.append("under $\(Int(price))")
        } else if priceRange != "$$" {
            parts.append(priceRange)
        }

        parts.append("near me")

        return parts.joined(separator: " ").capitalized
    }

    private func getEmoji() -> String {
        if category == "cafe" { return "☕" }
        if category == "grocery" { return "🛒" }
        if cuisine.contains("Italian") { return "🍝" }
        if cuisine.contains("Japanese") { return "🍜" }
        if cuisine.contains("Mexican") { return "🌮" }
        if dishType == "pizza" { return "🍕" }
        if dishType == "burger" { return "🍔" }
        if dietaryNeeds.contains("healthy") { return "🥗" }
        return "🍽️"
    }

    private func determineSearchType() -> SearchType {
        if category == "cafe" { return .coffee }
        if category == "grocery" { return .groceries }
        if dietaryNeeds.contains("healthy") { return .healthyLunch }
        return .custom
    }
}

struct TimeoutError: Error {}
