//
//  Item.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/17/26.
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
