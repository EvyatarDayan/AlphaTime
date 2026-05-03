//
//  Color+Hex.swift
//  AlphaTime
//
//  Hex string conversion for storing colors in AppStorage.
//

import SwiftUI

#if canImport(UIKit)
import UIKit
#endif

extension Color {
    /// Creates a color from HSV. Hue 0–1 (red=0, green≈0.33, blue≈0.66), saturation 0–1, brightness 0–1.
    static func fromHSV(hue h: Double, saturation s: Double, brightness v: Double) -> Color {
        let r: Double, g: Double, b: Double
        if s <= 0 {
            r = v; g = v; b = v
        } else {
            let hp = (h * 6).truncatingRemainder(dividingBy: 6)
            let i = Int(hp)
            let f = hp - Double(i)
            let p = v * (1 - s)
            let q = v * (1 - s * f)
            let t = v * (1 - s * (1 - f))
            switch i {
            case 0: r = v; g = t; b = p
            case 1: r = q; g = v; b = p
            case 2: r = p; g = v; b = t
            case 3: r = p; g = q; b = v
            case 4: r = t; g = p; b = v
            default: r = v; g = p; b = q
            }
        }
        return Color(red: r, green: g, blue: b)
    }

    /// Creates a Color from a hex string (e.g. "#e9e5d8" or "e9e5d8").
    init(hex: String) {
        let cleaned = hex.hasPrefix("#") ? String(hex.dropFirst()) : hex
        let r, g, b: Double
        if cleaned.count == 6 {
            r = Double(Int(cleaned.prefix(2), radix: 16) ?? 0) / 255
            g = Double(Int(cleaned.dropFirst(2).prefix(2), radix: 16) ?? 0) / 255
            b = Double(Int(cleaned.suffix(2), radix: 16) ?? 0) / 255
        } else {
            r = 0.914; g = 0.898; b = 0.847
        }
        self.init(red: r, green: g, blue: b)
    }

    /// Hex string (e.g. "#e9e5d8") for storing in AppStorage.
    var hexString: String {
        #if canImport(UIKit)
        let ui = UIColor(self)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(
            format: "#%02X%02X%02X",
            Int(r * 255),
            Int(g * 255),
            Int(b * 255)
        )
        #else
        return "#e9e5d8"
        #endif
    }

    /// Composites this color at the given opacity on top of the background; returns the resulting solid color.
    func composited(on background: Color, opacity: Double) -> Color {
        #if canImport(UIKit)
        let fg = UIColor(self)
        let bg = UIColor(background)
        var fr: CGFloat = 0, fg_g: CGFloat = 0, fb: CGFloat = 0, fa: CGFloat = 0
        var br: CGFloat = 0, bg_g: CGFloat = 0, bb: CGFloat = 0, ba: CGFloat = 0
        fg.getRed(&fr, green: &fg_g, blue: &fb, alpha: &fa)
        bg.getRed(&br, green: &bg_g, blue: &bb, alpha: &ba)
        let a = fa * CGFloat(opacity)
        let r = fr * a + br * (1 - a)
        let g = fg_g * a + bg_g * (1 - a)
        let b = fb * a + bb * (1 - a)
        return Color(red: r, green: g, blue: b)
        #else
        return self
        #endif
    }
}
