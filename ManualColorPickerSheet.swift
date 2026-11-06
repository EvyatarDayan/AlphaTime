//
//  ManualColorPickerSheet.swift
//  AlphaTime
//

import SwiftUI

struct ManualColorPickerSheet: View {
    @ObservedObject var settings: SettingsStore
    let onDismiss: () -> Void

    @State private var isEditingBackground = true
    @State private var showBackgroundPicker = false

    @State private var draftBgBase = ""
    @State private var draftBgOpacity = 1.0
    @State private var draftBgHex = ""
    @State private var draftTextBase = ""
    @State private var draftTextOpacity = 1.0
    @State private var draftTextHex = ""
    @State private var draftImageIndex = 0

    @State private var initialBgBase = ""
    @State private var initialBgOpacity = 1.0
    @State private var initialBgHex = ""
    @State private var initialTextBase = ""
    @State private var initialTextOpacity = 1.0
    @State private var initialTextHex = ""
    @State private var initialImageIndex = 0

    @State private var hue: Double = 0
    @State private var saturation: Double = 0
    @State private var value: Double = 1
    @State private var opacity: Double = 1
    @State private var hexInput = "#000000"
    @State private var selectedColorHex = "#000000"

    @State private var wordClockData: WordClockData?

    private var language: WordClockLanguage { settings.language }
    private var fontOption: ClockFontOption {
        ClockFontOption.fromIndex(settings.fontIndex(for: language))
    }
    private var selectedColor: Color { Color(hex: selectedColorHex) }
    private var pureHue: Color { Color.fromHSV(hue: hue, saturation: 1, brightness: 1) }

    private var hasChanges: Bool {
        draftImageIndex != initialImageIndex
            || !hexEquals(draftBgBase, initialBgBase)
            || abs(draftBgOpacity - initialBgOpacity) > 0.001
            || !hexEquals(draftBgHex, initialBgHex)
            || !hexEquals(draftTextBase, initialTextBase)
            || abs(draftTextOpacity - initialTextOpacity) > 0.001
            || !hexEquals(draftTextHex, initialTextHex)
    }

    private var examplePhrase: String {
        let phrase = WordClockPhraseBuilder.displayPhrase(
            for: Date(),
            settings: settings.snapshot,
            data: wordClockData,
            useRandomPrefix: false
        )
        return phrase.isEmpty ? "Example" : phrase
    }

    private var exampleBackground: Color {
        if isEditingBackground {
            return selectedColor.composited(on: .white, opacity: opacity)
        }
        return Color(hex: draftBgHex)
    }

    private var exampleText: Color {
        if isEditingBackground {
            return Color(hex: draftTextHex)
        }
        return selectedColor.composited(on: Color(hex: draftBgHex), opacity: opacity)
    }

    private var exampleImageName: String? {
        ClockBackgrounds.imageName(for: draftImageIndex)
    }

    private var imageOpacity: Double {
        isEditingBackground ? opacity : draftBgOpacity
    }

    var body: some View {
        ZStack {
            Color.black.opacity(0.35)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            GeometryReader { geo in
                let width = min(geo.size.width * 0.72, geo.size.width - 40)
                VStack(spacing: 0) {
                    Text("Manual")
                        .font(UIChromeFont.nunito(size: 22, weight: .semibold))
                        .foregroundStyle(manualSettingsText)
                        .frame(maxWidth: .infinity)
                        .padding(.top, 24)
                        .padding(.bottom, 10)

                    VStack(spacing: 10) {
                        segmentedControl

                        colorController

                        previewCard

                        actionButtons
                    }
                    .padding(.horizontal, 14)
                    .padding(.bottom, 24)
                }
                .frame(width: width)
                .fixedSize(horizontal: false, vertical: true)
                .background(manualSheetColor, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }

            if showBackgroundPicker {
                BackgroundImagePickerDialog(
                    selectedIndex: draftImageIndex,
                    onSelect: { index in
                        draftImageIndex = index
                        showBackgroundPicker = false
                    },
                    onDismiss: { showBackgroundPicker = false }
                )
            }
        }
        .onAppear {
            captureInitial()
            loadStateForCurrentSegment()
            wordClockData = WordClockData(
                language: language,
                hebrewUseNikud: settings.effectiveHebrewNikud
            )
        }
        .onChange(of: isEditingBackground) { _, _ in
            loadStateForCurrentSegment()
        }
    }

    private var segmentedControl: some View {
        HStack(spacing: 0) {
            segmentButton(title: "Background", value: true)
            segmentButton(title: "Text", value: false)
        }
        .padding(2)
        .background(Color.black.opacity(0.08), in: RoundedRectangle(cornerRadius: 9))
    }

    private func segmentButton(title: String, value: Bool) -> some View {
        let selected = isEditingBackground == value
        return Button {
            isEditingBackground = value
        } label: {
            Text(title)
                .font(UIChromeFont.nunito(size: 13, weight: selected ? .semibold : .regular))
                .foregroundStyle(manualSettingsText)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 6)
                .background(selected ? Color.white : Color.clear, in: RoundedRectangle(cornerRadius: 7))
        }
        .buttonStyle(.plain)
    }

