//
//  WelcomeView.swift
//  AlphaTime
//
//  Welcome screen with settings and a button to show the Word Clock.
//

import SwiftUI

struct Theme {
    let name: String
    let backgroundColor: Color
    let textColor: Color
    let secondaryColor: Color
}

private enum Themes {
    static var list: [Theme] {
        [
            Theme(name: "Midnight", backgroundColor: Color(hex: "050505"), textColor: Color(hex: "D4AF37"), secondaryColor: Color(hex: "8E8E93")),
            Theme(name: "Desert", backgroundColor: Color(hex: "F4ECD8"), textColor: Color(hex: "3D2B1F"), secondaryColor: Color(hex: "7D6B5D")),
            Theme(name: "Warm", backgroundColor: Color(hex: "A3001C"), textColor: Color(hex: "ECF0F1"), secondaryColor: Color(hex: "3A3A3C")),
            Theme(name: "Nordic", backgroundColor: Color(hex: "2C3E50"), textColor: Color(hex: "ECF0F1"), secondaryColor: Color(hex: "BDC3C7"))
        ]
    }
}

struct WelcomeView: View {
    @AppStorage("wordClockLanguage") private var selectedLanguageRaw = WordClockLanguage.english.rawValue
    @AppStorage("backgroundColor") private var backgroundColorHex = "#e9e5d8"
    @AppStorage("textColor") private var textColorHex = "#000000"
    @AppStorage("hebrewNikud") private var hebrewNikud = false
    @AppStorage("hebrewFontIndex") private var hebrewFontIndex = 1
    @AppStorage("englishFontIndex") private var englishFontIndex = 0
    @AppStorage("swedishFontIndex") private var swedishFontIndex = 0
    @AppStorage("germanFontIndex") private var germanFontIndex = 0
    @AppStorage("frenchFontIndex") private var frenchFontIndex = 0
    @AppStorage("recommendedColors") private var recommendedColors = true
    @AppStorage("selectedThemeName") private var selectedThemeName = ""
    @AppStorage("manualBackgroundBaseHex") private var manualBackgroundBaseHex = ""
    @AppStorage("manualBackgroundOpacity") private var manualBackgroundOpacity = 1.0
    @AppStorage("manualTextBaseHex") private var manualTextBaseHex = ""
    @AppStorage("manualTextOpacity") private var manualTextOpacity = 1.0
    @State private var showWordClock = false
    @State private var showManualColorPicker = false

    private var backgroundColor: Color { Color(hex: backgroundColorHex) }
    private var textColor: Color { Color(hex: textColorHex) }

    /// Colors to show in the Manual row swatch: last manual selection, or empty square + black A.
    private var manualSwatchBackground: Color {
        guard !manualBackgroundBaseHex.isEmpty else { return Color(white: 0.92) }
        return Color(hex: manualBackgroundBaseHex).composited(on: .white, opacity: manualBackgroundOpacity)
    }
    private var manualSwatchText: Color {
        guard !manualTextBaseHex.isEmpty else { return .black }
        return Color(hex: manualTextBaseHex).composited(on: .white, opacity: manualTextOpacity)
    }

    private static let recommendedBackgroundHex = "#e9e5d8"
    private static let recommendedTextHex = "#000000"

    /// Colors used only for the settings (Welcome) view; always recommended.
    private var settingsBackgroundColor: Color { Color(hex: Self.recommendedBackgroundHex) }
    private var settingsTextColor: Color { Color(hex: Self.recommendedTextHex) }

    private func fontIndexBinding(for language: WordClockLanguage) -> Binding<Int>? {
        switch language {
        case .hebrew: return $hebrewFontIndex
        case .english: return $englishFontIndex
        case .swedish: return $swedishFontIndex
        case .german: return $germanFontIndex
        case .french: return $frenchFontIndex
        }
    }

