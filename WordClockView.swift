//
//  WordClockView.swift
//  AlphaTime
//
//  Displays the current time as text from word_clock.json, with a timer that
//  updates every second but only refreshes the displayed phrase when HH:mm changes.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

/// Font options for the clock; index is stored in AppStorage per language.
enum ClockFontOption: Int, CaseIterable {
    case sansSerif = 0
    case serif = 1
    case rounded = 2
    case monospaced = 3
    case georgia = 4

    var displayName: String {
        switch self {
        case .sansSerif: return "Sans-serif"
        case .serif: return "Serif"
        case .rounded: return "Rounded"
        case .monospaced: return "Monospaced"
        case .georgia: return "Georgia"
        }
    }

    /// Font for displaying this option’s name in the menu (actual typeface).
    func menuPreviewFont(size: CGFloat = 17) -> Font {
        switch self {
        case .sansSerif: return .system(size: size, weight: .regular, design: .default)
        case .serif: return .system(size: size, weight: .regular, design: .serif)
        case .rounded: return .system(size: size, weight: .regular, design: .rounded)
        case .monospaced: return .system(size: size, weight: .regular, design: .monospaced)
        case .georgia: return .custom("Georgia", size: size)
        }
    }

    func font(size: CGFloat, language: WordClockLanguage, bold: Bool) -> Font {
        let weight: Font.Weight = bold ? .bold : .medium
        switch self {
        case .sansSerif:
            if language == .hebrew { return .system(size: size, weight: weight, design: .default) }
            return .system(size: size, weight: weight, design: .rounded)
        case .serif:
            return .system(size: size, weight: weight, design: .serif)
        case .rounded:
            return .system(size: size, weight: weight, design: .rounded)
        case .monospaced:
            return .system(size: size, weight: weight, design: .monospaced)
        case .georgia:
            if bold {
                return .custom("Georgia-Bold", size: size)
            }
            return .custom("Georgia", size: size)
        }
    }
}

