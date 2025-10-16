//
//  VendorImageService.swift
//  Campusmealsv2
//
//  Industry-standard image service: Fetch photo references from Firebase, build URLs dynamically
//

import Foundation
import SwiftUI

/// Builds Google Places Photo URLs from photo references
class VendorImageService {
    static let shared = VendorImageService()

    private let apiKey = "YOUR_GOOGLE_API_KEY_HERE"
    private let maxWidth = 800

    private init() {}

    /// Build Google Places Photo URL from photo reference
    func buildPhotoURL(photoReference: String?) -> String? {
        guard let photoRef = photoReference, !photoRef.isEmpty else {
            return nil
        }

        return "https://maps.googleapis.com/maps/api/place/photo?maxwidth=\(maxWidth)&photoreference=\(photoRef)&key=\(apiKey)"
    }

    /// Get fallback image URL based on category and cuisine
    func getFallbackImageURL(category: VendorCategory, cuisine: String?) -> String {
        // Use category-appropriate Unsplash images as fallback
        switch category {
        case .restaurants:
            if let cuisine = cuisine?.lowercased() {
                if cuisine.contains("pizza") || cuisine.contains("italian") {
                    return "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&q=80"
                } else if cuisine.contains("salad") || cuisine.contains("bowl") {
                    return "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80"
                } else if cuisine.contains("vegan") || cuisine.contains("plant") {
                    return "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80"
                } else if cuisine.contains("burger") {
                    return "https://images.unsplash.com/photo-1550547660-d9450f859349?w=800&q=80"
                }
            }
            return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80"

        case .cafes:
            return "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80"

        case .groceries:
            return "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80"

        case .desserts:
            return "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800&q=80"

        case .alcohol:
            return "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800&q=80"

        case .all, .convenience:
            return "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80"
        }
    }
}
