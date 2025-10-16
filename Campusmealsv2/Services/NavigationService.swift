//
//  NavigationService.swift
//  Campusmealsv2
//
//  Handle navigation to external map apps (Apple Maps, Google Maps)
//  Citi Bike-style deep linking
//

import Foundation
import CoreLocation
import UIKit

@MainActor
class NavigationService: ObservableObject {
    static let shared = NavigationService()

    private init() {}

    // MARK: - Navigation Options

    enum MapApp: String, CaseIterable, Identifiable {
        case appleMaps = "Apple Maps"
        case googleMaps = "Google Maps"
        case waze = "Waze"

        var id: String { rawValue }

        var icon: String {
            switch self {
            case .appleMaps: return "map.fill"
            case .googleMaps: return "map.circle.fill"
            case .waze: return "car.fill"
            }
        }

        var color: (red: Double, green: Double, blue: Double) {
            switch self {
            case .appleMaps: return (0, 122, 255) // Apple blue
            case .googleMaps: return (66, 133, 244) // Google blue
            case .waze: return (51, 194, 255) // Waze blue
            }
        }

        var urlScheme: String {
            switch self {
            case .appleMaps: return "maps://"
            case .googleMaps: return "comgooglemaps://"
            case .waze: return "waze://"
            }
        }

        var isInstalled: Bool {
            guard let url = URL(string: urlScheme) else { return false }
            return UIApplication.shared.canOpenURL(url)
        }
    }

    // MARK: - Available Apps

    func availableMapApps() -> [MapApp] {
        var apps: [MapApp] = [.appleMaps] // Always available on iOS

        if MapApp.googleMaps.isInstalled {
            apps.append(.googleMaps)
        }

        if MapApp.waze.isInstalled {
            apps.append(.waze)
        }

        return apps
    }

    // MARK: - Open Navigation

    func openNavigation(
        to destination: CLLocationCoordinate2D,
        destinationName: String,
        using app: MapApp
    ) {
        print("🗺️ Opening navigation to \(destinationName) in \(app.rawValue)")

        switch app {
        case .appleMaps:
            openAppleMaps(to: destination, name: destinationName)
        case .googleMaps:
            openGoogleMaps(to: destination, name: destinationName)
        case .waze:
            openWaze(to: destination, name: destinationName)
        }
    }

    // MARK: - Apple Maps

    private func openAppleMaps(to destination: CLLocationCoordinate2D, name: String) {
        let urlString = "maps://?daddr=\(destination.latitude),\(destination.longitude)&dirflg=w" // w = walking

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to web
            let webURL = "https://maps.apple.com/?daddr=\(destination.latitude),\(destination.longitude)&dirflg=w"
            if let fallbackURL = URL(string: webURL) {
                UIApplication.shared.open(fallbackURL)
            }
        }
    }

    // MARK: - Google Maps

    private func openGoogleMaps(to destination: CLLocationCoordinate2D, name: String) {
        // Try app first
        let appURLString = "comgooglemaps://?daddr=\(destination.latitude),\(destination.longitude)&directionsmode=walking"

        if let appURL = URL(string: appURLString), UIApplication.shared.canOpenURL(appURL) {
            UIApplication.shared.open(appURL)
        } else {
            // Fallback to web
            let webURLString = "https://www.google.com/maps/dir/?api=1&destination=\(destination.latitude),\(destination.longitude)&travelmode=walking"
            if let webURL = URL(string: webURLString) {
                UIApplication.shared.open(webURL)
            }
        }
    }

    // MARK: - Waze

    private func openWaze(to destination: CLLocationCoordinate2D, name: String) {
        let urlString = "waze://?ll=\(destination.latitude),\(destination.longitude)&navigate=yes"

        if let url = URL(string: urlString) {
            UIApplication.shared.open(url)
        } else {
            // Fallback to web
            let webURL = "https://www.waze.com/ul?ll=\(destination.latitude),\(destination.longitude)&navigate=yes"
            if let fallbackURL = URL(string: webURL) {
                UIApplication.shared.open(fallbackURL)
            }
        }
    }

    // MARK: - Quick Navigation (default app)

    func quickNavigate(to vendor: Vendor) {
        let destination = CLLocationCoordinate2D(latitude: vendor.latitude, longitude: vendor.longitude)

        // Default to Apple Maps (always available)
        openAppleMaps(to: destination, name: vendor.name)
    }
}
