import Foundation
import SwiftUI

enum PaletteKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case complementary, analogous, splitComplementary, monochrome, triadic
    var id: String { rawValue }
    var title: String {
        switch self {
        case .complementary: "Complementary"
        case .analogous: "Analogous"
        case .splitComplementary: "Split Complement"
        case .monochrome: "Monochrome"
        case .triadic: "Triadic"
        }
    }
}

enum PaletteService {
    static func colors(baseHue: Double, kind: PaletteKind, saturation: Double = 0.48, brightness: Double = 0.72) -> [CodableColor] {
        let h = norm(baseHue)
        let hues: [Double]
        switch kind {
        case .complementary: hues = [h, norm(h + 0.5)]
        case .analogous: hues = [norm(h - 0.07), h, norm(h + 0.07), norm(h + 0.14)]
        case .splitComplementary: hues = [h, norm(h + 0.42), norm(h + 0.58)]
        case .monochrome: hues = [h, h, h, h]
        case .triadic: hues = [h, norm(h + 1.0 / 3), norm(h + 2.0 / 3)]
        }
        if kind == .monochrome {
            let bri = [brightness, brightness * 0.85, brightness * 0.65, min(1, brightness * 1.05)]
            let sat = [saturation, saturation * 0.7, saturation * 0.4, saturation * 0.25]
            return zip(bri, sat).map { CodableColor(Color(hue: h, saturation: $0.1, brightness: $0.0)) }
        }
        return hues.enumerated().map { i, hue in
            CodableColor(Color(
                hue: hue,
                saturation: saturation * (i.isMultiple(of: 2) ? 1 : 0.8),
                brightness: min(1, brightness * (0.75 + Double(i % 3) * 0.08))
            ))
        }
    }

    private static func norm(_ v: Double) -> Double {
        var x = v.truncatingRemainder(dividingBy: 1)
        if x < 0 { x += 1 }
        return x
    }
}
