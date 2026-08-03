import Foundation
import CoreGraphics

/// Deterministic, center-true pattern generator. Clean geometry by default.
enum PatternEngine {
    static func primitives(for params: PatternParameters, in size: CGSize) -> [RenderPrimitive] {
        var p = params
        p.clamp()
        var rng = SeededGenerator(seed: p.seed)
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let minSide = min(size.width, size.height)

        switch p.layout {
        case .radial:
            return radial(p, center: center, minSide: minSide, rng: &rng)
        case .mirror:
            return mirror(p, center: center, minSide: minSide, rng: &rng)
        case .kaleidoscope:
            return kaleidoscope(p, center: center, minSide: minSide, rng: &rng)
        case .spiral:
            return spiral(p, center: center, minSide: minSide, rng: &rng)
        case .lattice:
            return lattice(p, size: size, rng: &rng)
        case .vortex:
            return vortex(p, center: center, minSide: minSide, rng: &rng)
        case .orbit:
            return orbit(p, center: center, minSide: minSide, rng: &rng)
        case .curtain:
            return curtain(p, center: center, size: size, rng: &rng)
        }
    }

    static func exportPixelSize(ratio: CanvasRatio, quality: ExportQuality) -> CGSize {
        let base = ratio.size
        return CGSize(width: base.width * quality.scale, height: base.height * quality.scale)
    }

    // MARK: Layouts — always centered, optional asymmetry only when requested

    private static func radial(
        _ p: PatternParameters,
        center: CGPoint,
        minSide: Double,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let base = minSide * p.scale * 0.46

        if p.showGlow {
            out += ring(center: center, radius: base * 1.08, color: p.secondary, opacity: 0.18 * p.opacity, width: 1.5)
            out += ring(center: center, radius: base * 0.22, color: p.foreground, opacity: 0.35 * p.opacity, width: 1.25)
        }

        for depth in 0..<p.layerDepth {
            let depthScale = 1.0 - Double(depth) * 0.16
            for rep in 0..<p.repetition {
                let radius = base * depthScale * (1 - Double(rep) * p.spacing * 0.85)
                guard radius > 8 else { continue }
                let unit = unitShape(p.geometry, radius: radius * 0.38, sides: p.polygonSides, distortion: p.distortion, rng: &rng)
                let color = (rep + depth).isMultiple(of: 2) ? p.foreground : p.secondary
                let opacity = p.opacity * (1 - Double(rep) * 0.06 - Double(depth) * 0.08)

                for s in 0..<max(1, p.symmetryCount) {
                    let angle = (Double(s) / Double(max(1, p.symmetryCount))) * .pi * 2
                        + p.rotation * .pi / 180
                    // Place motif along ring, not piled on center — cleaner radial bloom
                    let orbit = radius * 0.55
                    let anchor = CGPoint(x: center.x + cos(angle) * orbit, y: center.y + sin(angle) * orbit)
                    let jitter = p.asymmetry * (rng.nextDouble() - 0.5) * radius * 0.12
                    let pos = CGPoint(x: anchor.x + cos(angle + .pi / 2) * jitter, y: anchor.y + sin(angle + .pi / 2) * jitter)
                    let transformed = unit.map { rotate($0, by: angle + .pi / 2) }
                        .map { CGPoint(x: pos.x + $0.x, y: pos.y + $0.y) }
                    out += draw(transformed, params: p, color: color, opacity: opacity)
                }
            }
        }
        return out
    }

