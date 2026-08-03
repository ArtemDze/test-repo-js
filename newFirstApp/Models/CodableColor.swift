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

    var color: Color {
        Color(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }

    func withOpacity(_ value: Double) -> CodableColor {
        CodableColor(red: red, green: green, blue: blue, opacity: value)
    }

    static let ink = CodableColor(red: 0.05, green: 0.055, blue: 0.07)
    static let ivory = CodableColor(red: 0.96, green: 0.95, blue: 0.93)
    static let burgundy = CodableColor(red: 0.55, green: 0.22, blue: 0.28)
    static let gold = CodableColor(red: 0.72, green: 0.58, blue: 0.36)
    static let teal = CodableColor(red: 0.30, green: 0.52, blue: 0.52)
}
