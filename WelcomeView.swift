//
//  WelcomeView.swift
//  AlphaTime
//

import SwiftUI

private let settingsBackground = Color(hex: WordClockSettings.defaultBackgroundHex)
private let settingsText = Color(hex: WordClockSettings.defaultTextHex)
private let buttonSurface = Color(hex: "FFFDF8")
private let buttonStroke = Color.black.opacity(0.10)
private let selectedFill = Color(hex: "EAF3FF")
private let selectedStroke = Color(hex: "007AFF")
private let accentBlue = Color(hex: "007AFF")
private let sheetColor = Color(hex: "F7F7F8")
private let popupWidthFraction: CGFloat = 0.72
private let popupButtonHeight: CGFloat = 58
private let popupButtonGap: CGFloat = 10
private let popupVisibleItemCount = 5
private let popupListHeight: CGFloat =
    popupButtonHeight * CGFloat(popupVisibleItemCount)
    + popupButtonGap * CGFloat(popupVisibleItemCount - 1)
private let popupCorner: CGFloat = 20
private let popupButtonCorner: CGFloat = 14

struct WelcomeView: View {
    @ObservedObject var settings: SettingsStore
    let onShowtime: () -> Void

    @State private var showLanguagePicker = false
    @State private var showFontPicker = false
    @State private var showColorsPicker = false
    @State private var showManualPicker = false
    @State private var wordClockData: WordClockData?
    @State private var previewOpacity: Double = 1

    private var language: WordClockLanguage { settings.language }
    private var fontOption: ClockFontOption {
        ClockFontOption.fromIndex(settings.fontIndex(for: language))
    }
    private var backgroundColor: Color { Color(hex: settings.backgroundColorHex) }
    private var textColor: Color { Color(hex: settings.textColorHex) }
    private var backgroundImageName: String? {
        ClockBackgrounds.imageName(for: settings.backgroundImageIndex)
    }

    private var previewPhrase: String {
        WordClockPhraseBuilder.displayPhrase(
            for: Date(),
            settings: settings.snapshot,
            data: wordClockData,
            useRandomPrefix: false
        )
    }

