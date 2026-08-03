import SwiftUI
import CoreText

enum JSRFont {
    /// Theatrical display serif — Cormorant Garamond (OFL).
    static let serifName = "Cormorant Garamond"

    static func registerBundledFonts() {
        let names = ["CormorantGaramond", "CormorantGaramond-Italic"]
        for name in names {
            if let url = Bundle.main.url(forResource: name, withExtension: "ttf") {
                CTFontManagerRegisterFontsForURL(url as CFURL, .process, nil)
            }
        }
    }

    static func serif(size: CGFloat, relativeTo textStyle: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        Font.custom(serifName, size: size, relativeTo: textStyle).weight(weight)
    }
}

enum JSRType {
    static let display = JSRFont.serif(size: 36, relativeTo: .largeTitle, weight: .semibold)
    static let title = JSRFont.serif(size: 26, relativeTo: .title2, weight: .medium)
    static let headline = JSRFont.serif(size: 20, relativeTo: .headline, weight: .semibold)
    static let body = JSRFont.serif(size: 17, relativeTo: .body, weight: .regular)
    static let callout = JSRFont.serif(size: 16, relativeTo: .callout, weight: .medium)
    static let caption = Font.system(.caption, design: .default)
    static let footnote = Font.system(.footnote, design: .default)
    /// Small labels stay geometric / rounded for contrast with the display serif.
    static let motif = Font.system(.caption2, design: .rounded).weight(.bold)
}
