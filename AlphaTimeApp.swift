//
//  AlphaTimeApp.swift
//  AlphaTime
//

import SwiftUI

@main
struct AlphaTimeApp: App {
    init() {
        WordClockAppGroup.migrateIfNeeded()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.light)
        }
    }
}
