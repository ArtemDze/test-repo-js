import SwiftUI

/// Premium theatrical launch — geometric chaos resolves into the Jestora Pattern Studio emblem.
struct LaunchAlignmentView: View {
    var isReturningUser: Bool = false
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var phase: CGFloat = 0
    @State private var spotlight: CGFloat = 0
    @State private var markOpacity: CGFloat = 0
    @State private var markScale: CGFloat = 0.92
    @State private var ringPulse: CGFloat = 0
    @State private var curtainOpen: CGFloat = 0
    @State private var exitFade: CGFloat = 1

    private var totalDuration: TimeInterval {
        if reduceMotion { return 0.45 }
        return isReturningUser ? JSRMotion.launchReturning : JSRMotion.launchDuration
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                stageBackground

                if reduceMotion {
                    Canvas { context, size in
                        let center = CGPoint(x: size.width / 2, y: size.height / 2 - 24)
                        drawOrbitRingsResolved(context: &context, center: center, progress: 1, shimmer: 0)
                        drawEmblemResolved(context: &context, center: center, progress: 1)
                    }
                    .opacity(markOpacity)
                } else {
                    animatedStage
                }

                VStack(spacing: 0) {
                    Spacer(minLength: geo.size.height * 0.58)
                    wordmark
                        .opacity(markOpacity)
                        .scaleEffect(markScale)
                    Spacer()
                }

                // Side veil during open
                HStack(spacing: 0) {
                    JSRColor.ink
                        .offset(x: -geo.size.width * 0.55 * curtainOpen)
                    JSRColor.ink
                        .offset(x: geo.size.width * 0.55 * curtainOpen)
                }
                .opacity(0.5 * (1 - curtainOpen))
                .allowsHitTesting(false)
            }
        }
        .opacity(exitFade)
        .background(JSRColor.ink.ignoresSafeArea())
        .ignoresSafeArea()
        .onAppear { runChoreography() }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(AppBrand.fullName)
        .accessibilityAddTraits(.isHeader)
    }

    private var stageBackground: some View {
        ZStack {
            JSRColor.ink

            RadialGradient(
                colors: [
                    JSRColor.highlight.opacity(0.16 * spotlight),
                    JSRColor.accent.opacity(0.09 * spotlight),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 16,
                endRadius: 300
            )
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [.clear, .black.opacity(0.6)],
                center: UnitPoint(x: 0.5, y: 0.42),
                startRadius: 100,
                endRadius: 560
            )
        }
    }

    private var animatedStage: some View {
        TimelineView(.animation(minimumInterval: 1 / 60, paused: exitFade < 0.05)) { timeline in
            let shimmer = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width / 2, y: size.height / 2 - 28)
                drawConstellation(context: &context, center: center, shimmer: shimmer)
                drawOrbitRingsResolved(context: &context, center: center, progress: phase, shimmer: shimmer)
                drawEmblemResolved(context: &context, center: center, progress: phase)
                drawSparkArcs(context: &context, center: center, shimmer: shimmer)
            }
        }
        .allowsHitTesting(false)
    }

    private var wordmark: some View {
        VStack(spacing: 10) {
            Text(AppBrand.nameMark)
                .font(JSRFont.serif(size: 36, relativeTo: .largeTitle, weight: .semibold))
                .tracking(10)
                .foregroundStyle(JSRColor.ivory)

            Text(AppBrand.studioMark)
                .font(JSRFont.serif(size: 11, relativeTo: .caption, weight: .medium))
                .tracking(3.2)
                .foregroundStyle(JSRColor.highlight.opacity(0.9))
        }
        .accessibilityHidden(true)
    }

    // MARK: Drawing

    private func drawConstellation(context: inout GraphicsContext, center: CGPoint, shimmer: TimeInterval) {
        let count = 14
        let ease = easeInOut(phase)
        // After lock-in, keep a slow ceremonial drift so the scene stays alive.
        let settledSpin = Double(ease) * shimmer * 0.22

        for i in 0..<count {
            let seed = Double(i) * 2.399
            let chaosAngle = seed + Double(1 - phase) * 3.4 + shimmer * 0.55 * Double(1 - ease)
            let orderedAngle = Double(i) / Double(count) * .pi * 2 - .pi / 2 + settledSpin
            let angle = chaosAngle * Double(1 - ease) + orderedAngle * Double(ease)

            let chaosRadius = 52 + CGFloat((i * 37) % 100) + (1 - phase) * 140
            let orderedRadius: CGFloat = 80 + CGFloat(i % 3) * 11 + CGFloat(sin(shimmer * 0.9 + seed)) * 2 * ease
            let radius = chaosRadius * (1 - ease) + orderedRadius * ease

            let wobble = CGFloat(sin(shimmer * 1.8 + seed)) * (1 - phase) * 10
            let pos = CGPoint(
                x: center.x + CGFloat(cos(angle)) * radius + wobble,
                y: center.y + CGFloat(sin(angle)) * radius
            )

            let sizeFactor: CGFloat = 11 + CGFloat(i % 4) * 3.2
            let diamond = diamondPath(
                center: pos,
                size: sizeFactor * (0.65 + 0.35 * phase),
                rotation: angle + settledSpin * 0.5
            )

            let color: Color = i.isMultiple(of: 3)
                ? JSRColor.secondaryAccent
                : (i.isMultiple(of: 2) ? JSRColor.highlight : JSRColor.accent)

            context.fill(diamond, with: .color(color.opacity(0.18 + 0.55 * phase)))
            context.stroke(diamond, with: .color(JSRColor.ivory.opacity(0.22 + 0.4 * phase)), lineWidth: 1)

            if phase < 0.62 {
                var filament = Path()
                filament.move(to: center)
                filament.addLine(to: pos)
                context.stroke(filament, with: .color(color.opacity(0.08 * (1 - phase))), lineWidth: 0.7)
            }
        }
    }

    private func drawOrbitRingsResolved(
        context: inout GraphicsContext,
        center: CGPoint,
        progress: CGFloat,
        shimmer: TimeInterval = 0
    ) {
        let rings: [(CGFloat, Color, CGFloat)] = [
            (54, JSRColor.highlight, 1.6),
            (90, JSRColor.secondaryAccent, 1.25),
            (122, JSRColor.accent, 1.05)
        ]
        for (index, ring) in rings.enumerated() {
            let appear = smoothstep(CGFloat(index) * 0.1, CGFloat(index) * 0.1 + 0.42, progress)
            let pulse = 1 + ringPulse * 0.028 * CGFloat(index + 1)
            let rect = CGRect(
                x: center.x - ring.0 * pulse,
                y: center.y - ring.0 * pulse,
                width: ring.0 * 2 * pulse,
                height: ring.0 * 2 * pulse
            )
            context.stroke(
                Path(ellipseIn: rect),
                with: .color(ring.1.opacity(0.12 + 0.5 * appear)),
                style: StrokeStyle(
                    lineWidth: ring.2,
                    lineCap: .round,
                    dash: [5, 9],
                    dashPhase: CGFloat(-shimmer * (18 + Double(index) * 10))
                )
            )
        }
    }

    private func drawEmblemResolved(context: inout GraphicsContext, center: CGPoint, progress: CGFloat) {
        let p = easeInOut(progress)

        let maskW: CGFloat = 74 * (0.55 + 0.45 * p)
        let maskH: CGFloat = 92 * (0.55 + 0.45 * p)
        let maskRect = CGRect(x: center.x - maskW / 2, y: center.y - maskH / 2, width: maskW, height: maskH)
        context.stroke(
            Path(ellipseIn: maskRect),
            with: .color(JSRColor.ivory.opacity(0.18 + 0.6 * p)),
            lineWidth: 2
        )

        let dSize: CGFloat = 36 * p
        if dSize > 1 {
            let upright = diamondPath(center: center, size: dSize, rotation: 0)
            context.fill(upright, with: .color(JSRColor.highlight.opacity(0.22 + 0.5 * p)))
            context.stroke(upright, with: .color(JSRColor.highlight.opacity(0.75 * p)), lineWidth: 1.6)
        }

        if p > 0.32 {
            let arcOpacity = (p - 0.32) / 0.68
            strokeArc(
                context: &context,
                center: CGPoint(x: center.x - 17, y: center.y - 6),
                radius: 15,
                start: .degrees(200),
                end: .degrees(340),
                color: JSRColor.secondaryAccent.opacity(0.75 * arcOpacity)
            )
            strokeArc(
                context: &context,
                center: CGPoint(x: center.x + 17, y: center.y - 6),
                radius: 15,
                start: .degrees(200),
                end: .degrees(340),
                color: JSRColor.secondaryAccent.opacity(0.75 * arcOpacity)
            )
        }

        let core = CGRect(x: center.x - 3.2, y: center.y - 3.2, width: 6.4, height: 6.4)
        context.fill(Path(ellipseIn: core), with: .color(JSRColor.ivory.opacity(0.25 + 0.75 * p)))
    }

    private func drawSparkArcs(context: inout GraphicsContext, center: CGPoint, shimmer: TimeInterval) {
        guard phase > 0.42 else { return }
        let intensity = smoothstep(0.42, 0.88, phase)
        for i in 0..<3 {
            let a0 = Double(i) / 3.0 * .pi * 2 + shimmer * 0.35
            strokeArc(
                context: &context,
                center: center,
                radius: 136,
                start: .radians(a0),
                end: .radians(a0 + 0.5),
                color: JSRColor.highlight.opacity(0.2 * intensity)
            )
        }
    }

    // MARK: Choreography

    private func runChoreography() {
        if reduceMotion {
            phase = 1
            spotlight = 1
            curtainOpen = 1
            withAnimation(.easeOut(duration: 0.25)) {
                markOpacity = 1
                markScale = 1
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                withAnimation(.easeOut(duration: 0.22)) { exitFade = 0 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.24, execute: onFinished)
            }
            return
        }

        // ~5s arc:
        // 0.0–0.9  curtains + chaos
        // 0.9–3.4  fragments converge
        // 3.4–4.3  emblem locks + wordmark
        // 4.3–5.0  hold with living drift
        // 5.0–5.5  soft exit
        withAnimation(.easeOut(duration: 0.9)) {
            curtainOpen = 1
        }

        withAnimation(.timingCurve(0.22, 0.7, 0.2, 1.0, duration: 3.4)) {
            phase = 1
        }

        withAnimation(.easeInOut(duration: 2.2).delay(0.6)) {
            spotlight = 1
        }

        withAnimation(.easeInOut(duration: 0.85).delay(3.35)) {
            ringPulse = 1
        }
        withAnimation(.easeInOut(duration: 0.7).delay(4.15)) {
            ringPulse = 0
        }

        withAnimation(.spring(response: 0.7, dampingFraction: 0.86).delay(3.45)) {
            markOpacity = 1
            markScale = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + totalDuration) {
            withAnimation(.easeInOut(duration: 0.45)) {
                exitFade = 0
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.48, execute: onFinished)
        }
    }

    // MARK: Helpers

    private func diamondPath(center: CGPoint, size: CGFloat, rotation: Double) -> Path {
        let pts = [
            CGPoint(x: 0, y: -size),
            CGPoint(x: size * 0.68, y: 0),
            CGPoint(x: 0, y: size),
            CGPoint(x: -size * 0.68, y: 0)
        ].map { rotate($0, by: rotation) }
            .map { CGPoint(x: center.x + $0.x, y: center.y + $0.y) }

        var path = Path()
        path.move(to: pts[0])
        for pt in pts.dropFirst() { path.addLine(to: pt) }
        path.closeSubpath()
        return path
    }

    private func strokeArc(
        context: inout GraphicsContext,
        center: CGPoint,
        radius: CGFloat,
        start: Angle,
        end: Angle,
        color: Color
    ) {
        var path = Path()
        path.addArc(center: center, radius: radius, startAngle: start, endAngle: end, clockwise: false)
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
    }

    private func rotate(_ point: CGPoint, by angle: Double) -> CGPoint {
        let c = cos(angle), s = sin(angle)
        return CGPoint(x: point.x * c - point.y * s, y: point.x * s + point.y * c)
    }

    private func easeInOut(_ t: CGFloat) -> CGFloat {
        t < 0.5 ? 2 * t * t : 1 - pow(-2 * t + 2, 2) / 2
    }

    private func smoothstep(_ edge0: CGFloat, _ edge1: CGFloat, _ x: CGFloat) -> CGFloat {
        let t = min(max((x - edge0) / max(edge1 - edge0, 0.0001), 0), 1)
        return t * t * (3 - 2 * t)
    }
}

#Preview("First launch") {
    LaunchAlignmentView(isReturningUser: false, onFinished: {})
}

#Preview("Returning") {
    LaunchAlignmentView(isReturningUser: true, onFinished: {})
}
