//
//  GeminiVisionService.swift
//  Campusmealsv2
//
//  Created by Claude on 04/10/2025.
//

import Foundation
import UIKit
// Uncomment this line after adding the package:
// import GoogleGenerativeAI

class GeminiVisionService {
    static let shared = GeminiVisionService()

    // Uncomment after adding the Swift package:
    // private var generativeModel: GenerativeModel

    private init() {
        // Uncomment after adding the Swift package:
        // self.generativeModel = GenerativeModel(
        //     name: "gemini-1.5-flash-latest",
        //     apiKey: APIKey.default
        // )
    }

    @MainActor
    func analyzeFood(image: UIImage) async throws -> String {
        // TEMPORARY: Using REST API until you add the Swift package
        // TODO: Replace this with the SDK implementation below

        return try await analyzeFoodWithREST(image: image)

        // ===== UNCOMMENT THIS AFTER ADDING THE PACKAGE =====
        /*
        let prompt = "Analyze this food image and list ONLY the main ingredients needed to cook this dish. Format your response as a simple comma-separated list of ingredients, nothing else. Example: 'Pasta, Tomatoes, Garlic, Olive Oil, Basil'"

        do {
            let response = try await generativeModel.generateContent(prompt, image)

            if let text = response.text {
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else {
                throw NSError(domain: "GeminiVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "No text in response"])
            }
        } catch {
            throw NSError(domain: "GeminiVisionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Failed to analyze: \(error.localizedDescription)"])
        }
        */
    }

