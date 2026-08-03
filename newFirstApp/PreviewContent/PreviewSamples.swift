import Foundation

enum PreviewSamples {
    static var diamond: PatternParameters {
        var p = PatternParameters.default
        p.geometry = .diamond
        p.symmetryCount = 8
        p.foreground = .gold
        p.background = .ink
        return p
    }

    static var mask: PatternParameters {
        var p = PatternParameters.default
        p.geometry = .mask
        p.symmetryCount = 2
        p.asymmetry = 0.2
        p.foreground = .burgundy
        return p
    }

    static func project(title: String, parameters: PatternParameters) -> StudioProject {
        StudioProject(title: title, parameters: parameters)
    }
}
