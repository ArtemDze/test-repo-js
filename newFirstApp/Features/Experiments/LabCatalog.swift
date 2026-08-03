import Foundation
import SwiftUI

// MARK: - Navigation

enum LabDestination: Hashable {
    case practice(ExperimentKind)
    case drill(String)
}

// MARK: - Progress (offline, AppStorage-friendly)

enum LabProgress {
    static let drillsStorageKey = "jestora.labs.clearedDrills"

    static func notesStorageKey(for kind: ExperimentKind) -> String {
        "jestora.labs.notes.\(kind.rawValue)"
    }

    static func clearedIDs(from raw: String) -> Set<String> {
        Set(raw.split(separator: ",").map(String.init).filter { !$0.isEmpty })
    }

    static func encode(_ ids: Set<String>) -> String {
        ids.sorted().joined(separator: ",")
    }

    static func isCleared(_ drillID: String, raw: String) -> Bool {
        clearedIDs(from: raw).contains(drillID)
    }

    static func markCleared(_ drillID: String, raw: inout String) {
        var set = clearedIDs(from: raw)
        set.insert(drillID)
        raw = encode(set)
    }

    static func isNoteChecked(_ index: Int, mask: Int) -> Bool {
        mask & (1 << index) != 0
    }

    static func toggledNote(index: Int, mask: Int) -> Int {
        mask ^ (1 << index)
    }
}

// MARK: - Field notes (practice stages)

struct LabFieldNotes: Sendable {
    let principle: String
    let notice: [String]
    let craftTip: String
    let relatedDrillID: String?
}

// MARK: - Eye drill

enum LabChoice: String, Sendable {
    case a, b
}

struct LabDrill: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let actLabel: String
    let question: String
    let context: String
    let optionA: PatternParameters
    let optionB: PatternParameters
    let labelA: String
    let labelB: String
    let correct: LabChoice
    let revealTitle: String
    let revealBody: String
    let relatedPractice: ExperimentKind?
    let kinetic: KineticStyle

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: LabDrill, rhs: LabDrill) -> Bool { lhs.id == rhs.id }
}

enum LabCatalog {
    static func drill(id: String) -> LabDrill? {
        drills.first { $0.id == id }
    }

    static var tonightDrill: LabDrill {
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return drills[day % drills.count]
    }

    static func fieldNotes(for kind: ExperimentKind) -> LabFieldNotes {
        switch kind {
        case .symmetryChamber:
            LabFieldNotes(
                principle: "One decision, many echoes. Symmetry is multiplication with manners.",
                notice: [
                    "Count the folds — odd counts feel ceremonial; even counts feel architectural.",
                    "Watch the center: if it stays quiet, the rim can afford drama.",
                    "Reflective folds read as theatre curtains; radial folds read as ritual."
                ],
                craftTip: "In Studio, lock seed and change only fold count — notice how identity holds.",
                relatedDrillID: "fold-count"
            )
        case .contrastTheatre:
            LabFieldNotes(
                principle: "Color is relational. A gold is never only gold — it is gold-against.",
                notice: [
                    "The same hue advances on ink and retreats on ivory.",
                    "When values invert, figure and ground trade roles without changing shapes.",
                    "Strong contrast feels loud; soft contrast feels whispered — both are valid stages."
                ],
                craftTip: "Use Invert in this lab, then rebuild the quieter version in Studio.",
                relatedDrillID: "figure-ground"
            )
        case .controlledChaos:
            LabFieldNotes(
                principle: "Irregularity is spice. Too little is bland; too much dissolves the recipe.",
                notice: [
                    "Asymmetry should feel intentional — like a spotlight off-center.",
                    "Distortion bends structure; asymmetry shifts weight.",
                    "Order remains readable when chaos stays under ~30% of the system."
                ],
                craftTip: "Dial chaos up, then back one notch — that last step is usually the craft.",
                relatedDrillID: "chaos-dial"
            )
        case .motionIllusion:
            LabFieldNotes(
                principle: "Stillness can imply travel when repetition leans forward.",
                notice: [
                    "Angled ribbons and spiral layouts persuade the eye of spin.",
                    "Tighter spacing accelerates; wider spacing slows the imagined pace.",
                    "Kinetic preview amplifies the illusion — turn Reduce Motion off to feel it."
                ],
                craftTip: "Pin version A with calm spacing, B with lean — compare which ‘moves’ more.",
                relatedDrillID: "implied-motion"
            )
        case .colorDuality:
            LabFieldNotes(
                principle: "Harmony systems are lenses, not laws. Compare before you commit.",
                notice: [
                    "Complementary pairs vibrate; analogous pairs settle.",
                    "Monochrome depends on value steps — without them it flattens.",
                    "A palette that thrills in the swatch may quarrel on a dense motif."
                ],
                craftTip: "Save two Library projects from this lab — complementary and analogous — then judge on stage.",
                relatedDrillID: "harmony-pair"
            )
        }
    }

