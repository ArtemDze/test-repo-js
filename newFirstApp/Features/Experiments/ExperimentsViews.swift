import SwiftUI

// MARK: - Labs home

struct ExperimentsHomeView: View {
    @State private var path = NavigationPath()
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var haptics: HapticsClient
    @AppStorage(LabProgress.drillsStorageKey) private var clearedRaw = ""

    private var tonight: LabDrill { LabCatalog.tonightDrill }
    private var clearedCount: Int { LabProgress.clearedIDs(from: clearedRaw).count }
    private var drillTotal: Int { LabCatalog.drills.count }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: JSRSpace.lg) {
                    header
                        .padding(.horizontal, JSRSpace.md)
                        .padding(.top, JSRSpace.sm)

                    progressRibbon
                        .padding(.horizontal, JSRSpace.md)
                        .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))

                    Button {
                        haptics.select()
                        path.append(LabDestination.drill(tonight.id))
                    } label: {
                        LabTonightDrillCard(drill: tonight, reduceMotion: reduceMotion)
                    }
                    .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                    .hoverEffect(.lift)
                    .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))
                    .padding(.horizontal, JSRSpace.md)
                    .accessibilityLabel("Tonight's eye drill: \(tonight.title). \(tonight.question)")

                    sectionLabel("EYE DRILLS", subtitle: "Mini tests that train judgment — not another motif shelf.")
                        .padding(.horizontal, JSRSpace.md)

                    VStack(spacing: 10) {
                        ForEach(Array(LabCatalog.drills.enumerated()), id: \.element.id) { index, drill in
                            Button {
                                haptics.select()
                                path.append(LabDestination.drill(drill.id))
                            } label: {
                                LabDrillRow(
                                    drill: drill,
                                    cleared: LabProgress.isCleared(drill.id, raw: clearedRaw),
                                    reduceMotion: reduceMotion
                                )
                            }
                            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                            .modifier(StageAppearModifier(index: index + 2, reduceMotion: reduceMotion))
                            .accessibilityLabel("\(drill.actLabel). \(drill.title). \(drill.question)")
                            .accessibilityValue(LabProgress.isCleared(drill.id, raw: clearedRaw) ? "Cleared" : "Not cleared")
                        }
                    }
                    .padding(.horizontal, JSRSpace.md)

                    sectionLabel("PRACTICE STAGES", subtitle: "Hands-on labs with field notes — deepen what the drills teach.")
                        .padding(.horizontal, JSRSpace.md)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(Array(ExperimentKind.allCases.enumerated()), id: \.element.id) { index, kind in
                                Button {
                                    haptics.select()
                                    path.append(LabDestination.practice(kind))
                                } label: {
                                    LabPracticeChip(kind: kind, reduceMotion: reduceMotion)
                                }
                                .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                                .modifier(StageAppearModifier(index: index + 8, reduceMotion: reduceMotion))
                            }
                        }
                        .padding(.horizontal, JSRSpace.md)
                    }

                    JSRScrollBottomSpacer()
                }
            }
            .scrollIndicators(.hidden)
            .background { JSRStageAtmosphere(tint: JSRColor.secondaryAccent) }
            .preferredColorScheme(.dark)
            .toolbarBackground(JSRColor.ink.opacity(0.94), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Labs")
                        .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                }
            }
            .navigationDestination(for: LabDestination.self) { destination in
                switch destination {
                case .practice(let kind):
                    ExperimentDetailView(kind: kind)
                case .drill(let id):
                    if let drill = LabCatalog.drill(id: id) {
                        LabDrillView(drill: drill) { practice in
                            path.append(LabDestination.practice(practice))
                        }
                    } else {
                        Text("Drill unavailable")
                            .foregroundStyle(JSRStage.labelSecondary)
                    }
                }
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: JSRSpace.xs) {
                Text("LABS")
                    .font(JSRType.motif)
                    .tracking(1.4)
                    .foregroundStyle(JSRColor.highlight)
                Text("Train the Eye")
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                Text("Drills first, practice second — learn to see folds, contrast, chaos, motion, and harmony before you craft.")
                    .font(JSRType.body)
                    .foregroundStyle(JSRStage.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 310, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LabsHeaderOrnament(reduceMotion: reduceMotion)
                .frame(width: 118)
                .opacity(0.9)
        }
    }

    private var progressRibbon: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text("DRILLS CLEARED")
                    .font(JSRType.motif)
                    .tracking(1.1)
                    .foregroundStyle(JSRColor.highlight)
                Text("\(clearedCount) of \(drillTotal)")
                    .font(JSRFont.serif(size: 22, relativeTo: .title3, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                                }
            Spacer()
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule().fill(JSRStage.chipFill)
                    Capsule()
                        .fill(JSRColor.highlight)
                        .frame(width: geo.size.width * CGFloat(clearedCount) / CGFloat(max(drillTotal, 1)))
                        .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: clearedCount)
                }
            }
            .frame(width: 88, height: 8)
        }
        .padding(JSRSpace.md)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Drills cleared: \(clearedCount) of \(drillTotal)")
    }

    private func sectionLabel(_ title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(JSRType.motif)
                .tracking(1.3)
                .foregroundStyle(JSRColor.highlight)
            Text(subtitle)
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

// MARK: - Home cards

struct LabTonightDrillCard: View {
    let drill: LabDrill
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 10) {
                PatternCanvasView(
                    parameters: drill.optionB,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : drill.kinetic,
                    reduceMotion: reduceMotion
                )
                .frame(width: 88, height: 88)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.55), lineWidth: 1.4)
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 6) {
                        Text("TONIGHT")
                            .font(JSRType.motif)
                            .tracking(1.0)
                            .foregroundStyle(JSRColor.ink)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(JSRColor.highlight)
                            .clipShape(Capsule())
                        Text(drill.actLabel)
                            .font(JSRType.motif)
                            .tracking(1.0)
                            .foregroundStyle(JSRColor.highlight)
                    }
                    Text(drill.title)
                        .font(JSRFont.serif(size: 22, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                    Text(drill.question)
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelSecondary)
                        .lineLimit(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            HStack(spacing: 4) {
                Text("Start eye drill")
                    .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
                Image(systemName: "eye")
                    .font(.system(size: 11, weight: .semibold))
            }
            .foregroundStyle(JSRColor.highlight)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.45), lineWidth: 1)
                }
                .shadow(color: JSRColor.highlight.opacity(0.18), radius: 16, y: 0)
        }
    }
}

