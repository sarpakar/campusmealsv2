//
//  FirestoreSeedData.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//
//  INSTRUCTIONS: Run this once to populate Firestore with sample vendor data
//  Call seedVendors() from your app initialization (only in debug mode)
//

import Foundation
import FirebaseFirestore

class FirestoreSeedData {
    static func seedAll() {
        seedVendors()
        // Menu items will be seeded when vendors are created
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            seedMenuItems()
        }
    }

    static func seedVendors() {
        let db = Firestore.firestore()

        // Sample vendors for New York City area
        let sampleVendors: [[String: Any]] = [
            [
                "name": "Veselka",
                "category": "Restaurants",
                "cuisine": "Ukrainian Diner",
                "image_url": "https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800",
                "rating": 4.8,
                "review_count": 5420,
                "delivery_time": "15-25 min",
                "delivery_fee": 0.0,
                "price_range": "$$",
                "latitude": 40.7265,
                "longitude": -73.9844,
                "address": "144 2nd Ave, New York, NY 10003",
                "is_open": true,
                "tags": ["Free Delivery", "East Village", "Open 24/7"],
                "wait_status": "confident",
                "dietary_highlights": ["Eggs", "Coffee", "Hash Browns", "Pancakes", "Pierogies", "Borscht"],
                "vibe_traits": ["Friendly service", "Good environment", "Fast service", "Cozy atmosphere"],
                "badges": [
                    ["type": "bestInArea", "title": "Best in Area"],
                    ["type": "comeOnceInAWhile", "title": "Come Once in a While"],
                    ["type": "luckyToEat", "title": "You're Lucky to Eat Here"]
                ],
                "friends_activity": [
                    "totalFriendsLoved": 3,
                    "recentVisits": [
                        ["friendName": "Sarah", "daysAgo": 2],
                        ["friendName": "Mike", "daysAgo": 5],
                        ["friendName": "Emma", "daysAgo": 7]
                    ]
                ]
            ],
            [
                "name": "Joe's Pizza",
                "category": "Restaurants",
                "cuisine": "Italian",
                "image_url": "https://images.unsplash.com/photo-1513104890138-7c749659a591?w=800",
                "rating": 4.7,
                "review_count": 2340,
                "delivery_time": "20-30 min",
                "delivery_fee": 0.0,
                "price_range": "$$",
                "latitude": 40.7589,
                "longitude": -73.9851,
                "address": "7 Carmine St, New York, NY 10014",
                "is_open": true,
                "tags": ["Free Delivery", "Popular", "Fast"]
            ],
            [
                "name": "Whole Foods Market",
                "category": "Groceries",
                "cuisine": "Supermarket",
                "image_url": "https://images.unsplash.com/photo-1542838132-92c53300491e?w=800",
                "rating": 4.5,
                "review_count": 1823,
                "delivery_time": "30-45 min",
                "delivery_fee": 3.99,
                "price_range": "$$$",
                "latitude": 40.7614,
                "longitude": -73.9776,
                "address": "250 7th Ave, New York, NY 10001",
                "is_open": true,
                "tags": ["Organic", "Fresh"]
            ],
            [
                "name": "Shake Shack",
                "category": "Restaurants",
                "cuisine": "American",
                "image_url": "https://unsplash.com/photos/red-and-white-concrete-building-under-blue-sky-during-daytime-iypd1qKelRY",
                "rating": 4.6,
                "review_count": 5678,
                "delivery_time": "25-35 min",
                "delivery_fee": 2.99,
                "price_range": "$$",
                "latitude": 40.7414,
                "longitude": -73.9887,
                "address": "Madison Square Park, New York, NY 10010",
                "is_open": true,
                "tags": ["Popular", "Burgers"]
            ],
            [
                "name": "Starbucks Coffee",
                "category": "Cafés",
                "cuisine": "Coffee & Tea",
                "image_url": "https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=800",
                "rating": 4.3,
                "review_count": 3421,
                "delivery_time": "15-25 min",
                "delivery_fee": 0.0,
                "price_range": "$$",
                "latitude": 40.7580,
                "longitude": -73.9855,
                "address": "Times Square, New York, NY 10036",
                "is_open": true,
                "tags": ["Free Delivery", "Coffee"]
            ],
            [
                "name": "Sweetgreen",
                "category": "Restaurants",
                "cuisine": "Salads & Bowls",
                "image_url": "https://images.unsplash.com/photo-1512621776951-a57141f2eefd?w=800",
                "rating": 4.8,
                "review_count": 2156,
                "delivery_time": "20-30 min",
                "delivery_fee": 1.99,
                "price_range": "$$",
                "latitude": 40.7505,
                "longitude": -73.9934,
                "address": "1164 Broadway, New York, NY 10001",
                "is_open": true,
                "tags": ["Healthy", "Popular", "Fast"]
            ],
            [
                "name": "7-Eleven",
                "category": "Convenience",
                "cuisine": "Convenience Store",
                "image_url": "https://images.unsplash.com/photo-1604719312566-8912e9227c6a?w=800",
                "rating": 4.1,
                "review_count": 892,
                "delivery_time": "10-20 min",
                "delivery_fee": 0.0,
                "price_range": "$",
                "latitude": 40.7589,
                "longitude": -73.9800,
                "address": "Multiple Locations",
                "is_open": true,
                "tags": ["Free Delivery", "24/7", "Quick"]
            ],
            [
                "name": "Levain Bakery",
                "category": "Desserts",
                "cuisine": "Bakery",
                "image_url": "https://images.unsplash.com/photo-1509440159596-0249088772ff?w=800",
                "rating": 4.9,
                "review_count": 4521,
                "delivery_time": "25-35 min",
                "delivery_fee": 2.49,
                "price_range": "$$",
                "latitude": 40.7799,
                "longitude": -73.9799,
                "address": "167 W 74th St, New York, NY 10023",
                "is_open": true,
                "tags": ["Cookies", "Popular", "Sweet"]
            ],
            [
                "name": "Trader Joe's",
                "category": "Groceries",
                "cuisine": "Supermarket",
                "image_url": "https://images.unsplash.com/photo-1588964895597-cfccd6e2dbf9?w=800",
                "rating": 4.7,
                "review_count": 3245,
                "delivery_time": "35-45 min",
                "delivery_fee": 4.99,
                "price_range": "$$",
                "latitude": 40.7282,
                "longitude": -73.9942,
                "address": "142 E 14th St, New York, NY 10003",
                "is_open": true,
                "tags": ["Affordable", "Organic"]
            ]
        ]

        // Batch write to Firestore
        let batch = db.batch()

        for vendorData in sampleVendors {
            let docRef = db.collection("vendors").document()
            batch.setData(vendorData, forDocument: docRef)
        }

        batch.commit { error in
            if let error = error {
                print("❌ Error seeding vendors: \(error.localizedDescription)")
            } else {
                print("✅ Successfully seeded \(sampleVendors.count) vendors to Firestore!")
            }
        }
    }

    static func seedMenuItems() {
        let db = Firestore.firestore()

        // First, get all vendors to associate menu items with them
        db.collection("vendors").getDocuments { snapshot, error in
            guard let documents = snapshot?.documents, error == nil else {
                print("❌ Error fetching vendors for menu seeding: \(error?.localizedDescription ?? "Unknown")")
                return
            }

            guard let firstVendor = documents.first else { return }
            let vendorId = firstVendor.documentID

            // Sample menu items for first vendor
            let menuItems: [[String: Any]] = [
                [
                    "vendor_id": vendorId,
                    "name": "Margherita Pizza",
                    "description": "Fresh mozzarella, basil, and tomato sauce on crispy crust",
                    "price": 12.99,
                    "image_url": "https://images.unsplash.com/photo-1604068549290-dea0e4a305ca?w=400",
                    "category": "Entrees",
                    "is_popular": true,
                    "is_new": false,
                    "liked_by_friends": ["Sarah M.", "Mike L."],
                    "dietary_tags": ["Vegetarian"]
                ],
                [
                    "vendor_id": vendorId,
                    "name": "Pepperoni Pizza",
                    "description": "Classic pepperoni with extra mozzarella cheese",
                    "price": 14.99,
                    "image_url": "https://images.unsplash.com/photo-1628840042765-356cda07504e?w=400",
                    "category": "Entrees",
                    "is_popular": true,
                    "is_new": false,
                    "liked_by_friends": ["John D."],
                    "dietary_tags": []
                ],
                [
                    "vendor_id": vendorId,
                    "name": "Truffle Mushroom Pizza",
                    "description": "Wild mushrooms, truffle oil, arugula, and parmesan",
                    "price": 18.99,
                    "image_url": "https://images.unsplash.com/photo-1565299624946-b28f40a0ae38?w=400",
                    "category": "Entrees",
                    "is_popular": false,
                    "is_new": true,
                    "liked_by_friends": [],
                    "dietary_tags": ["Vegetarian", "Gourmet"]
                ],
                [
                    "vendor_id": vendorId,
                    "name": "Caesar Salad",
                    "description": "Romaine lettuce, parmesan, croutons, Caesar dressing",
                    "price": 8.99,
                    "image_url": "https://images.unsplash.com/photo-1546793665-c74683f339c1?w=400",
                    "category": "Sides",
                    "is_popular": false,
                    "is_new": false,
                    "liked_by_friends": ["Sarah M.", "Emma K.", "Jake P."],
                    "dietary_tags": ["Vegetarian"]
                ],
                [
                    "vendor_id": vendorId,
                    "name": "Buffalo Wings",
                    "description": "Crispy wings tossed in spicy buffalo sauce",
                    "price": 11.99,
                    "image_url": "https://images.unsplash.com/photo-1608039829572-78524f79c4c7?w=400",
                    "category": "Appetizers",
                    "is_popular": true,
                    "is_new": false,
                    "liked_by_friends": ["Mike L.", "Chris R."],
                    "dietary_tags": ["Spicy"]
                ],
                [
                    "vendor_id": vendorId,
                    "name": "Tiramisu",
                    "description": "Classic Italian dessert with espresso and mascarpone",
                    "price": 7.99,
                    "image_url": "https://images.unsplash.com/photo-1571877227200-a0d98ea607e9?w=400",
                    "category": "Desserts",
                    "is_popular": true,
                    "is_new": false,
                    "liked_by_friends": ["Emma K."],
                    "dietary_tags": ["Vegetarian", "Sweet"]
                ]
            ]

            let batch = db.batch()
            for itemData in menuItems {
                let docRef = db.collection("menu_items").document()
                batch.setData(itemData, forDocument: docRef)
            }

            batch.commit { error in
                if let error = error {
                    print("❌ Error seeding menu items: \(error.localizedDescription)")
                } else {
                    print("✅ Successfully seeded \(menuItems.count) menu items to Firestore!")
                }
            }
        }
    }
}