    var body: some View {
        ZStack {
            settingsBackground.ignoresSafeArea()
            GeometryReader { geo in
                let contentWidth = geo.size.width - 88
                VStack(spacing: 0) {
                    Spacer(minLength: 0)
                    header
                    Spacer(minLength: 0)
                    categoryRow
                    Spacer(minLength: 0)
                    Rectangle()
                        .fill(settingsText.opacity(0.18))
                        .frame(width: contentWidth * 0.6, height: 1)
                        .frame(maxWidth: .infinity)
                    Spacer(minLength: 0)
                    previewCard(contentWidth: contentWidth)
                    Spacer(minLength: 0)
                    showtimeButton(contentWidth: contentWidth)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, 44)
                .padding(.vertical, 16)
            }
        }
        .onAppear { reloadData() }
        .onChange(of: settings.languageCode) { _, _ in reloadData(); animatePreview() }
        .onChange(of: settings.hebrewNikud) { _, _ in reloadData(); animatePreview() }
        .onChange(of: settings.hebrewFontIndex) { _, _ in animatePreview() }
        .onChange(of: settings.englishFontIndex) { _, _ in animatePreview() }
        .onChange(of: settings.backgroundColorHex) { _, _ in animatePreview() }
        .onChange(of: settings.textColorHex) { _, _ in animatePreview() }
        .onChange(of: settings.backgroundImageIndex) { _, _ in animatePreview() }
        .overlay {
            if showLanguagePicker {
                LanguagePickerDialog(settings: settings) {
                    showLanguagePicker = false
                }
            }
            if showFontPicker {
                FontPickerDialog(settings: settings) {
                    showFontPicker = false
                }
            }
            if showColorsPicker {
                ColorsPickerDialog(settings: settings, onOpenManual: {
                    showManualPicker = true
                }) {
                    showColorsPicker = false
                }
            }
        }
        .overlay {
            if showManualPicker {
                ManualColorPickerSheet(settings: settings) {
                    showManualPicker = false
                }
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Text("AlphaTime")
                .font(UIChromeFont.nunito(size: 58, weight: .semibold))
                .foregroundStyle(settingsText)
                .multilineTextAlignment(.center)
            Text("Choose language, font and colors, then hit Showtime to see your clock.")
                .font(UIChromeFont.nunito(size: 20))
                .foregroundStyle(settingsText.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
        }
        .frame(maxWidth: .infinity)
    }

    private var categoryRow: some View {
        GeometryReader { geo in
            HStack(spacing: 20) {
                categoryCard(title: "Language", subtitle: "\(language.flagEmoji)  \(language.displayName)") {
                    showLanguagePicker = true
                }
                categoryCard(
                    title: "Font",
                    subtitle: {
                        var s = fontOption.label(for: language)
                        if language == .hebrew && settings.effectiveHebrewNikud { s += " · Nikud" }
                        return s
                    }()
                ) {
                    showFontPicker = true
                }
                colorsCategoryCard
            }
            .frame(width: geo.size.width * 0.9)
            .frame(maxWidth: .infinity)
        }
        .frame(height: 180)
    }

    private var colorsCategoryCard: some View {
        Button { showColorsPicker = true } label: {
            categoryChrome(title: "Colors") {
                GeometryReader { geo in
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(backgroundImageName == nil ? backgroundColor : .white)
                        if let name = backgroundImageName {
                            ClockBackgroundFill(
                                name: name,
                                opacity: max(0.05, settings.manualBackgroundOpacity),
                                cornerRadius: 10
                            )
                        } else {
                            Text("A")
                                .font(UIChromeFont.nunito(size: 18, weight: .bold))
                                .foregroundStyle(textColor)
                        }
                    }
                    .frame(width: geo.size.width * 0.72, height: 42)
                    .clipped()
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.12), lineWidth: 1))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .frame(height: 42)
            }
        }
        .buttonStyle(.plain)
    }

    private func categoryCard(title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            categoryChrome(title: title) {
                Text(subtitle)
                    .font(UIChromeFont.nunito(size: 20, weight: .medium))
                    .foregroundStyle(settingsText.opacity(0.65))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private func categoryChrome<Content: View>(
        title: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(spacing: 0) {
            Text(title)
                .font(UIChromeFont.nunito(size: 30, weight: .semibold))
                .foregroundStyle(settingsText)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)

            Spacer(minLength: 0)

            Rectangle()
                .fill(settingsText.opacity(0.14))
                .frame(height: 1)

            Spacer(minLength: 0)

            content()
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 26)
        .frame(maxWidth: .infinity, minHeight: 180, maxHeight: 180)
        .background(buttonSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(buttonStroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 3, y: 1)
    }

    private func previewCard(contentWidth: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(backgroundImageName == nil ? backgroundColor : .white)
            if let name = backgroundImageName {
                ClockBackgroundFill(
                    name: name,
                    opacity: max(0.05, settings.manualBackgroundOpacity),
                    cornerRadius: 16
                )
            }
            Text(previewPhrase)
                .font(fontOption.font(size: 36, language: language, bold: language != .hebrew))
                .foregroundStyle(textColor)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .minimumScaleFactor(0.5)
                .lineSpacing(4)
                .padding(.horizontal, 24)
                .padding(.vertical, 18)
                .opacity(previewOpacity)
        }
        .frame(width: contentWidth * 0.68)
        .frame(height: 130)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(buttonStroke, lineWidth: 1))
        .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
        .frame(maxWidth: .infinity)
    }

    private func showtimeButton(contentWidth: CGFloat) -> some View {
        Button(action: onShowtime) {
            Text("Showtime")
                .font(UIChromeFont.nunito(size: 32, weight: .semibold))
                .foregroundStyle(settingsBackground)
                .frame(width: contentWidth * 0.36)
                .frame(height: 68)
                .background(settingsText, in: RoundedRectangle(cornerRadius: 16))
                .shadow(color: .black.opacity(0.12), radius: 8, y: 3)
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func reloadData() {
        wordClockData = WordClockData(
            language: language,
            hebrewUseNikud: settings.effectiveHebrewNikud
        )
    }

    private func animatePreview() {
        withAnimation(.easeInOut(duration: 0.15)) { previewOpacity = 0.35 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.28)) { previewOpacity = 1 }
        }
    }
}