    private var colorController: some View {
        VStack(spacing: 8) {
            SaturationValuePanel(
                hueColor: pureHue,
                saturation: saturation,
                value: value,
                onChange: { s, v in
                    if isEditingBackground { draftImageIndex = 0 }
                    applyColorFromHSV(hue: hue, saturation: s, value: v)
                }
            )
            .frame(height: 148)

            HueSlider(hue: hue) { newHue in
                applyColorFromHSV(hue: newHue, saturation: saturation, value: value)
            }
            .frame(height: 22)

            hexField

            GeometryReader { geo in
                HStack(spacing: 8) {
                    OpacityField(value: opacity, textColor: manualSettingsText) { newOpacity in
                        opacity = newOpacity
                        applyColorFromHSV(hue: hue, saturation: saturation, value: value, opacity: newOpacity)
                    }
                    .frame(width: isEditingBackground ? geo.size.width * 0.62 - 4 : geo.size.width)

                    if isEditingBackground {
                        BackgroundsEntryButton(
                            selectedIndex: draftImageIndex,
                            onClick: { showBackgroundPicker = true }
                        )
                        .frame(width: geo.size.width * 0.38 - 4)
                    }
                }
            }
            .frame(height: 48)
        }
        .padding(10)
        .background(Color.white, in: RoundedRectangle(cornerRadius: 14))
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.black.opacity(0.08), lineWidth: 1))
    }

    private var hexField: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(selectedColor)
                .frame(width: 18, height: 18)
                .overlay(Circle().stroke(Color.black.opacity(0.15), lineWidth: 1))
            TextField("", text: $hexInput)
                .font(.system(size: 14, weight: .medium, design: .monospaced))
                .multilineTextAlignment(.center)
                .foregroundStyle(manualSettingsText)
                .frame(width: 96)
                .onChange(of: hexInput) { _, typed in
                    let cleaned = typed.trimmingCharacters(in: .whitespacesAndNewlines)
                        .replacingOccurrences(of: "#", with: "")
                    if cleaned.count == 6,
                       cleaned.allSatisfy({ $0.isHexDigit }) {
                        applyColorFromHex("#\(cleaned)")
                    }
                }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 38)
        .background(Color(hex: "F2F2F7"), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 1))
    }

    private var previewCard: some View {
        GeometryReader { geo in
            let previewWidth = geo.size.width * 0.8
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(exampleImageName == nil ? exampleBackground : .white)
                if let name = exampleImageName {
                    ClockBackgroundFill(
                        name: name,
                        opacity: max(0.05, imageOpacity),
                        cornerRadius: 10
                    )
                    .frame(width: previewWidth, height: 88)
                }
                Text(examplePhrase)
                    .font(fontOption.font(size: 24, language: language, bold: language != .hebrew))
                    .foregroundStyle(exampleText)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.5)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 12)
            }
            .frame(width: previewWidth, height: 88)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(height: 88)
        .padding(.top, 4)
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(UIChromeFont.nunito(size: 18, weight: .medium))
                    .foregroundStyle(manualSettingsText)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.black.opacity(0.12), lineWidth: 1)
                    )
            }
            .buttonStyle(.plain)

            Button(action: saveAndClose) {
                Text(hasChanges ? "Save & Apply" : "Apply")
                    .font(UIChromeFont.nunito(size: 18, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(manualSettingsText, in: RoundedRectangle(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 28)
        .padding(.top, 4)
    }

    private func captureInitial() {
        let bgBase = settings.manualBackgroundBaseHex.isEmpty
            ? settings.backgroundColorHex
            : settings.manualBackgroundBaseHex
        let bgOpacity = settings.manualBackgroundOpacity
        let bgHex = settings.manualBackgroundComposedHex.isEmpty
            ? Color(hex: bgBase).composited(on: .white, opacity: bgOpacity).hexString
            : settings.manualBackgroundComposedHex

        let textBase = settings.manualTextBaseHex.isEmpty
            ? settings.textColorHex
            : settings.manualTextBaseHex
        let textOpacity = settings.manualTextOpacity
        let textHex = settings.manualTextComposedHex.isEmpty
            ? Color(hex: textBase).composited(on: .white, opacity: textOpacity).hexString
            : settings.manualTextComposedHex

        let imageIndex = settings.manualBackgroundImageIndex != ClockBackgrounds.none
            ? settings.manualBackgroundImageIndex
            : settings.backgroundImageIndex

        draftBgBase = bgBase
        draftBgOpacity = bgOpacity
        draftBgHex = bgHex
        draftTextBase = textBase
        draftTextOpacity = textOpacity
        draftTextHex = textHex
        draftImageIndex = imageIndex

        initialBgBase = bgBase
        initialBgOpacity = bgOpacity
        initialBgHex = bgHex
        initialTextBase = textBase
        initialTextOpacity = textOpacity
        initialTextHex = textHex
        initialImageIndex = imageIndex
    }

    private func loadStateForCurrentSegment() {
        let base = isEditingBackground ? draftBgBase : draftTextBase
        let op = isEditingBackground ? draftBgOpacity : draftTextOpacity
        opacity = op
        applyColorFromHex(base, opacity: op)
    }

    private func applyColorFromHSV(hue h: Double, saturation s: Double, value v: Double, opacity op: Double? = nil) {
        let useOpacity = op ?? opacity
        hue = h
        saturation = s
        value = v
        opacity = useOpacity
        let color = Color.fromHSV(hue: h, saturation: s, brightness: v)
        let hex = color.hexString
        selectedColorHex = hex
        hexInput = hex.uppercased()
        let composed = color.composited(on: .white, opacity: useOpacity).hexString
        if isEditingBackground {
            draftBgBase = hex
            draftBgOpacity = useOpacity
            draftBgHex = composed
        } else {
            draftTextBase = hex
            draftTextOpacity = useOpacity
            draftTextHex = composed
        }
    }

    private func applyColorFromHex(_ raw: String, opacity op: Double? = nil) {
        let useOpacity = op ?? opacity
        var cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        if !cleaned.hasPrefix("#") { cleaned = "#\(cleaned)" }
        guard cleaned.dropFirst().count == 6 else { return }
        let color = Color(hex: cleaned)
        let hsv = color.hsvComponents
        hue = hsv.hue
        saturation = hsv.saturation
        value = hsv.brightness
        opacity = useOpacity
        selectedColorHex = color.hexString
        hexInput = selectedColorHex.uppercased()
        let composed = color.composited(on: .white, opacity: useOpacity).hexString
        if isEditingBackground {
            draftBgBase = selectedColorHex
            draftBgOpacity = useOpacity
            draftBgHex = composed
        } else {
            draftTextBase = selectedColorHex
            draftTextOpacity = useOpacity
            draftTextHex = composed
        }
    }

    private func saveAndClose() {
        settings.setManualBackground(baseHex: draftBgBase, opacity: draftBgOpacity, composedHex: draftBgHex)
        settings.setManualText(baseHex: draftTextBase, opacity: draftTextOpacity, composedHex: draftTextHex)
        settings.updateBackgroundImageIndex(draftImageIndex)
        settings.markManualColors()
        onDismiss()
    }

    private func hexEquals(_ a: String, _ b: String) -> Bool {
        a.trimmingCharacters(in: CharacterSet(charactersIn: "#")).caseInsensitiveCompare(
            b.trimmingCharacters(in: CharacterSet(charactersIn: "#"))
        ) == .orderedSame
    }
}

// MARK: - Saturation / Value panel

private struct SaturationValuePanel: View {
    let hueColor: Color
    let saturation: Double
    let value: Double
    let onChange: (Double, Double) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [.white, hueColor], startPoint: .leading, endPoint: .trailing)
                    )
                RoundedRectangle(cornerRadius: 12)
                    .fill(
                        LinearGradient(colors: [.clear, .black], startPoint: .top, endPoint: .bottom)
                    )

                Circle()
                    .strokeBorder(Color.white, lineWidth: 2.5)
                    .background(Circle().stroke(Color.black.opacity(0.25), lineWidth: 1))
                    .frame(width: 20, height: 20)
                    .position(
                        x: saturation * geo.size.width,
                        y: (1 - value) * geo.size.height
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .contentShape(RoundedRectangle(cornerRadius: 12))
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        let s = min(max(drag.location.x / geo.size.width, 0), 1)
                        let v = min(max(1 - drag.location.y / geo.size.height, 0), 1)
                        onChange(s, v)
                    }
            )
        }
    }
}

