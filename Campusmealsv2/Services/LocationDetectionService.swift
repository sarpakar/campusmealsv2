//
//  LocationDetectionService.swift
//  Campusmealsv2
//
//  Automatic location and restaurant detection from photo metadata
//

import Foundation
import CoreLocation
import UIKit
import Photos

@MainActor
class LocationDetectionService: ObservableObject {
    static let shared = LocationDetectionService()

    @Published var detectedLocation: CLLocation?
    @Published var detectedRestaurant: DetectedRestaurant?
    @Published var isDetecting = false

    private let placesService = GooglePlacesService.shared

    private init() {}

    // MARK: - API Key Helper

    private func getGoogleMapsAPIKey() -> String {
        return "AIzaSyB6GvIr0em_xyPExHyz3T4G9gh0cK-fNts"
    }

    // MARK: - Main Detection Function

    func detectLocationAndRestaurant(
        from image: UIImage,
        fallbackLocation: CLLocation?
    ) async throws -> DetectedLocationInfo {

        isDetecting = true
        defer { isDetecting = false }

        guard let location = fallbackLocation else {
            throw LocationDetectionError.noLocationAvailable
        }

        let address = try await reverseGeocode(location: location)
        let nearbyRestaurants = try await findNearbyRestaurants(at: location)

        var closestRestaurant: DetectedRestaurant?
        var closestDistance: Double = 50.0

        for restaurant in nearbyRestaurants {
            let restaurantLocation = CLLocation(
                latitude: restaurant.latitude,
                longitude: restaurant.longitude
            )
            let distance = location.distance(from: restaurantLocation)

            if distance < closestDistance {
                closestDistance = distance
                closestRestaurant = restaurant
            }
        }

        return DetectedLocationInfo(
            location: location,
            address: address,
            restaurant: closestRestaurant
        )
    }

    // MARK: - Extract GPS from Image Metadata

    /// Extracts GPS coordinates from image EXIF data
    func extractLocationFromImage(_ image: UIImage) -> CLLocation? {
        // Try to get image data
        guard let imageData = image.jpegData(compressionQuality: 1.0),
              let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let metadata = CGImageSourceCopyPropertiesAtIndex(source, 0, nil) as? [String: Any],
              let gpsData = metadata[kCGImagePropertyGPSDictionary as String] as? [String: Any] else {
            print("⚠️ No GPS metadata found in image")
            return nil
        }

        // Extract latitude and longitude
        guard let latitude = gpsData[kCGImagePropertyGPSLatitude as String] as? Double,
              let latitudeRef = gpsData[kCGImagePropertyGPSLatitudeRef as String] as? String,
              let longitude = gpsData[kCGImagePropertyGPSLongitude as String] as? Double,
              let longitudeRef = gpsData[kCGImagePropertyGPSLongitudeRef as String] as? String else {
            print("⚠️ Incomplete GPS data in image")
            return nil
        }

        // Adjust for hemisphere (N/S, E/W)
        let finalLatitude = latitudeRef == "S" ? -latitude : latitude
        let finalLongitude = longitudeRef == "W" ? -longitude : longitude

        print("✅ Extracted GPS from image: \(finalLatitude), \(finalLongitude)")

        return CLLocation(latitude: finalLatitude, longitude: finalLongitude)
    }

    // MARK: - Alternative: Extract from PHAsset (if using Photo Library)

    /// Extracts location from PHAsset (when user picks from photo library)
    func extractLocationFromPHAsset(_ asset: PHAsset) -> CLLocation? {
        guard let location = asset.location else {
            print("⚠️ No location data in PHAsset")
            return nil
        }

        print("✅ Extracted GPS from PHAsset: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        return location
    }

    // MARK: - Reverse Geocoding (DETAILED ADDRESS WITH PLACE NAME)

    /// Converts coordinates to SPECIFIC address AND tries to identify the exact place/business
    private func reverseGeocode(location: CLLocation) async throws -> String {
        let geocoder = CLGeocoder()

        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            guard let placemark = placemarks.first else {
                return "Unknown Location"
            }

            var components: [String] = []

            if let areasOfInterest = placemark.areasOfInterest, !areasOfInterest.isEmpty {
                components.append(areasOfInterest.first!)
            }

            if let neighborhood = placemark.subLocality {
                components.append(neighborhood)
            } else if let city = placemark.locality {
                components.append(city)
            }

            return components.isEmpty ? "Unknown Location" : components.joined(separator: ", ")
        } catch {
            return "Unknown Location"
        }
    }

    // MARK: - Find Nearby Restaurants (Google Places)

    /// Finds restaurants near the given location using Google Places API with HIGH PRECISION
    private func findNearbyRestaurants(at location: CLLocation) async throws -> [DetectedRestaurant] {
        // Get Google Maps API key (different from Gemini AI key)
        let apiKey = getGoogleMapsAPIKey()

        guard !apiKey.isEmpty && !apiKey.starts(with: "YOUR_") else {
            print("⚠️ No valid Google Maps API key - skipping restaurant detection")
            return [] // Return empty array instead of throwing
        }

        let radius = 50
        let lat = String(format: "%.6f", location.coordinate.latitude)
        let lng = String(format: "%.6f", location.coordinate.longitude)
        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&radius=\(radius)&type=restaurant&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw LocationDetectionError.invalidURL
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LocationDetectionError.apiError("Invalid response")
        }

