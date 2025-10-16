//
//  FoodResultsMapView.swift
//  Campusmealsv2
//
//  Results map UI (like Citi Bike R2)
//

import SwiftUI
import MapKit
import CoreLocation

struct FoodResultsMapView: View {
    let results: [FoodResult]
    let userLocation: CLLocation

    @Environment(\.dismiss) var dismiss
    @State private var region: MKCoordinateRegion
    @State private var selectedResult: FoodResult?

    private let citiBikeBlue = Color(red: 0/255, green: 174/255, blue: 239/255)

    init(results: [FoodResult], userLocation: CLLocation) {
        self.results = results
        self.userLocation = userLocation

        // Center map on user location
        _region = State(initialValue: MKCoordinateRegion(
            center: userLocation.coordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        ))
    }

    var body: some View {
        ZStack {
            // Map with routes (iOS 17+ API like R2)
            Map(position: .constant(.region(region))) {
                UserAnnotation()

                ForEach(results.prefix(10)) { result in
                    Annotation(result.vendor.name, coordinate: CLLocationCoordinate2D(
                        latitude: result.vendor.latitude,
                        longitude: result.vendor.longitude
                    )) {
                        ResultPin(result: result, citiBikeBlue: citiBikeBlue)
                            .onTapGesture {
                                selectedResult = result
                            }
                    }
                }
            }
            .ignoresSafeArea()

            // Top header + Bottom sheet (like R2)
            VStack {
                topHeader
                    .padding(.horizontal, 16)
                    .padding(.top, 12)

                Spacer()

                // Bottom sheet with results (like R2 Citi Bike options)
                resultsSheet
            }
        }
    }

    // MARK: - Top Header (Citi Bike R2 Style)

    private var topHeader: some View {
        HStack(spacing: 12) {
            Button(action: { dismiss() }) {
                ZStack {
                    Circle()
                        .fill(Color.white)
                        .frame(width: 44, height: 44)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 2)

                    Image(systemName: "arrow.left")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                }
            }

            Spacer()

            // Result count pill (like R2 bike count)
            HStack(spacing: 6) {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 16))

                Text("\(results.count)")
                    .font(.system(size: 16, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.85))
            )
        }
    }

    // MARK: - Results Sheet (like R2 bottom sheet)

    private var resultsSheet: some View {
        VStack(spacing: 0) {
            // Drag handle
            RoundedRectangle(cornerRadius: 2.5)
                .fill(Color(.systemGray4))
                .frame(width: 36, height: 5)
                .padding(.top, 8)
                .padding(.bottom, 16)

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 12) {
                    Text("Best options near you")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 20)

                    ForEach(results.prefix(10)) { result in
                        ResultCard(result: result, citiBikeBlue: citiBikeBlue)
                            .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 34)
            }
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.5)
        .background(
            Color.white
                .cornerRadius(20, corners: [.topLeft, .topRight])
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: -4)
                .ignoresSafeArea(edges: .bottom)
        )
    }
}


// MARK: - Result Pin (on map)

struct ResultPin: View {
    let result: FoodResult
    let citiBikeBlue: Color

    var body: some View {
        ZStack {
            // Pin base (like R2)
            Circle()
                .fill(citiBikeBlue)
                .frame(width: 36, height: 36)
                .shadow(color: Color.black.opacity(0.25), radius: 6, x: 0, y: 2)

            // Walk time text
            Text("\(result.walkTime)")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white)
        }
    }
}

// MARK: - Result Card (like Citi Bike card in R2)

struct ResultCard: View {
    let result: FoodResult
    let citiBikeBlue: Color

    var body: some View {
        HStack(spacing: 14) {
            // Vendor image
            AsyncImage(url: URL(string: result.vendor.finalImageURL)) { image in
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            } placeholder: {
                Rectangle()
                    .fill(Color.gray.opacity(0.2))
            }
            .frame(width: 60, height: 60)
            .cornerRadius(10)
            .clipped()

            // Vendor info
            VStack(alignment: .leading, spacing: 4) {
                Text(result.vendor.name)
                    .font(.system(size: 17, weight: .bold))
                    .foregroundColor(.black)

                // Match reason (like "1 min · 3 bikes" in R2)
                Text(result.matchReason)
                    .font(.system(size: 14))
                    .foregroundColor(.gray)

                // Match score (like "Lyft Pink applied" in R2)
                if result.matchScore > 80 {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12))
                            .foregroundColor(.green)

                        Text("Great match · \(Int(result.matchScore))%")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.green)
                    }
                }
            }

            Spacer()

            // Distance
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(result.walkTime)")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.black)

                Text("min walk")
                    .font(.system(size: 12))
                    .foregroundColor(.gray)
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white)
                .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        )
    }
}

#Preview {
    FoodResultsMapView(
        results: [],
        userLocation: CLLocation(latitude: 40.7295, longitude: -73.9965)
    )
}