struct LabDrillRow: View {
    let drill: LabDrill
    var cleared: Bool
    var reduceMotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            PatternCanvasView(
                parameters: drill.optionA,
                showChrome: false,
                kinetic: reduceMotion ? .none : .breathe,
                reduceMotion: reduceMotion
            )
            .frame(width: 64, height: 64)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(cleared ? JSRColor.highlight.opacity(0.55) : JSRStage.separator, lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(drill.actLabel)
                        .font(JSRType.motif)
                        .tracking(1.0)
                        .foregroundStyle(JSRColor.highlight)
                    if cleared {
                        Text("CLEARED")
                            .font(JSRType.motif)
                            .tracking(0.8)
                            .foregroundStyle(JSRColor.ink)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(JSRColor.highlight.opacity(0.95))
                            .clipShape(Capsule())
                    }
                }
                Text(drill.title)
                    .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                Text(drill.question)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
                    .lineLimit(2)
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JSRStage.labelTertiary)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

struct LabPracticeChip: View {
    let kind: ExperimentKind
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PatternCanvasView(
                parameters: kind.previewParameters,
                showChrome: false,
                kinetic: reduceMotion ? .none : kind.kinetic,
                reduceMotion: reduceMotion
            )
            .frame(width: 148, height: 110)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(JSRStage.chipStroke, lineWidth: 1)
            }

            Text(kind.actLabel)
                .font(JSRType.motif)
                .tracking(1.0)
                .foregroundStyle(JSRColor.highlight)
            Text(kind.title)
                .font(JSRFont.serif(size: 15, relativeTo: .subheadline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .lineLimit(2)
                .frame(width: 148, alignment: .leading)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

// MARK: - Header ornament

struct LabsHeaderOrnament: View {
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.72, y: size.height * 0.42)
                for i in 0..<8 {
                    let a = Double(i) / 8.0 * .pi * 2 + t * 0.22
                    let r: CGFloat = 14 + CGFloat(i % 4) * 6
                    let p = CGPoint(
                        x: center.x + CGFloat(cos(a)) * r,
                        y: center.y + CGFloat(sin(a)) * r * 0.72
                    )
                    var spark = Path()
                    let s: CGFloat = 2.8 + CGFloat(i % 2)
                    spark.move(to: CGPoint(x: p.x, y: p.y - s))
                    spark.addLine(to: CGPoint(x: p.x + s * 0.55, y: p.y))
                    spark.addLine(to: CGPoint(x: p.x, y: p.y + s))
                    spark.addLine(to: CGPoint(x: p.x - s * 0.55, y: p.y))
                    spark.closeSubpath()
                    let color = i.isMultiple(of: 3) ? JSRColor.secondaryAccent : JSRColor.highlight
                    context.fill(spark, with: .color(color.opacity(0.32 + Double(i % 3) * 0.06)))
                }
                // Soft footlight arc
                var arc = Path()
                arc.addEllipse(in: CGRect(x: center.x - 28, y: center.y + 10, width: 56, height: 18))
                context.fill(arc, with: .color(JSRColor.highlight.opacity(0.08)))
            }
        }
        .frame(height: 56)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Experiment model

