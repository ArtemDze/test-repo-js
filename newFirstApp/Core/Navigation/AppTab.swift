import Foundation

enum AppTab: Int, CaseIterable, Identifiable, Hashable {
    case studio
    case atelier
    case experiments
    case collection
    case profile

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .studio: "Studio"
        case .atelier: "Atelier"
        case .experiments: "Labs"
        case .collection: "Library"
        case .profile: "Profile"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .studio: "Studio"
        case .atelier: "Atelier"
        case .experiments: "Labs"
        case .collection: "Library"
        case .profile: "Profile"
        }
    }

    /// Resting (outline) mark.
    var symbol: String {
        switch self {
        case .studio: "paintbrush.pointed"
        case .atelier: "rhombus"
        case .experiments: "sparkles"
        case .collection: "rectangle.stack"
        case .profile: "person.crop.circle"
        }
    }

    /// Selected (filled) mark.
    var symbolSelected: String {
        switch self {
        case .studio: "paintbrush.pointed.fill"
        case .atelier: "rhombus.fill"
        case .experiments: "sparkles"
        case .collection: "rectangle.stack.fill"
        case .profile: "person.crop.circle.fill"
        }
    }
}
