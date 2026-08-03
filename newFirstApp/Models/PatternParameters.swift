import Foundation
import CoreGraphics

struct PatternParameters: Codable, Hashable, Equatable, Sendable {
    var geometry: GeometryKind
    var layout: PatternLayout
    var symmetryCount: Int
    var rotation: Double
    var scale: Double
    var repetition: Int
    var spacing: Double
    var strokeWidth: Double
    var renderMode: RenderMode
    var opacity: Double
    var foreground: CodableColor
    var secondary: CodableColor
    var background: CodableColor
    var asymmetry: Double
    var distortion: Double
    var seed: UInt64
    var canvasRatio: CanvasRatio
    var polygonSides: Int
    var seedLocked: Bool
    var showGlow: Bool
    var layerDepth: Int

    enum CodingKeys: String, CodingKey {
        case geometry, layout, symmetryCount, rotation, scale, repetition, spacing
        case strokeWidth, renderMode, opacity, foreground, secondary, background
        case asymmetry, distortion, seed, canvasRatio, polygonSides, seedLocked
        case showGlow, layerDepth
    }

    init(
        geometry: GeometryKind = .diamond,
        layout: PatternLayout = .radial,
        symmetryCount: Int = 6,
        rotation: Double = 0,
        scale: Double = 0.42,
        repetition: Int = 3,
        spacing: Double = 0.18,
        strokeWidth: Double = 2.5,
        renderMode: RenderMode = .both,
        opacity: Double = 0.92,
        foreground: CodableColor = .gold,
        secondary: CodableColor = .teal,
        background: CodableColor = .ink,
        asymmetry: Double = 0,
        distortion: Double = 0,
        seed: UInt64 = 42,
        canvasRatio: CanvasRatio = .square,
        polygonSides: Int = 5,
        seedLocked: Bool = false,
        showGlow: Bool = true,
        layerDepth: Int = 2
    ) {
        self.geometry = geometry
        self.layout = layout
        self.symmetryCount = symmetryCount
        self.rotation = rotation
        self.scale = scale
        self.repetition = repetition
        self.spacing = spacing
        self.strokeWidth = strokeWidth
        self.renderMode = renderMode
        self.opacity = opacity
        self.foreground = foreground
        self.secondary = secondary
        self.background = background
        self.asymmetry = asymmetry
        self.distortion = distortion
        self.seed = seed
        self.canvasRatio = canvasRatio
        self.polygonSides = polygonSides
        self.seedLocked = seedLocked
        self.showGlow = showGlow
        self.layerDepth = layerDepth
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        geometry = try c.decodeIfPresent(GeometryKind.self, forKey: .geometry) ?? .diamond
        layout = try c.decodeIfPresent(PatternLayout.self, forKey: .layout) ?? .radial
        symmetryCount = try c.decodeIfPresent(Int.self, forKey: .symmetryCount) ?? 6
        rotation = try c.decodeIfPresent(Double.self, forKey: .rotation) ?? 0
        scale = try c.decodeIfPresent(Double.self, forKey: .scale) ?? 0.42
        repetition = try c.decodeIfPresent(Int.self, forKey: .repetition) ?? 3
        spacing = try c.decodeIfPresent(Double.self, forKey: .spacing) ?? 0.18
        strokeWidth = try c.decodeIfPresent(Double.self, forKey: .strokeWidth) ?? 2.5
        renderMode = try c.decodeIfPresent(RenderMode.self, forKey: .renderMode) ?? .both
        opacity = try c.decodeIfPresent(Double.self, forKey: .opacity) ?? 0.92
        foreground = try c.decodeIfPresent(CodableColor.self, forKey: .foreground) ?? .gold
        secondary = try c.decodeIfPresent(CodableColor.self, forKey: .secondary) ?? .teal
        background = try c.decodeIfPresent(CodableColor.self, forKey: .background) ?? .ink
        asymmetry = try c.decodeIfPresent(Double.self, forKey: .asymmetry) ?? 0.08
        distortion = try c.decodeIfPresent(Double.self, forKey: .distortion) ?? 0
        seed = try c.decodeIfPresent(UInt64.self, forKey: .seed) ?? 42
        canvasRatio = try c.decodeIfPresent(CanvasRatio.self, forKey: .canvasRatio) ?? .square
        polygonSides = try c.decodeIfPresent(Int.self, forKey: .polygonSides) ?? 5
        seedLocked = try c.decodeIfPresent(Bool.self, forKey: .seedLocked) ?? false
        showGlow = try c.decodeIfPresent(Bool.self, forKey: .showGlow) ?? true
        layerDepth = try c.decodeIfPresent(Int.self, forKey: .layerDepth) ?? 2
    }

    static let `default` = PatternParameters(
        geometry: .diamond,
        layout: .radial,
        symmetryCount: 8,
        rotation: 0,
        scale: 0.52,
        repetition: 3,
        spacing: 0.16,
        strokeWidth: 2,
        renderMode: .both,
        opacity: 0.92,
        foreground: .gold,
        secondary: .teal,
        background: .ink,
        asymmetry: 0,
        distortion: 0,
        seed: 42,
        canvasRatio: .square,
        polygonSides: 5,
        seedLocked: false,
        showGlow: true,
        layerDepth: 2
    )

    mutating func clamp() {
        symmetryCount = PatternMath.clamp(symmetryCount, 1, 24)
        rotation = rotation.truncatingRemainder(dividingBy: 360)
        if rotation < 0 { rotation += 360 }
        scale = PatternMath.clamp(scale, 0.08, 1.25)
        repetition = PatternMath.clamp(repetition, 1, 14)
        spacing = PatternMath.clamp(spacing, 0, 0.65)
        strokeWidth = PatternMath.clamp(strokeWidth, 0.5, 28)
        opacity = PatternMath.clamp(opacity, 0.05, 1)
        asymmetry = PatternMath.clamp(asymmetry, 0, 1)
        distortion = PatternMath.clamp(distortion, 0, 1)
        polygonSides = PatternMath.clamp(polygonSides, 3, 12)
        layerDepth = PatternMath.clamp(layerDepth, 1, 5)
    }

    var accessibilitySummary: String {
        "\(geometry.title) \(layout.title) pattern, \(symmetryCount)-fold symmetry, scale \(Int(scale * 100)) percent"
    }
}

enum PatternMath {
    static func clamp<T: Comparable>(_ value: T, _ lo: T, _ hi: T) -> T {
        min(max(value, lo), hi)
    }
}

struct RenderPrimitive: Equatable, Sendable {
    enum Kind: Equatable, Sendable {
        case path
        case stroke
    }

    var points: [CGPoint]
    var closed: Bool
    var kind: Kind
    var lineWidth: CGFloat
    var color: CodableColor
    var opacity: Double
}
