import Combine
import Foundation
import SwiftUI

enum StudioConstraint: String, CaseIterable, Identifiable, Sendable {
    case free
    case quiet
    case tension

    var id: String { rawValue }

    var title: String {
        switch self {
        case .free: "Free"
        case .quiet: "Quiet"
        case .tension: "Tension"
        }
    }

    var blurb: String {
        switch self {
        case .free: "Full range — explore without clamps."
        case .quiet: "Keep asymmetry and distortion restrained."
        case .tension: "Push contrast while holding a readable structure."
        }
    }

    func applyVisibleShift(to params: inout PatternParameters) {
        switch self {
        case .free:
            break
        case .quiet:
            params.asymmetry = min(params.asymmetry, 0.08)
            params.distortion = min(params.distortion, 0.05)
        case .tension:
            params.asymmetry = max(params.asymmetry, 0.26)
            params.distortion = max(params.distortion, 0.12)
            params.asymmetry = min(params.asymmetry, 0.55)
            params.distortion = min(params.distortion, 0.4)
        }
    }

    func clamp(_ params: inout PatternParameters) {
        switch self {
        case .free:
            break
        case .quiet:
            params.asymmetry = min(params.asymmetry, 0.18)
            params.distortion = min(params.distortion, 0.12)
        case .tension:
            params.asymmetry = min(max(params.asymmetry, 0.12), 0.55)
            params.distortion = min(params.distortion, 0.4)
        }
    }
}

enum StudioCompareMode: String, CaseIterable, Identifiable, Sendable {
    case off
    case peek
    case split

    var id: String { rawValue }

    var title: String {
        switch self {
        case .off: "Live"
        case .peek: "Peek A"
        case .split: "A / B"
        }
    }
}