// MARK: - Hue slider

private struct HueSlider: View {
    let hue: Double
    let onHueChange: (Double) -> Void

    private let hues: [Color] = [
        .red, .yellow, .green, .cyan, .blue, .purple, .red
    ]

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(LinearGradient(colors: hues, startPoint: .leading, endPoint: .trailing))
                    .frame(height: 12)
                    .frame(maxWidth: .infinity)
                    .frame(maxHeight: .infinity)

                Circle()
                    .fill(Color.white)
                    .overlay(Circle().stroke(Color.black.opacity(0.2), lineWidth: 2))
                    .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                    .frame(width: 18, height: 18)
                    .offset(x: min(max(hue * geo.size.width - 9, -9), geo.size.width - 9))
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { drag in
                        onHueChange(min(max(drag.location.x / geo.size.width, 0), 1))
                    }
            )
        }
    }
}

// MARK: - Opacity field

private struct OpacityField: View {
    let value: Double
    let textColor: Color
    let onValueChange: (Double) -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text("Opacity")
                .font(UIChromeFont.nunito(size: 12, weight: .medium))
                .foregroundStyle(textColor.opacity(0.7))
            Text("A")
                .font(UIChromeFont.nunito(size: 15, weight: .bold))
                .foregroundStyle(textColor.opacity(0.35))
            Slider(value: Binding(
                get: { value },
                set: { onValueChange($0) }
            ), in: 0.05...1)
            .tint(textColor)
            Text("A")
                .font(UIChromeFont.nunito(size: 15, weight: .bold))
                .foregroundStyle(textColor.opacity(0.9))
        }
        .padding(.horizontal, 10)
        .frame(height: 48)
        .background(Color(hex: "F2F2F7"), in: RoundedRectangle(cornerRadius: 10))
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 1))
    }
}

