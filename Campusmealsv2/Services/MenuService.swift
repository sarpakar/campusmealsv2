//
//  MenuService.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation
import FirebaseFirestore

@MainActor
class MenuService: ObservableObject {
    static let shared = MenuService()
    private let db = Firestore.firestore()

    @Published var menuItems: [MenuItem] = []
    @Published var isLoading = false

    private init() {}

    func fetchMenuItems(for vendorId: String) async -> [MenuItem] {
        isLoading = true
        defer { isLoading = false }

        do {
            let snapshot = try await db.collection("menu_items")
                .whereField("vendor_id", isEqualTo: vendorId)
                .getDocuments()

            let items = snapshot.documents.compactMap { doc -> MenuItem? in
                try? doc.data(as: MenuItem.self)
            }

            // Sort: popular first, then new items
            let sorted = items.sorted { item1, item2 in
                if item1.isPopular != item2.isPopular {
                    return item1.isPopular
                }
                if item1.isNew != item2.isNew {
                    return item1.isNew
                }
                return item1.name < item2.name
            }

            self.menuItems = sorted
            return sorted
        } catch {
            print("❌ Error fetching menu items: \(error.localizedDescription)")
            return []
        }
    }
}
