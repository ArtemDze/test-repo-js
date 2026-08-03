import SwiftUI

/// Five-act theatrical onboarding — typed copy + interactive stage moments.
struct OnboardingFlowView: View {
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(HapticsClient.self) private var haptics

    @State private var page: OnboardingPage = .prologue
    @State private var demo = MotifCatalog.all[0].parameters
    @State private var kinetic: KineticStyle = .breathe
    @State private var inverted = false
    @State private var titleDone = false
    @State private var bodyDone = false
    @State private var prologueProgress: CGFloat = 0
    @State private var appearToken = UUID()

    var body: some View {
        ZStack {
            atmosphere.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, JSRSpace.lg)
                    .padding(.top, JSRSpace.sm)

                stage
                    .frame(maxHeight: .infinity)
                    .padding(.horizontal, JSRSpace.lg)
                    .padding(.top, JSRSpace.md)

                copyBlock
                    .padding(.horizontal, JSRSpace.lg)
                    .padding(.top, JSRSpace.lg)

                interactiveChrome
                    .padding(.top, JSRSpace.md)
                    .frame(minHeight: 56)

                progressDiamonds
                    .padding(.top, JSRSpace.md)

                bottomBar
                    .padding(.horizontal, JSRSpace.lg)
                    .padding(.top, JSRSpace.md)
                    .padding(.bottom, JSRSpace.lg)
            }
        }
        // Same dark stage language as launch — not the light app chrome.
        .preferredColorScheme(.dark)
        .onAppear { configure(for: .prologue, animateScene: true) }
        .onChange(of: page) { _, newValue in
            configure(for: newValue, animateScene: true)
        }
    }

    // MARK: Atmosphere

    private var atmosphere: some View {
        JSRStageAtmosphere(tint: pageTint)
            .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: page)
    }

    private var pageTint: Color {
        switch page {
        case .prologue: JSRColor.accent
        case .symmetry: JSRColor.highlight
        case .contrast: JSRColor.secondaryAccent
        case .motion: JSRColor.accent
        case .yours: JSRColor.highlight
        }
    }

    // MARK: Top

    private var topBar: some View {
        HStack {
            if page != .prologue {
                Button {
                    goBack()
                } label: {
                    Label("Back", systemImage: "chevron.left")
                        .font(JSRType.callout)
                        .foregroundStyle(JSRColor.ivory.opacity(0.55))
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Previous page")
            }

            Spacer()

            Text(page.eyebrow.uppercased())
                .font(JSRType.motif)
                .tracking(1.4)
                .foregroundStyle(JSRColor.highlight)

            Spacer()

            Button("Skip") {
                haptics.select()
                onFinished()
            }
            .font(JSRType.callout)
            .foregroundStyle(JSRColor.ivory.opacity(0.55))
            .accessibilityLabel("Skip onboarding")
            .opacity(page == .yours ? 0 : 1)
            .allowsHitTesting(page != .yours)
        }
    }

    // MARK: Stage

    @ViewBuilder
    private var stage: some View {
        OnboardingStageChrome {
            Group {
                switch page {
                case .prologue:
                    OnboardingPrologueScene(progress: prologueProgress, reduceMotion: reduceMotion)
                case .contrast:
                    PatternCanvasView(
                        parameters: displayParams,
                        kinetic: reduceMotion ? .none : .shimmer,
                        reduceMotion: reduceMotion
                    )
                    .contentShape(Rectangle())
                    .onTapGesture { toggleInvert() }
                case .motion:
                    PatternCanvasView(
                        parameters: demo,
                        kinetic: reduceMotion ? .none : kinetic,
                        reduceMotion: reduceMotion
                    )
                case .symmetry, .yours:
                    PatternCanvasView(
                        parameters: demo,
                        kinetic: reduceMotion ? .none : (page == .yours ? .orbit : .breathe),
                        reduceMotion: reduceMotion
                    )
                }
            }
            .id(appearToken)
            .transition(.asymmetric(
                insertion: .opacity.combined(with: .scale(scale: 0.98)),
                removal: .opacity
            ))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .frame(height: stageHeight)
        .animation(JSRMotion.preferred(JSRMotion.morph, reduceMotion: reduceMotion), value: page)
    }

    private var stageHeight: CGFloat {
        page == .prologue ? 300 : 280
    }

    private var displayParams: PatternParameters {
        guard inverted else { return demo }
        var p = demo
        swap(&p.foreground, &p.background)
        return p
    }

    // MARK: Copy

    private var copyBlock: some View {
        VStack(spacing: JSRSpace.sm) {
            TypewriterText(
                fullText: page.title,
                font: JSRType.display,
                foreground: JSRColor.ivory,
                duration: 0.55,
                startDelay: 0.04,
                showCaret: false,
                reduceMotion: reduceMotion,
                isActive: true
            ) {
                titleDone = true
            }
            .id("title-\(page.id)-\(appearToken)")

            // Space always reserved; reveal starts after title, without layout shifts.
            TypewriterText(
                fullText: page.body,
                font: JSRType.body,
                foreground: JSRColor.ivory.opacity(0.62),
                duration: 0.7,
                startDelay: 0.06,
                showCaret: false,
                reduceMotion: reduceMotion,
                isActive: titleDone || reduceMotion
            ) {
                bodyDone = true
            }
            .id("body-\(page.id)-\(appearToken)")
            .frame(maxWidth: 360)
        }
        .frame(minHeight: 128, alignment: .top)
        .accessibilityElement(children: .combine)
    }

    // MARK: Interactive chrome

    @ViewBuilder
    private var interactiveChrome: some View {
        switch page {
        case .prologue:
            Text("Curtains part for geometric play.")
                .font(JSRType.caption)
                .foregroundStyle(JSRColor.ivory.opacity(0.38))
                .padding(.horizontal, JSRSpace.lg)

        case .symmetry:
            JSRParameterSlider(
                title: "Symmetry folds",
                value: Binding(
                    get: { Double(demo.symmetryCount) },
                    set: {
                        demo.symmetryCount = Int($0)
                        demo.clamp()
                        haptics.select()
                    }
                ),
                range: 4...16,
                step: 1,
                valueLabel: { "\(Int($0))" },
                stageChrome: true
            )
            .padding(.horizontal, JSRSpace.lg)

        case .contrast:
            VStack(spacing: JSRSpace.xs) {
                Text(inverted ? "Tap stage · inverted" : "Tap stage · invert figure & ground")
                    .font(JSRType.caption)
                    .foregroundStyle(JSRColor.ivory.opacity(0.38))
                JSRParameterSlider(
                    title: "Tension",
                    value: $demo.asymmetry,
                    range: 0...0.75,
                    stageChrome: true
                )
                .padding(.horizontal, JSRSpace.lg)
            }

        case .motion:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: JSRSpace.xs) {
                    ForEach(KineticStyle.allCases) { style in
                        OnboardingChip(title: style.title, isSelected: kinetic == style) {
                            withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                                kinetic = style
                            }
                            haptics.select()
                        }
                    }
                }
                .padding(.horizontal, JSRSpace.lg)
            }

        case .yours:
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: JSRSpace.xs) {
                    ForEach(Array(MotifCatalog.all.prefix(6))) { motif in
                        OnboardingChip(title: motif.title, isSelected: demo == motif.parameters) {
                            withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                                demo = motif.parameters
                                demo.clamp()
                            }
                            haptics.select()
                        }
                    }
                }
                .padding(.horizontal, JSRSpace.lg)
            }
        }
    }

    // MARK: Progress

    private var progressDiamonds: some View {
        HStack(spacing: 10) {
            ForEach(OnboardingPage.allCases) { item in
                DiamondMark(filled: item.rawValue <= page.rawValue, active: item == page)
                    .frame(width: item == page ? 12 : 8, height: item == page ? 12 : 8)
                    .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: page)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Onboarding progress")
        .accessibilityValue("Page \(page.rawValue + 1) of \(OnboardingPage.allCases.count)")
    }

    // MARK: Bottom

    private var bottomBar: some View {
        JSRPrimaryAction(
            title: page.primaryTitle,
            systemImage: page.primarySymbol,
            isEnabled: canAdvance
        ) {
            advance()
        }
    }

    private var canAdvance: Bool {
        if reduceMotion { return true }
        // Interactive pages unlock earlier; still wait for title so copy leads.
        switch page {
        case .prologue: return titleDone && bodyDone
        case .symmetry, .contrast, .motion: return titleDone
        case .yours: return titleDone
        }
    }

    // MARK: Navigation

    private func advance() {
        haptics.select()
        if page == .yours {
            haptics.success()
            onFinished()
            return
        }
        guard let next = OnboardingPage(rawValue: page.rawValue + 1) else {
            onFinished()
            return
        }
        withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
            page = next
        }
    }

    private func goBack() {
        guard let prev = OnboardingPage(rawValue: page.rawValue - 1) else { return }
        haptics.select()
        withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
            page = prev
        }
    }

    private func toggleInvert() {
        withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
            inverted.toggle()
        }
        haptics.select()
    }

    private func configure(for page: OnboardingPage, animateScene: Bool) {
        titleDone = reduceMotion
        bodyDone = reduceMotion
        appearToken = UUID()
        inverted = false

        switch page {
        case .prologue:
            demo = MotifCatalog.all[0].parameters
            prologueProgress = reduceMotion ? 1 : 0
            if animateScene && !reduceMotion {
                withAnimation(.timingCurve(0.22, 0.75, 0.2, 1, duration: 2.4)) {
                    prologueProgress = 1
                }
            }
        case .symmetry:
            demo = MotifCatalog.all[0].parameters
            demo.symmetryCount = 8
            kinetic = .breathe
        case .contrast:
            demo = MotifCatalog.all[1].parameters
            demo.asymmetry = 0.2
            kinetic = .shimmer
        case .motion:
            demo = MotifCatalog.all[5].parameters
            kinetic = .orbit
        case .yours:
            demo = MotifCatalog.all[3].parameters
            kinetic = .orbit
        }
        demo.clamp()
    }
}