// MARK: - Backgrounds entry

private struct BackgroundsEntryButton: View {
    let selectedIndex: Int
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 8) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(hex: "E8E8ED"))
                    if let name = ClockBackgrounds.imageName(for: selectedIndex) {
                        ClockBackgroundFill(name: name, cornerRadius: 6)
                    }
                }
                .frame(width: 28, height: 28)
                .clipped()
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.black.opacity(0.08), lineWidth: 1))

                Text("Backgrounds")
                    .font(UIChromeFont.nunito(size: 12, weight: .semibold))
                    .foregroundStyle(manualSettingsText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 10)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color(hex: "F2F2F7"), in: RoundedRectangle(cornerRadius: 10))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.black.opacity(0.06), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Background image picker

private struct BackgroundImagePickerDialog: View {
    let selectedIndex: Int
    let onSelect: (Int) -> Void
    let onDismiss: () -> Void

    private let rows: [[Int]] = [
        [1, 2, 3, 4],
        [5, 6, 7, 8]
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.25)
                .ignoresSafeArea()
                .onTapGesture(perform: onDismiss)

            GeometryReader { geo in
                let width = min(geo.size.width * 0.66, geo.size.width - 40)
                VStack(spacing: 12) {
                    Text("Backgrounds")
                        .font(UIChromeFont.nunito(size: 17, weight: .semibold))
                        .foregroundStyle(manualSettingsText)
                        .frame(maxWidth: .infinity)

                    Button {
                        onSelect(0)
                    } label: {
                        Text("Solid color")
                            .font(UIChromeFont.nunito(size: 13, weight: .medium))
                            .foregroundStyle(manualSettingsText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(
                                selectedIndex == 0 ? Color(hex: "EAF3FF") : Color.white,
                                in: RoundedRectangle(cornerRadius: 10)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(
                                        selectedIndex == 0 ? Color(hex: "007AFF") : Color.black.opacity(0.10),
                                        lineWidth: selectedIndex == 0 ? 2 : 1
                                    )
                            )
                    }
                    .buttonStyle(.plain)

                    VStack(spacing: 10) {
                        ForEach(rows, id: \.self) { row in
                            HStack(spacing: 10) {
                                ForEach(row, id: \.self) { index in
                                    backgroundCell(index)
                                }
                            }
                        }
                    }

                    Button(action: onDismiss) {
                        Text("Close")
                            .font(UIChromeFont.nunito(size: 15, weight: .medium))
                            .foregroundStyle(manualSettingsText)
                            .frame(maxWidth: .infinity)
                            .frame(height: 42)
                            .background(Color.white, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.black.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                }
                .padding(16)
                .frame(width: width)
                .background(manualSheetColor, in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 16, y: 8)
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }
        }
    }

    private func backgroundCell(_ index: Int) -> some View {
        let selected = selectedIndex == index
        return Button {
            onSelect(index)
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(hex: "E8E8ED"))
                if let name = ClockBackgrounds.imageName(for: index) {
                    ClockBackgroundFill(name: name, cornerRadius: 10)
                } else {
                    Text("\(index)")
                        .font(UIChromeFont.nunito(size: 16, weight: .medium))
                        .foregroundStyle(manualSettingsText.opacity(0.35))
                }
            }
            .aspectRatio(1.35, contentMode: .fit)
            .frame(maxWidth: .infinity)
            .clipped()
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(selected ? Color(hex: "007AFF") : Color.black.opacity(0.10), lineWidth: selected ? 2.5 : 1)
            )
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

private let manualSettingsText = Color(hex: WordClockSettings.defaultTextHex)
private let manualSheetColor = Color(hex: "F7F7F8")