enum ExperimentKind: String, CaseIterable, Identifiable, Hashable {
    case symmetryChamber, contrastTheatre, controlledChaos, motionIllusion, colorDuality

    var id: String { rawValue }

    var actIndex: Int {
        switch self {
        case .symmetryChamber: 1
        case .contrastTheatre: 2
        case .controlledChaos: 3
        case .motionIllusion: 4
        case .colorDuality: 5
        }
    }

    var actLabel: String {
        let roman = ["I", "II", "III", "IV", "V"]
        return "ACT \(roman[actIndex - 1])"
    }

    var title: String {
        switch self {
        case .symmetryChamber: "Symmetry Chamber"
        case .contrastTheatre: "Contrast Theatre"
        case .controlledChaos: "Controlled Chaos"
        case .motionIllusion: "Motion Illusion"
        case .colorDuality: "Color Duality"
        }
    }

    var blurb: String {
        switch self {
        case .symmetryChamber: "Explore radial and reflective symmetry."
        case .contrastTheatre: "Compare simultaneous contrast and figure-ground."
        case .controlledChaos: "Introduce irregularity into ordered form."
        case .motionIllusion: "Static geometry that implies movement."
        case .colorDuality: "Complementary, analogous, split, and mono palettes."
        }
    }

    var symbol: String {
        switch self {
        case .symmetryChamber: "circle.grid.cross"
        case .contrastTheatre: "circle.lefthalf.filled"
        case .controlledChaos: "wind"
        case .motionIllusion: "waveform"
        case .colorDuality: "paintpalette"
        }
    }

    var explanation: String {
        switch self {
        case .symmetryChamber:
            "Symmetry multiplies a single decision into a motif. Reflective folds feel theatrical; radial folds feel ceremonial."
        case .contrastTheatre:
            "A hue looks different against ink than against ivory. Figure and ground trade roles when values invert."
        case .controlledChaos:
            "Order becomes expressive when a measured amount of irregularity enters the system."
        case .motionIllusion:
            "Offset repetition and angled ribbons persuade the eye that stillness is moving."
        case .colorDuality:
            "Harmony systems are tools — not rules. Compare relationships before committing to a studio palette."
        }
    }

    var kinetic: KineticStyle {
        switch self {
        case .motionIllusion: .orbit
        case .controlledChaos: .shimmer
        case .symmetryChamber, .contrastTheatre, .colorDuality: .breathe
        }
    }

