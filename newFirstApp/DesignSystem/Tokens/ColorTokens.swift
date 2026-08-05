import SwiftUI
import UIKit

enum JSRColor {
    static let background = adaptive(
        light: UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1),
        dark: UIColor(red: 0.05, green: 0.055, blue: 0.07, alpha: 1)
    )
    static let surface = adaptive(
        light: UIColor(red: 0.99, green: 0.98, blue: 0.96, alpha: 1),
        dark: UIColor(red: 0.10, green: 0.11, blue: 0.13, alpha: 1)
    )
    static let surfaceElevated = adaptive(
        light: UIColor(red: 1, green: 1, blue: 0.99, alpha: 1),
        dark: UIColor(red: 0.14, green: 0.15, blue: 0.18, alpha: 1)
    )
    static let textPrimary = adaptive(
        light: UIColor(red: 0.08, green: 0.09, blue: 0.11, alpha: 1),
        dark: UIColor(red: 0.96, green: 0.95, blue: 0.93, alpha: 1)
    )
    static let textSecondary = adaptive(
        light: UIColor(red: 0.38, green: 0.36, blue: 0.34, alpha: 1),
        dark: UIColor(red: 0.70, green: 0.68, blue: 0.65, alpha: 1)
    )
    static let textTertiary = adaptive(
        light: UIColor(red: 0.55, green: 0.53, blue: 0.50, alpha: 1),
        dark: UIColor(red: 0.52, green: 0.50, blue: 0.48, alpha: 1)
    )

    static let accent = Color(footlight_hex: "8C3847")
    static let accentMuted = accent.opacity(0.16)

    static let highlight = Color(footlight_hex: "B8945C")

    static let secondaryAccent = Color(footlight_hex: "4D8585")

    static let success = Color(footlight_hex: "47946F")
    static let warning = Color(footlight_hex: "C79442")
    static let danger = Color(footlight_hex: "B8474D")
    static let separator = Color.primary.opacity(0.10)
    static let fill = Color.primary.opacity(0.06)
    static let ink = Color(footlight_hex: "0D0E12")
    static let ivory = Color(footlight_hex: "F5F2ED")

    private static func adaptive(light: UIColor, dark: UIColor) -> Color {
        Color(uiColor: UIColor { $0.userInterfaceStyle == .dark ? dark : light })
    }
}
