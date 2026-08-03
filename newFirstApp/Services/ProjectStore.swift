import Foundation
import SwiftData
import SwiftUI

@Observable
final class ProjectStore {
    var persistenceError: String?

    func save(_ project: StudioProject, context: ModelContext) {
        do {
            project.updatedAt = .now
            if project.modelContext == nil {
                context.insert(project)
            }
            try context.save()
            persistenceError = nil
        } catch {
            persistenceError = "Couldn’t save this composition. Try again, or free device storage."
        }
    }

    func delete(_ project: StudioProject, context: ModelContext) {
        do {
            context.delete(project)
            try context.save()
            persistenceError = nil
        } catch {
            persistenceError = "Couldn’t delete the composition. Please try again."
        }
    }

    func duplicate(_ project: StudioProject, context: ModelContext) -> StudioProject {
        let copy = project.duplicate()
        save(copy, context: context)
        return copy
    }

    func clearAll(projects: [StudioProject], context: ModelContext) {
        do {
            for project in projects { context.delete(project) }
            try context.save()
            persistenceError = nil
        } catch {
            persistenceError = "Couldn’t clear the library. Please try again."
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