    static let drills: [LabDrill] = [
        LabDrill(
            id: "fold-count",
            title: "Fold Count",
            actLabel: "DRILL I",
            question: "Which composition has more radial folds?",
            context: "Don’t guess the mood — count the echoes around the center.",
            optionA: foldParams(count: 6),
            optionB: foldParams(count: 12),
            labelA: "A",
            labelB: "B",
            correct: .b,
            revealTitle: "B carries twelve folds",
            revealBody: "Higher fold counts densify the rim and feel more ceremonial. Six folds leave air between echoes — architectural calm. Counting is a craft skill: the eye that counts designs with intent.",
            relatedPractice: .symmetryChamber,
            kinetic: .breathe
        ),
        LabDrill(
            id: "figure-ground",
            title: "Figure & Ground",
            actLabel: "DRILL II",
            question: "Which stage makes the gold feel more like the figure?",
            context: "Figure advances; ground recedes. Contrast decides the casting.",
            optionA: contrastParams(goldOnInk: true),
            optionB: contrastParams(goldOnInk: false),
            labelA: "A · gold on ink",
            labelB: "B · ink on gold",
            correct: .a,
            revealTitle: "A casts gold as the lead",
            revealBody: "Against deep ink, gold advances and reads as figure. When the field flips to gold, dark shapes become the actors and gold becomes the curtain. Same pigments — different casting.",
            relatedPractice: .contrastTheatre,
            kinetic: .breathe
        ),
        LabDrill(
            id: "chaos-dial",
            title: "Chaos Dial",
            actLabel: "DRILL III",
            question: "Which motif holds more intentional irregularity?",
            context: "Look for shifted weight and bent structure — not noise for its own sake.",
            optionA: chaosParams(asymmetry: 0.08, distortion: 0.04),
            optionB: chaosParams(asymmetry: 0.42, distortion: 0.28),
            labelA: "A",
            labelB: "B",
            correct: .b,
            revealTitle: "B leans harder into chaos",
            revealBody: "Asymmetry shifts mass; distortion warps paths. B raises both so the system still reads as a motif, but the spotlight sits off-center. Craft is knowing when to stop turning the dial.",
            relatedPractice: .controlledChaos,
            kinetic: .shimmer
        ),
        LabDrill(
            id: "implied-motion",
            title: "Implied Motion",
            actLabel: "DRILL IV",
            question: "Which still image suggests stronger movement?",
            context: "Motion here is persuasion — lean, spiral, and spacing do the acting.",
            optionA: motionParams(rotation: 4, spacing: 0.22, spiral: false),
            optionB: motionParams(rotation: 28, spacing: 0.1, spiral: true),
            labelA: "A · calm lattice",
            labelB: "B · leaning spiral",
            correct: .b,
            revealTitle: "B sells the travel",
            revealBody: "Spiral layout plus tighter spacing and angled ribbons imply spin even when every frame is still. A stays polite and architectural. Illusion is directed stillness.",
            relatedPractice: .motionIllusion,
            kinetic: .orbit
        ),
        LabDrill(
            id: "harmony-pair",
            title: "Harmony Pair",
            actLabel: "DRILL V",
            question: "Which pair is closer to a complementary relationship?",
            context: "Complementary hues sit opposite on the wheel — they vibrate when neighbors.",
            optionA: harmonyParams(kind: .analogous, hue: 0.10),
            optionB: harmonyParams(kind: .complementary, hue: 0.10),
            labelA: "A",
            labelB: "B",
            correct: .b,
            revealTitle: "B is the complementary cast",
            revealBody: "Analogous neighbors soothe; complements argue productively. B’s opposition creates optical tension — useful for accents, risky as equal partners across a dense stage.",
            relatedPractice: .colorDuality,
            kinetic: .breathe
        ),
        LabDrill(
            id: "value-weight",
            title: "Value Weight",
            actLabel: "DRILL VI",
            question: "Which composition has the stronger value contrast?",
            context: "Ignore hue for a moment — weigh light against dark.",
            optionA: valueParams(soft: true),
            optionB: valueParams(soft: false),
            labelA: "A · soft values",
            labelB: "B · hard values",
            correct: .b,
            revealTitle: "B hits harder",
            revealBody: "Strong value steps read from across the room; soft steps ask for intimacy. Designers often adjust hue when the real problem is value. Squint — the louder silhouette wins.",
            relatedPractice: .contrastTheatre,
            kinetic: .breathe
        )
    ]

