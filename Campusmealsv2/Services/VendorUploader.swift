//
//  VendorUploader.swift
//  Campusmealsv2
//
//  Upload sample vendors to Firebase - RUN ONCE
//

import Foundation
import FirebaseFirestore

class VendorUploader {
    static let shared = VendorUploader()
    private let db = Firestore.firestore()

    private init() {}

    /// Call this ONCE to upload all vendors to Firebase
    func uploadAllVendors() async {
        print("🚀 Starting vendor upload to Firebase...")

        let vendors = VendorService.shared.getSampleVendorsPublic()

        var successCount = 0
        var errorCount = 0

        for vendor in vendors {
            guard let vendorId = vendor.id else {
                print("⚠️ Skipping vendor with no ID: \(vendor.name)")
                continue
            }

            do {
                try db.collection("vendors").document(vendorId).setData(from: vendor)
                print("✅ Uploaded: \(vendor.name)")
                successCount += 1
            } catch {
                print("❌ Error uploading \(vendor.name): \(error.localizedDescription)")
                errorCount += 1
            }
        }

        print("\n" + String(repeating: "=", count: 60))
        print("🎉 Upload Complete!")
        print("✅ Success: \(successCount)")
        print("❌ Errors: \(errorCount)")
        print(String(repeating: "=", count: 60))
    }
}
