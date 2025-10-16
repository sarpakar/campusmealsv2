//
//  GooglePlacesService.swift
//  Campusmealsv2
//
//  Fetch real venues using Google Places API
//

import Foundation
import CoreLocation

@MainActor
class GooglePlacesService: ObservableObject {
    static let shared = GooglePlacesService()

    private let apiKey = "AIzaSyB6GvIr0em_xyPExHyz3T4G9gh0cK-fNts"
    private let baseURL = "https://maps.googleapis.com/maps/api/place/nearbysearch/json"

    @Published var vendors: [Vendor] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private init() {}

    // Fetch venues near location
    func fetchNearbyVendors(location: CLLocation, radius: Int = 500, type: String? = nil) async {
        isLoading = true
        errorMessage = nil

        print("🌍 Google Places API Request:")
        print("   Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("   Radius: \(radius)m")

        // Build URL - fetch only 5 places
        var urlString = "\(baseURL)?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&radius=\(radius)&key=\(apiKey)&type=restaurant"

        guard let url = URL(string: urlString) else {
            errorMessage = "Invalid URL"
            isLoading = false
            return
        }

        do {
            print("   URL: \(urlString)")
            let (data, response) = try await URLSession.shared.data(from: url)

            // Debug: Print response
            if let httpResponse = response as? HTTPURLResponse {
                print("   HTTP Status: \(httpResponse.statusCode)")
            }

            // Print raw JSON for debugging
            if let jsonString = String(data: data, encoding: .utf8) {
                print("   Raw Response: \(jsonString.prefix(500))")
            }

            let placesResponse = try JSONDecoder().decode(PlacesResponse.self, from: data)
            print("   Status: \(placesResponse.status)")
            print("   Results count: \(placesResponse.results.count)")

            // Convert to Vendor objects - only top 5
            let newVendors = placesResponse.results
                .prefix(5)
                .map { place in
                    print("   Converting: \(place.name)")
                    return convertToVendor(place, userLocation: location)
                }

            vendors = Array(newVendors)
            isLoading = false

            print("✅ Loaded \(vendors.count) venues from Google Places API")
            if !vendors.isEmpty {
                print("   Venues: \(vendors.map { $0.name }.joined(separator: ", "))")
            }

        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
            print("❌ Google Places error: \(error)")
            print("   Error details: \(error.localizedDescription)")
        }
    }

    // Helper: Fetch by specific type
    private func fetchByType(location: CLLocation, radius: Int, type: String) async -> [Vendor] {
        let urlString = "\(baseURL)?location=\(location.coordinate.latitude),\(location.coordinate.longitude)&radius=\(radius)&type=\(type)&key=\(apiKey)"

        guard let url = URL(string: urlString) else { return [] }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(PlacesResponse.self, from: data)
            return response.results.map { place in
                convertToVendor(place, userLocation: location)
            }
        } catch {
            print("❌ Error fetching \(type): \(error)")
            return []
        }
    }

    // Convert Google Place to Vendor
    private func convertToVendor(_ place: GooglePlace, userLocation: CLLocation) -> Vendor {
        let category = mapCategory(place.types)
        let cuisine = extractCuisine(from: place.types, name: place.name)
        let priceLevel = place.priceLevel ?? 2
        let priceRange = mapPriceRange(priceLevel)

        // Get photo URL - ALWAYS use Google Photos if available
        var imageURL: String
        if let photoRef = place.photos?.first?.photoReference {
            imageURL = "https://maps.googleapis.com/maps/api/place/photo?maxwidth=800&photoreference=\(photoRef)&key=\(apiKey)"
            print("   📷 Photo for \(place.name): \(photoRef.prefix(20))...")
        } else {
            // Fallback to category-appropriate Unsplash image
            imageURL = getFallbackImage(for: category, cuisine: cuisine)
            print("   ⚠️ No photo for \(place.name), using fallback")
        }

        // Calculate delivery time based on distance
        let placeLocation = CLLocation(latitude: place.geometry.location.lat, longitude: place.geometry.location.lng)
        let distance = userLocation.distance(from: placeLocation)
        let deliveryTime = calculateDeliveryTime(distance)

        return Vendor(
            id: place.placeId,
            name: place.name,
            category: category,
            cuisine: cuisine,
            imageURL: imageURL,
            rating: place.rating ?? 4.0,
            reviewCount: place.userRatingsTotal ?? 100,
            deliveryTime: deliveryTime,
            deliveryFee: priceLevel > 2 ? 2.99 : 0.0,
            priceRange: priceRange,
            latitude: place.geometry.location.lat,
            longitude: place.geometry.location.lng,
            address: place.vicinity,
            isOpen: place.openingHours?.openNow ?? true,
            tags: extractTags(from: place.types)
        )
    }

