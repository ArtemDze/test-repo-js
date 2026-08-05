import Combine
import Foundation
import SwiftUI

@MainActor
final class ProjectStore: ObservableObject {
    @Published private(set) var projects: [StudioProject] = []
    @Published var settings: AppSettings
    @Published var persistenceError: String?

    private let projectsURL: URL
    private let settingsURL: URL

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        let dir = base.appendingPathComponent("JestoraLibrary", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        projectsURL = dir.appendingPathComponent("projects.json")
        settingsURL = dir.appendingPathComponent("settings.json")
        settings = AppSettings()
        load()
    }

    func load() {
        if let data = try? Data(contentsOf: settingsURL),
           let decoded = try? JSONDecoder().decode(AppSettings.self, from: data) {
            settings = decoded
        } else {
            settings = AppSettings()
            persistSettings()
        }

        if let data = try? Data(contentsOf: projectsURL),
           let decoded = try? JSONDecoder().decode([StudioProject].self, from: data) {
            projects = decoded.sorted { $0.updatedAt > $1.updatedAt }
        } else {
            projects = []
        }
    }

    func save(_ project: StudioProject) {
        project.updatedAt = Date()
        if let idx = projects.firstIndex(where: { $0.id == project.id }) {
            projects[idx] = project
        } else {
            projects.insert(project, at: 0)
        }
        projects.sort { $0.updatedAt > $1.updatedAt }
        persistProjects()
        objectWillChange.send()
        persistenceError = nil
    }

    func delete(_ project: StudioProject) {
        projects.removeAll { $0.id == project.id }
        if settings.lastProjectID == project.id {
            settings.lastProjectID = nil
            persistSettings()
        }
        persistProjects()
        persistenceError = nil
    }

    func duplicate(_ project: StudioProject) -> StudioProject {
        let copy = project.duplicate()
        save(copy)
        return copy
    }

    func clearAll() {
        projects = []
        settings.lastProjectID = nil
        settings.completedPromptDates = []
        persistProjects()
        persistSettings()
        persistenceError = nil
    }

    func persistSettings() {
        do {
            let data = try JSONEncoder().encode(settings)
            try data.write(to: settingsURL, options: [.atomic])
            persistenceError = nil
        } catch {
            persistenceError = "Couldn’t save preferences. Try again, or free device storage."
        }
        objectWillChange.send()
    }

    private func persistProjects() {
        do {
            let data = try JSONEncoder().encode(projects)
            try data.write(to: projectsURL, options: [.atomic])
            persistenceError = nil
        } catch {
            persistenceError = "Couldn’t save this composition. Try again, or free device storage."
        }
    }
}

enum CollectionSort: String, CaseIterable, Identifiable {
    case updated, created, title, favoritesFirst
    var id: String { rawValue }
    var title: String {
        switch self {
        case .updated: "Recently Edited"
        case .created: "Date Created"
        case .title: "Name"
        case .favoritesFirst: "Favorites First"
        }
    }
}

enum CollectionFilter: String, CaseIterable, Identifiable {
    case all, favorites, notes, diamond, mask, ribbon, starburst
    var id: String { rawValue }
    var title: String {
        switch self {
        case .all: "All"
        case .favorites: "Favorites"
        case .notes: "With Notes"
        case .diamond: "Diamond"
        case .mask: "Mask"
        case .ribbon: "Ribbon"
        case .starburst: "Starburst"
        }
    }
}

enum CollectionQuery {
    static func filter(
        _ projects: [StudioProject],
        search: String,
        sort: CollectionSort,
        filter: CollectionFilter
    ) -> [StudioProject] {
        var items = projects.filter { project in
            let matchesSearch = search.isEmpty
                || project.title.localizedCaseInsensitiveContains(search)
                || project.notes.localizedCaseInsensitiveContains(search)
            let matchesFilter: Bool = {
                switch filter {
                case .all: true
                case .favorites: project.isFavorite
                case .notes: !project.notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                case .diamond: project.parameters.geometry == .diamond
                case .mask: project.parameters.geometry == .mask
                case .ribbon: project.parameters.geometry == .ribbon
                case .starburst: project.parameters.geometry == .starburst
                }
            }()
            return matchesSearch && matchesFilter
        }
        switch sort {
        case .updated: items.sort { $0.updatedAt > $1.updatedAt }
        case .created: items.sort { $0.createdAt > $1.createdAt }
        case .title: items.sort { $0.title.localizedCaseInsensitiveCompare($1.title) == .orderedAscending }
        case .favoritesFirst: items.sort {
            if $0.isFavorite != $1.isFavorite { return $0.isFavorite && !$1.isFavorite }
            return $0.updatedAt > $1.updatedAt
        }
        }
        return items
    }
}
