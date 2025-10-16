//
//  DetectedFridgeItem.swift
//  Campusmealsv2
//
//  Created by Claude on 04/10/2025.
//

import Foundation

// Item detected by Gemini AI in the fridge
struct DetectedFridgeItem: Identifiable, Codable, Hashable {
    let id: String
    let name: String // e.g., "Steak", "Oranges"
    let quantity: String // e.g., "8 oz", "6 oranges"
    let position: TapZonePosition // Tap zone coordinates
    let emoji: String // Visual representation

    // Optional details
    var category: String? // e.g., "Meat", "Fruit"
    var expiryDays: Int? // Days until expiry
    var confidence: Double? // AI confidence (0-1)

    init(id: String = UUID().uuidString,
         name: String,
         quantity: String,
         position: TapZonePosition,
         emoji: String,
         category: String? = nil,
         expiryDays: Int? = nil,
         confidence: Double? = nil) {
        self.id = id
        self.name = name
        self.quantity = quantity
        self.position = position
        self.emoji = emoji
        self.category = category
        self.expiryDays = expiryDays
        self.confidence = confidence
    }

    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: DetectedFridgeItem, rhs: DetectedFridgeItem) -> Bool {
        lhs.id == rhs.id
    }
}

// Position on fridge image (percentage-based for responsive layout)
struct TapZonePosition: Codable, Equatable, Hashable {
    let x: Double // 0.0 - 1.0 (percentage from left)
    let y: Double // 0.0 - 1.0 (percentage from top)
    let width: Double // Tap zone width (percentage)
    let height: Double // Tap zone height (percentage)

    // Check if a tap point is within this zone
    func contains(point: CGPoint, in size: CGSize) -> Bool {
        let tapX = Double(point.x / size.width)
        let tapY = Double(point.y / size.height)

        return tapX >= x && tapX <= (x + width) &&
               tapY >= y && tapY <= (y + height)
    }
}