    // MARK: Parameter builders

    private static func foldParams(count: Int) -> PatternParameters {
        var p = MotifCatalog.all.first(where: { $0.id == "crown" })?.parameters ?? .default
        p.layout = .radial
        p.geometry = .diamond
        p.symmetryCount = count
        p.repetition = 3
        p.scale = 0.54
        p.showGlow = true
        return p
    }

    private static func contrastParams(goldOnInk: Bool) -> PatternParameters {
        var p = PatternParameters.default
        p.geometry = .mask
        p.layout = .mirror
        p.symmetryCount = 2
        p.repetition = 4
        p.scale = 0.55
        if goldOnInk {
            p.foreground = .gold
            p.secondary = .ivory
            p.background = .ink
        } else {
            p.foreground = .ink
            p.secondary = .burgundy
            p.background = .gold
        }
        return p
    }

    private static func chaosParams(asymmetry: Double, distortion: Double) -> PatternParameters {
        var p = MotifCatalog.all.first(where: { $0.id == "bloom" })?.parameters ?? .default
        p.asymmetry = asymmetry
        p.distortion = distortion
        p.layout = .radial
        return p
    }

    private static func motionParams(rotation: Double, spacing: Double, spiral: Bool) -> PatternParameters {
        var p = MotifCatalog.all.first(where: { $0.id == "spiral" })?.parameters ?? .default
        p.geometry = .ribbon
        p.layout = spiral ? .spiral : .lattice
        p.rotation = rotation
        p.spacing = spacing
        p.symmetryCount = 6
        return p
    }

    private static func harmonyParams(kind: PaletteKind, hue: Double) -> PatternParameters {
        var p = PatternParameters.default
        p.geometry = .starburst
        p.layout = .kaleidoscope
        p.symmetryCount = 8
        let colors = PaletteService.colors(baseHue: hue, kind: kind)
        p.foreground = colors.first ?? .gold
        p.secondary = colors.count > 2 ? colors[2] : .teal
        p.background = colors.count > 1 ? colors[1] : .ink
        if kind == .monochrome { p.background = .ink }
        return p
    }

    private static func valueParams(soft: Bool) -> PatternParameters {
        var p = PatternParameters.default
        p.geometry = .polygon
        p.layout = .vortex
        p.polygonSides = 6
        p.repetition = 5
        p.scale = 0.56
        if soft {
            p.foreground = CodableColor(red: 0.62, green: 0.52, blue: 0.38)
            p.secondary = CodableColor(red: 0.42, green: 0.38, blue: 0.34)
            p.background = CodableColor(red: 0.16, green: 0.15, blue: 0.14)
            p.opacity = 0.75
        } else {
            p.foreground = .ivory
            p.secondary = .gold
            p.background = .ink
            p.opacity = 1
            p.showGlow = true
        }
        return p
    }
}
