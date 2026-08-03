import Foundation
import SwiftData
import UIKit

@Model
final class StudioProject {
    var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date
    var isFavorite: Bool
    var parametersData: Data
    var thumbnailData: Data?
    var notes: String
    var promptID: String?

    init(
        id: UUID = UUID(),
        title: String = "Untitled Composition",
        createdAt: Date = .now,
        updatedAt: Date = .now,
        isFavorite: Bool = false,
        parameters: PatternParameters = .default,
        thumbnailData: Data? = nil,
        notes: String = "",
        promptID: String? = nil
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.isFavorite = isFavorite
        self.parametersData = (try? JSONEncoder().encode(parameters)) ?? Data()
        self.thumbnailData = thumbnailData
        self.notes = notes
        self.promptID = promptID
    }

    var parameters: PatternParameters {
        get { (try? JSONDecoder().decode(PatternParameters.self, from: parametersData)) ?? .default }
        set {
            parametersData = (try? JSONEncoder().encode(newValue)) ?? parametersData
            updatedAt = .now
        }
    }

    var thumbnailImage: UIImage? {
        guard let thumbnailData else { return nil }
        return UIImage(data: thumbnailData)
    }

    func duplicate() -> StudioProject {
        StudioProject(
            title: "\(title) Copy",
            parameters: parameters,
            thumbnailData: thumbnailData,
            notes: notes,
            promptID: promptID
        )
    }
}

@Model
final class AppSettings {
    var hasCompletedOnboarding: Bool
    var hasSeenLaunch: Bool
    var appearanceRaw: String
    var defaultRatioRaw: String
    var hapticsEnabled: Bool
    var motionIntensity: Double
    var exportQualityRaw: String
    var lastProjectID: UUID?
    var completedPromptDates: [String]

    init(
        hasCompletedOnboarding: Bool = false,
        hasSeenLaunch: Bool = false,
        appearance: AppearancePreference = .system,
        defaultRatio: CanvasRatio = .square,
        hapticsEnabled: Bool = true,
        motionIntensity: Double = 1,
        exportQuality: ExportQuality = .high,
        lastProjectID: UUID? = nil,
        completedPromptDates: [String] = []
    ) {
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.hasSeenLaunch = hasSeenLaunch
        self.appearanceRaw = appearance.rawValue
        self.defaultRatioRaw = defaultRatio.rawValue
        self.hapticsEnabled = hapticsEnabled
        self.motionIntensity = motionIntensity
        self.exportQualityRaw = exportQuality.rawValue
        self.lastProjectID = lastProjectID
        self.completedPromptDates = completedPromptDates
    }

    var appearance: AppearancePreference {
        get { AppearancePreference(rawValue: appearanceRaw) ?? .system }
        set { appearanceRaw = newValue.rawValue }
    }

    var defaultRatio: CanvasRatio {
        get { CanvasRatio(rawValue: defaultRatioRaw) ?? .square }
        set { defaultRatioRaw = newValue.rawValue }
    }

    var exportQuality: ExportQuality {
        get { ExportQuality(rawValue: exportQualityRaw) ?? .high }
        set { exportQualityRaw = newValue.rawValue }
    }
}
