import SwiftUI

/// Fixed theatrical palette for stage surfaces (Studio / onboarding chrome).
/// Not adaptive — always reads against ink.
enum JSRStage {
    static let label = JSRColor.ivory
    static let labelSecondary = JSRColor.ivory.opacity(0.62)
    static let labelTertiary = JSRColor.ivory.opacity(0.40)
    static let chipFill = JSRColor.ivory.opacity(0.08)
    static let chipFillStrong = JSRColor.ivory.opacity(0.12)
    static let chipStroke = JSRColor.ivory.opacity(0.16)
    static let panel = Color(red: 0.09, green: 0.095, blue: 0.11)
    static let panelElevated = Color(red: 0.12, green: 0.125, blue: 0.15)
    static let separator = JSRColor.ivory.opacity(0.12)
    static let control = JSRColor.highlight
    static let accentFill = JSRColor.accent
}