// MARK: - Progress mark

private struct DiamondMark: View {
    var filled: Bool
    var active: Bool

    var body: some View {
        DiamondShape()
            .fill(filled ? (active ? JSRColor.highlight : JSRColor.accent.opacity(0.85)) : JSRColor.ivory.opacity(0.14))
            .overlay {
                DiamondShape()
                    .strokeBorder(JSRColor.ivory.opacity(0.22), lineWidth: active ? 0 : 1)
            }
    }
}

private struct DiamondShape: InsettableShape {
    var insetAmount: CGFloat = 0

    func path(in rect: CGRect) -> Path {
        let r = rect.insetBy(dx: insetAmount, dy: insetAmount)
        var path = Path()
        path.move(to: CGPoint(x: r.midX, y: r.minY))
        path.addLine(to: CGPoint(x: r.maxX, y: r.midY))
        path.addLine(to: CGPoint(x: r.midX, y: r.maxY))
        path.addLine(to: CGPoint(x: r.minX, y: r.midY))
        path.closeSubpath()
        return path
    }

    func inset(by amount: CGFloat) -> some InsettableShape {
        var copy = self
        copy.insetAmount += amount
        return copy
    }
}

#Preview {
    OnboardingFlowView(onFinished: {})
        .environment(HapticsClient())
}
