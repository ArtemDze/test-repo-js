import Foundation

struct MotifPreset: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let subtitle: String
    let parameters: PatternParameters
}

/// Curated, centered, low-noise showpieces — beauty first.
enum MotifCatalog {
    static let all: [MotifPreset] = [
        make("crown", "Footlight Crown", "Radial diamonds, quiet center", {
            $0.geometry = .diamond; $0.layout = .radial
            $0.symmetryCount = 10; $0.repetition = 3; $0.spacing = 0.16
            $0.scale = 0.56; $0.layerDepth = 2; $0.strokeWidth = 2
            $0.foreground = .gold; $0.secondary = .burgundy; $0.background = .ink
            $0.renderMode = .both; $0.showGlow = true; $0.seed = 11
        }),
        make("masque", "Paper Masque", "Balanced mirror ovals", {
            $0.geometry = .mask; $0.layout = .mirror
            $0.repetition = 3; $0.spacing = 0.14; $0.scale = 0.52
            $0.foreground = .burgundy; $0.secondary = .gold; $0.background = .ink
            $0.renderMode = .both; $0.strokeWidth = 2; $0.seed = 22
        }),
        make("vortex", "Quiet Vortex", "Nested precise rings", {
            $0.geometry = .polygon; $0.layout = .vortex; $0.polygonSides = 6
            $0.repetition = 6; $0.scale = 0.58; $0.rotation = 8
            $0.foreground = .teal; $0.secondary = .gold; $0.background = .ink
            $0.renderMode = .outline; $0.strokeWidth = 2.5; $0.seed = 33
        }),
        make("kaleido", "Kaleido Stage", "Even theatrical wedges", {
            $0.geometry = .starburst; $0.layout = .kaleidoscope
            $0.symmetryCount = 8; $0.scale = 0.55; $0.polygonSides = 5
            $0.foreground = .gold; $0.secondary = .teal; $0.background = .ink
            $0.renderMode = .both; $0.strokeWidth = 1.8; $0.seed = 44
        }),
        make("lattice", "Card Lattice", "Aligned paper grid", {
            $0.geometry = .diamond; $0.layout = .lattice
            $0.scale = 0.72; $0.rotation = 0
            $0.foreground = .gold; $0.secondary = .burgundy
            $0.background = CodableColor(red: 0.06, green: 0.07, blue: 0.09)
            $0.renderMode = .both; $0.strokeWidth = 1.6; $0.opacity = 0.9; $0.seed = 55
        }),
        make("spiral", "Ribbon Spiral", "Measured path", {
            $0.geometry = .ribbon; $0.layout = .spiral
            $0.symmetryCount = 6; $0.scale = 0.6
            $0.foreground = .gold; $0.secondary = .teal; $0.background = .ink
            $0.renderMode = .fill; $0.opacity = 0.88; $0.seed = 66
        }),
        make("orbit", "Orbit Ceremony", "Even satellites", {
            $0.geometry = .arc; $0.layout = .orbit
            $0.symmetryCount = 8; $0.scale = 0.68
            $0.foreground = .gold; $0.secondary = .teal; $0.background = .ink
            $0.renderMode = .both; $0.strokeWidth = 2.2; $0.seed = 77
        }),
        make("curtain", "Dual Curtain", "Opposing planes", {
            $0.geometry = .mask; $0.layout = .curtain
            $0.repetition = 3; $0.scale = 0.62
            $0.foreground = .burgundy; $0.secondary = CodableColor(red: 0.5, green: 0.36, blue: 0.24)
            $0.background = .ink; $0.renderMode = .both; $0.opacity = 0.9; $0.seed = 88
        }),
        make("halo", "Quiet Halo", "Restrained rings", {
            $0.geometry = .circle; $0.layout = .vortex
            $0.repetition = 7; $0.scale = 0.5
            $0.foreground = .ivory; $0.secondary = .gold; $0.background = .ink
            $0.renderMode = .outline; $0.strokeWidth = 2; $0.opacity = 0.8
            $0.showGlow = true; $0.seed = 99
        }),
        make("bloom", "Gold Bloom", "Soft radial ceremony", {
            $0.geometry = .starburst; $0.layout = .radial
            $0.symmetryCount = 12; $0.repetition = 2; $0.spacing = 0.2
            $0.scale = 0.5; $0.layerDepth = 2; $0.polygonSides = 6
            $0.foreground = .gold; $0.secondary = .ivory; $0.background = .ink
            $0.renderMode = .both; $0.strokeWidth = 1.5; $0.showGlow = true; $0.seed = 101
        })
    ]

    private static func make(
        _ id: String,
        _ title: String,
        _ subtitle: String,
        _ edit: (inout PatternParameters) -> Void
    ) -> MotifPreset {
        var p = PatternParameters()
        p.asymmetry = 0
        p.distortion = 0
        edit(&p)
        p.clamp()
        return MotifPreset(id: id, title: title, subtitle: subtitle, parameters: p)
    }
}
