import Foundation

struct DailyPrompt: Identifiable, Hashable, Sendable {
    var id: String
    var title: String
    var body: String
    var suggestedGeometry: GeometryKind
    var suggestedSymmetry: Int
    var suggestedAsymmetry: Double
}

enum DailyPromptService {
    static func prompt(for date: Date = .now, calendar: Calendar = .current) -> DailyPrompt {
        let day = calendar.ordinality(of: .day, in: .year, for: date) ?? 1
        let year = calendar.component(.year, from: date)
        let index = abs(day + year * 13) % catalog.count
        var item = catalog[index]
        item.id = String(format: "%04d-%03d", year, day)
        return item
    }

    static func dateKey(_ date: Date = .now, calendar: Calendar = .current) -> String {
        let f = DateFormatter()
        f.calendar = calendar
        f.locale = Locale(identifier: "en_US_POSIX")
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: date)
    }

    static let catalog: [DailyPrompt] = [
        DailyPrompt(id: "a", title: "Two Shapes", body: "Create tension using only two shape families.", suggestedGeometry: .diamond, suggestedSymmetry: 2, suggestedAsymmetry: 0.35),
        DailyPrompt(id: "b", title: "Imperfect Balance", body: "Build balance without perfect symmetry.", suggestedGeometry: .mask, suggestedSymmetry: 1, suggestedAsymmetry: 0.45),
        DailyPrompt(id: "c", title: "Implied Motion", body: "Express motion in a static composition.", suggestedGeometry: .ribbon, suggestedSymmetry: 4, suggestedAsymmetry: 0.2),
        DailyPrompt(id: "d", title: "One Accent", body: "Use one accent color with restraint.", suggestedGeometry: .arc, suggestedSymmetry: 6, suggestedAsymmetry: 0.05),
        DailyPrompt(id: "e", title: "Order to Chaos", body: "Transform an ordered pattern into controlled chaos.", suggestedGeometry: .polygon, suggestedSymmetry: 8, suggestedAsymmetry: 0.55),
        DailyPrompt(id: "f", title: "Quiet Center", body: "Keep the center calm; place drama at the rim.", suggestedGeometry: .starburst, suggestedSymmetry: 10, suggestedAsymmetry: 0.12),
        DailyPrompt(id: "g", title: "Paper Layers", body: "Suggest depth with repetition and opacity alone.", suggestedGeometry: .circle, suggestedSymmetry: 5, suggestedAsymmetry: 0.18)
    ]
}