    var body: some View {
        ZStack {
            settingsBackgroundColor
                .ignoresSafeArea()
            mainContent
        }
        .fullScreenCover(isPresented: $showWordClock) {
            WordClockView()
        }
    }

    private var mainContent: some View {
        VStack(spacing: 0) {
            Text("AlphaTime")
                .font(.system(size: 34, weight: .semibold, design: .rounded))
                .foregroundStyle(settingsTextColor)
                .frame(maxWidth: .infinity)
                .padding(.top, 48)
            Text("Choose language, font and colors, then hit Showtime to see your clock.")
                .font(.system(size: 15, weight: .regular, design: .rounded))
                .foregroundStyle(settingsTextColor.opacity(0.85))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .padding(.horizontal, 28)
                .padding(.top, 6)
                .padding(.bottom, 24)
            ScrollView {
                VStack(spacing: 32) {
                    languageCard
                    colorsCard
                    colorPreviewRow
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
            showtimeButton
        }
    }

    private var languageCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Language")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(settingsTextColor)
            VStack(spacing: 0) {
                ForEach(Array(WordClockLanguage.allCases.enumerated()), id: \.element.rawValue) { index, lang in
                    LanguageRow(
                        language: lang,
                        isSelected: selectedLanguageRaw == lang.rawValue,
                        textColor: settingsTextColor,
                        showNikudCheckbox: lang == .hebrew,
                        nikudChecked: $hebrewNikud,
                        fontIndexBinding: fontIndexBinding(for: lang)
                    ) {
                        selectedLanguageRaw = lang.rawValue
                    }
                    if index < WordClockLanguage.allCases.count - 1 {
                        Divider()
                            .padding(.leading, 18)
                    }
                }
            }
            .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var colorsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Colors")
                .font(.system(size: 17, weight: .medium, design: .rounded))
                .foregroundStyle(settingsTextColor)
            VStack(spacing: 0) {
                themesSection
            }
            .background(Color.white.opacity(0.7), in: RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.black.opacity(0.08), lineWidth: 0.5))
            .shadow(color: Color.black.opacity(0.06), radius: 6, x: 0, y: 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var themesSection: some View {
        VStack(spacing: 0) {
            ForEach(Array(Themes.list.enumerated()), id: \.element.name) { index, theme in
                ThemeRow(
                    theme: theme,
                    isSelected: selectedThemeName == theme.name,
                    settingsTextColor: settingsTextColor,
                    onSelect: {
                        selectedThemeName = theme.name
                        recommendedColors = true
                        backgroundColorHex = theme.backgroundColor.hexString
                        textColorHex = theme.textColor.hexString
                    }
                )
                if index < Themes.list.count - 1 {
                    Divider()
                        .padding(.leading, 18)
                }
            }
            Divider()
                .padding(.leading, 18)
            manualColorRow
        }
        .sheet(isPresented: $showManualColorPicker) {
            ManualColorPickerSheet(
                backgroundColorHex: $backgroundColorHex,
                textColorHex: $textColorHex,
                settingsTextColor: settingsTextColor,
                onSelect: {
                    recommendedColors = false
                    selectedThemeName = ""
                }
            )
        }
    }

    private var manualColorRow: some View {
        Button {
            showManualColorPicker = true
        } label: {
            HStack(spacing: 12) {
                ThemeColorSwatch(backgroundColor: manualSwatchBackground, textColor: manualSwatchText)
                Text("Manual color")
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(settingsTextColor)
                Spacer(minLength: 8)
                ZStack(alignment: .trailing) {
                    Color.clear
                    if selectedThemeName.isEmpty {
                        Image("editManual")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 22, height: 22)
                            .foregroundStyle(settingsTextColor)
                    }
                }
                .frame(width: 28, height: 22)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(selectedThemeName.isEmpty ? Color(red: 0.85, green: 0.95, blue: 0.85) : Color.clear)
        }
        .buttonStyle(.plain)
    }

    private var colorPreviewRow: some View {
        HStack {
            Spacer(minLength: 0)
            Text("Example")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(textColor)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(backgroundColor, in: RoundedRectangle(cornerRadius: 8))
//                .overlay(RoundedRectangle(cornerRadius: 8).stroke(settingsTextColor.opacity(0.25), lineWidth: 1))
            Spacer(minLength: 0)
        }
//        .padding(.vertical, 4)
    }

    private var showtimeButton: some View {
        Button(action: { showWordClock = true }) {
            Text("Showtime")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(settingsBackgroundColor)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(settingsTextColor, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
        .padding(.top, 16)
    }
}

private struct SimpleColorPickerSheet: View {
    let title: String
    @Binding var selectedHex: String
    let presetHexes: [String]
    let settingsTextColor: Color
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss

    static let presetHexes: [String] = [
        "#FFFFFF", "#F2F2F7", "#E9E5D8", "#F4ECD8",
        "#BDC3C7", "#8E8E93", "#3A3A3C", "#1C1C1E",
        "#000000", "#050505", "#2C3E50", "#3D2B1F",
        "#D4AF37", "#ECF0F1", "#7D6B5D", "#B8860B",
        "#6B7B6B", "#1C2E1C", "#F5F0E6", "#C4A574", "#A0522D",
        "#87CEEB", "#00B4D8", "#1E3A5F", "#FFB347", "#CC5500",
        "#800020", "#DC143C", "#FFF8E7", "#1B365D", "#6B8E9E",
        "#E6E6FA", "#FFC0CB", "#E8A0A0", "#ADD8E6", "#A8D4ED"
    ]

    /// Preset colors ordered dark → light (by luminance) for a logical gradient in the manual picker.
    static var presetHexesSortedByLuminance: [String] {
        presetHexes.sorted { luminance(for: $0) < luminance(for: $1) }
    }

    private static func luminance(for hex: String) -> Double {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        guard cleaned.count == 6,
              let r = Int(cleaned.prefix(2), radix: 16),
              let g = Int(cleaned.dropFirst(2).prefix(2), radix: 16),
              let b = Int(cleaned.suffix(2), radix: 16) else { return 0.5 }
        return (0.299 * Double(r) + 0.587 * Double(g) + 0.114 * Double(b)) / 255
    }

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 12), count: 4)

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(presetHexes, id: \.self) { hex in
                        Button {
                            selectedHex = hex
                            onSelect()
                            dismiss()
                        } label: {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color(hex: hex))
                                .frame(width: 32, height: 32)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(selectedHex.uppercased() == hex.uppercased() ? settingsTextColor : Color.clear, lineWidth: 2)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(20)
            }
            .background(Color(hex: "F2F2F7"))
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(settingsTextColor)
                }
            }
        }
    }
}