        if httpResponse.statusCode != 200 {
            // Try to parse error message
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let status = json["status"] as? String,
               let errorMessage = json["error_message"] as? String {
                print("❌ Google Places API Error: \(status) - \(errorMessage)")
            }
            throw LocationDetectionError.apiError("HTTP \(httpResponse.statusCode)")
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw LocationDetectionError.invalidResponse
        }

        // Check API status
        if let status = json["status"] as? String {
            print("📡 API Status: \(status)")

            if status == "REQUEST_DENIED" {
                if let errorMessage = json["error_message"] as? String {
                    print("❌ REQUEST_DENIED: \(errorMessage)")
                }
                print("⚠️ Please enable Google Places API in Google Cloud Console")
                return [] // Return empty instead of throwing
            }
        }

        guard let results = json["results"] as? [[String: Any]] else {
            print("⚠️ No results in API response")
            return []
        }

        print("📍 Found \(results.count) restaurants within \(radius)m")

        var restaurants: [DetectedRestaurant] = []

        for result in results {
            guard let name = result["name"] as? String,
                  let geometry = result["geometry"] as? [String: Any],
                  let locationData = geometry["location"] as? [String: Double],
                  let lat = locationData["lat"],
                  let lng = locationData["lng"] else {
                continue
            }

            let rating = result["rating"] as? Double
            let placeId = result["place_id"] as? String
            let address = result["vicinity"] as? String

            let restaurant = DetectedRestaurant(
                name: name,
                latitude: lat,
                longitude: lng,
                placeId: placeId,
                rating: rating,
                address: address
            )

            restaurants.append(restaurant)
        }

        // Sort by distance from photo location
        return restaurants.sorted { r1, r2 in
            r1.distance(from: location) < r2.distance(from: location)
        }
    }

    // MARK: - Find Place at Exact Location (Reverse Search)

    /// Tries to find the exact business/place AT the given coordinates
    private func findPlaceAtExactLocation(at location: CLLocation) async throws -> DetectedRestaurant? {
        let apiKey = getGoogleMapsAPIKey()

        guard !apiKey.isEmpty && !apiKey.starts(with: "YOUR_") else {
            return nil
        }

        // Use VERY small radius (10m) to find place at exact location
        let radius = 10
        let lat = String(format: "%.6f", location.coordinate.latitude)
        let lng = String(format: "%.6f", location.coordinate.longitude)

        let urlString = "https://maps.googleapis.com/maps/api/place/nearbysearch/json?location=\(lat),\(lng)&radius=\(radius)&key=\(apiKey)"

        print("🎯 REVERSE PLACE SEARCH (exact location): radius=\(radius)m")

        guard let url = URL(string: urlString) else { return nil }

        let (data, response) = try await URLSession.shared.data(from: url)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let results = json["results"] as? [[String: Any]],
              !results.isEmpty else {
            return nil
        }

        // Get the FIRST result (should be the place at exact location)
        guard let result = results.first,
              let name = result["name"] as? String,
              let geometry = result["geometry"] as? [String: Any],
              let locationData = geometry["location"] as? [String: Double],
              let lat = locationData["lat"],
              let lng = locationData["lng"] else {
            return nil
        }

        let rating = result["rating"] as? Double
        let placeId = result["place_id"] as? String
        let address = result["vicinity"] as? String
        let types = result["types"] as? [String] ?? []

        print("   🎯 Found place at exact location: \(name)")
        print("   Types: \(types.joined(separator: ", "))")

        return DetectedRestaurant(
            name: name,
            latitude: lat,
            longitude: lng,
            placeId: placeId,
            rating: rating,
            address: address
        )
    }

    // MARK: - Get Place Details (Enhanced Info)

    /// Fetches detailed information about a place (reviews, hours, etc.)
    func getPlaceDetails(placeId: String) async throws -> PlaceDetails {
        let apiKey = APIKey.default
        let urlString = "https://maps.googleapis.com/maps/api/place/details/json?place_id=\(placeId)&fields=name,rating,formatted_phone_number,opening_hours,website,reviews,photos&key=\(apiKey)"

        guard let url = URL(string: urlString) else {
            throw LocationDetectionError.invalidURL
        }

        let (data, _) = try await URLSession.shared.data(from: url)

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let result = json["result"] as? [String: Any] else {
            throw LocationDetectionError.invalidResponse
        }

        return PlaceDetails(
            name: result["name"] as? String ?? "",
            rating: result["rating"] as? Double,
            phoneNumber: result["formatted_phone_number"] as? String,
            website: result["website"] as? String
        )
    }
}

// MARK: - Models

struct DetectedLocationInfo {
    let location: CLLocation
    let address: String
    let restaurant: DetectedRestaurant?
}

struct DetectedRestaurant {
    let name: String
    let latitude: Double
    let longitude: Double
    let placeId: String?
    let rating: Double?
    let address: String?

    func distance(from location: CLLocation) -> Double {
        let restaurantLocation = CLLocation(latitude: latitude, longitude: longitude)
        return location.distance(from: restaurantLocation)
    }
}

struct PlaceDetails {
    let name: String
    let rating: Double?
    let phoneNumber: String?
    let website: String?
}

enum LocationDetectionError: Error, LocalizedError {
    case noLocationAvailable
    case invalidURL
    case apiError(String)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noLocationAvailable:
            return "No location data available from image or device"
        case .invalidURL:
            return "Invalid API URL"
        case .apiError(let message):
            return "API error: \(message)"
        case .invalidResponse:
            return "Invalid API response"
        }
    }
}
