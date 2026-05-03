//
//  WordClockData.swift
//  AlphaTime
//
//  Loads word_clock.json (or language-specific file) and provides phrase lookup by "HH:mm" key.
//  All displayed text comes from the JSON; no strings are calculated in code.
//

import Foundation

/// Supported display languages for the word clock.
enum WordClockLanguage: String, CaseIterable {
    case hebrew = "he"
    case english = "en"
    case swedish = "sv"
    case german = "de"
    case french = "fr"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .hebrew: return "Hebrew"
        case .swedish: return "Swedish"
        case .german: return "German"
        case .french: return "French"
        }
    }

    /// Flag emoji for the language (e.g. for settings).
    var flagEmoji: String {
        switch self {
        case .hebrew: return "🇮🇱"
        case .english: return "🇺🇸"
        case .swedish: return "🇸🇪"
        case .german: return "🇩🇪"
        case .french: return "🇫🇷"
        }
    }

    /// Bundle resource name for this language (e.g. "word_clock" or "word_clock_sv").
    var jsonResourceName: String {
        switch self {
        case .english: return "word_clock_en"
        case .hebrew: return "word_clock_he"
        case .swedish: return "word_clock_sv"
        case .german: return "word_clock_de"
        case .french: return "word_clock_fr"
        }
    }
}

/// Loads and provides lookup for word clock phrases from the bundled JSON.
struct WordClockData {
    private let phrases: [String: String]

    /// - Parameters:
    ///   - language: Display language.
    ///   - hebrewUseNikud: If true and language is Hebrew, loads `word_clock_he_nikud.json`; otherwise `word_clock_he.json`.
    init?(language: WordClockLanguage = .english, hebrewUseNikud: Bool = false, bundle: Bundle = .main) {
        let resourceName: String
        if case .hebrew = language, hebrewUseNikud {
            resourceName = "word_clock_he_nikud"
        } else {
            resourceName = language.jsonResourceName
        }
        guard let url = bundle.url(forResource: resourceName, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let decoded = try? JSONDecoder().decode([String: String].self, from: data) else {
            return nil
        }
        self.phrases = decoded
    }

    /// Returns the phrase for the given time key (e.g. "14:30"), or a fallback if missing.
    func phrase(for timeKey: String) -> String {
        phrases[timeKey] ?? "—"
    }
}
