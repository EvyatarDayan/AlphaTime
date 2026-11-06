//
//  WordClockView.swift
//  AlphaTime
//

import SwiftUI

struct WordClockView: View {
    @ObservedObject var settings: SettingsStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @StateObject private var speech = TimeSpeechReader()
    @State private var currentTimeKey = ""
    @State private var displayedPhrase = ""
    @State private var wordClockData: WordClockData?
    @State private var showControls = false
    @State private var contentOpacity: Double = 1
    @State private var hideControlsTask: Task<Void, Never>?
    @State private var transitionTask: Task<Void, Never>?
    @State private var liveSizeValue: Double = 5

    private static let timeChangeDuration: Double = 0.4

    private var language: WordClockLanguage { settings.language }
    private var backgroundColor: Color { Color(hex: settings.backgroundColorHex) }
    private var textColor: Color { Color(hex: settings.textColorHex) }
    private var backgroundImageName: String? {
        ClockBackgrounds.imageName(for: settings.backgroundImageIndex)
    }
    private var backgroundImageOpacity: Double {
        max(0.05, min(1, settings.manualBackgroundOpacity))
    }
    private var fontOption: ClockFontOption {
        ClockFontOption.fromIndex(settings.snapshot.fontIndex)
    }
    private var isLargeLandscape: Bool {
        horizontalSizeClass == .regular
    }

    private var displayLines: [String] {
        let (a, b) = WordClockPhraseBuilder.splitSentenceIntoTwoLines(displayedPhrase)
        return [a, b].map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
    }

    private var sizeScale: CGFloat {
        let progress = CGFloat((liveSizeValue - 1) / 4)
        return 0.50 + progress * 0.50
    }