    var previewParameters: PatternParameters {
        switch self {
        case .symmetryChamber: MotifCatalog.all[0].parameters
        case .contrastTheatre: MotifCatalog.all[1].parameters
        case .controlledChaos: MotifCatalog.all[9].parameters
        case .motionIllusion: MotifCatalog.all[5].parameters
        case .colorDuality: MotifCatalog.all[3].parameters
        }
    }
}

// MARK: - Detail

struct ExperimentDetailView: View {
    let kind: ExperimentKind
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: ProjectStore
    @EnvironmentObject private var haptics: HapticsClient
    
    @State private var params = PatternParameters.default
    @State private var hue: Double = 0.08
    @State private var paletteKind: PaletteKind = .analogous
    @State private var toast: String?
    @State private var stagePulse = false
    @State private var controlsRevealed = false
    @State private var toastTask: Task<Void, Never>?

    private var settings: AppSettings { store.settings }

    private var kineticForKind: KineticStyle {
        reduceMotion ? .none : kind.kinetic
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JSRSpace.md) {
                detailHeader
                    .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))

                StudioStageChrome(pulse: stagePulse && !reduceMotion) {
                    PatternCanvasView(
                        parameters: liveParameters,
                        showChrome: false,
                        kinetic: kineticForKind,
                        reduceMotion: reduceMotion
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 320)
                    .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: liveParameters)
                }
                .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))

                LabControlPanel {
                    controls
                }
                .opacity(controlsRevealed || reduceMotion ? 1 : 0)
                .offset(y: controlsRevealed || reduceMotion ? 0 : 10)
                .modifier(StageAppearModifier(index: 2, reduceMotion: reduceMotion))

                LabFieldNotesView(kind: kind)
                    .modifier(StageAppearModifier(index: 3, reduceMotion: reduceMotion))

                HStack(spacing: JSRSpace.sm) {
                    LabActionButton(title: "Reset", systemImage: "arrow.counterclockwise", role: .secondary) {
                        withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                            reset()
                        }
                        pulseStage()
                        haptics.select()
                        showToast("Reset")
                    }
                    LabActionButton(title: "Save to Library", systemImage: "square.and.arrow.down", role: .primary) {
                        saveAsProject()
                    }
                }
                .modifier(StageAppearModifier(index: 4, reduceMotion: reduceMotion))

                JSRScrollBottomSpacer()
            }
            .padding(JSRSpace.md)
        }
        .scrollIndicators(.hidden)
        .background { JSRStageAtmosphere(tint: kind.atmosphereTint) }
        .preferredColorScheme(.dark)
        .toolbarBackground(JSRColor.ink.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text(kind.title)
                    .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                    .lineLimit(1)
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .medium))
                    .foregroundStyle(JSRColor.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(JSRColor.highlight)
                    .clipShape(Capsule())
                    .shadow(color: JSRColor.highlight.opacity(0.35), radius: 12, y: 4)
                    .padding(.bottom, JSRSpace.md)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .accessibilityLabel(toast)
            }
        }
        .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: toast)
        .onAppear {
            reset()
            if !reduceMotion {
                withAnimation(JSRMotion.fluid.delay(0.12)) {
                    controlsRevealed = true
                }
            } else {
                controlsRevealed = true
            }
        }
    }

    private var detailHeader: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xs) {
            Text("PRACTICE · \(kind.actLabel)")
                .font(JSRType.motif)
                .tracking(1.4)
                .foregroundStyle(JSRColor.highlight)
            Text(kind.title)
                .font(JSRType.title)
                .foregroundStyle(JSRStage.label)
            Text(kind.explanation)
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }

    private var liveParameters: PatternParameters {
        var p = params
        if kind == .colorDuality {
            let colors = PaletteService.colors(baseHue: hue, kind: paletteKind)
            p.foreground = colors.first ?? .gold
            p.background = colors.count > 1 ? colors[1].withOpacity(1) : .ink
            if paletteKind == .monochrome {
                p.background = .ink
            }
        }
        return p
    }

    @ViewBuilder
    private var controls: some View {
        switch kind {
        case .symmetryChamber:
            LabStageSlider(
                title: "Folds",
                value: Binding(
                    get: { Double(params.symmetryCount) },
                    set: { params.symmetryCount = Int($0); params.clamp(); pulseStage() }
                ),
                range: 1...16,
                step: 1,
                valueLabel: { "\(Int($0))" },
                onEditingChanged: { editing in
                    if !editing { haptics.select() }
                }
            )
            LabChipRow(
                title: "Geometry",
                items: GeometryKind.allCases.map { ($0, $0.title) },
                selection: $params.geometry,
                reduceMotion: reduceMotion
            ) {
                pulseStage()
                haptics.select()
            }

        case .contrastTheatre:
            LabStageSlider(
                title: "Opacity",
                value: $params.opacity,
                range: 0.2...1,
                onEditingChanged: { editing in
                    if editing { pulseStage() }
                    if !editing { haptics.select() }
                }
            )
            LabActionButton(title: "Invert figure / ground", systemImage: "circle.lefthalf.filled", role: .secondary) {
                withAnimation(JSRMotion.preferred(JSRMotion.morph, reduceMotion: reduceMotion)) {
                    let fg = params.foreground
                    params.foreground = params.background
                    params.background = fg
                }
                pulseStage()
                haptics.select()
                showToast("Inverted")
            }

        case .controlledChaos:
            LabStageSlider(
                title: "Asymmetry",
                value: $params.asymmetry,
                range: 0...1,
                onEditingChanged: { editing in
                    if editing { pulseStage() }
                    if !editing { haptics.select() }
                }
            )
            LabStageSlider(
                title: "Distortion",
                value: $params.distortion,
                range: 0...1,
                onEditingChanged: { editing in
                    if editing { pulseStage() }
                    if !editing { haptics.select() }
                }
            )

        case .motionIllusion:
            LabStageSlider(
                title: "Rotation",
                value: $params.rotation,
                range: 0...360,
                valueLabel: { "\(Int($0))°" },
                onEditingChanged: { editing in
                    if editing { pulseStage() }
                    if !editing { haptics.select() }
                }
            )
            LabStageSlider(
                title: "Spacing",
                value: $params.spacing,
                range: 0...0.5,
                onEditingChanged: { editing in
                    if editing { pulseStage() }
                    if !editing { haptics.select() }
                }
            )

        case .colorDuality:
            LabChipRow(
                title: "Harmony",
                items: PaletteKind.allCases.map { ($0, $0.title) },
                selection: $paletteKind,
                reduceMotion: reduceMotion
            ) {
                pulseStage()
                haptics.select()
            }
            LabStageSlider(
                title: "Base hue",
                value: $hue,
                range: 0...1,
                onEditingChanged: { editing in
                    if editing { pulseStage() }
                    if !editing { haptics.select() }
                }
            )
            HStack(spacing: 8) {
                ForEach(Array(PaletteService.colors(baseHue: hue, kind: paletteKind).enumerated()), id: \.offset) { _, c in
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .fill(c.color)
                        .frame(height: 40)
                        .overlay {
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(JSRStage.chipStroke, lineWidth: 1)
                        }
                }
            }
            .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: hue)
            .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: paletteKind)
        }
    }

    private func pulseStage() {
        guard !reduceMotion else { return }
        stagePulse = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            stagePulse = false
        }
    }

    private func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    private func reset() {
        params = .default
        params.canvasRatio = settings.defaultRatio
        switch kind {
        case .symmetryChamber:
            params = MotifCatalog.all.first(where: { $0.id == "crown" })?.parameters ?? .default
            params.layout = .radial
            params.geometry = .diamond
            params.symmetryCount = 10
        case .contrastTheatre:
            params.geometry = .mask
            params.layout = .mirror
            params.symmetryCount = 2
            params.repetition = 4
            params.scale = 0.55
            params.foreground = .gold
            params.secondary = .ivory
            params.background = .ink
        case .controlledChaos:
            params = MotifCatalog.all.first(where: { $0.id == "bloom" })?.parameters ?? .default
            params.asymmetry = 0.15
            params.distortion = 0.08
        case .motionIllusion:
            params = MotifCatalog.all.first(where: { $0.id == "spiral" })?.parameters ?? .default
            params.layout = .spiral
            params.geometry = .ribbon
        case .colorDuality:
            params.geometry = .starburst
            params.layout = .kaleidoscope
            params.symmetryCount = 8
            hue = 0.08
            paletteKind = .analogous
        }
        params.clamp()
    }

    private func saveAsProject() {
        var p = liveParameters
        p.clamp()
        let project = StudioProject(title: kind.title, parameters: p)
        project.thumbnailData = ExportService.thumbnail(parameters: p)
        store.save(project)
        store.settings.lastProjectID = project.id
        store.persistSettings()
        if store.persistenceError != nil {
            showToast(store.persistenceError ?? "Could not save")
            haptics.warning()
        } else {
            showToast("Saved to Library")
            haptics.success()
            pulseStage()
        }
    }
}