    // TEMPORARY REST API METHOD - Remove after adding SDK
    private func analyzeFoodWithREST(image: UIImage) async throws -> String {
        let apiKey = APIKey.default
        // Use the correct model that's available on the free tier
        let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

        // Resize image
        let maxSize: CGFloat = 800
        let resizedImage: UIImage
        if image.size.width > maxSize || image.size.height > maxSize {
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.5) else {
            throw NSError(domain: "GeminiVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        let base64Image = imageData.base64EncodedString()

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": "Analyze this food image and list ONLY the main ingredients needed to cook this dish. Format your response as a simple comma-separated list."
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiVisionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            let errorMessage = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw NSError(domain: "GeminiVisionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "API failed: \(errorMessage)"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiVisionService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        return text.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: - Analyze Fridge Contents
    func analyzeFridge(image: UIImage) async throws -> [DetectedFridgeItem] {
        let apiKey = APIKey.default
        // Use Gemini Flash
        let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

        // Resize image for better segmentation (higher resolution + quality)
        let maxSize: CGFloat = 1024 // Increased from 800 for better accuracy
        let resizedImage: UIImage
        if image.size.width > maxSize || image.size.height > maxSize {
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }

        // Higher compression quality for better segmentation accuracy
        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "GeminiVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        print("📸 Image size for segmentation: \(resizedImage.size.width)x\(resizedImage.size.height)")

        let base64Image = imageData.base64EncodedString()

        // Enhanced segmentation prompt with explicit pixel calculation instructions
        let prompt = """
        You are an advanced computer vision model performing SEMANTIC SEGMENTATION on food items.

        TASK: Identify and segment the 4-6 LARGEST, most prominent food items in this fridge image.

        For each food item, you MUST:
        1. Perform pixel-level segmentation to find exact boundaries
        2. Calculate the TIGHT bounding box around the segmented region
        3. Convert to normalized coordinates (0.0 to 1.0)

        COORDINATE SYSTEM:
        - Image origin (0,0) is at TOP-LEFT corner
        - x increases rightward (0.0 = left edge, 1.0 = right edge)
        - y increases downward (0.0 = top edge, 1.0 = bottom edge)
        - x = leftmost_pixel / image_width
        - y = topmost_pixel / image_height
        - width = box_width / image_width
        - height = box_height / image_height

        Return ONLY valid JSON (no markdown):
        [
          {
            "name": "Oranges",
            "quantity": "6 oranges",
            "x": 0.12,
            "y": 0.08,
            "width": 0.35,
            "height": 0.28,
            "category": "Fruit"
          }
        ]

        STRICT RULES:
        - Maximum 6 items (only the MOST VISIBLE ones)
        - Only include: steak, oranges, milk, avocados, large vegetables, large packages
        - NO small items (condiments, spices, tiny bottles)
        - Bounding boxes must be TIGHT around the actual food
        - Double-check x,y coordinates - must align with actual position in image
        - All values must be between 0.0 and 1.0
        - No overlapping bounding boxes
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiVisionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        // Check HTTP response
        if let httpResponse = response as? HTTPURLResponse {
            print("🌐 HTTP Status: \(httpResponse.statusCode)")
            if httpResponse.statusCode != 200 {
                let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
                print("❌ API Error: \(errorText)")
                throw NSError(domain: "GeminiVisionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "API Error: \(errorText)"])
            }
        }

        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("❌ Failed to parse JSON")
            throw NSError(domain: "GeminiVisionService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Invalid JSON response"])
        }

        print("📦 Full response: \(json)")

        guard let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("❌ Failed to extract text from response structure")
            print("Response keys: \(json.keys)")
            throw NSError(domain: "GeminiVisionService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        print("📝 Gemini response text: \(text)")

        // Extract JSON from response (may have markdown wrapper)
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        // Parse JSON array
        guard let jsonData = cleanedText.data(using: String.Encoding.utf8),
              let itemsArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw NSError(domain: "GeminiVisionService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse items JSON"])
        }

        // Convert to DetectedFridgeItem objects
        var detectedItems: [DetectedFridgeItem] = []

        for itemDict in itemsArray {
            guard let name = itemDict["name"] as? String,
                  let quantity = itemDict["quantity"] as? String,
                  let x = itemDict["x"] as? Double,
                  let y = itemDict["y"] as? Double,
                  let width = itemDict["width"] as? Double,
                  let height = itemDict["height"] as? Double else {
                print("⚠️ Skipping invalid item: \(itemDict)")
                continue
            }

            let category = itemDict["category"] as? String
            let position = TapZonePosition(x: x, y: y, width: width, height: height)
            let emoji = getEmojiForFood(name)

            let item = DetectedFridgeItem(
                name: name,
                quantity: quantity,
                position: position,
                emoji: emoji,
                category: category
            )

            print("✅ Item: \(name) at x:\(x) y:\(y) w:\(width) h:\(height)")
            detectedItems.append(item)
        }

        print("📦 Total items detected: \(detectedItems.count)")
        return detectedItems
    }

    // MARK: - Generate Recipes Based on Fridge Contents
    func generateRecipes(from fridgeItems: [DetectedFridgeItem]) async throws -> [Recipe] {
        let apiKey = APIKey.default
        let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

        // Get current time of day
        let hour = Calendar.current.component(.hour, from: Date())
        let mealType: String
        if hour >= 5 && hour < 11 {
            mealType = "Breakfast"
        } else if hour >= 11 && hour < 16 {
            mealType = "Lunch"
        } else {
            mealType = "Dinner"
        }

        // Extract ingredient names
        let ingredients = fridgeItems.map { $0.name }.joined(separator: ", ")

        let prompt = """
        3 quick \(mealType) recipes using: \(ingredients)

        JSON only:
        [{"name":"Steak & Eggs","description":"","emojiCombo":"🥩🍳","cookTime":"12 min","protein":"42g","calories":"520","difficulty":"Easy","mealType":"\(mealType)","ingredients":["steak","eggs"],"instructions":["Cook steak","Fry eggs"],"isRecommended":true}]

        Rules: <15min, simple, name+emoji+time only
        """

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiVisionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
            let errorText = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("❌ Recipe API Error: \\(errorText)")
            throw NSError(domain: "GeminiVisionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "API Error"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            throw NSError(domain: "GeminiVisionService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        // Clean JSON
        let cleanedText = text
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)

        // Parse recipes
        guard let jsonData = cleanedText.data(using: String.Encoding.utf8),
              let recipesArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] else {
            throw NSError(domain: "GeminiVisionService", code: -5, userInfo: [NSLocalizedDescriptionKey: "Failed to parse recipes JSON"])
        }

        var recipes: [Recipe] = []
        for recipeDict in recipesArray {
            guard let name = recipeDict["name"] as? String,
                  let description = recipeDict["description"] as? String,
                  let emojiCombo = recipeDict["emojiCombo"] as? String,
                  let cookTime = recipeDict["cookTime"] as? String,
                  let protein = recipeDict["protein"] as? String,
                  let calories = recipeDict["calories"] as? String,
                  let difficulty = recipeDict["difficulty"] as? String,
                  let mealType = recipeDict["mealType"] as? String,
                  let ingredients = recipeDict["ingredients"] as? [String],
                  let instructions = recipeDict["instructions"] as? [String] else {
                continue
            }

            let isRecommended = recipeDict["isRecommended"] as? Bool ?? false

            let recipe = Recipe(
                name: name,
                description: description,
                emojiCombo: emojiCombo,
                cookTime: cookTime,
                protein: protein,
                calories: calories,
                difficulty: difficulty,
                mealType: mealType,
                ingredients: ingredients,
                instructions: instructions,
                isRecommended: isRecommended
            )

            recipes.append(recipe)
            print("✅ Recipe: \\(name) | \\(emojiCombo) | \\(cookTime)")
        }

        return recipes
    }

    // Get emoji for food item
    private func getEmojiForFood(_ food: String) -> String {
        let lowercased = food.lowercased()

        // Meats
        if lowercased.contains("steak") || lowercased.contains("beef") { return "🥩" }
        if lowercased.contains("chicken") { return "🍗" }
        if lowercased.contains("pork") { return "🥓" }
        if lowercased.contains("fish") { return "🐟" }

        // Fruits
        if lowercased.contains("orange") { return "🍊" }
        if lowercased.contains("apple") { return "🍎" }
        if lowercased.contains("banana") { return "🍌" }
        if lowercased.contains("lemon") { return "🍋" }

        // Vegetables
        if lowercased.contains("carrot") { return "🥕" }
        if lowercased.contains("broccoli") { return "🥦" }
        if lowercased.contains("tomato") { return "🍅" }
        if lowercased.contains("lettuce") { return "🥬" }

        // Dairy
        if lowercased.contains("milk") { return "🥛" }
        if lowercased.contains("cheese") { return "🧀" }
        if lowercased.contains("egg") { return "🥚" }
        if lowercased.contains("butter") { return "🧈" }

        // Default
        return "🍽️"
    }

    // MARK: - Match Food Photo to Menu Item
    func matchFoodToMenuItem(image: UIImage, menuItems: [String]) async throws -> String {
        let apiKey = APIKey.default
        let apiURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-flash-latest:generateContent"

        // Resize image for better quality
        let maxSize: CGFloat = 1024
        let resizedImage: UIImage
        if image.size.width > maxSize || image.size.height > maxSize {
            let scale = min(maxSize / image.size.width, maxSize / image.size.height)
            let newSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
            image.draw(in: CGRect(origin: .zero, size: newSize))
            resizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
            UIGraphicsEndImageContext()
        } else {
            resizedImage = image
        }

        guard let imageData = resizedImage.jpegData(compressionQuality: 0.8) else {
            throw NSError(domain: "GeminiVisionService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert image"])
        }

        let base64Image = imageData.base64EncodedString()

        // Create numbered menu list for better matching
        let menuList = menuItems.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")

        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        [
                            "text": """
                            What food dish do you see in this photo? Name it in 2-4 words maximum.

                            Response format: Just the dish name, nothing else.
                            Examples: "Pepperoni Pizza", "Caesar Salad", "Chicken Burger"
                            """
                        ],
                        [
                            "inline_data": [
                                "mime_type": "image/jpeg",
                                "data": base64Image
                            ]
                        ]
                    ]
                ]
            ]
        ]

        guard let url = URL(string: "\(apiURL)?key=\(apiKey)") else {
            throw NSError(domain: "GeminiVisionService", code: -2, userInfo: [NSLocalizedDescriptionKey: "Invalid URL"])
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "GeminiVisionService", code: -3, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let content = candidates.first?["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let text = parts.first?["text"] as? String else {
            throw NSError(domain: "GeminiVisionService", code: -4, userInfo: [NSLocalizedDescriptionKey: "Failed to parse response"])
        }

        var result = text.trimmingCharacters(in: .whitespacesAndNewlines)

        // Clean up formatting
        result = result
            .replacingOccurrences(of: "\"", with: "")
            .replacingOccurrences(of: "*", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        print("✅ Gemini identified: '\(result)'")
        return result
    }
}
