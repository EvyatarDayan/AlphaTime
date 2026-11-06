//
//  ContentView.swift
//  AlphaTime
//

import SwiftUI

struct ContentView: View {
    @StateObject private var settings = SettingsStore.shared
    @State private var showWordClock = false

    var body: some View {
        ZStack {
            WelcomeView(settings: settings, onShowtime: {
                withAnimation(.easeInOut(duration: 0.4)) {
                    showWordClock = true
                }
            })

            if showWordClock {
                WordClockView(settings: settings, onClose: {
                    withAnimation(.easeInOut(duration: 0.4)) {
                        showWordClock = false
                    }
                })
                .transition(.opacity)
                .zIndex(1)
            }
        }
        .statusBarHidden(true)
    }
}

#Preview {
    ContentView()
}