// MARK: - Popup scaffold

private enum PreviewAnimateMode {
    case text
    case colors
}

private struct SettingsPopupScaffold<Content: View>: View {
    let title: String
    @ObservedObject var settings: SettingsStore
    let hasChanges: Bool
    let onCancel: () -> Void
    let onApply: () -> Void
    var previewTopPadding: CGFloat = 36
    var previewAnimateMode: PreviewAnimateMode = .text
    @ViewBuilder var content: () -> Content

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onCancel)

            GeometryReader { geo in
                let width = min(geo.size.width * popupWidthFraction, geo.size.width - 40)
                VStack(spacing: 0) {
                    Text(title)
                        .font(UIChromeFont.nunito(size: 22, weight: .semibold))
                        .foregroundStyle(settingsText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 36)
                        .padding(.bottom, 12)

                    VStack(spacing: popupButtonGap) {
                        content()
                    }
                    .padding(.horizontal, 14)

                    Rectangle()
                        .fill(buttonStroke)
                        .frame(height: 1)
                        .padding(.horizontal, 14)
                        .padding(.top, 24)

                    VStack(spacing: popupButtonGap) {
                        SettingsLivePreview(
                            settings: settings,
                            topPadding: previewTopPadding,
                            animateMode: previewAnimateMode
                        )

                        HStack(spacing: 12) {
                            Button(action: onCancel) {
                                Text("Cancel")
                                    .font(UIChromeFont.nunito(size: 18, weight: .medium))
                                    .foregroundStyle(settingsText)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)

                            Button(action: onApply) {
                                Text(hasChanges ? "Save & Apply" : "Apply")
                                    .font(UIChromeFont.nunito(size: 18, weight: .semibold))
                                    .foregroundStyle(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(settingsText, in: RoundedRectangle(cornerRadius: 12))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 28)
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 36)
                }
                .frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
                .background(sheetColor, in: RoundedRectangle(cornerRadius: popupCorner))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }
}

private struct SettingsLivePreview: View {
    @ObservedObject var settings: SettingsStore
    var topPadding: CGFloat = 36
    var animateMode: PreviewAnimateMode = .text

    @State private var wordClockData: WordClockData?
    @State private var textOpacity: Double = 1

    private var language: WordClockLanguage { settings.language }
    private var fontOption: ClockFontOption {
        ClockFontOption.fromIndex(settings.fontIndex(for: language))
    }
    private var backgroundColor: Color { Color(hex: settings.backgroundColorHex) }
    private var textColor: Color { Color(hex: settings.textColorHex) }
    private var backgroundImageName: String? {
        ClockBackgrounds.imageName(for: settings.backgroundImageIndex)
    }
    private var previewPhrase: String {
        let phrase = WordClockPhraseBuilder.displayPhrase(
            for: Date(),
            settings: settings.snapshot,
            data: wordClockData,
            useRandomPrefix: false
        )
        return phrase.isEmpty ? "Example" : phrase
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(backgroundImageName == nil ? backgroundColor : .white)
                if let name = backgroundImageName {
                    ClockBackgroundFill(
                        name: name,
                        opacity: max(0.05, settings.manualBackgroundOpacity),
                        cornerRadius: 10
                    )
                }
                Text(previewPhrase)
                    .font(fontOption.font(size: 24, language: language, bold: language != .hebrew))
                    .foregroundStyle(textColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
                    .opacity(textOpacity)
            }
            .frame(width: geo.size.width * 0.8, height: 88)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(buttonStroke, lineWidth: 1))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 88)
        .padding(.top, topPadding)
        .padding(.bottom, 32)
        .onAppear { reloadData() }
        .onChange(of: settings.languageCode) { _, _ in reloadData(); animateText() }
        .onChange(of: settings.hebrewNikud) { _, _ in reloadData(); animateText() }
        .onChange(of: settings.hebrewFontIndex) { _, _ in animateText() }
        .onChange(of: settings.englishFontIndex) { _, _ in animateText() }
        .onChange(of: settings.backgroundColorHex) { _, _ in
            if animateMode == .colors {
                withAnimation(.easeInOut(duration: 0.25)) {}
            }
        }
    }

    private func reloadData() {
        wordClockData = WordClockData(
            language: language,
            hebrewUseNikud: settings.effectiveHebrewNikud
        )
    }

    private func animateText() {
        guard animateMode == .text else { return }
        withAnimation(.easeInOut(duration: 0.15)) { textOpacity = 0.2 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.16) {
            withAnimation(.easeInOut(duration: 0.22)) { textOpacity = 1 }
        }
    }
}

