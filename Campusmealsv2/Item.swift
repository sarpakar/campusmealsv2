//
//  Item.swift
//  Campusmealsv2
//
//  Created by sarp akar on 02/10/2025.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