private struct ManualColorPickerSheet: View {
    @Binding var backgroundColorHex: String
    @Binding var textColorHex: String
    let settingsTextColor: Color
    let onSelect: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isEditingBackground = true
    @State private var selectedColorHex: String = "#000000"
    @State private var opacity: Double = 1.0
    @AppStorage("manualBackgroundBaseHex") private var manualBackgroundBaseHex = ""
    @AppStorage("manualBackgroundOpacity") private var manualBackgroundOpacity = 1.0
    @AppStorage("manualTextBaseHex") private var manualTextBaseHex = ""
    @AppStorage("manualTextOpacity") private var manualTextOpacity = 1.0

    private var backgroundColor: Color { Color(hex: backgroundColorHex) }
    private var textColor: Color { Color(hex: textColorHex) }

    private static let gridColumns = 10
    private static let gridRows = 10

    private func colorAt(row: Int, column: Int) -> Color {
        // Row 0: grayscale (white → black)
        if row == 0 {
            let v = 1.0 - Double(column) / Double(max(1, Self.gridColumns - 1))
            return Color.fromHSV(hue: 0, saturation: 0, brightness: max(0, min(1, v)))
        }
        // Rows 1–9: hue down (red → yellow → green → cyan → blue → magenta), pastel→vivid across
        let h = Double(row - 1) / 8.0
        let sat = 0.3 + 0.7 * Double(column) / 9.0
        let v = 0.95 - 0.5 * Double(column) / 9.0
        return Color.fromHSV(hue: h, saturation: sat, brightness: max(0.25, min(1, v)))
    }

