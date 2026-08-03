import Foundation

/// Theatrical programme note derived from the live composition — unique craft copy, not generic lorem.
struct ProgrammeNote: Hashable, Sendable {
    var actLabel: String
    var headline: String
    var body: String
}

enum ProgrammeNoteService {
    static func note(for parameters: PatternParameters, title: String) -> ProgrammeNote {
        let folds = parameters.symmetryCount
        let tension = parameters.asymmetry
        let warp = parameters.distortion
        let act = actLabel(folds: folds, tension: tension)

        let headline = headlineLine(
            geometry: parameters.geometry,
            layout: parameters.layout,
            title: title
        )

        let body = [
            foldLine(folds),
            temperLine(tension: tension, warp: warp),
            paletteLine(parameters),
            layoutLine(parameters.layout)
        ].joined(separator: " ")

        return ProgrammeNote(actLabel: act, headline: headline, body: body)
    }

    private static func actLabel(folds: Int, tension: Double) -> String {
        if tension > 0.35 { return "ACT · OFF-CENTER" }
        if folds >= 10 { return "ACT · CEREMONY" }
        if folds <= 3 { return "ACT · DUET" }
        return "ACT · MEASURE"
    }

    private static func headlineLine(geometry: GeometryKind, layout: PatternLayout, title: String) -> String {
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let name = trimmed.isEmpty ? "Untitled" : trimmed
        switch (geometry, layout) {
        case (.ribbon, .spiral): return "\(name) — a measured spiral"
        case (.diamond, .radial): return "\(name) — radial crowns"
        case (.mask, .mirror): return "\(name) — mirrored masque"
        case (.starburst, .kaleidoscope): return "\(name) — kaleido wedges"
        case (.circle, _): return "\(name) — quiet rings"
        case (_, .curtain): return "\(name) — opposing planes"
        case (_, .lattice): return "\(name) — aligned lattice"
        default: return "\(name) — \(geometry.title.lowercased()) on \(layout.title.lowercased())"
        }
    }

    private static func foldLine(_ folds: Int) -> String {
        switch folds {
        case 1: return "A single decision holds the stage."
        case 2...3: return "\(folds) folds keep the dialogue intimate."
        case 4...7: return "\(folds) folds braid order into ornament."
        case 8...11: return "\(folds) folds read as ceremony at the rim."
        default: return "\(folds) folds densify the periphery; keep the center calm."
        }
    }

    private static func temperLine(tension: Double, warp: Double) -> String {
        if tension < 0.08 && warp < 0.08 {
            return "Temper is poised — almost architectural."
        }
        if tension >= 0.35 {
            return "Weight sits off-center on purpose."
        }
        if warp >= 0.25 {
            return "Structure bends, but the motif still holds."
        }
        return "A measured irregularity keeps the eye awake."
    }

    private static func paletteLine(_ p: PatternParameters) -> String {
        let bright = p.foreground.red + p.foreground.green + p.foreground.blue
        let ground = p.background.red + p.background.green + p.background.blue
        if ground < 0.35 && bright > 1.2 {
            return "Gold advances on ink."
        }
        if abs(bright - ground) < 0.45 {
            return "Values stay close — a whispered contrast."
        }
        return "Figure and ground keep a clear casting."
    }

    private static func layoutLine(_ layout: PatternLayout) -> String {
        switch layout {
        case .radial: return "Attention returns to the quiet center."
        case .spiral: return "The path implies travel without leaving stillness."
        case .mirror: return "Reflection doubles the gesture."
        case .kaleidoscope: return "Every wedge echoes the same vow."
        case .lattice: return "Alignment does the talking."
        case .curtain: return "Two planes share the footlights."
        case .vortex: return "Nesting rings pull focus inward."
        case .orbit: return "Satellites keep even company."
        }
    }
}