struct WordClockView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage("wordClockLanguage") private var selectedLanguageRaw = WordClockLanguage.english.rawValue
    @AppStorage("backgroundColor") private var backgroundColorHex = "#e9e5d8"
    @AppStorage("textColor") private var textColorHex = "#000000"
    @AppStorage("clockDimmer") private var clockDimmer = 1.0
    @AppStorage("hebrewNikud") private var hebrewNikud = false
    @AppStorage("hebrewFontIndex") private var hebrewFontIndex = 1
    @AppStorage("englishFontIndex") private var englishFontIndex = 0
    @AppStorage("swedishFontIndex") private var swedishFontIndex = 0
    @AppStorage("germanFontIndex") private var germanFontIndex = 0
    @AppStorage("frenchFontIndex") private var frenchFontIndex = 0
    @State private var currentTimeKey: String = ""
    @State private var displayedPhrase: String = ""
    @State private var wordClockData: WordClockData?
    @State private var timer: Timer?
    @State private var showDoneButton = false
    @State private var hideDoneTask: Task<Void, Never>?
    @State private var contentOpacity: Double = 1
    @State private var transitionTask: Task<Void, Never>?

    private static let timeChangeDuration: Double = 0.4
    private static var timeChangeAnimation: Animation { .easeInOut(duration: timeChangeDuration) }

    private var currentLanguage: WordClockLanguage {
        WordClockLanguage(rawValue: selectedLanguageRaw) ?? .english
    }

    /// iPad in landscape: detected via device idiom and actual size (width > height).
    private func isIPadLandscape(geometry: GeometryProxy) -> Bool {
        #if targetEnvironment(macCatalyst)
        return false
        #elseif os(iOS)
        let isIPad = UIDevice.current.userInterfaceIdiom == .pad
        let isLandscape = geometry.size.width > geometry.size.height
        return isIPad && isLandscape
        #else
        return false
        #endif
    }

    /// For iPad landscape: sentence split into two roughly equal lines; otherwise original.
    private func clockDisplayText(iPadLandscape: Bool) -> String {
        guard iPadLandscape else { return displayedPhrase }
        return Self.splitSentenceIntoTwoLines(displayedPhrase)
    }

    private func fontIndexForCurrentLanguage() -> Int {
        switch currentLanguage {
        case .hebrew: return hebrewFontIndex
        case .english: return englishFontIndex
        case .swedish: return swedishFontIndex
        case .german: return germanFontIndex
        case .french: return frenchFontIndex
        }
    }

    /// Font for the clock text from the selected font option for the current language.
    private func clockFont(iPadLandscape: Bool) -> Font {
        let size: CGFloat = iPadLandscape ? 150 : 80
        let option = ClockFontOption(rawValue: fontIndexForCurrentLanguage()) ?? .sansSerif
        let bold = currentLanguage != .hebrew
        return option.font(size: size, language: currentLanguage, bold: bold)
    }

    /// Splits the sentence at a space nearest the middle so both lines are roughly equal length.
    private static func splitSentenceIntoTwoLines(_ s: String) -> String {
        let trimmed = s.trimmingCharacters(in: .whitespaces)
        guard trimmed.count > 1 else { return s }
        let mid = trimmed.count / 2
        let chars = Array(trimmed)
        var splitIndex: Int? = nil
        for offset in 0..<mid {
            let left = mid - offset
            let right = mid + offset
            if left > 0, left < chars.count, chars[left] == " " {
                splitIndex = left
                break
            }
            if right > 0, right < chars.count, chars[right] == " " {
                splitIndex = right
                break
            }
        }
        guard let idx = splitIndex else { return s }
        let before = String(chars.prefix(idx)).trimmingCharacters(in: .whitespaces)
        let after = String(chars.dropFirst(idx)).trimmingCharacters(in: .whitespaces)
        if after.isEmpty { return s }
        return before + "\n" + after
    }

    private static let timePrefixes = [
//        "The time is",
        "Time is",
//        "It is",
//        "It's currently",
//        "It's",
//        "Right now it's",
//        "The time now is",
//        "Now it's",
//        "It's about",
//        "We're at",
//        "Currently it's",
//        "Right about",
//        "Just turned",
//        "Exactly",
//        "Precisely",
//        "Sharply",
//        "Present time is",
//        "Of cours it's",
//        "Time check is",
//        "System time is",
//        "Looking at",
//        "I see",
//        "My clock shows",
//        "Steady at",
//        "Captured at",
//        "The hour is",
//        "It's already",
    ]

    private static let hebrewPrefixes = [
//        "השעה עכשיו",
//        "השעה היא",
//        "הזמן כרגע",
        "השעה",
//        "עכשיו",
//        "בדיוק עכשיו",
//        "כרגע",
//        "כבר",
//        "בערך",
//        "ברור שעכשיו",
//        "פלוס מינוס",
//        "ממש עכשיו",
//        "זמן נוכחי",
//        "גם אתמול היה",
    ]
    
    private static let hebrewPrefixesNukid = [
//        "הַשָּׁעָה עַכְשָׁיו",        // The hour now is
//        "הַשָּׁעָה הִיא",          // The hour is
//        "הַזְּמַן כָּרֶגַע",        // The time currently
        "הַשָּׁעָה",               // The hour
//        "עַכְשָׁיו",               // Now
//        "בְּדִיּוּק עַכְשָׁיו",      // Exactly now
//        "כָּרֶגַע",                // Currently
//        "כְּבָר",                 // Already
//        "בְּעֵרֶךְ",               // Approximately
//        "בָּרוּר שֶׁעַכְשָׁיו",      // Clearly it's now
//        "פְּלוּס מִינוּס",          // Plus minus
//        "מַמָּשׁ עַכְשָׁיו",         // Right now
//        "זְמַן נוֹכְחִי",          // Current time
//        "גַּם אֶתְמוֹל הָיָה",       // Yesterday was also...
//        "בְּדִיּוּק"               // Exactly
    ]

    private static let swedishPrefixes = [
        "Klockan är",
//        "Det är",
//        "Just nu är klockan",
//        "Klockan visar",
//        "Tiden är",
//        "Nu är det",
//        "Ungefär",
//        "Prick",
//        "Exakt",
//        "Vi är vid",
//        "Tidsavståndet är",
    ]

    private static let germanPrefixes = [
        "Es ist",              // It is (Standard)
//        "Gerade ist es",       // Right now it is
//        "Die Uhr zeigt",       // The clock shows
//        "Wir haben",           // We have (e.g. "Wir haben eins")
//        "Pünktlich",           // On time / Exactly
//        "Schon",               // Already
//        "Aktuelle Zeit:"       // Current time
    ]

    private static let frenchPrefixes = [
        "Il est",               // It is (Standard)
//        "Il est exactement",    // It is exactly
//        "L'heure est",          // The hour is
//        "Maintenant il est",    // Now it is
//        "La montre indique",    // The watch indicates
//        "Bientôt",              // Soon
//        "C'est"                 // It is (Casual)
    ]

    /// Time-of-day suffix in German (e.g. "morgens").
    private static func getTimeOfDaySuffixGerman(hour: Int) -> String {
        switch hour {
        case 5...10: return "morgens"
        case 11...12: return "mittags"
        case 13...17: return "nachmittags"
        case 18...22: return "abends"
        default: return "nachts"
        }
    }

    /// Time-of-day suffix in French (e.g. "du matin").
    private static func getTimeOfDaySuffixFrench(hour: Int) -> String {
        switch hour {
        case 5...11:
            return "du matin"        // In the morning
        case 12...17:
            return "de l'après-midi" // In the afternoon
        case 18...23:
            return "du soir"         // In the evening
        default:
            return "du matin"        // Late night
        }
    }

    private static let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "HH:mm"
        f.locale = Locale(identifier: "en_US_POSIX")
        return f
    }()

    /// Time-of-day suffix in Hebrew with nikud (e.g. "בַּבּוֹקֶר").
    private static func getTimeOfDaySuffixHebrewWithNikud(hour: Int) -> String {
        switch hour {
        case 5...11:
            return "בַּבּוֹקֶר"      // Morning (5 AM - 11 AM)
        case 12...16:
            return "בַּצָּהֳרַיִם"    // Afternoon (12 PM - 4 PM)
        case 17...21:
            return "בָּעֶרֶב"       // Evening (5 PM - 9 PM)
        default:
            return "בַּלַּיְלָה"      // Night (10 PM - 4 AM)
        }
    }

    /// Time-of-day suffix in Hebrew without nikud (e.g. "בבוקר").
    private static func getTimeOfDaySuffixHebrewWithoutNikud(hour: Int) -> String {
        switch hour {
        case 5...11:
            return "בבוקר"      // Morning (5 AM - 11 AM)
        case 12...16:
            return "בצהרים"    // Afternoon (12 PM - 4 PM)
        case 17...21:
            return "בערב"       // Evening (5 PM - 9 PM)
        default:
            return "בלילה"      // Night (10 PM - 4 AM)
        }
    }

    /// Time-of-day suffix in English (e.g. "in the morning").
    private static func getTimeOfDaySuffixEnglish(hour: Int) -> String {
        switch hour {
        case 5...11:
            return "in the morning"
        case 12...16:
            return "in the afternoon"
        case 17...21:
            return "in the evening"
        default:
            return "at night"
        }
    }

    /// Time-of-day suffix in Swedish (e.g. "på morgonen").
    private static func getTimeOfDaySuffixSwedish(hour: Int) -> String {
        switch hour {
        case 5...11:
            return "på morgonen"       // Morning
        case 12...16:
            return "på eftermiddagen"  // Afternoon
        case 17...21:
            return "på kvällen"        // Evening
        default:
            return "på natten"         // Night
        }
    }

    var body: some View {
        GeometryReader { geometry in
            let iPadLandscape = isIPadLandscape(geometry: geometry)
            ZStack {
                Color(hex: backgroundColorHex)
                    .ignoresSafeArea()

                Text(clockDisplayText(iPadLandscape: iPadLandscape))
                    .font(clockFont(iPadLandscape: iPadLandscape))
                    .multilineTextAlignment(.center)
                    .lineLimit(iPadLandscape ? 2 : (verticalSizeClass == .regular ? 3 : 2))
                    .minimumScaleFactor(0.35)
                    .foregroundStyle(Color(hex: textColorHex))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.horizontal, iPadLandscape ? 48 : 32)
                    .opacity(contentOpacity)
                    .animation(Self.timeChangeAnimation, value: contentOpacity)
            }
        }
        .overlay {
            Color.black.opacity(1 - clockDimmer)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            showDoneButton = true
            scheduleHideDoneAfterThreeSeconds()
        }
        .overlay(alignment: .topTrailing) {
            if showDoneButton {
                Button("Close") {
                    dismiss()
                }
                .font(.system(size: 22, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(hex: textColorHex))
                .padding(28)
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: showDoneButton)
        .onAppear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = true
            #endif
            loadData()
            tick()
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                tick()
            }
            RunLoop.main.add(timer!, forMode: .common)
        }
        .onChange(of: selectedLanguageRaw) { _, _ in
            loadData()
            tick()
        }
        .onChange(of: hebrewNikud) { _, _ in
            loadData()
            tick()
        }
        .onDisappear {
            #if canImport(UIKit)
            UIApplication.shared.isIdleTimerDisabled = false
            #endif
            timer?.invalidate()
            timer = nil
            transitionTask?.cancel()
        }
    }

    private func scheduleHideDoneAfterThreeSeconds() {
        hideDoneTask?.cancel()
        hideDoneTask = Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            guard !Task.isCancelled else { return }
            await MainActor.run {
                showDoneButton = false
            }
        }
    }

    private func loadData() {
        wordClockData = WordClockData(language: currentLanguage, hebrewUseNikud: hebrewNikud)
    }

    private func tick() {
        let key = Self.timeFormatter.string(from: Date())
        guard key != currentTimeKey else { return }

        let phrase = wordClockData?.phrase(for: key) ?? "—"
        let prefix: String
        switch currentLanguage {
        case .hebrew:
            prefix = hebrewNikud
                ? (Self.hebrewPrefixesNukid.randomElement() ?? Self.hebrewPrefixesNukid[0])
                : (Self.hebrewPrefixes.randomElement() ?? Self.hebrewPrefixes[0])
        case .english:
            prefix = Self.timePrefixes.randomElement() ?? Self.timePrefixes[0]
        case .swedish:
            prefix = Self.swedishPrefixes.randomElement() ?? Self.swedishPrefixes[0]
        case .german:
            prefix = Self.germanPrefixes.randomElement() ?? Self.germanPrefixes[0]
        case .french:
            prefix = Self.frenchPrefixes.randomElement() ?? Self.frenchPrefixes[0]
        }
        let hour = Int(key.prefix(2)) ?? 0
        var newPhrase = "\(prefix) \(phrase)"
        switch currentLanguage {
        case .hebrew:
            let suffix = hebrewNikud
                ? Self.getTimeOfDaySuffixHebrewWithNikud(hour: hour)
                : Self.getTimeOfDaySuffixHebrewWithoutNikud(hour: hour)
            let exactlyWithNikud = " בְּדִיּוּק"
            let exactlyNoNikud = " בדיוק"
            let phraseEndsWithExactly: Bool
            let trimmedPhrase: String
            let exactlyWord: String
            if phrase.hasSuffix(exactlyWithNikud) {
                phraseEndsWithExactly = true
                trimmedPhrase = String(phrase.dropLast(exactlyWithNikud.count)).trimmingCharacters(in: .whitespaces)
                exactlyWord = "בְּדִיּוּק"
            } else if phrase.hasSuffix(exactlyNoNikud) {
                phraseEndsWithExactly = true
                trimmedPhrase = String(phrase.dropLast(exactlyNoNikud.count)).trimmingCharacters(in: .whitespaces)
                exactlyWord = "בדיוק"
            } else {
                phraseEndsWithExactly = false
                trimmedPhrase = phrase
                exactlyWord = ""
            }
            if phraseEndsWithExactly {
                newPhrase = "\(prefix) \(trimmedPhrase) \(suffix) \(exactlyWord)"
            } else {
                let isExactlyPrefix = (prefix == "בדיוק" || prefix == "בְּדִיּוּק")
                if isExactlyPrefix {
                    newPhrase = phrase + " " + suffix + " " + prefix
                } else {
                    newPhrase += " " + suffix
                }
            }
        case .english:
            newPhrase += " " + Self.getTimeOfDaySuffixEnglish(hour: hour)
        case .swedish:
            newPhrase += " " + Self.getTimeOfDaySuffixSwedish(hour: hour)
        case .german:
            newPhrase += " " + Self.getTimeOfDaySuffixGerman(hour: hour)
        case .french:
            newPhrase += " " + Self.getTimeOfDaySuffixFrench(hour: hour)
        }

        // Cancel any in-flight transition
        transitionTask?.cancel()

        transitionTask = Task {
            // Phase 1: fade out the current text
            await MainActor.run {
                withAnimation(Self.timeChangeAnimation) {
                    contentOpacity = 0
                }
            }
            try? await Task.sleep(nanoseconds: UInt64(Self.timeChangeDuration * 1_000_000_000))
            guard !Task.isCancelled else { return }

            // Phase 2: update content, then fade in the new text
            await MainActor.run {
                currentTimeKey = key
                displayedPhrase = newPhrase
                withAnimation(Self.timeChangeAnimation) {
                    contentOpacity = 1
                }
            }
        }
    }
}

#Preview {
    WordClockView()
}