// MARK: - Lab chrome bits

private struct LabControlPanel<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.md) {
            Text("CONTROLS")
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(JSRColor.highlight)
            content
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

private struct LabStageSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double? = nil
    var valueLabel: ((Double) -> String)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xxs) {
            HStack {
                Text(title)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
                Spacer()
                Text(valueLabel?(value) ?? String(format: "%.2f", value))
                    .font(JSRType.caption.monospacedDigit())
                    .foregroundStyle(JSRStage.label)
            }
            Slider(
                value: $value,
                in: range,
                step: step ?? 0.01,
                onEditingChanged: { onEditingChanged?($0) }
            )
            .tint(JSRColor.highlight)
            .accessibilityLabel(title)
            .accessibilityValue(valueLabel?(value) ?? "\(value)")
        }
    }
}

private struct LabChipRow<T: Hashable & Identifiable>: View {
    let title: String
    let items: [(T, String)]
    @Binding var selection: T
    var reduceMotion: Bool
    var onSelect: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.0.id) { item, label in
                        let selected = selection == item
                        Button {
                            withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                                selection = item
                            }
                            onSelect()
                        } label: {
                            Text(label)
                                .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .medium))
                                .foregroundStyle(selected ? JSRColor.ink : JSRStage.label)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? JSRColor.highlight : JSRStage.chipFill)
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .strokeBorder(
                                            selected ? Color.clear : JSRStage.chipStroke,
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        }
    }
}

