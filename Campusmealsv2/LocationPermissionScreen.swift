//
//  LocationPermissionScreen.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import SwiftUI
import CoreLocation

class LocationManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    static let shared = LocationManager()

    private let manager = CLLocationManager()
    @Published var authorizationStatus: CLAuthorizationStatus
    @Published var isProcessing: Bool = false
    @Published var currentLocation: CLLocation?

    private var authorizationContinuation: CheckedContinuation<CLAuthorizationStatus, Never>?

    private override init() {
        self.authorizationStatus = CLLocationManager().authorizationStatus
        super.init()
        manager.delegate = self
        // Request BEST accuracy for precise restaurant detection
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.distanceFilter = kCLDistanceFilterNone // Get all updates
    }

    func startUpdatingLocation() {
        print("📍 Starting location updates with BEST accuracy")
        manager.desiredAccuracy = kCLLocationAccuracyBest
        manager.startUpdatingLocation()
    }

    // Request a single high-accuracy location update
    func requestPreciseLocation() {
        print("📍 Requesting PRECISE location update")
        manager.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        manager.requestLocation()
    }

    func stopUpdatingLocation() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.last {
            currentLocation = location
            print("📍 Location updated: (\(location.coordinate.latitude), \(location.coordinate.longitude)) ±\(location.horizontalAccuracy)m")
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("❌ Location error: \(error.localizedDescription)")
    }

    func checkCurrentStatus() {
        authorizationStatus = manager.authorizationStatus
        print("📍 Current location status: \(authorizationStatus.rawValue)")
    }

    func requestLocationPermission() async -> CLAuthorizationStatus {
        await MainActor.run { isProcessing = true }

        // If already determined, return immediately
        guard authorizationStatus == .notDetermined else {
            await MainActor.run { isProcessing = false }
            return authorizationStatus
        }

        let status = await withCheckedContinuation { continuation in
            authorizationContinuation = continuation
            manager.requestWhenInUseAuthorization()
        }

        await MainActor.run { isProcessing = false }
        return status
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let newStatus = manager.authorizationStatus

        Task { @MainActor in
            self.authorizationStatus = newStatus
            print("📍 Location authorization changed to: \(newStatus.rawValue)")

            // Resume continuation immediately
            if let continuation = self.authorizationContinuation {
                self.authorizationContinuation = nil
                continuation.resume(returning: newStatus)
            }
        }
    }
}

struct LocationPermissionScreen: View {
    @StateObject private var locationManager = LocationManager.shared
    @Environment(\.dismiss) private var dismiss
    var onGetStarted: () -> Void

    var body: some View {
        ZStack {
            Color.white
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Header with back button
                HStack {
                    Button(action: {
                        dismiss()
                    }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20))
                            .foregroundColor(.black)
                    }
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)

                Spacer()

                // Title and subtitle
                VStack(spacing: 16) {
                    Image(systemName: "location.circle.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.black)

                    Text("Enable Location")
                        .font(.custom("Helvetica-Bold", size: 28))
                        .foregroundColor(.black)

                    Text("We need your location to find the best meals near you")
                        .font(.custom("HelveticaNeue", size: 16))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }

                Spacer()

                // Buttons
                VStack(spacing: 12) {
                    Button(action: {
                        Task {
                            _ = await locationManager.requestLocationPermission()
                            onGetStarted()
                        }
                    }) {
                        HStack(spacing: 8) {
                            Text(locationManager.isProcessing ? "Processing..." : "Allow Location")
                                .font(.custom("Helvetica-Bold", size: 18))
                                .foregroundColor(.white)

                            if locationManager.isProcessing {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                    .scaleEffect(0.8)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.black)
                        .cornerRadius(28)
                    }
                    .disabled(locationManager.isProcessing)
                    .opacity(locationManager.isProcessing ? 0.7 : 1.0)

                    Button(action: onGetStarted) {
                        Text("Skip for Now")
                            .font(.custom("HelveticaNeue", size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 4)
                    .disabled(locationManager.isProcessing)
                }
                .padding(.horizontal, 40)
                .padding(.bottom, 50)
            }
        }
    }
}

#Preview {
    LocationPermissionScreen(onGetStarted: {})
}
