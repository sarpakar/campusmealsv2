//
//  VendorService.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation
import FirebaseFirestore
import CoreLocation

class VendorService: ObservableObject {
    @Published var vendors: [Vendor] = []
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?

    private let db = Firestore.firestore()
    static let shared = VendorService()

    private init() {}

    func fetchVendors(near location: CLLocation, category: VendorCategory = .all, radius: Double = 10.0) async {
        await MainActor.run { isLoading = true; errorMessage = nil }

        print("📍 VendorService.fetchVendors called")
        print("   Location: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        print("   Loading from Firestore...")

        // LOAD FROM FIRESTORE (with fallback to sample data)
        do {
            let query = db.collection("vendors")
                .limit(to: 50)

            let snapshot = try await query.getDocuments()

            let firestoreVendors = snapshot.documents.compactMap { document -> Vendor? in
                do {
                    var vendor = try document.data(as: Vendor.self)
                    // Ensure ID is populated from document ID
                    if vendor.id == nil {
                        vendor.id = document.documentID
                    }

                    // Debug: Check if socialVideos exist
                    if let socialVideos = vendor.socialVideos {
                        print("✅ Vendor '\(vendor.name)' has \(socialVideos.count) social videos")
                        for (index, video) in socialVideos.enumerated() {
                            print("   Video \(index + 1): \(video.platform.rawValue) - \(video.title ?? "no title")")
                        }
                    } else {
                        print("⚠️ Vendor '\(vendor.name)' has no social videos")
                    }

                    return vendor
                } catch {
                    print("⚠️ Error decoding vendor \(document.documentID): \(error)")
                    return nil
                }
            }

            // Build final vendor list
            let finalVendors: [Vendor]
            if firestoreVendors.isEmpty {
                print("⚠️ No vendors in Firestore, using sample data")
                finalVendors = getSampleVendors()
            } else {
                print("✅ Loaded \(firestoreVendors.count) vendors from Firestore")
                // Add sample data for vendors without videos yet
                let sampleVendors = getSampleVendors().filter { sampleVendor in
                    !firestoreVendors.contains { $0.name == sampleVendor.name }
                }
                finalVendors = firestoreVendors + sampleVendors
            }

            await MainActor.run {
                self.vendors = finalVendors
                self.isLoading = false
                print("✅ Total vendors: \(self.vendors.count)")
                print("   First 3: \(self.vendors.prefix(3).map { "\($0.name) (ID: \($0.id ?? "nil"))" }.joined(separator: ", "))")
            }
        } catch {
            print("❌ Firestore error: \(error.localizedDescription)")
            print("⚠️ Using sample data as fallback")
            let fallbackVendors = getSampleVendors()
            await MainActor.run {
                self.vendors = fallbackVendors
                self.isLoading = false
            }
        }

        /* GOOGLE PLACES API - DISABLED FOR DEBUGGING
        print("🌍 Fetching real venues from Google Places API...")
        let placesService = GooglePlacesService.shared
        await placesService.fetchNearbyVendors(location: location, radius: Int(radius * 1000))

        await MainActor.run {
            if placesService.vendors.isEmpty {
                // Fallback to sample data if API fails
                print("⚠️ Google Places returned no results, using sample data")
                self.vendors = getSampleVendors()
            } else {
                self.vendors = placesService.vendors
            }
            self.isLoading = false
        }
        */

        /* UNCOMMENT THIS LATER TO RE-ENABLE FIRESTORE
        do {
            var query: Query = db.collection("vendors")
                .whereField("is_open", isEqualTo: true)
                .limit(to: 50)

            if category != .all {
                query = query.whereField("category", isEqualTo: category.rawValue)
            }

            let snapshot = try await query.getDocuments()

            let allVendors = snapshot.documents.compactMap { document -> Vendor? in
                try? document.data(as: Vendor.self)
            }

            // If Firestore is empty, use sample data
            let vendorsToShow: [Vendor]
            if allVendors.isEmpty {
                print("⚠️ No vendors in Firestore, using sample data")
                vendorsToShow = getSampleVendors()
            } else {
                print("✅ Loaded \(allVendors.count) vendors from Firestore")
                // Filter by distance and sort
                vendorsToShow = allVendors
                    .filter { vendor in
                        vendor.distance(from: location.coordinate.latitude,
                                      userLon: location.coordinate.longitude) <= radius
                    }
                    .sorted { vendor1, vendor2 in
                        let dist1 = vendor1.distance(from: location.coordinate.latitude,
                                                    userLon: location.coordinate.longitude)
                        let dist2 = vendor2.distance(from: location.coordinate.latitude,
                                                    userLon: location.coordinate.longitude)
                        return dist1 < dist2
                    }
            }

            await MainActor.run {
                self.vendors = vendorsToShow
                self.isLoading = false
            }

        } catch {
            // On error, use sample data as fallback
            print("❌ Error fetching vendors: \(error.localizedDescription)")
            print("⚠️ Using sample data as fallback")

            await MainActor.run {
                self.vendors = getSampleVendors()
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
        */
    }

    // Sample data fallback - NYU & Columbia area
    func getSampleVendorsPublic() -> [Vendor] {
        return getSampleVendors()
    }

    private func getSampleVendors() -> [Vendor] {
        return [
            // Veselka Diner - Featured with enhanced data
            Vendor(
                id: "veselka1",
                name: "Veselka",
                category: .restaurants,
                cuisine: "Ukrainian Diner",
                imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
                rating: 4.6,
                reviewCount: 7333,
                deliveryTime: "15-25 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7265,
                longitude: -73.9844,
                address: "144 2nd Ave, New York, NY 10003",
                isOpen: true,
                tags: ["Free Delivery", "East Village", "Open 24/7"],
                waitStatus: .confident,
                dietaryHighlights: ["Eggs", "Coffee", "Hash Browns", "Pancakes", "Pierogies", "Borscht"],
                vibeTraits: ["Friendly service", "Good environment", "Fast service", "Cozy atmosphere"],
                badges: [
                    VendorBadge(type: .bestInArea),
                    VendorBadge(type: .comeOnceInAWhile),
                    VendorBadge(type: .luckyToEat)
                ],
                friendsActivity: FriendsActivity(
                    totalFriendsLoved: 3,
                    recentVisits: [
                        FriendVisit(friendName: "Sarah", daysAgo: 2, photoURL: nil),
                        FriendVisit(friendName: "Mike", daysAgo: 5, photoURL: nil),
                        FriendVisit(friendName: "Emma", daysAgo: 7, photoURL: nil)
                    ]
                ),
                socialVideos: nil // Will be loaded dynamically by VendorDetailCard
            ),

            // GROCERY STORES
            Vendor(
                id: "traderjoes1",
                name: "Trader Joe's",
                category: .groceries,
                cuisine: "Grocery Store",
                imageURL: "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800&q=80",
                rating: 4.5,
                reviewCount: 4987,
                deliveryTime: "30-45 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7325,
                longitude: -73.9890,
                address: "142 E 14th St, New York, NY 10003",
                isOpen: true,
                tags: ["Groceries", "Organic", "Popular"]
            ),
            Vendor(
                id: "wholefoodsunionsq",
                name: "Whole Foods Market",
                category: .groceries,
                cuisine: "Organic Grocery",
                imageURL: "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800&q=80",
                rating: 4.2,
                reviewCount: 5200,
                deliveryTime: "25-35 min",
                deliveryFee: 0.0,
                priceRange: "$$$",
                latitude: 40.7347,
                longitude: -73.9900,
                address: "4 Union Square S, New York, NY 10003",
                isOpen: true,
                tags: ["Organic", "Premium", "Health Foods"]
            ),

            // CAFES
            Vendor(
                id: "bluebottle1",
                name: "Blue Bottle Coffee",
                category: .cafes,
                cuisine: "Specialty Coffee",
                imageURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80",
                rating: 4.7,
                reviewCount: 304,
                deliveryTime: "10-15 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7290,
                longitude: -73.9950,
                address: "54 W 8th St, New York, NY 10011",
                isOpen: true,
                tags: ["Coffee", "Artisan", "Pastries"]
            ),
            // NYU Area Vendors
            Vendor(
                id: "sample1",
                name: "Artichoke Pizza",
                category: .restaurants,
                cuisine: "Italian",
                imageURL: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&q=80",
                rating: 4.7,
                reviewCount: 3240,
                deliveryTime: "15-25 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7282,
                longitude: -73.9942,
                address: "328 E 14th St, New York, NY 10003",
                isOpen: true,
                tags: ["Free Delivery", "NYU", "Popular"]
            ),
            Vendor(
                id: "choptcreative",
                name: "Chopt Creative Salad",
                category: .restaurants,
                cuisine: "Salads & Bowls",
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
                rating: 4.4,
                reviewCount: 1567,
                deliveryTime: "15-20 min",
                deliveryFee: 1.99,
                priceRange: "$$",
                latitude: 40.7310,
                longitude: -73.9980,
                address: "24 E 12th St, New York, NY 10003",
                isOpen: true,
                tags: ["Healthy", "Fast", "Customizable"]
            ),
            Vendor(
                id: "bycehloe",
                name: "by CHLOE",
                category: .restaurants,
                cuisine: "Vegan Fast Food",
                imageURL: "https://sp-ao.shortpixel.ai/client/to_webp,q_glossy,ret_img,w_640,h_300/https://www.glenwoodnyc.com/wp-content/uploads/2016/09/by-chloe-vegetarian-burger-lemonade.jpg",
                rating: 4.5,
                reviewCount: 2134,
                deliveryTime: "20-30 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7305,
                longitude: -73.9925,
                address: "60 E 11th St, New York, NY 10003",
                isOpen: true,
                tags: ["Vegan", "Plant-Based", "Healthy"]
            ),
            Vendor(
                id: "shakeshack1",
                name: "Shake Shack",
                category: .restaurants,
                cuisine: "Burgers & Fries",
                imageURL: "https://images.unsplash.com/photo-1568901346375-23c9450c58cd?w=800&q=80",
                rating: 4.6,
                reviewCount: 4521,
                deliveryTime: "20-30 min",
                deliveryFee: 2.49,
                priceRange: "$$",
                latitude: 40.7411,
                longitude: -73.9897,
                address: "Madison Square Park, New York, NY 10010",
                isOpen: true,
                tags: ["Burgers", "Classic", "NYC Icon"]
            ),
            Vendor(
                id: "joeandpizza",
                name: "Joe & The Juice",
                category: .cafes,
                cuisine: "Juice Bar & Cafe",
                imageURL: "https://images.unsplash.com/photo-1610970881699-44a5587cabec?w=800&q=80",
                rating: 4.3,
                reviewCount: 678,
                deliveryTime: "10-15 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.7318,
                longitude: -73.9970,
                address: "1 University Pl, New York, NY 10003",
                isOpen: true,
                tags: ["Juice", "Healthy", "Quick"]
            ),
            Vendor(
                id: "sample2",
                name: "Dig Inn",
                category: .restaurants,
                cuisine: "American",
                imageURL: "https://images.unsplash.com/photo-1546069901-ba9599a7e63c?w=800&q=80",
                rating: 4.6,
                reviewCount: 2156,
                deliveryTime: "20-30 min",
                deliveryFee: 1.99,
                priceRange: "$$",
                latitude: 40.7308,
                longitude: -73.9973,
                address: "80 E 8th St, New York, NY 10003",
                isOpen: true,
                tags: ["Healthy", "NYU"]
            ),
            Vendor(
                id: "sample3",
                name: "Sweetgreen",
                category: .restaurants,
                cuisine: "Salads & Bowls",
                imageURL: "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800&q=80",
                rating: 4.8,
                reviewCount: 1876,
                deliveryTime: "20-30 min",
                deliveryFee: 1.99,
                priceRange: "$$",
                latitude: 40.7295,
                longitude: -73.9935,
                address: "1 Union Square W, New York, NY 10003",
                isOpen: true,
                tags: ["Healthy", "Popular", "NYU"]
            ),
            Vendor(
                id: "sample4",
                name: "Think Coffee",
                category: .cafes,
                cuisine: "Coffee & Tea",
                imageURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80",
                rating: 4.5,
                reviewCount: 2341,
                deliveryTime: "10-20 min",
                deliveryFee: 0.0,
                priceRange: "$",
                latitude: 40.7299,
                longitude: -73.9969,
                address: "1 Bleecker St, New York, NY 10012",
                isOpen: true,
                tags: ["Free Delivery", "Coffee", "NYU"]
            ),
            // Columbia Area Vendors
            Vendor(
                id: "sample5",
                name: "Community Food & Juice",
                category: .restaurants,
                cuisine: "American",
                imageURL: "https://images.unsplash.com/photo-1504674900247-0877df9cc836?w=800&q=80",
                rating: 4.6,
                reviewCount: 1923,
                deliveryTime: "25-35 min",
                deliveryFee: 2.49,
                priceRange: "$$",
                latitude: 40.8075,
                longitude: -73.9626,
                address: "2893 Broadway, New York, NY 10025",
                isOpen: true,
                tags: ["Brunch", "Columbia"]
            ),
            Vendor(
                id: "sample6",
                name: "Koronet Pizza",
                category: .restaurants,
                cuisine: "Italian",
                imageURL: "https://images.unsplash.com/photo-1574071318508-1cdbab80d002?w=800&q=80",
                rating: 4.4,
                reviewCount: 2567,
                deliveryTime: "15-25 min",
                deliveryFee: 0.0,
                priceRange: "$",
                latitude: 40.8063,
                longitude: -73.9644,
                address: "2848 Broadway, New York, NY 10025",
                isOpen: true,
                tags: ["Free Delivery", "Columbia", "Late Night"]
            ),
            Vendor(
                id: "sample7",
                name: "Insomnia Cookies",
                category: .desserts,
                cuisine: "Bakery",
                imageURL: "https://images.unsplash.com/photo-1558961363-fa8fdf82db35?w=800&q=80",
                rating: 4.7,
                reviewCount: 3421,
                deliveryTime: "20-30 min",
                deliveryFee: 0.0,
                priceRange: "$",
                latitude: 40.8069,
                longitude: -73.9628,
                address: "2929 Broadway, New York, NY 10025",
                isOpen: true,
                tags: ["Free Delivery", "Columbia", "Late Night"]
            ),
            Vendor(
                id: "sample8",
                name: "Joe Coffee",
                category: .cafes,
                cuisine: "Coffee & Tea",
                imageURL: "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800&q=80",
                rating: 4.6,
                reviewCount: 1654,
                deliveryTime: "10-20 min",
                deliveryFee: 0.0,
                priceRange: "$$",
                latitude: 40.8081,
                longitude: -73.9618,
                address: "2897 Broadway, New York, NY 10025",
                isOpen: true,
                tags: ["Free Delivery", "Coffee", "Columbia"]
            )
        ]
    }

    // Get city name from coordinates
    func getCityName(from location: CLLocation) async -> String {
        let geocoder = CLGeocoder()
        do {
            let placemarks = try await geocoder.reverseGeocodeLocation(location)
            if let city = placemarks.first?.locality {
                return city
            }
        } catch {
            print("❌ Geocoding error: \(error.localizedDescription)")
        }
        return "Your Location"
    }
}