private struct LabActionButton: View {
    let title: String
    var systemImage: String? = nil
    var role: Role = .primary
    let action: () -> Void

    enum Role { case primary, secondary }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: 13, weight: .semibold))
                }
                Text(title)
                    .font(JSRFont.serif(size: 15, relativeTo: .callout, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 46)
            .foregroundStyle(role == .primary ? JSRColor.ink : JSRStage.label)
            .background(role == .primary ? JSRColor.highlight : JSRStage.chipFillStrong)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        role == .primary ? Color.clear : JSRStage.chipStroke,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(title)
    }
}

private extension ExperimentKind {
    var atmosphereTint: Color {
        switch self {
        case .symmetryChamber: JSRColor.highlight
        case .contrastTheatre: JSRColor.secondaryAccent
        case .controlledChaos: JSRColor.accent
        case .motionIllusion: JSRColor.highlight
        case .colorDuality: JSRColor.secondaryAccent
        }
    }
}

#Preview("Labs Home") {
    ExperimentsHomeView()
        .environmentObject(ProjectStore())
        .environmentObject(HapticsClient())
        }

#Preview("Lab Detail") {
    NavigationStack {
        ExperimentDetailView(kind: .symmetryChamber)
    }
    .environmentObject(ProjectStore())
    .environmentObject(HapticsClient())
    }
