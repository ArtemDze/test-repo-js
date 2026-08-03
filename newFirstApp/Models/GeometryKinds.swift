import Foundation
import SwiftUI

enum PatternLayout: String, Codable, CaseIterable, Identifiable, Sendable {
    case radial
    case mirror
    case kaleidoscope
    case spiral
    case lattice
    case vortex
    case orbit
    case curtain

    var id: String { rawValue }

    var title: String {
        switch self {
        case .radial: "Radial"
        case .mirror: "Mirror"
        case .kaleidoscope: "Kaleido"
        case .spiral: "Spiral"
        case .lattice: "Lattice"
        case .vortex: "Vortex"
        case .orbit: "Orbit"
        case .curtain: "Curtain"
        }
    }

    var blurb: String {
        switch self {
        case .radial: "Ceremonial folds around a quiet center."
        case .mirror: "Theatrical left–right duality."
        case .kaleidoscope: "Mirrored wedges in full rotation."
        case .spiral: "A measured path that guides the eye."
        case .lattice: "Paper-card grid with gentle drift."
        case .vortex: "Nested rings that tighten toward the core."
        case .orbit: "Satellites held in staged spacing."
        case .curtain: "Two opposing planes framing the stage."
        }
    }
}

enum GeometryKind: String, Codable, CaseIterable, Identifiable, Sendable {
    case diamond, arc, circle, polygon, ribbon, starburst, mask

    var id: String { rawValue }

    var title: String {
        switch self {
        case .diamond: "Diamond"
        case .arc: "Arc"
        case .circle: "Circle"
        case .polygon: "Polygon"
        case .ribbon: "Ribbon"
        case .starburst: "Starburst"
        case .mask: "Mask"
        }
    }

    var symbolName: String {
        switch self {
        case .diamond: "diamond.fill"
        case .arc: "degrees"
        case .circle: "circle"
        case .polygon: "hexagon"
        case .ribbon: "waveform"
        case .starburst: "sparkle"
        case .mask: "oval.portrait"
        }
    }
}

enum RenderMode: String, Codable, CaseIterable, Identifiable, Sendable {
    case fill, outline, both
    var id: String { rawValue }
    var title: String {
        switch self {
        case .fill: "Fill"
        case .outline: "Outline"
        case .both: "Both"
        }
    }
}

enum CanvasRatio: String, Codable, CaseIterable, Identifiable, Sendable {
    case square, portrait, landscape
    var id: String { rawValue }
    var title: String {
        switch self {
        case .square: "Square"
        case .portrait: "Portrait"
        case .landscape: "Landscape"
        }
    }
    var size: CGSize {
        switch self {
        case .square: JSRCanvasMetrics.square
        case .portrait: JSRCanvasMetrics.portrait
        case .landscape: JSRCanvasMetrics.landscape
        }
    }
    var aspect: CGFloat { size.width / size.height }
}

enum AppearancePreference: String, Codable, CaseIterable, Identifiable, Sendable {
    case system, light, dark
    var id: String { rawValue }
    var title: String {
        switch self {
        case .system: "System"
        case .light: "Light"
        case .dark: "Dark"
        }
    }
    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

enum KineticStyle: String, Codable, CaseIterable, Identifiable, Sendable {
    case none
    case breathe
    case orbit
    case shimmer

    var id: String { rawValue }
    var title: String {
        switch self {
        case .none: "Still"
        case .breathe: "Breathe"
        case .orbit: "Orbit"
        case .shimmer: "Shimmer"
        }
    }
}