final class StudioViewModel: ObservableObject {
    @Published var parameters: PatternParameters
    @Published var projectID: UUID?
    @Published var title: String
    @Published var notes: String
    @Published var isFocusMode = false
    @Published var toast: String?
    @Published var kinetic: KineticStyle = .breathe
    @Published var activeMotifID: String?
    @Published var constraint: StudioConstraint = .free
    @Published var pinnedA: PatternParameters?
    @Published var compareMode: StudioCompareMode = .off
    @Published var showCue = true
    @Published var stagePulse = false
    @Published var canvasTick: UInt = 0
    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }
    var hasPinnedA: Bool { pinnedA != nil }

    private var undoStack: [PatternParameters] = []
    private var redoStack: [PatternParameters] = []
    private var toastTask: Task<Void, Never>?
    private var pulseTask: Task<Void, Never>?

    init(
        parameters: PatternParameters = MotifCatalog.all[0].parameters,
        projectID: UUID? = nil,
        title: String = MotifCatalog.all[0].title,
        notes: String = ""
    ) {
        self.parameters = parameters
        self.projectID = projectID
        self.title = title
        self.notes = notes
        self.activeMotifID = MotifCatalog.all[0].id
    }

    var displayParameters: PatternParameters {
        if compareMode == .peek, let pinnedA { return pinnedA }
        return parameters
    }

    func load(project: StudioProject) {
        projectID = project.id
        title = project.title
        notes = project.notes
        parameters = project.parameters
        undoStack.removeAll()
        redoStack.removeAll()
        activeMotifID = nil
        pinnedA = nil
        compareMode = .off
        bumpCanvas(pulse: true)
    }

    func apply(
        _ mutate: (inout PatternParameters) -> Void,
        recordUndo: Bool = true,
        pulse: Bool = true,
        toast: String? = nil,
        haptics: HapticsClient? = nil
    ) {
        if recordUndo {
            undoStack.append(parameters)
            if undoStack.count > 60 { undoStack.removeFirst() }
            redoStack.removeAll()
        }
        mutate(&parameters)
        constraint.clamp(&parameters)
        parameters.clamp()
        bumpCanvas(pulse: pulse)
        if let toast { showToast(toast) }
        haptics?.select()
    }

    func applyMotif(_ motif: MotifPreset, haptics: HapticsClient) {
        apply({ $0 = motif.parameters }, toast: motif.title, haptics: haptics)
        title = motif.title
        activeMotifID = motif.id
        haptics.select()
    }

    func setGeometry(_ kind: GeometryKind, haptics: HapticsClient) {
        guard parameters.geometry != kind else {
            haptics.select()
            showToast(kind.title)
            bumpCanvas(pulse: true)
            return
        }
        apply({ $0.geometry = kind }, toast: kind.title, haptics: haptics)
        activeMotifID = nil
    }

    func setLayout(_ layout: PatternLayout, haptics: HapticsClient) {
        guard parameters.layout != layout else {
            haptics.select()
            showToast(layout.title)
            bumpCanvas(pulse: true)
            return
        }
        apply({ $0.layout = layout }, toast: layout.title, haptics: haptics)
        activeMotifID = nil
    }

    func setRenderMode(_ mode: RenderMode, haptics: HapticsClient) {
        apply({ $0.renderMode = mode }, toast: mode.title, haptics: haptics)
    }

    func setCanvasRatio(_ ratio: CanvasRatio, haptics: HapticsClient) {
        apply({ $0.canvasRatio = ratio }, toast: ratio.title, haptics: haptics)
    }

    func setConstraint(_ value: StudioConstraint, haptics: HapticsClient) {
        constraint = value
        apply({ value.applyVisibleShift(to: &$0) }, toast: "\(value.title) constraint", haptics: haptics)
    }

    func toggleSeedLock(haptics: HapticsClient) {
        apply({ $0.seedLocked.toggle() }, toast: nil, haptics: haptics)
        showToast(parameters.seedLocked ? "Seed locked" : "Seed unlocked")
    }

    func reseed(haptics: HapticsClient) {
        guard !parameters.seedLocked else {
            haptics.limit()
            showToast("Seed is locked — unlock first")
            bumpCanvas(pulse: true)
            return
        }
        apply({ $0.seed = UInt64.random(in: 1...UInt64.max) }, toast: "New seed", haptics: nil)
        activeMotifID = nil
        haptics.warning()
    }

    func pinAsA(haptics: HapticsClient) {
        pinnedA = parameters
        bumpCanvas(pulse: true)
        haptics.success()
        showToast("Pinned as A")
    }

    func cycleCompareMode(haptics: HapticsClient) {
        guard pinnedA != nil else {
            haptics.limit()
            showToast("Pin A first")
            bumpCanvas(pulse: true)
            return
        }
        switch compareMode {
        case .off: compareMode = .peek
        case .peek: compareMode = .split
        case .split: compareMode = .off
        }
        bumpCanvas(pulse: true)
        haptics.select()
        showToast(compareMode == .off ? "Live edit" : compareMode.title)
    }

    func clearPinnedA(haptics: HapticsClient) {
        pinnedA = nil
        compareMode = .off
        bumpCanvas(pulse: true)
        haptics.select()
        showToast("Cleared A")
    }

    func restorePinnedA(haptics: HapticsClient) {
        guard let pinnedA else { return }
        apply({ $0 = pinnedA }, toast: "Restored A → live", haptics: haptics)
    }

    func randomize(haptics: HapticsClient) {
        apply({ params in
            var rng = SeededGenerator(seed: params.seedLocked ? params.seed : UInt64.random(in: 1...UInt64.max))
            if !params.seedLocked { params.seed = rng.next() }
            params.layout = PatternLayout.allCases[Int(rng.nextDouble() * Double(PatternLayout.allCases.count)) % PatternLayout.allCases.count]
            params.geometry = GeometryKind.allCases[Int(rng.nextDouble() * Double(GeometryKind.allCases.count)) % GeometryKind.allCases.count]
            params.symmetryCount = 6 + Int(rng.nextDouble() * 6)
            params.rotation = Double(Int(rng.nextDouble() * 12)) * 5
            params.scale = 0.45 + rng.nextDouble() * 0.2
            params.repetition = 2 + Int(rng.nextDouble() * 3)
            params.spacing = 0.12 + rng.nextDouble() * 0.12
            params.asymmetry = 0
            params.distortion = 0
            params.layerDepth = 1 + Int(rng.nextDouble() * 2)
            let swatches = [CodableColor.gold, .burgundy, .teal, .ivory]
            params.foreground = swatches[Int(rng.nextDouble() * 4) % 4]
            params.secondary = swatches[Int(rng.nextDouble() * 4) % 4]
        }, toast: "New variation", haptics: nil)
        activeMotifID = nil
        haptics.warning()
    }

    func morphTowardChaos(haptics: HapticsClient) {
        let before = parameters.asymmetry + parameters.distortion
        apply({
            $0.asymmetry = min(0.5, $0.asymmetry + 0.14)
            $0.distortion = min(0.4, $0.distortion + 0.1)
        }, toast: nil, haptics: nil)
        let after = parameters.asymmetry + parameters.distortion
        haptics.limit()
        showToast(after > before + 0.001 ? "More chaos" : "Chaos at limit")
    }

    func morphTowardOrder(haptics: HapticsClient) {
        let before = parameters.asymmetry + parameters.distortion
        apply({
            $0.asymmetry = max(0, $0.asymmetry - 0.14)
            $0.distortion = max(0, $0.distortion - 0.1)
        }, toast: nil, haptics: nil)
        let after = parameters.asymmetry + parameters.distortion
        haptics.select()
        showToast(after < before - 0.001 ? "More order" : "Already ordered")
    }

    func toggleGlow(haptics: HapticsClient) {
        apply({ $0.showGlow.toggle() }, toast: nil, haptics: haptics)
        showToast(parameters.showGlow ? "Glow on" : "Glow off")
    }

    func cycleColor(slot: ColorSlot, haptics: HapticsClient) {
        apply({ params in
            switch slot {
            case .foreground: params.foreground = Self.nextSwatch(params.foreground)
            case .secondary: params.secondary = Self.nextSwatch(params.secondary)
            case .background: params.background = Self.nextBackground(params.background)
            }
        }, toast: slot.title, haptics: haptics)
    }

    enum ColorSlot {
        case foreground, secondary, background
        var title: String {
            switch self {
            case .foreground: "Accent A"
            case .secondary: "Accent B"
            case .background: "Background"
            }
        }
    }

    func undo(haptics: HapticsClient) {
        guard let previous = undoStack.popLast() else {
            haptics.limit()
            showToast("Nothing to undo")
            return
        }
        redoStack.append(parameters)
        parameters = previous
        activeMotifID = nil
        bumpCanvas(pulse: true)
        haptics.select()
        showToast("Undo")
    }

    func redo(haptics: HapticsClient) {
        guard let next = redoStack.popLast() else {
            haptics.limit()
            showToast("Nothing to redo")
            return
        }
        undoStack.append(parameters)
        parameters = next
        activeMotifID = nil
        bumpCanvas(pulse: true)
        haptics.select()
        showToast("Redo")
    }

    func applyDailyPrompt(_ prompt: DailyPrompt, haptics: HapticsClient) {
        apply({
            $0.geometry = prompt.suggestedGeometry
            $0.symmetryCount = max(1, prompt.suggestedSymmetry)
            $0.asymmetry = min(0.45, prompt.suggestedAsymmetry)
            $0.distortion = 0
        }, toast: prompt.title, haptics: haptics)
        activeMotifID = nil
    }

    func cycleKinetic(haptics: HapticsClient) {
        let all = KineticStyle.allCases
        if let idx = all.firstIndex(of: kinetic) {
            kinetic = all[(idx + 1) % all.count]
        }
        bumpCanvas(pulse: true)
        haptics.select()
        showToast("Motion · \(kinetic.title)")
    }

    func setInt(
        _ keyPath: WritableKeyPath<PatternParameters, Int>,
        to new: Int,
        limits: ClosedRange<Int>,
        label: String,
        haptics: HapticsClient
    ) {
        let clamped = PatternMath.clamp(new, limits.lowerBound, limits.upperBound)
        guard parameters[keyPath: keyPath] != clamped else {
            haptics.limit()
            showToast(label)
            return
        }
        apply({ $0[keyPath: keyPath] = clamped }, toast: "\(label) \(clamped)", haptics: haptics)
        activeMotifID = nil
    }

    /// Call once when a continuous gesture/slider starts.
    func beginContinuousEdit() {
        undoStack.append(parameters)
        if undoStack.count > 60 { undoStack.removeFirst() }
        redoStack.removeAll()
    }

    /// Call when a continuous gesture/slider ends.
    func endContinuousEdit(label: String, haptics: HapticsClient) {
        constraint.clamp(&parameters)
        parameters.clamp()
        activeMotifID = nil
        bumpCanvas(pulse: true)
        haptics.select()
        showToast(label)
    }

    func bumpCanvas(pulse: Bool) {
        canvasTick &+= 1
        if pulse { pulseStage() }
    }

    func pulseStage() {
        stagePulse = false
        stagePulse = true
        pulseTask?.cancel()
        pulseTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            if !Task.isCancelled { stagePulse = false }
        }
    }

    func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_250_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    private static func nextSwatch(_ c: CodableColor) -> CodableColor {
        let s: [CodableColor] = [.gold, .burgundy, .teal, .ivory]
        if let i = s.firstIndex(of: c) { return s[(i + 1) % s.count] }
        return .gold
    }

    private static func nextBackground(_ c: CodableColor) -> CodableColor {
        let s: [CodableColor] = [
            .ink,
            CodableColor(red: 0.09, green: 0.1, blue: 0.12),
            CodableColor(red: 0.14, green: 0.08, blue: 0.1),
            .ivory
        ]
        if let i = s.firstIndex(where: { abs($0.red - c.red) < 0.03 && abs($0.green - c.green) < 0.03 }) {
            return s[(i + 1) % s.count]
        }
        return .ink
    }
}
