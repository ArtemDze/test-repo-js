import Foundation
import SwiftUI
import UIKit

struct CodableColor: Codable, Hashable, Equatable, Sendable {
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double

    init(red: Double, green: Double, blue: Double, opacity: Double = 1) {
        self.red = red
        self.green = green
        self.blue = blue
        self.opacity = opacity
    }

    init(_ color: Color) {
        let ui = UIColor(color)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        ui.getRed(&r, green: &g, blue: &b, alpha: &a)
        red = Double(r); green = Double(g); blue = Double(b); opacity = Double(a)
    }

    init?(footlightHex: String) {
        guard let ui = UIColor(footlight_hex: footlightHex) else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard ui.getRed(&r, green: &g, blue: &b, alpha: &a) else { return nil }
        red = Double(r); green = Double(g); blue = Double(b); opacity = Double(a)
    }

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    var footlightHexString: String {
        let r = Int((red * 255).rounded())
        let g = Int((green * 255).rounded())
        let b = Int((blue * 255).rounded())
        return String(format: "%02X%02X%02X", r, g, b)
    }

    func withOpacity(_ value: Double) -> CodableColor {
        CodableColor(red: red, green: green, blue: blue, opacity: value)
    }

    static let ink = CodableColor(footlightHex: "0D0E12") ?? CodableColor(red: 0.05, green: 0.055, blue: 0.07)
    static let ivory = CodableColor(footlightHex: "F5F2ED") ?? CodableColor(red: 0.96, green: 0.95, blue: 0.93)
    static let burgundy = CodableColor(footlightHex: "8C3847") ?? CodableColor(red: 0.55, green: 0.22, blue: 0.28)
    static let gold = CodableColor(footlightHex: "B8945C") ?? CodableColor(red: 0.72, green: 0.58, blue: 0.36)
    static let teal = CodableColor(footlightHex: "4D8585") ?? CodableColor(red: 0.30, green: 0.52, blue: 0.52)
}
