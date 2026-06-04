//
//  NaturallyYoursApp.swift
//  NaturallyYours
//
//  Created by Jamiel Trimble II on 5/17/26.
//

import SwiftUI
import SwiftData

@main
struct NaturallyYoursApp: App {
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Item.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            LoginRegisterView()
        }
        .modelContainer(sharedModelContainer)
    }
}