    var body: some View {
        GeometryReader { geometry in
            let baseSize: CGFloat = isLargeLandscape ? 150 : 80
            let fontSize = baseSize * sizeScale

            ZStack {
                Group {
                    if backgroundImageName != nil {
                        Color.white
                    } else {
                        backgroundColor
                    }
                }
                .ignoresSafeArea()

                if let name = backgroundImageName {
                    let fullWidth = geometry.size.width
                        + geometry.safeAreaInsets.leading
                        + geometry.safeAreaInsets.trailing
                    let fullHeight = geometry.size.height
                        + geometry.safeAreaInsets.top
                        + geometry.safeAreaInsets.bottom
                    ClockBackgroundFill(name: name, opacity: backgroundImageOpacity)
                        .frame(width: fullWidth, height: fullHeight)
                        .clipped()
                        .ignoresSafeArea()
                }

                VStack(spacing: (isLargeLandscape ? 28 : 20) * sizeScale) {
                    ForEach(Array(displayLines.enumerated()), id: \.offset) { _, line in
                        Text(line)
                            .font(fontOption.font(size: fontSize, language: language, bold: language != .hebrew))
                            .foregroundStyle(textColor)
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.2)
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.horizontal, isLargeLandscape ? 48 : 32)
                .opacity(contentOpacity)
                .animation(.easeInOut(duration: Self.timeChangeDuration), value: contentOpacity)

                if settings.clockDimmer < 1 {
                    Color.black.opacity(1 - settings.clockDimmer)
                        .ignoresSafeArea()
                        .allowsHitTesting(false)
                }

                if showControls {
                    controlsOverlay
                        .transition(.opacity)
                }
            }
            .contentShape(Rectangle())
            .onTapGesture {
                showControls = true
                scheduleHideControls()
            }
        }
        .statusBarHidden(true)
        .persistentSystemOverlays(.hidden)
        .onAppear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            liveSizeValue = Double(settings.clockTextSizeLevel)
            speech.prepare(language: language)
            reloadData()
            tick(force: true)
            startTimer()
        }
        .onDisappear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
            speech.stop()
            transitionTask?.cancel()
            hideControlsTask?.cancel()
            timer?.invalidate()
            timer = nil
        }
        .onChange(of: settings.languageCode) { _, _ in
            speech.prepare(language: language)
            reloadData()
            tick(force: true)
        }
        .onChange(of: settings.hebrewNikud) { _, _ in reloadData(); tick(force: true) }
        .onChange(of: settings.hebrewFontIndex) { _, _ in reloadData(); tick(force: true) }
        .onChange(of: settings.clockTextSizeLevel) { _, newValue in
            liveSizeValue = Double(newValue)
        }
    }

    @State private var timer: Timer?

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            Task { @MainActor in tick(force: false) }
        }
        if let timer {
            RunLoop.main.add(timer, forMode: .common)
        }
    }

    private var controlsOverlay: some View {
        ZStack {
            VStack {
                HStack(alignment: .top) {
                    HStack(spacing: 12) {
                        if backgroundImageName == nil {
                            colorSwapButton
                        }
                        speakButton
                    }
                    Spacer()
                    closeButton
                }
                .padding(.top, 28)
                .padding(.horizontal, 28)
                Spacer()
                sizeSlider
                    .containerRelativeFrame(.horizontal) { width, _ in width * 0.4 }
                    .padding(.bottom, 28)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showControls)
    }

    private var colorSwapButton: some View {
        Button {
            settings.swapClockColors()
            scheduleHideControls()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(textColor.opacity(0.12))
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(textColor.opacity(0.28), lineWidth: 1))
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(backgroundColor)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(textColor.opacity(0.55), lineWidth: 1.5))
                        .frame(width: 20, height: 20)
                        .offset(x: -4, y: -4)
                    RoundedRectangle(cornerRadius: 5)
                        .fill(textColor)
                        .overlay(RoundedRectangle(cornerRadius: 5).stroke(backgroundColor.opacity(0.55), lineWidth: 1.5))
                        .frame(width: 20, height: 20)
                        .offset(x: 4, y: 4)
                }
            }
            .frame(width: 56, height: 56)
        }
        .buttonStyle(.plain)
    }

    private var speakButton: some View {
        Button {
            speech.speak(phrase: displayedPhrase, language: language)
            scheduleHideControls()
        } label: {
            Image(systemName: speech.isSpeaking ? "speaker.wave.2.fill" : "speaker.wave.2")
                .font(.system(size: 22, weight: .semibold))
                .foregroundStyle(textColor)
                .frame(width: 56, height: 56)
                .background(textColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                .overlay(RoundedRectangle(cornerRadius: 16).stroke(textColor.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var closeButton: some View {
        Button {
            dismiss()
        } label: {
            Image(systemName: "xmark")
                .font(.system(size: 20, weight: .bold))
                .foregroundStyle(textColor)
                .frame(width: 56, height: 56)
                .background(textColor.opacity(0.12), in: Circle())
                .overlay(Circle().stroke(textColor.opacity(0.28), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    private var sizeSlider: some View {
        VStack(spacing: 8) {
            Slider(
                value: $liveSizeValue,
                in: 1...5
            ) { editing in
                if !editing {
                    let snapped = liveSizeValue.rounded()
                    liveSizeValue = snapped
                    settings.updateClockTextSizeLevel(Int(snapped))
                }
                scheduleHideControls()
            }
            .tint(textColor)
            .animation(.interactiveSpring(response: 0.25, dampingFraction: 0.85), value: liveSizeValue)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 14))
    }

    private func scheduleHideControls() {
        showControls = true
        hideControlsTask?.cancel()
        hideControlsTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run { showControls = false }
        }
    }

    private func reloadData() {
        wordClockData = WordClockData(
            language: language,
            hebrewUseNikud: settings.effectiveHebrewNikud
        )
    }

    private func tick(force: Bool) {
        let key = WordClockPhraseBuilder.timeKey(for: Date())
        guard force || key != currentTimeKey else { return }

        let newPhrase = WordClockPhraseBuilder.displayPhrase(
            for: Date(),
            settings: settings.snapshot,
            data: wordClockData,
            useRandomPrefix: true
        )

        transitionTask?.cancel()
        transitionTask = Task {
            await MainActor.run {
                withAnimation(.easeInOut(duration: Self.timeChangeDuration)) {
                    contentOpacity = 0
                }
            }
            try? await Task.sleep(nanoseconds: UInt64(Self.timeChangeDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                currentTimeKey = key
                displayedPhrase = newPhrase
                withAnimation(.easeInOut(duration: Self.timeChangeDuration)) {
                    contentOpacity = 1
                }
            }
        }
    }
}

#Preview {
    WordClockView(settings: SettingsStore.shared)
}
