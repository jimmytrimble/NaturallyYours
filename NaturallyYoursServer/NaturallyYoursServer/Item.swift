//
//  Item.swift
//  NaturallyYoursServer
//
//  Created by Jamiel Trimble II on 5/25/26.
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