    private var displayColor: Color {
        let base = Color(hex: selectedColorHex)
        return base.composited(on: .white, opacity: opacity)
    }

    private func applyToBinding() {
        let hex = displayColor.hexString
        if isEditingBackground {
            backgroundColorHex = hex
            manualBackgroundBaseHex = selectedColorHex
            manualBackgroundOpacity = opacity
        } else {
            textColorHex = hex
            manualTextBaseHex = selectedColorHex
            manualTextOpacity = opacity
        }
        onSelect()
    }

    private func loadStateForCurrentSegment() {
        if isEditingBackground {
            selectedColorHex = manualBackgroundBaseHex.isEmpty ? backgroundColorHex : manualBackgroundBaseHex
            opacity = manualBackgroundOpacity
        } else {
            selectedColorHex = manualTextBaseHex.isEmpty ? textColorHex : manualTextBaseHex
            opacity = manualTextOpacity
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    Picker("", selection: $isEditingBackground) {
                        Text("Background").tag(true)
                        Text("Text").tag(false)
                    }
                    .padding(.top, 30)
                    .padding(.bottom, 30)
                    .pickerStyle(.segmented)
                    .labelsHidden()
                    .onChange(of: isEditingBackground) { _, _ in
                        loadStateForCurrentSegment()
                    }

                    colorGrid

                    VStack(alignment: .leading, spacing: 8) {
                        Text("OPACITY")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundStyle(settingsTextColor.opacity(0.7))
                            .padding(.top, 30)
                        HStack(spacing: 12) {
                            Slider(value: $opacity, in: 0.05...1.0)
                                .onChange(of: opacity) { _, _ in applyToBinding() }
                            Text("\(Int(opacity * 100)) %")
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundStyle(settingsTextColor)
                                .frame(width: 44, alignment: .trailing)
                        }
                        .padding(.bottom, 30)
                    }

                    previewIndicator
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 24)
            }
            .background(Color(hex: "F2F2F7"))
            .navigationTitle("Manual")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                    .foregroundStyle(settingsTextColor)
                }
            }
            .onAppear {
                loadStateForCurrentSegment()
            }
        }
    }

    private static let cellSize: CGFloat = 26
    private static let gridSpacing: CGFloat = 4

    private var colorGrid: some View {
        VStack(spacing: Self.gridSpacing) {
            ForEach(0..<Self.gridRows, id: \.self) { row in
                HStack(spacing: Self.gridSpacing) {
                    ForEach(0..<Self.gridColumns, id: \.self) { col in
                        colorCell(row: row, column: col)
                    }
                }
            }
        }
        .frame(height: CGFloat(Self.gridRows) * Self.cellSize + CGFloat(Self.gridRows - 1) * Self.gridSpacing)
    }

    private func colorCell(row: Int, column: Int) -> some View {
        let color = colorAt(row: row, column: column)
        let hex = color.hexString
        let isSelected = selectedColorHex.lowercased() == hex.lowercased()
        return Button {
            selectedColorHex = hex
            applyToBinding()
        } label: {
            RoundedRectangle(cornerRadius: 4)
                .fill(color)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .strokeBorder(isSelected ? settingsTextColor : Color.clear, lineWidth: isSelected ? 3 : 0)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(Color.black.opacity(0.15), lineWidth: 0.5)
                )
        }
        .buttonStyle(.plain)
        .frame(width: Self.cellSize, height: Self.cellSize)
    }

    private var previewIndicator: some View {
        let previewBg = isEditingBackground ? displayColor : backgroundColor
        let previewText = isEditingBackground ? textColor : displayColor
        return HStack {
            Spacer(minLength: 0)
            Text("Example")
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(previewText)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(previewBg, in: RoundedRectangle(cornerRadius: 8))
//                .overlay(RoundedRectangle(cornerRadius: 10).stroke(settingsTextColor.opacity(0.25), lineWidth: 1))
            Spacer(minLength: 0)
        }
        .padding(.vertical, 4)
    }
}

