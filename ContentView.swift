//
//  ContentView.swift
//  AlphaTime
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var showWordClock = false

    var body: some View {
        WelcomeView(settings: settings, onShowtime: { showWordClock = true })
            .fullScreenCover(isPresented: $showWordClock) {
                WordClockView(settings: settings)
            }
            .statusBarHidden(true)
    }
}

#Preview {
    ContentView()
}