    private static func mirror(
        _ p: PatternParameters,
        center: CGPoint,
        minSide: Double,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let base = minSide * p.scale * 0.36
        let gap = minSide * 0.16

        for rep in 0..<p.repetition {
            let radius = base * (1 - Double(rep) * p.spacing * 0.7)
            guard radius > 8 else { continue }
            let unit = unitShape(p.geometry, radius: radius, sides: p.polygonSides, distortion: p.distortion, rng: &rng)
            let rot = p.rotation * .pi / 180
            let left = unit.map { rotate($0, by: rot) }
                .map { CGPoint(x: center.x - gap + $0.x, y: center.y + $0.y) }
            let right = unit.map { CGPoint(x: -$0.x, y: $0.y) }
                .map { rotate($0, by: -rot) }
                .map { CGPoint(x: center.x + gap + $0.x, y: center.y + $0.y) }
            let fade = p.opacity * (1 - Double(rep) * 0.1)
            out += draw(left, params: p, color: p.foreground, opacity: fade)
            out += draw(right, params: p, color: p.secondary, opacity: fade)
        }

        let jewel = unitShape(.diamond, radius: base * 0.18, sides: 4, distortion: 0, rng: &rng)
            .map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }
        out += draw(jewel, params: p, color: p.foreground, opacity: p.opacity)
        out += ring(center: center, radius: base * 1.15, color: p.secondary, opacity: 0.2 * p.opacity, width: 1.25)
        return out
    }

    private static func kaleidoscope(
        _ p: PatternParameters,
        center: CGPoint,
        minSide: Double,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let wedges = max(6, p.symmetryCount)
        let base = minSide * p.scale * 0.42
        let petal = unitShape(p.geometry, radius: base * 0.42, sides: p.polygonSides, distortion: p.distortion * 0.35, rng: &rng)

        for w in 0..<wedges {
            let angle = (Double(w) / Double(wedges)) * .pi * 2 + p.rotation * .pi / 180
            let color = w.isMultiple(of: 2) ? p.foreground : p.secondary
            let transformed = petal.map { rotate($0, by: angle) }
                .map { CGPoint(x: center.x + $0.x * 0.55 + cos(angle) * base * 0.28, y: center.y + $0.y * 0.55 + sin(angle) * base * 0.28) }
            out += draw(transformed, params: p, color: color, opacity: p.opacity * 0.9)
        }
        out += ring(center: center, radius: base * 0.2, color: p.foreground, opacity: p.opacity * 0.7, width: 2)
        return out
    }

    private static func spiral(
        _ p: PatternParameters,
        center: CGPoint,
        minSide: Double,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let count = 20 + p.symmetryCount
        let turns = 2.2
        for i in 0..<count {
            let t = Double(i) / Double(max(1, count - 1))
            let angle = t * .pi * 2 * turns + p.rotation * .pi / 180
            let radius = minSide * 0.06 + t * minSide * p.scale * 0.38
            let size = 10 + t * 36
            let unit = unitShape(p.geometry, radius: size, sides: p.polygonSides, distortion: p.distortion * t * 0.5, rng: &rng)
            let pos = CGPoint(x: center.x + cos(angle) * radius, y: center.y + sin(angle) * radius)
            let transformed = unit.map { rotate($0, by: angle) }
                .map { CGPoint(x: pos.x + $0.x, y: pos.y + $0.y) }
            let color = i.isMultiple(of: 2) ? p.foreground : p.secondary
            out += draw(transformed, params: p, color: color, opacity: p.opacity * (0.4 + t * 0.6))
        }
        return out
    }

    private static func lattice(
        _ p: PatternParameters,
        size: CGSize,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let cols = 5
        let rows = 5
        let marginX = size.width * 0.12
        let marginY = size.height * 0.12
        let usableW = size.width - marginX * 2
        let usableH = size.height - marginY * 2
        let cellW = usableW / Double(cols - 1)
        let cellH = usableH / Double(rows - 1)
        let motifR = min(cellW, cellH) * p.scale * 0.38

        for r in 0..<rows {
            for c in 0..<cols {
                let x = marginX + Double(c) * cellW
                let y = marginY + Double(r) * cellH
                // Asymmetry only if user asks — otherwise perfect grid
                let jx = p.asymmetry > 0.001 ? (rng.nextDouble() - 0.5) * cellW * p.asymmetry * 0.35 : 0
                let jy = p.asymmetry > 0.001 ? (rng.nextDouble() - 0.5) * cellH * p.asymmetry * 0.35 : 0
                let rot = p.rotation * .pi / 180 + (p.distortion > 0 ? Double(r + c) * 0.04 * p.distortion : 0)
                let unit = unitShape(p.geometry, radius: motifR, sides: p.polygonSides, distortion: p.distortion * 0.3, rng: &rng)
                let transformed = unit.map { rotate($0, by: rot) }
                    .map { CGPoint(x: x + jx + $0.x, y: y + jy + $0.y) }
                let color = (r + c).isMultiple(of: 2) ? p.foreground : p.secondary
                out += draw(transformed, params: p, color: color, opacity: p.opacity * 0.88)
            }
        }
        return out
    }

    private static func vortex(
        _ p: PatternParameters,
        center: CGPoint,
        minSide: Double,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let rings = max(5, p.repetition + 3)
        for i in 0..<rings {
            let t = Double(i) / Double(rings - 1)
            let radius = minSide * p.scale * (0.12 + t * 0.38)
            let rot = p.rotation * .pi / 180 + t * .pi * 0.65
            let unit = unitShape(
                p.geometry == .circle ? .polygon : p.geometry,
                radius: radius,
                sides: max(3, p.polygonSides),
                distortion: 0,
                rng: &rng
            )
            let transformed = unit.map { rotate($0, by: rot) }
                .map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }
            let color = i.isMultiple(of: 2) ? p.foreground : p.secondary
            // Outline-dominant for clean nested look
            out.append(RenderPrimitive(
                points: transformed,
                closed: true,
                kind: .stroke,
                lineWidth: max(1.2, p.strokeWidth * (1 - t * 0.3)),
                color: color,
                opacity: p.opacity * (0.35 + t * 0.55)
            ))
        }
        return out
    }

    private static func orbit(
        _ p: PatternParameters,
        center: CGPoint,
        minSide: Double,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let count = max(5, p.symmetryCount)
        let orbitR = minSide * p.scale * 0.34
        let bodyR = minSide * p.scale * 0.09

        out += ring(center: center, radius: orbitR, color: p.secondary, opacity: p.opacity * 0.25, width: 1.25)
        let core = unitShape(.circle, radius: bodyR * 0.75, sides: 32, distortion: 0, rng: &rng)
            .map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }
        out += draw(core, params: p, color: p.secondary, opacity: p.opacity)

        for i in 0..<count {
            let angle = (Double(i) / Double(count)) * .pi * 2 + p.rotation * .pi / 180
            let pos = CGPoint(x: center.x + cos(angle) * orbitR, y: center.y + sin(angle) * orbitR)
            let unit = unitShape(p.geometry, radius: bodyR, sides: p.polygonSides, distortion: 0, rng: &rng)
            let transformed = unit.map { rotate($0, by: angle) }
                .map { CGPoint(x: pos.x + $0.x, y: pos.y + $0.y) }
            out += draw(transformed, params: p, color: i.isMultiple(of: 2) ? p.foreground : p.secondary, opacity: p.opacity)
        }
        return out
    }

    private static func curtain(
        _ p: PatternParameters,
        center: CGPoint,
        size: CGSize,
        rng: inout SeededGenerator
    ) -> [RenderPrimitive] {
        var out: [RenderPrimitive] = []
        let panels = max(3, min(5, p.repetition + 1))
        for side in [-1.0, 1.0] {
            for i in 0..<panels {
                let t = Double(i) / Double(panels)
                let w = size.width * 0.2 * p.scale / 0.55
                let h = size.height * (0.42 + t * 0.08)
                let x = center.x + side * (size.width * (0.22 + t * 0.05))
                let rect = [
                    CGPoint(x: -w / 2, y: -h / 2),
                    CGPoint(x: w / 2, y: -h / 2),
                    CGPoint(x: w / 2, y: h / 2),
                    CGPoint(x: -w / 2, y: h / 2)
                ]
                let rot = side * (0.04 + t * 0.03)
                let transformed = rect.map { rotate($0, by: rot) }
                    .map { CGPoint(x: x + $0.x, y: center.y + $0.y) }
                out += draw(transformed, params: p, color: side < 0 ? p.foreground : p.secondary, opacity: p.opacity * (0.55 + t * 0.35))
            }
        }
        let emblem = unitShape(p.geometry, radius: min(size.width, size.height) * 0.1, sides: p.polygonSides, distortion: 0, rng: &rng)
            .map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }
        out += draw(emblem, params: p, color: p.foreground, opacity: p.opacity)
        return out
    }

    // MARK: Helpers

    private static func ring(center: CGPoint, radius: Double, color: CodableColor, opacity: Double, width: Double) -> [RenderPrimitive] {
        let pts = ellipse(rx: radius, ry: radius, steps: 64).map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }
        return [RenderPrimitive(points: pts, closed: true, kind: .stroke, lineWidth: width, color: color, opacity: opacity)]
    }

    private static func draw(_ points: [CGPoint], params: PatternParameters, color: CodableColor, opacity: Double) -> [RenderPrimitive] {
        switch params.renderMode {
        case .fill:
            return [RenderPrimitive(points: points, closed: true, kind: .path, lineWidth: 0, color: color, opacity: opacity)]
        case .outline:
            return [RenderPrimitive(points: points, closed: true, kind: .stroke, lineWidth: params.strokeWidth, color: color, opacity: opacity)]
        case .both:
            return [
                RenderPrimitive(points: points, closed: true, kind: .path, lineWidth: 0, color: color, opacity: opacity * 0.55),
                RenderPrimitive(points: points, closed: true, kind: .stroke, lineWidth: params.strokeWidth, color: color, opacity: opacity)
            ]
        }
    }

    private static func unitShape(
        _ kind: GeometryKind,
        radius: Double,
        sides: Int,
        distortion: Double,
        rng: inout SeededGenerator
    ) -> [CGPoint] {
        let base: [CGPoint]
        switch kind {
        case .diamond:
            base = [
                CGPoint(x: 0, y: -radius),
                CGPoint(x: radius * 0.68, y: 0),
                CGPoint(x: 0, y: radius),
                CGPoint(x: -radius * 0.68, y: 0)
            ]
        case .circle:
            base = ellipse(rx: radius, ry: radius, steps: 48)
        case .arc:
            base = arcPoints(radius: radius, start: -.pi * 0.15, end: .pi * 1.05, steps: 36)
        case .polygon:
            base = polygon(sides: max(3, sides), radius: radius)
        case .ribbon:
            var pts: [CGPoint] = []
            let steps = 32
            for i in 0...steps {
                let t = Double(i) / Double(steps)
                pts.append(CGPoint(x: (t - 0.5) * radius * 2.2, y: sin(t * .pi * 2) * radius * 0.32 - radius * 0.12))
            }
            for i in stride(from: steps, through: 0, by: -1) {
                let t = Double(i) / Double(steps)
                pts.append(CGPoint(x: (t - 0.5) * radius * 2.2, y: sin(t * .pi * 2) * radius * 0.32 + radius * 0.12))
            }
            base = pts
        case .starburst:
            base = star(points: max(5, sides), outer: radius, inner: radius * 0.42)
        case .mask:
            base = ellipse(rx: radius * 0.82, ry: radius, steps: 40)
        }
        guard distortion > 0.001 else { return base }
        return base.map { pt in
            CGPoint(
                x: pt.x + (rng.nextDouble() - 0.5) * distortion * 6,
                y: pt.y + (rng.nextDouble() - 0.5) * distortion * 6
            )
        }
    }

    private static func rotate(_ point: CGPoint, by angle: Double) -> CGPoint {
        let c = cos(angle), s = sin(angle)
        return CGPoint(x: point.x * c - point.y * s, y: point.x * s + point.y * c)
    }

    private static func polygon(sides: Int, radius: Double) -> [CGPoint] {
        (0..<sides).map { i in
            let a = (Double(i) / Double(sides)) * .pi * 2 - .pi / 2
            return CGPoint(x: cos(a) * radius, y: sin(a) * radius)
        }
    }

    private static func star(points: Int, outer: Double, inner: Double) -> [CGPoint] {
        let total = points * 2
        return (0..<total).map { i in
            let a = (Double(i) / Double(total)) * .pi * 2 - .pi / 2
            let r = i.isMultiple(of: 2) ? outer : inner
            return CGPoint(x: cos(a) * r, y: sin(a) * r)
        }
    }

    private static func ellipse(rx: Double, ry: Double, steps: Int) -> [CGPoint] {
        (0..<steps).map { i in
            let a = (Double(i) / Double(steps)) * .pi * 2
            return CGPoint(x: cos(a) * rx, y: sin(a) * ry)
        }
    }

    private static func arcPoints(radius: Double, start: Double, end: Double, steps: Int) -> [CGPoint] {
        (0...steps).map { i in
            let t = Double(i) / Double(steps)
            let a = start + (end - start) * t
            return CGPoint(x: cos(a) * radius, y: sin(a) * radius)
        }
    }
}

struct SeededGenerator: Sendable {
    private var state: UInt64
    init(seed: UInt64) { state = seed == 0 ? 0x9E3779B97F4A7C15 : seed }
    mutating func next() -> UInt64 {
        state &+= 0x9E3779B97F4A7C15
        var z = state
        z = (z ^ (z >> 30)) &* 0xBF58476D1CE4E5B9
        z = (z ^ (z >> 27)) &* 0x94D049BB133111EB
        return z ^ (z >> 31)
    }
    mutating func nextDouble() -> Double { Double(next() % 10_000) / 10_000 }
}

enum ExportQuality: String, Codable, CaseIterable, Identifiable, Sendable {
    case standard, high, maximum
    var id: String { rawValue }
    var title: String {
        switch self {
        case .standard: "Standard"
        case .high: "High"
        case .maximum: "Maximum"
        }
    }
    var scale: CGFloat {
        switch self {
        case .standard: 1
        case .high: 2
        case .maximum: 3
        }
    }
}
