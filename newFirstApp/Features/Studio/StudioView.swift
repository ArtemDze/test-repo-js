import SwiftUI

struct StudioView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var haptics: HapticsClient
    @EnvironmentObject private var store: ProjectStore

    @StateObject private var model: StudioViewModel
    @State private var showExport = false
    @State private var exportRatio: CanvasRatio = .square
    @State private var exportImage: UIImage?
    @State private var exportError: String?
    @State private var isExporting = false
    @State private var showInspector = true
    @State private var showAtelier = false
    @State private var showNotes = false
    @State private var showPremiere = false
    @State private var showRename = false
    @State private var renameDraft = ""
    @State private var dragRotation: Double = 0
    @State private var isOrbiting = false
    @State private var sliderEditing = false
    @State private var dailyPrompt = DailyPromptService.prompt()
    @State private var notesAutosaveTask: Task<Void, Never>?
    @Binding private var motifToApply: MotifPreset?
    @Binding private var stageMotifID: String?

    private var settings: AppSettings { store.settings }
    private var projects: [StudioProject] { store.projects }

    init(
        project: StudioProject? = nil,
        motifToApply: Binding<MotifPreset?> = .constant(nil),
        stageMotifID: Binding<String?> = .constant(nil)
    ) {
        _motifToApply = motifToApply
        _stageMotifID = stageMotifID
        if let project {
            _model = StateObject(wrappedValue: StudioViewModel(
                parameters: project.parameters,
                projectID: project.id,
                title: project.title,
                notes: project.notes
            ))
        } else {
            _model = StateObject(wrappedValue: StudioViewModel())
        }
    }

    var body: some View {
        Group {
            if model.isFocusMode {
                stageCanvas
                    .padding(JSRSpace.md)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                // One continuous scroll — nav toolbar stays pinned above.
                ScrollView {
                    VStack(spacing: JSRSpace.md) {
                        if model.showCue {
                            StudioCueRibbon(
                                prompt: dailyPrompt,
                                onApply: {
                                    withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                        model.applyDailyPrompt(dailyPrompt, haptics: haptics)
                                        model.showCue = false
                                    }
                                    markCueDoneForToday()
                                },
                                onDismiss: {
                                    withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                                        model.showCue = false
                                    }
                                    markCueDoneForToday()
                                }
                            )
                            .padding(.horizontal, JSRSpace.md)
                            .transition(.opacity.combined(with: .move(edge: .top)))
                        }

                        MotifAtelierStrip(selectedID: model.activeMotifID) { applyMotif($0) }

                        stageCanvas
                            .padding(.horizontal, JSRSpace.md)
                            .frame(maxWidth: .infinity)
                            // Keep stage readable on iPad without crowding CONSTRAINT / tools under the tab bar.
                            .frame(
                                minHeight: horizontalSizeClass == .regular ? 360 : 340,
                                maxHeight: horizontalSizeClass == .regular ? 480 : 400
                            )

                        StudioToolStrip(
                            seedLocked: model.parameters.seedLocked,
                            hasPinnedA: model.hasPinnedA,
                            compareMode: model.compareMode,
                            onSeedLock: { model.toggleSeedLock(haptics: haptics) },
                            onReseed: {
                                withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                    model.reseed(haptics: haptics)
                                }
                            },
                            onPinA: { model.pinAsA(haptics: haptics) },
                            onCompare: { model.cycleCompareMode(haptics: haptics) },
                            onNotes: { showNotes = true },
                            onPremiere: {
                                haptics.select()
                                showPremiere = true
                            }
                        )

                        layoutBar
                            .padding(.horizontal, JSRSpace.md)

                        if showInspector {
                            inspectorContent
                                .padding(.horizontal, JSRSpace.md)
                                .transition(.opacity)
                        }

                        JSRScrollBottomSpacer(height: JSRTabBarMetrics.studioScrollBottom)
                    }
                    .padding(.top, JSRSpace.xs)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background {
            JSRStageAtmosphere(tint: JSRColor.highlight)
        }
        .preferredColorScheme(.dark)
        .tint(JSRColor.highlight)
        .toolbarBackground(JSRColor.ink.opacity(0.92), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .overlay(alignment: .top) {
            if let toast = model.toast {
                StudioToast(text: toast)
                    .padding(.top, 6)
                    .transition(.move(edge: .top).combined(with: .opacity))
                    .zIndex(20)
            }
        }
        .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: model.isFocusMode)
        .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: model.toast)
        .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: model.compareMode)
        .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: model.showCue)
        .animation(JSRMotion.preferred(JSRMotion.morph, reduceMotion: reduceMotion), value: model.canvasTick)
        .sheet(isPresented: $showExport) { exportSheet }
        .sheet(isPresented: $showAtelier) {
            NavigationStack {
                MotifAtelierGrid(
                    onSelect: { motif in
                        applyMotif(motif)
                        showAtelier = false
                    },
                    selectedID: model.activeMotifID
                )
            }
            .preferredColorScheme(.dark)
            .presentationDetents([.large])
            .presentationDragIndicator(.visible)
        }
        .sheet(isPresented: $showNotes) { notesSheet }
        .fullScreenCover(isPresented: $showPremiere) {
            StudioPremiereView(
                title: model.title,
                parameters: model.displayParameters,
                kinetic: reduceMotion ? .none : (model.kinetic == .none ? .breathe : model.kinetic),
                onClose: { showPremiere = false }
            )
        }
        .alert("Rename composition", isPresented: $showRename) {
            TextField("Title", text: $renameDraft)
            Button("Cancel", role: .cancel) {}
            Button("Save") {
                let trimmed = renameDraft.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { model.title = trimmed }
            }
        }
        .onAppear {
            haptics.isEnabled = settings.hapticsEnabled
            if reduceMotion { model.kinetic = .none }
            exportRatio = settings.defaultRatio
            refreshCueVisibility()
            consumePendingMotif()
            publishStageMotifID()
        }
        .onChange(of: motifToApply) { _ in
            consumePendingMotif()
        }
        .onChange(of: model.activeMotifID) { _ in
            publishStageMotifID()
        }
        .onChange(of: model.notes) { _ in
            scheduleNotesAutosave()
        }
        .onDisappear {
            notesAutosaveTask?.cancel()
            persistNotesIfNeeded()
        }
    }

    private func publishStageMotifID() {
        // Keep last known stage motif when parameters diverge (activeMotifID clears).
        if let id = model.activeMotifID {
            stageMotifID = id
        }
    }

    private func refreshCueVisibility() {
        let key = DailyPromptService.dateKey()
        model.showCue = !settings.completedPromptDates.contains(key)
    }

    private func markCueDoneForToday() {
        let key = DailyPromptService.dateKey()
        guard !settings.completedPromptDates.contains(key) else { return }
        settings.completedPromptDates.append(key)
        // Keep the list bounded.
        if settings.completedPromptDates.count > 60 {
            settings.completedPromptDates.removeFirst(settings.completedPromptDates.count - 60)
        }
        store.persistSettings()
    }

    private func scheduleNotesAutosave() {
        notesAutosaveTask?.cancel()
        notesAutosaveTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            guard !Task.isCancelled else { return }
            persistNotesIfNeeded()
        }
    }

    private func persistNotesIfNeeded() {
        guard let id = model.projectID,
              let existing = projects.first(where: { $0.id == id }),
              existing.notes != model.notes
        else { return }
        existing.notes = model.notes
        store.save(existing)
    }

    private func consumePendingMotif() {
        guard let motif = motifToApply else { return }
        applyMotif(motif)
        motifToApply = nil
    }

    // MARK: Stage

    @ViewBuilder
    private var stageCanvas: some View {
        if model.compareMode == .split, let pinned = model.pinnedA {
            HStack(spacing: 10) {
                comparePane(title: "A", parameters: pinned, kinetic: .none)
                comparePane(title: "B", parameters: liveDisplayParameters, kinetic: reduceMotion ? .none : model.kinetic)
            }
            .transition(.opacity)
        } else {
            StudioStageChrome(
                pulse: model.stagePulse && !reduceMotion,
                compareLabel: model.compareMode == .peek ? "A · pinned" : nil
            ) {
                PatternCanvasView(
                    parameters: liveDisplayParameters,
                    showChrome: false,
                    kinetic: model.compareMode == .peek || reduceMotion ? .none : model.kinetic,
                    reduceMotion: reduceMotion
                )
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .drawingGroup()
                .highPriorityGesture(orbitGesture)
            }
            .scaleEffect(model.stagePulse && !reduceMotion ? 1.018 : 1)
            .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: model.stagePulse)
        }
    }

    private func comparePane(title: String, parameters: PatternParameters, kinetic: KineticStyle) -> some View {
        StudioStageChrome(pulse: false, compareLabel: title) {
            PatternCanvasView(
                parameters: parameters,
                showChrome: false,
                kinetic: kinetic,
                reduceMotion: reduceMotion
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var liveDisplayParameters: PatternParameters {
        var p = model.displayParameters
        if model.compareMode != .peek {
            p.rotation += dragRotation
        }
        return p
    }

    private var orbitGesture: some Gesture {
        DragGesture(minimumDistance: 14)
            .onChanged { value in
                guard model.compareMode != .peek else { return }
                if !isOrbiting {
                    isOrbiting = abs(value.translation.width) > abs(value.translation.height) + 8
                }
                guard isOrbiting else { return }
                dragRotation = value.translation.width * 0.22
            }
            .onEnded { value in
                defer {
                    isOrbiting = false
                    dragRotation = 0
                }
                guard model.compareMode != .peek, isOrbiting else { return }
                let delta = value.translation.width * 0.22
                model.apply({ $0.rotation += delta }, toast: "Rotated", haptics: haptics)
            }
    }

    private var layoutBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: JSRSpace.xs) {
                ForEach(PatternLayout.allCases) { layout in
                    StudioChip(title: layout.title, selected: model.parameters.layout == layout) {
                        withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                            model.setLayout(layout, haptics: haptics)
                        }
                    }
                }
            }
        }
    }

    // MARK: Inspector (part of the main scroll — not a nested scroll cage)

    private var inspectorContent: some View {
        VStack(spacing: JSRSpace.sm) {
            constraintRow
            geometryRow

            StudioInspectorSection(title: "Structure") {
                VStack(spacing: JSRSpace.sm) {
                    StudioStepperRow(title: "Symmetry", value: model.parameters.symmetryCount, range: 1...16) {
                        model.setInt(\.symmetryCount, to: $0, limits: 1...16, label: "Symmetry", haptics: haptics)
                    }
                    StudioStepperRow(title: "Repetition", value: model.parameters.repetition, range: 1...10) {
                        model.setInt(\.repetition, to: $0, limits: 1...10, label: "Repetition", haptics: haptics)
                    }
                    StudioStepperRow(title: "Layers", value: model.parameters.layerDepth, range: 1...5) {
                        model.setInt(\.layerDepth, to: $0, limits: 1...5, label: "Layers", haptics: haptics)
                    }
                    if model.parameters.geometry == .polygon {
                        StudioStepperRow(title: "Sides", value: model.parameters.polygonSides, range: 3...12) {
                            model.setInt(\.polygonSides, to: $0, limits: 3...12, label: "Sides", haptics: haptics)
                        }
                    }
                    liveSlider("Rotation", keyPath: \.rotation, range: 0...360) { "\(Int($0))°" }
                    liveSlider("Scale", keyPath: \.scale, range: 0.25...0.9) { "\(Int($0 * 100))%" }
                    liveSlider("Spacing", keyPath: \.spacing, range: 0.05...0.4)
                }
            }

            StudioInspectorSection(title: "Look") {
                VStack(alignment: .leading, spacing: JSRSpace.sm) {
                    HStack {
                        ForEach(RenderMode.allCases) { mode in
                            StudioChip(title: mode.title, selected: model.parameters.renderMode == mode) {
                                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                                    model.setRenderMode(mode, haptics: haptics)
                                }
                            }
                        }
                        Spacer()
                    }
                    HStack {
                        ForEach(CanvasRatio.allCases) { ratio in
                            StudioChip(title: ratio.title, selected: model.parameters.canvasRatio == ratio) {
                                withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                    model.setCanvasRatio(ratio, haptics: haptics)
                                }
                            }
                        }
                        Spacer()
                    }
                    liveSlider("Stroke", keyPath: \.strokeWidth, range: 1...8) { String(format: "%.1f", $0) }
                    liveSlider("Opacity", keyPath: \.opacity, range: 0.4...1) { "\(Int($0 * 100))%" }
                    Toggle(isOn: Binding(
                        get: { model.parameters.showGlow },
                        set: { newValue in
                            guard model.parameters.showGlow != newValue else { return }
                            model.toggleGlow(haptics: haptics)
                        }
                    )) {
                        Text("Stage glow")
                            .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
                            .foregroundStyle(JSRStage.labelSecondary)
                    }
                    .tint(JSRColor.highlight)
                    colorRow
                }
            }

            StudioInspectorSection(title: "Expression") {
                VStack(spacing: JSRSpace.sm) {
                    liveSlider("Asymmetry", keyPath: \.asymmetry, range: 0...0.55)
                    liveSlider("Distortion", keyPath: \.distortion, range: 0...0.4)
                    HStack(spacing: 8) {
                        StudioGhostButton(title: "Order") {
                            withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                model.morphTowardOrder(haptics: haptics)
                            }
                        }
                        StudioGhostButton(title: "Chaos") {
                            withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                model.morphTowardChaos(haptics: haptics)
                            }
                        }
                    }
                }
            }

            ProgrammeNotePanel(parameters: model.parameters, title: model.title)
                .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: model.canvasTick)

            StudioInspectorSection(title: "System") {
                VStack(spacing: JSRSpace.sm) {
                    Button {
                        haptics.select()
                        showPremiere = true
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "theatermasks.fill")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Open Premiere")
                                .font(JSRFont.serif(size: 15, relativeTo: .callout, weight: .semibold))
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .foregroundStyle(JSRColor.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .background(JSRColor.highlight)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                    .accessibilityLabel("Open Premiere")

                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Seed")
                                .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
                                .foregroundStyle(JSRStage.labelSecondary)
                            Text("\(model.parameters.seed)")
                                .font(JSRType.caption.monospacedDigit())
                                .foregroundStyle(JSRStage.label)
                                                        }
                        Spacer()
                        Image(systemName: model.parameters.seedLocked ? "lock.fill" : "lock.open")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(model.parameters.seedLocked ? JSRColor.highlight : JSRStage.labelTertiary)
                    }
                    HStack(spacing: 8) {
                        StudioGhostButton(
                            title: model.parameters.seedLocked ? "Unlock" : "Lock",
                            systemImage: model.parameters.seedLocked ? "lock.open" : "lock.fill"
                        ) {
                            model.toggleSeedLock(haptics: haptics)
                        }
                        StudioGhostButton(title: "Reseed", systemImage: "dice") {
                            withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                model.reseed(haptics: haptics)
                            }
                        }
                    }
                    if model.hasPinnedA {
                        HStack(spacing: 8) {
                            StudioGhostButton(title: "Restore A") {
                                withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                                    model.restorePinnedA(haptics: haptics)
                                }
                            }
                            StudioGhostButton(title: "Clear A") {
                                model.clearPinnedA(haptics: haptics)
                            }
                        }
                    }
                }
            }
        }
    }

    private var constraintRow: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("CONSTRAINT")
                .font(JSRType.motif)
                .tracking(1.1)
                .foregroundStyle(JSRColor.highlight)
            HStack(spacing: 8) {
                ForEach(StudioConstraint.allCases) { item in
                    StudioChip(title: item.title, selected: model.constraint == item) {
                        withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                            model.setConstraint(item, haptics: haptics)
                        }
                    }
                }
                Spacer()
            }
            Text(model.constraint.blurb)
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelTertiary)
        }
    }

    private var geometryRow: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(GeometryKind.allCases) { kind in
                    let selected = model.parameters.geometry == kind
                    Button {
                        withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                            model.setGeometry(kind, haptics: haptics)
                        }
                    } label: {
                        VStack(spacing: 4) {
                            Image(systemName: kind.symbolName)
                                .font(.body.weight(.medium))
                                .frame(width: 42, height: 42)
                                .foregroundStyle(selected ? JSRStage.label : JSRStage.labelSecondary)
                                .background(selected ? JSRStage.accentFill : JSRStage.chipFill)
                                .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
                                .overlay {
                                    RoundedRectangle(cornerRadius: 11, style: .continuous)
                                        .strokeBorder(
                                            selected ? JSRColor.highlight.opacity(0.55) : JSRStage.chipStroke,
                                            lineWidth: 1
                                        )
                                }
                            Text(kind.title)
                                .font(JSRFont.serif(size: 10, relativeTo: .caption2, weight: .medium))
                                .foregroundStyle(selected ? JSRStage.label : JSRStage.labelTertiary)
                        }
                    }
                    .buttonStyle(SoftPressStyle())
                    .accessibilityLabel(kind.title)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
        }
    }

    private var colorRow: some View {
        HStack(spacing: 16) {
            colorDot("A", model.parameters.foreground.color) {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    model.cycleColor(slot: .foreground, haptics: haptics)
                }
            }
            colorDot("B", model.parameters.secondary.color) {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    model.cycleColor(slot: .secondary, haptics: haptics)
                }
            }
            colorDot("BG", model.parameters.background.color) {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    model.cycleColor(slot: .background, haptics: haptics)
                }
            }
            Spacer()
        }
    }

    // MARK: Toolbar

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .principal) {
            Button {
                renameDraft = model.title
                showRename = true
            } label: {
                Text(model.isFocusMode ? "" : model.title)
                    .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                    .lineLimit(1)
                    .foregroundStyle(JSRStage.label)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Rename composition")
        }
        ToolbarItemGroup(placement: .topBarLeading) {
            Button {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    model.undo(haptics: haptics)
                }
            } label: {
                Image(systemName: "arrow.uturn.backward")
                    .foregroundStyle(model.canUndo ? JSRStage.label : JSRStage.labelTertiary)
            }
            Button {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    model.redo(haptics: haptics)
                }
            } label: {
                Image(systemName: "arrow.uturn.forward")
                    .foregroundStyle(model.canRedo ? JSRStage.label : JSRStage.labelTertiary)
            }
        }
        ToolbarItemGroup(placement: .topBarTrailing) {
            Button {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    model.isFocusMode.toggle()
                }
                haptics.select()
                model.showToast(model.isFocusMode ? "Focus mode" : "Controls restored")
            } label: {
                Image(systemName: model.isFocusMode ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    .foregroundStyle(model.isFocusMode ? JSRColor.highlight : JSRStage.label)
            }
            .accessibilityLabel(model.isFocusMode ? "Exit focus" : "Focus mode")

            Button {
                model.cycleKinetic(haptics: haptics)
            } label: {
                Image(systemName: model.kinetic == .none ? "pause.circle" : "metronome")
                    .foregroundStyle(model.kinetic == .none ? JSRStage.labelSecondary : JSRColor.highlight)
            }
            .accessibilityLabel("Kinetic \(model.kinetic.title)")

            Menu {
                Button("Premiere", systemImage: "theatermasks") {
                    haptics.select()
                    showPremiere = true
                }
                Button("All Motifs", systemImage: "square.grid.2x2") {
                    showAtelier = true
                    haptics.select()
                }
                Button("New Variation", systemImage: "dice") {
                    withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                        model.randomize(haptics: haptics)
                    }
                }
                Button("Today’s Cue", systemImage: "sun.max") {
                    withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                        model.showCue = true
                    }
                    haptics.select()
                    model.showToast(settings.completedPromptDates.contains(DailyPromptService.dateKey())
                        ? "Cue revisited"
                        : "Cue shown")
                }
                Divider()
                Button("Save", systemImage: "square.and.arrow.down") { save(duplicate: false) }
                Button("Save Copy", systemImage: "plus.square.on.square") { save(duplicate: true) }
                Button("Export…", systemImage: "square.and.arrow.up") {
                    haptics.select()
                    prepareExport()
                }
                Button(showInspector ? "Hide Controls" : "Show Controls") {
                    withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                        showInspector.toggle()
                    }
                    haptics.select()
                    model.showToast(showInspector ? "Controls shown" : "Controls hidden")
                }
            } label: {
                Image(systemName: "ellipsis.circle")
                    .foregroundStyle(JSRStage.label)
            }
        }
    }

    // MARK: Sheets

    private var notesSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: JSRSpace.md) {
                Text("Composition notes")
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                Text("Capture intent, constraints, or export notes. Autosaves with the composition.")
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
                TextEditor(text: $model.notes)
                    .scrollContentBackground(.hidden)
                    .font(JSRType.body)
                    .foregroundStyle(JSRStage.label)
                    .padding(10)
                    .frame(minHeight: 180)
                    .background(JSRStage.panelElevated)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .strokeBorder(JSRStage.separator, lineWidth: 1)
                    }
                Text(model.projectID == nil
                     ? "Save the composition once to keep notes in Library."
                     : "Notes save automatically.")
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelTertiary)
                Spacer()
            }
            .padding(JSRSpace.lg)
            .background { JSRStageAtmosphere(tint: JSRColor.highlight) }
            .preferredColorScheme(.dark)
            .toolbarBackground(JSRColor.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        persistNotesIfNeeded()
                        showNotes = false
                    }
                    .font(JSRFont.serif(size: 16, relativeTo: .callout, weight: .semibold))
                    .foregroundStyle(JSRColor.highlight)
                }
            }
        }
        .presentationDetents([.medium, .large])
    }

    private var exportSheet: some View {
        NavigationStack {
            VStack(spacing: JSRSpace.md) {
                Text("Export stage")
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal)

                Picker("Aspect", selection: $exportRatio) {
                    ForEach(CanvasRatio.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if isExporting {
                    ProgressView("Preparing…")
                        .tint(JSRColor.highlight)
                        .foregroundStyle(JSRStage.labelSecondary)
                        .padding()
                } else if let exportError {
                    Text(exportError).foregroundStyle(JSRColor.danger).padding()
                } else if let exportImage, let data = exportImage.pngData() {
                    Image(uiImage: exportImage)
                        .resizable().scaledToFit()
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .padding(.horizontal)
                        .shadow(color: .black.opacity(0.35), radius: 16, y: 8)
                    ShareLink(
                        item: TransferableImage(data: data),
                        preview: SharePreview(model.title, image: Image(uiImage: exportImage))
                    ) {
                        Label("Share composition", systemImage: "square.and.arrow.up")
                            .font(JSRFont.serif(size: 16, relativeTo: .callout, weight: .semibold))
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(JSRColor.highlight)
                            .foregroundStyle(JSRColor.ink)
                            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .padding(.horizontal)
                }
                Spacer()
            }
            .padding(.top, JSRSpace.md)
            .background { JSRStageAtmosphere(tint: JSRColor.highlight) }
            .preferredColorScheme(.dark)
            .toolbarBackground(JSRColor.ink, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { showExport = false }
                        .font(JSRFont.serif(size: 16, relativeTo: .callout, weight: .semibold))
                        .foregroundStyle(JSRColor.highlight)
                }
            }
            .onChange(of: exportRatio) { _ in prepareExport() }
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: Actions

    private func applyMotif(_ motif: MotifPreset) {
        withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
            model.applyMotif(motif, haptics: haptics)
        }
    }

    /// Live slider: one undo point for the whole drag; toast + pulse on release.
    private func liveSlider(
        _ title: String,
        keyPath: WritableKeyPath<PatternParameters, Double>,
        range: ClosedRange<Double>,
        valueLabel: ((Double) -> String)? = nil
    ) -> some View {
        StudioSlider(
            title: title,
            value: Binding(
                get: { model.parameters[keyPath: keyPath] },
                set: { newValue in
                    if !sliderEditing {
                        sliderEditing = true
                        model.beginContinuousEdit()
                    }
                    model.parameters[keyPath: keyPath] = newValue
                    model.parameters.clamp()
                }
            ),
            range: range,
            valueLabel: valueLabel,
            onEditingChanged: { editing in
                if !editing {
                    sliderEditing = false
                    model.endContinuousEdit(label: title, haptics: haptics)
                }
            }
        )
    }

    private func colorDot(_ title: String, _ color: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Circle().fill(color).frame(width: 28, height: 28)
                    .overlay(Circle().strokeBorder(JSRColor.highlight.opacity(0.35), lineWidth: 1))
                Text(title)
                    .font(JSRFont.serif(size: 10, relativeTo: .caption2, weight: .medium))
                    .foregroundStyle(JSRStage.labelTertiary)
            }
        }
        .buttonStyle(SoftPressStyle())
    }

    private func save(duplicate: Bool) {
        let project: StudioProject
        if let id = model.projectID, !duplicate, let existing = projects.first(where: { $0.id == id }) {
            existing.title = model.title
            existing.parameters = model.parameters
            existing.notes = model.notes
            existing.thumbnailData = ExportService.thumbnail(parameters: model.parameters)
            project = existing
        } else {
            project = StudioProject(title: model.title, parameters: model.parameters, notes: model.notes)
            project.thumbnailData = ExportService.thumbnail(parameters: model.parameters)
            model.projectID = project.id
        }
        store.save(project)
        settings.lastProjectID = project.id
        store.persistSettings()
        withAnimation(JSRMotion.preferred(JSRMotion.echo, reduceMotion: reduceMotion)) {
            model.pulseStage()
        }
        model.showToast(store.persistenceError ?? "Saved")
        if store.persistenceError == nil { haptics.success() } else { haptics.warning() }
    }

    private func prepareExport() {
        isExporting = true
        exportError = nil
        exportImage = nil
        showExport = true
        let params = model.parameters
        let quality = settings.exportQuality
        let ratio = exportRatio
        DispatchQueue.main.async {
            let image = ExportService.render(parameters: params, quality: quality, ratio: ratio)
            exportImage = image
            isExporting = false
            if let image {
                ExportService.archiveRendered(image)
            } else {
                exportError = "Export failed. Try again."
            }
        }
    }
}

#Preview {
    NavigationStack {
        StudioView()
    }
    .environmentObject(HapticsClient())
    .environmentObject(ProjectStore())
}
