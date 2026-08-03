import Foundation

enum OnboardingPage: Int, CaseIterable, Identifiable {
    case prologue
    case symmetry
    case contrast
    case motion
    case yours

    var id: Int { rawValue }

    var eyebrow: String {
        switch self {
        case .prologue: "Act I"
        case .symmetry: "Act II"
        case .contrast: "Act III"
        case .motion: "Act IV"
        case .yours: "Finale"
        }
    }

    var title: String {
        switch self {
        case .prologue: "The stage is yours."
        case .symmetry: "Fold one idea into many."
        case .contrast: "Push light against shadow."
        case .motion: "Give the pattern a pulse."
        case .yours: "Keep what you compose."
        }
    }

    var body: String {
        switch self {
        case .prologue:
            "\(AppBrand.fullName) is a quiet theatre for geometric composition — symmetry, illusion, and color in your hands."
        case .symmetry:
            "Drag the folds. Watch a single motif bloom into a balanced ceremony."
        case .contrast:
            "Tap the stage to invert figure and ground. Feel how tension shapes the scene."
        case .motion:
            "Choose a kinetic style. Stillness, breath, orbit, or shimmer — each changes the mood."
        case .yours:
            "Projects stay on this device. Export when ready. No accounts. No noise."
        }
    }

    var primaryTitle: String {
        self == .yours ? "Enter Studio" : "Continue"
    }

    var primarySymbol: String? {
        self == .yours ? "paintbrush.pointed.fill" : nil
    }
}
