import SwiftUI

// MARK: - Prologue (cinematic, non-interactive)

struct OnboardingPrologueScene: View {
    var progress: CGFloat
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                drawCurtains(context: &context, size: size)
                drawConstellation(context: &context, center: center, t: t)
                drawEmblem(context: &context, center: center)
            }
        }
        .background(JSRColor.ink)
        .clipShape(RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous))
        .accessibilityHidden(true)
    }

    private func drawCurtains(context: inout GraphicsContext, size: CGSize) {
        let open = ease(progress)
        let width = size.width * 0.5 * (1 - open)
        var left = Path(CGRect(x: 0, y: 0, width: width, height: size.height))
        var right = Path(CGRect(x: size.width - width, y: 0, width: width, height: size.height))
        context.fill(left, with: .color(JSRColor.accent.opacity(0.88)))
        context.fill(right, with: .color(JSRColor.accent.opacity(0.88)))
    }

    private func drawConstellation(context: inout GraphicsContext, center: CGPoint, t: TimeInterval) {
        let count = 12
        let easeP = ease(progress)
        for i in 0..<count {
            let seed = Double(i) * 2.17
            let angle = Double(i) / Double(count) * .pi * 2 - .pi / 2 + t * 0.18 * Double(easeP)
            let radius: CGFloat = 52 + CGFloat(i % 3) * 14 + CGFloat(1 - easeP) * 70
            let pos = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius,
                y: center.y + CGFloat(sin(angle)) * radius
            )
            let size: CGFloat = 8 + CGFloat(i % 3) * 2.5
            let path = diamond(at: pos, size: size, rotation: angle)
            let color: Color = i.isMultiple(of: 2) ? JSRColor.highlight : JSRColor.secondaryAccent
            context.fill(path, with: .color(color.opacity(0.25 + 0.55 * easeP)))
            context.stroke(path, with: .color(JSRColor.ivory.opacity(0.35 * easeP)), lineWidth: 1)
        }
    }

    private func drawEmblem(context: inout GraphicsContext, center: CGPoint) {
        let p = ease(progress)
        guard p > 0.35 else { return }
        let local = smoothstep(0.35, 0.95, p)
        let outer = diamond(at: center, size: 34 * local, rotation: .pi / 4)
        let inner = diamond(at: center, size: 16 * local, rotation: 0)
        context.stroke(outer, with: .color(JSRColor.highlight.opacity(0.85 * local)), lineWidth: 2)
        context.fill(inner, with: .color(JSRColor.ivory.opacity(0.9 * local)))
    }

    private func diamond(at center: CGPoint, size: CGFloat, rotation: Double) -> Path {
        let pts = [
            CGPoint(x: 0, y: -size),
            CGPoint(x: size * 0.68, y: 0),
            CGPoint(x: 0, y: size),
            CGPoint(x: -size * 0.68, y: 0)
        ].map { p -> CGPoint in
            let c = cos(rotation), s = sin(rotation)
            return CGPoint(x: center.x + p.x * c - p.y * s, y: center.y + p.x * s + p.y * c)
        }
        var path = Path()
        path.move(to: pts[0])
        for pt in pts.dropFirst() { path.addLine(to: pt) }
        path.closeSubpath()
        return path
    }

    private func ease(_ x: CGFloat) -> CGFloat {
        let t = min(max(x, 0), 1)
        return t * t * (3 - 2 * t)
    }

    private func smoothstep(_ a: CGFloat, _ b: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = min(max((x - a) / (b - a), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

// MARK: - Shared stage chrome

struct OnboardingStageChrome<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                    .fill(JSRColor.ink)
                    .overlay {
                        RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        JSRColor.highlight.opacity(0.55),
                                        JSRColor.accent.opacity(0.25),
                                        JSRColor.secondaryAccent.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.2
                            )
                    }
                    .shadow(color: Color.black.opacity(0.28), radius: 22, y: 10)
            }
    }
}

// MARK: - Interactive chips

struct OnboardingChip: View {
    let title: String
    var isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(JSRType.caption.weight(.semibold))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .foregroundStyle(isSelected ? JSRColor.ivory : JSRColor.ivory.opacity(0.72))
                .background(isSelected ? JSRColor.accent : JSRColor.ivory.opacity(0.08))
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            isSelected ? JSRColor.highlight.opacity(0.65) : JSRColor.ivory.opacity(0.14),
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}
