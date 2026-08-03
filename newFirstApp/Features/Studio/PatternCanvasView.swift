import SwiftUI

/// Renders a static composition. Kinetic motion is applied as view transforms
/// (not per-frame geometry rebuild) so patterns stay crisp and aligned.
struct PatternCanvasView: View {
    let parameters: PatternParameters
    var showChrome: Bool = false
    var kinetic: KineticStyle = .none
    var reduceMotion: Bool = false

    @Environment(\.motionIntensity) private var motionIntensity

    private var intensity: Double {
        reduceMotion ? 0 : MotionIntensity.clamped(motionIntensity)
    }

    private var primitives: [RenderPrimitive] {
        PatternEngine.primitives(for: parameters, in: parameters.canvasRatio.size)
    }

    var body: some View {
        TimelineView(.animation(minimumInterval: shouldAnimate ? 1 / 30 : 100, paused: !shouldAnimate)) { timeline in
            let t = shouldAnimate ? timeline.date.timeIntervalSinceReferenceDate : 0
            drawnCanvas
                .scaleEffect(breatheScale(t))
                .rotationEffect(.degrees(orbitDegrees(t)))
                .opacity(breatheOpacity(t))
        }
        .aspectRatio(parameters.canvasRatio.aspect, contentMode: .fit)
        .accessibilityElement()
        .accessibilityLabel("Composition canvas")
        .accessibilityValue(parameters.accessibilitySummary)
    }

    private var shouldAnimate: Bool {
        !reduceMotion && kinetic != .none && intensity > MotionIntensity.pauseThreshold
    }

    private var drawnCanvas: some View {
        Canvas { context, size in
            let canvasSize = parameters.canvasRatio.size
            let scale = min(size.width / canvasSize.width, size.height / canvasSize.height)
            let drawSize = CGSize(width: canvasSize.width * scale, height: canvasSize.height * scale)
            let origin = CGPoint(
                x: (size.width - drawSize.width) / 2,
                y: (size.height - drawSize.height) / 2
            )
            let bg = CGRect(origin: origin, size: drawSize)
            context.fill(
                Path(roundedRect: bg, cornerRadius: 0),
                with: .color(parameters.background.color)
            )

            for primitive in primitives {
                let mapped = primitive.points.map {
                    CGPoint(x: origin.x + $0.x * scale, y: origin.y + $0.y * scale)
                }
                guard let first = mapped.first else { continue }
                var path = Path()
                path.move(to: first)
                for pt in mapped.dropFirst() { path.addLine(to: pt) }
                if primitive.closed { path.closeSubpath() }

                let color = primitive.color.color.opacity(primitive.opacity)
                switch primitive.kind {
                case .path:
                    context.fill(path, with: .color(color))
                case .stroke:
                    context.stroke(
                        path,
                        with: .color(color),
                        style: StrokeStyle(
                            lineWidth: max(0.6, primitive.lineWidth * scale),
                            lineCap: .round,
                            lineJoin: .round
                        )
                    )
                }
            }

            if showChrome {
                context.stroke(
                    Path(bg.insetBy(dx: 0.5, dy: 0.5)),
                    with: .color(Color.white.opacity(0.08)),
                    lineWidth: 1
                )
            }
        }
    }

    private func breatheScale(_ t: TimeInterval) -> CGFloat {
        switch kinetic {
        case .breathe, .shimmer:
            guard shouldAnimate else { return 1 }
            let speed = 0.75 + intensity * 0.7
            return 1 + CGFloat(0.022 * intensity) * sin(t * speed)
        default:
            return 1
        }
    }

    private func orbitDegrees(_ t: TimeInterval) -> Double {
        switch kinetic {
        case .orbit:
            guard shouldAnimate else { return 0 }
            return t * (5 + 14 * intensity)
        case .shimmer:
            guard shouldAnimate else { return 0 }
            return sin(t * (0.55 + intensity * 0.5)) * (1.2 + 3.2 * intensity)
        default:
            return 0
        }
    }

    private func breatheOpacity(_ t: TimeInterval) -> Double {
        switch kinetic {
        case .breathe:
            guard shouldAnimate else { return 1 }
            return 1 - (0.08 * intensity) + (0.08 * intensity) * sin(t * (0.7 + intensity * 0.5))
        default:
            return 1
        }
    }
}

/// Soft stage plate behind artwork — consistent padding and corner.
struct StagePlate<Content: View>: View {
    var padding: CGFloat = JSRSpace.sm
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                    .fill(JSRColor.surfaceElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                            .strokeBorder(JSRColor.separator, lineWidth: 1)
                    }
                    .shadow(color: .black.opacity(0.18), radius: 20, y: 10)
            }
    }
}