private struct HalfWidthCentered<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        GeometryReader { geo in
            content()
                .frame(width: geo.size.width * 0.5)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: popupButtonHeight)
    }
}

// MARK: - Language picker

private struct LanguagePickerDialog: View {
    @ObservedObject var settings: SettingsStore
    let onDismiss: () -> Void
    @State private var initialLanguage: WordClockLanguage = .english

    private var hasChanges: Bool { settings.language != initialLanguage }

    var body: some View {
        SettingsPopupScaffold(
            title: "Language",
            settings: settings,
            hasChanges: hasChanges,
            onCancel: {
                settings.setLanguage(initialLanguage)
                onDismiss()
            },
            onApply: onDismiss
        ) {
            ScrollView {
                VStack(spacing: popupButtonGap) {
                    ForEach(WordClockLanguage.allCases) { lang in
                        HalfWidthCentered {
                            languageRow(lang, selected: settings.language == lang) {
                                settings.setLanguage(lang)
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: popupListHeight)
            .scrollIndicators(.visible)
        }
        .onAppear { initialLanguage = settings.language }
    }

    private func languageRow(
        _ lang: WordClockLanguage,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                HStack(spacing: 12) {
                    Text(lang.flagEmoji)
                        .font(.system(size: 20))
                        .frame(width: 36, height: 36)
                        .background(
                            selected ? Color.white.opacity(0.9) : Color.black.opacity(0.04),
                            in: RoundedRectangle(cornerRadius: 10)
                        )
                    Text(lang.displayName)
                        .font(UIChromeFont.nunito(size: 18, weight: selected ? .semibold : .medium))
                        .foregroundStyle(selected ? accentBlue : settingsText)
                }
                if selected {
                    HStack {
                        Spacer()
                        Text("✓")
                            .font(UIChromeFont.nunito(size: 18, weight: .bold))
                            .foregroundStyle(accentBlue)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: popupButtonHeight)
            .background(selected ? selectedFill : buttonSurface, in: RoundedRectangle(cornerRadius: popupButtonCorner))
            .overlay(
                RoundedRectangle(cornerRadius: popupButtonCorner)
                    .stroke(selected ? selectedStroke : buttonStroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Font picker

private struct FontPickerDialog: View {
    @ObservedObject var settings: SettingsStore
    let onDismiss: () -> Void
    @State private var initialFontIndex = 0
    @State private var initialNikud = false

    private var language: WordClockLanguage { settings.language }
    private var options: [ClockFontOption] { ClockFontOption.options(for: language) }
    private var selectedIndex: Int { settings.fontIndex(for: language) }
    private var nikudSupported: Bool {
        ClockFontOption.fromIndex(selectedIndex).supportsHebrewNikud
    }
    private var hasChanges: Bool {
        selectedIndex != initialFontIndex
            || (language == .hebrew && settings.hebrewNikud != initialNikud)
    }

    var body: some View {
        SettingsPopupScaffold(
            title: "Font",
            settings: settings,
            hasChanges: hasChanges,
            onCancel: {
                settings.setFontIndex(language: language, index: initialFontIndex)
                if language == .hebrew {
                    settings.updateHebrewNikud(initialNikud)
                }
                onDismiss()
            },
            onApply: onDismiss,
            previewTopPadding: language == .hebrew ? 24 : 36
        ) {
            ScrollView {
                VStack(spacing: popupButtonGap) {
                    ForEach(options) { opt in
                        HalfWidthCentered {
                            fontRow(opt, selected: opt.index == selectedIndex) {
                                settings.setFontIndex(language: language, index: opt.index)
                                if !opt.supportsHebrewNikud {
                                    settings.updateHebrewNikud(false)
                                }
                            }
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
            .frame(height: popupListHeight)
            .scrollIndicators(.visible)

            if language == .hebrew {
                VStack(alignment: .leading, spacing: 2) {
                    Rectangle()
                        .fill(buttonStroke)
                        .frame(height: 1)
                    Button {
                        guard nikudSupported else { return }
                        settings.updateHebrewNikud(!settings.hebrewNikud)
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: settings.hebrewNikud && nikudSupported ? "checkmark.square.fill" : "square")
                                .foregroundStyle(
                                    nikudSupported
                                        ? (settings.hebrewNikud ? accentBlue : settingsText.opacity(0.35))
                                        : settingsText.opacity(0.25)
                                )
                                .font(.system(size: 22))
                            Text("Nikud")
                                .font(UIChromeFont.nunito(
                                    size: 16,
                                    weight: settings.hebrewNikud && nikudSupported ? .semibold : .medium
                                ))
                                .foregroundStyle(
                                    !nikudSupported
                                        ? settingsText.opacity(0.35)
                                        : (settings.hebrewNikud ? accentBlue : settingsText)
                                )
                            Spacer(minLength: 0)
                        }
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        .frame(height: 40, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .disabled(!nikudSupported)
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
        }
        .onAppear {
            initialFontIndex = settings.fontIndex(for: language)
            initialNikud = settings.hebrewNikud
        }
    }

    private func fontRow(
        _ opt: ClockFontOption,
        selected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            ZStack {
                Text(opt.label(for: language))
                    .font(opt.menuPreviewFont(size: 17, language: language))
                    .fontWeight(selected ? .semibold : .medium)
                    .foregroundStyle(selected ? accentBlue : settingsText)
                    .multilineTextAlignment(.center)
                if selected {
                    HStack {
                        Spacer()
                        Text("✓")
                            .font(UIChromeFont.nunito(size: 18, weight: .bold))
                            .foregroundStyle(accentBlue)
                    }
                }
            }
            .padding(.horizontal, 14)
            .frame(maxWidth: .infinity)
            .frame(height: popupButtonHeight)
            .background(selected ? selectedFill : buttonSurface, in: RoundedRectangle(cornerRadius: popupButtonCorner))
            .overlay(
                RoundedRectangle(cornerRadius: popupButtonCorner)
                    .stroke(selected ? selectedStroke : buttonStroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Colors picker

private struct ColorsPickerDialog: View {
    @ObservedObject var settings: SettingsStore
    let onOpenManual: () -> Void
    let onDismiss: () -> Void

    @State private var baselineTheme = ""
    @State private var baselineBackground = ""
    @State private var baselineText = ""
    @State private var baselineImage = 0
    @State private var baselineRecommended = true

    private var hasChanges: Bool {
        settings.selectedThemeName != baselineTheme
            || !hexEquals(settings.backgroundColorHex, baselineBackground)
            || !hexEquals(settings.textColorHex, baselineText)
            || settings.backgroundImageIndex != baselineImage
    }

    private var themeRows: [[ClockTheme]] {
        stride(from: 0, to: ClockThemes.list.count, by: 2).map { start in
            Array(ClockThemes.list[start..<min(start + 2, ClockThemes.list.count)])
        }
    }

    private var manualSwatchBackground: Color {
        if !settings.manualBackgroundComposedHex.isEmpty {
            return Color(hex: settings.manualBackgroundComposedHex)
        }
        if !settings.manualBackgroundBaseHex.isEmpty {
            return Color(hex: settings.manualBackgroundBaseHex)
                .composited(on: .white, opacity: settings.manualBackgroundOpacity)
        }
        return Color(hex: "EBEBEB")
    }

    private var manualSwatchText: Color {
        if !settings.manualTextComposedHex.isEmpty {
            return Color(hex: settings.manualTextComposedHex)
        }
        if !settings.manualTextBaseHex.isEmpty {
            return Color(hex: settings.manualTextBaseHex)
                .composited(on: .white, opacity: settings.manualTextOpacity)
        }
        return .black
    }

    var body: some View {
        SettingsPopupScaffold(
            title: "Colors",
            settings: settings,
            hasChanges: hasChanges,
            onCancel: {
                settings.restoreActiveAppearance(
                    themeName: baselineTheme,
                    backgroundHex: baselineBackground,
                    textHex: baselineText,
                    imageIndex: baselineImage,
                    recommended: baselineRecommended
                )
                onDismiss()
            },
            onApply: onDismiss,
            previewAnimateMode: .colors
        ) {
            ScrollView {
                VStack(spacing: popupButtonGap) {
                    ForEach(Array(themeRows.enumerated()), id: \.offset) { index, row in
                        let isLast = index == themeRows.count - 1
                        HStack(spacing: popupButtonGap) {
                            ForEach(row) { theme in
                                themeButton(theme)
                            }
                            if row.count == 1 && isLast {
                                manualButton
                            } else if row.count == 1 {
                                Color.clear
                                    .frame(maxWidth: .infinity)
                                    .frame(height: popupButtonHeight)
                            }
                        }
                    }
                    if ClockThemes.list.count % 2 == 0 {
                        HStack(spacing: popupButtonGap) {
                            manualButton
                            Color.clear
                                .frame(maxWidth: .infinity)
                                .frame(height: popupButtonHeight)
                        }
                    }
                }
            }
            .frame(height: popupListHeight)
            .scrollIndicators(.visible)
        }
        .onAppear {
            baselineTheme = settings.selectedThemeName
            baselineBackground = settings.backgroundColorHex
            baselineText = settings.textColorHex
            baselineImage = settings.backgroundImageIndex
            baselineRecommended = settings.recommendedColors
        }
    }

    private func themeButton(_ theme: ClockTheme) -> some View {
        let selected = settings.selectedThemeName == theme.name
        return Button {
            settings.selectTheme(theme)
        } label: {
            colorSwatch(
                background: theme.backgroundColor,
                text: theme.textColor,
                selected: selected,
                label: nil,
                imageName: nil,
                opacity: 1
            )
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: popupButtonHeight)
            .background(selected ? selectedFill : buttonSurface, in: RoundedRectangle(cornerRadius: popupButtonCorner))
            .overlay(
                RoundedRectangle(cornerRadius: popupButtonCorner)
                    .stroke(selected ? selectedStroke : buttonStroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private var manualButton: some View {
        let selected = settings.selectedThemeName.isEmpty
        let imageName = settings.manualBackgroundImageIndex > 0
            ? ClockBackgrounds.imageName(for: settings.manualBackgroundImageIndex)
            : nil
        return Button {
            if settings.hasSavedManualColors {
                settings.restoreManualColors()
            }
            onOpenManual()
        } label: {
            colorSwatch(
                background: manualSwatchBackground,
                text: manualSwatchText,
                selected: selected,
                label: "Manual",
                imageName: imageName,
                opacity: settings.manualBackgroundOpacity
            )
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity)
            .frame(height: popupButtonHeight)
            .background(selected ? selectedFill : buttonSurface, in: RoundedRectangle(cornerRadius: popupButtonCorner))
            .overlay(
                RoundedRectangle(cornerRadius: popupButtonCorner)
                    .stroke(selected ? selectedStroke : buttonStroke, lineWidth: selected ? 2 : 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func colorSwatch(
        background: Color,
        text: Color,
        selected: Bool,
        label: String?,
        imageName: String?,
        opacity: Double
    ) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: 8)
                .fill(imageName == nil ? background : .white)
            if let imageName {
                ClockBackgroundFill(
                    name: imageName,
                    opacity: max(0.05, opacity),
                    cornerRadius: 8
                )
            }
            Text(label ?? "A")
                .font(UIChromeFont.nunito(size: label == nil ? 15 : 14, weight: .bold))
                .foregroundStyle(text)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 34)
        .clipped()
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(selected ? accentBlue : Color.black.opacity(0.12), lineWidth: selected ? 2 : 1)
        )
    }

    private func hexEquals(_ a: String, _ b: String) -> Bool {
        a.trimmingCharacters(in: CharacterSet(charactersIn: "#")).caseInsensitiveCompare(
            b.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        ) == .orderedSame
    }
}

#Preview {
    WelcomeView(settings: SettingsStore.shared, onShowtime: {})
}