    // Map Google types to VendorCategory
    private func mapCategory(_ types: [String]) -> VendorCategory {
        if types.contains("cafe") || types.contains("coffee_shop") {
            return .cafes
        } else if types.contains("supermarket") || types.contains("grocery_or_supermarket") {
            return .groceries
        } else if types.contains("bakery") {
            return .desserts
        } else if types.contains("bar") || types.contains("liquor_store") {
            return .alcohol
        } else if types.contains("convenience_store") {
            return .convenience
        } else {
            return .restaurants
        }
    }

    // Extract cuisine type
    private func extractCuisine(from types: [String], name: String) -> String {
        // Check name for cuisine hints
        let nameLower = name.lowercased()
        if nameLower.contains("pizza") { return "Italian" }
        if nameLower.contains("sushi") { return "Japanese" }
        if nameLower.contains("taco") || nameLower.contains("burrito") { return "Mexican" }
        if nameLower.contains("burger") { return "American" }
        if nameLower.contains("coffee") || nameLower.contains("cafe") { return "Coffee & Tea" }
        if nameLower.contains("salad") || nameLower.contains("bowl") { return "Healthy" }

        // Check types
        if types.contains("cafe") { return "Coffee & Tea" }
        if types.contains("supermarket") { return "Grocery Store" }
        if types.contains("bakery") { return "Bakery" }

        return "Restaurant"
    }

    // Map price level to range
    private func mapPriceRange(_ level: Int) -> String {
        switch level {
        case 0: return "$"
        case 1: return "$"
        case 2: return "$$"
        case 3: return "$$$"
        case 4: return "$$$$"
        default: return "$$"
        }
    }

    // Calculate delivery time based on distance
    private func calculateDeliveryTime(_ distance: Double) -> String {
        let minutes = Int(distance / 50) + 10 // rough estimate
        let low = max(10, minutes - 5)
        let high = minutes + 5
        return "\(low)-\(high) min"
    }

    // Extract tags from types
    private func extractTags(from types: [String]) -> [String] {
        var tags: [String] = []

        if types.contains("meal_takeaway") { tags.append("Takeout") }
        if types.contains("meal_delivery") { tags.append("Delivery") }
        if types.contains("cafe") { tags.append("Coffee") }
        if types.contains("bakery") { tags.append("Pastries") }

        return tags
    }

    // Get fallback image for venues without photos
    private func getFallbackImage(for category: VendorCategory, cuisine: String) -> String {
        switch category {
        case .cafes:
            return "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800"
        case .groceries:
            return "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800"
        case .desserts:
            return "https://images.unsplash.com/photo-1499636136210-6f4ee915583e?w=800"
        case .alcohol:
            return "https://images.unsplash.com/photo-1514362545857-3bc16c4c7d1b?w=800"
        case .convenience:
            return "https://images.unsplash.com/photo-1578916171728-46686eac8d58?w=800"
        case .restaurants:
            // Match by cuisine
            let cuisineLower = cuisine.lowercased()
            if cuisineLower.contains("italian") || cuisineLower.contains("pizza") {
                return "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800"
            } else if cuisineLower.contains("japanese") || cuisineLower.contains("sushi") {
                return "https://images.unsplash.com/photo-1579584425555-c3ce17fd4351?w=800"
            } else if cuisineLower.contains("mexican") {
                return "https://images.unsplash.com/photo-1565299585323-38d6b0865b47?w=800"
            } else if cuisineLower.contains("healthy") || cuisineLower.contains("salad") {
                return "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800"
            } else if cuisineLower.contains("burger") || cuisineLower.contains("american") {
                return "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800"
            }
            return "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800"
        default:
            return "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800"
        }
    }
}

// MARK: - Google Places Response Models

struct PlacesResponse: Codable {
    let results: [GooglePlace]
    let status: String
}

struct GooglePlace: Codable {
    let placeId: String
    let name: String
    let vicinity: String
    let geometry: Geometry
    let types: [String]
    let rating: Double?
    let userRatingsTotal: Int?
    let priceLevel: Int?
    let photos: [Photo]?
    let openingHours: OpeningHours?

    enum CodingKeys: String, CodingKey {
        case placeId = "place_id"
        case name
        case vicinity
        case geometry
        case types
        case rating
        case userRatingsTotal = "user_ratings_total"
        case priceLevel = "price_level"
        case photos
        case openingHours = "opening_hours"
    }
}

struct Geometry: Codable {
    let location: Location
}

struct Location: Codable {
    let lat: Double
    let lng: Double
}

struct Photo: Codable {
    let photoReference: String
    let height: Int
    let width: Int

    enum CodingKeys: String, CodingKey {
        case photoReference = "photo_reference"
        case height
        case width
    }
}

struct OpeningHours: Codable {
    let openNow: Bool?

    enum CodingKeys: String, CodingKey {
        case openNow = "open_now"
    }
}