private struct ThemeColorSwatch: View {
    let backgroundColor: Color
    let textColor: Color

    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(backgroundColor)
            .overlay(
                Text("A")
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(textColor)
            )
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(Color.black.opacity(0.12), lineWidth: 0.5))
            .frame(width: 22, height: 22)
    }
}

private struct ThemeRow: View {
    let theme: Theme
    let isSelected: Bool
    let settingsTextColor: Color
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(spacing: 12) {
                ThemeColorSwatch(backgroundColor: theme.backgroundColor, textColor: theme.textColor)
                Text(theme.name)
                    .font(.system(size: 17, weight: .regular, design: .rounded))
                    .foregroundStyle(settingsTextColor)
                Spacer(minLength: 8)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .contentShape(Rectangle())
            .background(isSelected ? Color(red: 0.85, green: 0.95, blue: 0.85) : Color.clear)
        }
        .buttonStyle(.plain)
    }
}

private struct LanguageRow: View {
    let language: WordClockLanguage
    let isSelected: Bool
    var textColor: Color = .black
    var showNikudCheckbox: Bool = false
    @Binding var nikudChecked: Bool
    var fontIndexBinding: Binding<Int>? = nil
    let action: () -> Void

    var body: some View {
        HStack(spacing: 0) {
            Button(action: action) {
                HStack(spacing: 8) {
                    Text(language.flagEmoji)
                        .font(.system(size: 20))
                    Text(language.displayName)
                        .font(.system(size: 17, weight: .regular, design: .rounded))
                        .foregroundStyle(textColor)
                    Spacer(minLength: 8)
                }
                .padding(.horizontal, 18)
                .padding(.vertical, 16)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            if let binding = fontIndexBinding {
                fontLabel(binding: binding)
                    .padding(.trailing, showNikudCheckbox && isSelected ? 4 : 18)
                if showNikudCheckbox && isSelected {
                    Button {
                        nikudChecked.toggle()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: nikudChecked ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18))
                                .foregroundStyle(nikudChecked ? Color.blue : textColor.opacity(0.5))
                            Text("Nikud")
                                .font(.system(size: 15, weight: nikudChecked ? .bold : .regular, design: .rounded))
                                .foregroundStyle(nikudChecked ? Color.blue : textColor.opacity(0.4))
                        }
                    }
                    .buttonStyle(.plain)
                    .padding(.trailing, 18)
                }
            }
        }
        .background(isSelected ? Color(red: 0.85, green: 0.95, blue: 0.85) : Color.clear)
    }

    @ViewBuilder
    private func fontLabel(binding: Binding<Int>) -> some View {
        let option = ClockFontOption(rawValue: binding.wrappedValue) ?? .sansSerif
        if isSelected {
            Menu {
                ForEach(ClockFontOption.allCases, id: \.rawValue) { opt in
                    Button {
                        binding.wrappedValue = opt.rawValue
                    } label: {
                        Text(opt.displayName)
                            .font(opt.menuPreviewFont())
                    }
                }
            } label: {
                Text(option.displayName)
                    .font(option.menuPreviewFont(size: 15))
                    .foregroundStyle(Color.blue)
            }
            .buttonStyle(.plain)
        } else {
            Text(option.displayName)
                .font(option.menuPreviewFont(size: 15))
                .foregroundStyle(textColor.opacity(0.4))
        }
    }
}

#Preview {
    WelcomeView()
}
