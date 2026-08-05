import SwiftUI

struct CollectionView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: ProjectStore
    @EnvironmentObject private var haptics: HapticsClient

    @State private var search = ""
    @State private var sort: CollectionSort = .updated
    @State private var filter: CollectionFilter = .all
    @State private var layout: LayoutMode = .grid
    @State private var path = NavigationPath()
    @State private var pendingDelete: StudioProject?
    @State private var renameTarget: StudioProject?
    @State private var renameText = ""
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var celebratingID: UUID?
    @State private var shelfPulse = false

    private var projects: [StudioProject] { store.projects }

    private enum LayoutMode { case grid, list }

    private var filtered: [StudioProject] {
        CollectionQuery.filter(projects, search: search, sort: sort, filter: filter)
    }

    private var favoritesCount: Int {
        projects.filter(\.isFavorite).count
    }

    private var spotlight: StudioProject? {
        projects.first
    }

    private var dailyPrompt: DailyPrompt {
        DailyPromptService.prompt()
    }

    var body: some View {
        NavigationStack(path: $path) {
            ScrollView {
                VStack(alignment: .leading, spacing: JSRSpace.lg) {
                    header
                        .padding(.horizontal, JSRSpace.md)
                        .padding(.top, JSRSpace.sm)

                    if projects.isEmpty {
                        emptyArchive
                    } else {
                        filledArchive
                    }

                    JSRScrollBottomSpacer()
                }
            }
            .scrollIndicators(.hidden)
            .background { JSRStageAtmosphere(tint: JSRColor.highlight) }
            .preferredColorScheme(.dark)
            .toolbarBackground(JSRColor.ink.opacity(0.94), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, prompt: "Search titles & notes")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Library")
                        .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Menu {
                        Picker("Sort", selection: $sort) {
                            ForEach(CollectionSort.allCases) { Text($0.title).tag($0) }
                        }
                    } label: {
                        Image(systemName: "arrow.up.arrow.down.circle")
                            .foregroundStyle(JSRColor.highlight)
                    }
                    .accessibilityLabel("Sort library")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        if !projects.isEmpty {
                            Button {
                                layout = layout == .grid ? .list : .grid
                                haptics.select()
                            } label: {
                                Image(systemName: layout == .grid ? "list.bullet" : "square.grid.2x2")
                                    .foregroundStyle(JSRColor.highlight)
                            }
                            .accessibilityLabel(layout == .grid ? "List layout" : "Grid layout")
                        }
                        Button {
                            path.append(CollectionRoute.newStudio)
                            haptics.select()
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .foregroundStyle(JSRColor.highlight)
                        }
                        .accessibilityLabel("New composition")
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                if let project = projects.first(where: { $0.id == id }) {
                    ProjectDetailView(project: project)
                } else {
                    libraryMissingState
                }
            }
            .navigationDestination(for: CollectionRoute.self) { route in
                switch route {
                case .newStudio:
                    StudioView()
                case .studioProject(let id):
                    if let project = projects.first(where: { $0.id == id }) {
                        StudioView(project: project)
                    } else {
                        StudioView()
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if let toast {
                    Text(toast)
                        .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .medium))
                        .foregroundStyle(JSRColor.ink)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(JSRColor.highlight)
                        .clipShape(Capsule())
                        .shadow(color: JSRColor.highlight.opacity(0.35), radius: 12, y: 4)
                        .padding(.bottom, JSRSpace.md)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: toast)
            .animation(JSRMotion.preferred(JSRMotion.echo, reduceMotion: reduceMotion), value: celebratingID)
            .alert("Delete composition?", isPresented: Binding(
                get: { pendingDelete != nil },
                set: { if !$0 { pendingDelete = nil } }
            )) {
                Button("Delete", role: .destructive) {
                    if let pendingDelete {
                        store.delete(pendingDelete)
                        showToast("Removed from Library")
                        haptics.warning()
                    }
                    pendingDelete = nil
                }
                Button("Cancel", role: .cancel) { pendingDelete = nil }
            } message: {
                Text("This removes the composition from this device.")
            }
            .alert("Rename", isPresented: Binding(
                get: { renameTarget != nil },
                set: { if !$0 { renameTarget = nil } }
            )) {
                TextField("Title", text: $renameText)
                Button("Save") {
                    if let renameTarget {
                        renameTarget.title = renameText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                            ? "Untitled Composition"
                            : renameText
                        store.save(renameTarget)
                        showToast("Renamed")
                        haptics.select()
                    }
                    renameTarget = nil
                }
                Button("Cancel", role: .cancel) { renameTarget = nil }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: JSRSpace.xs) {
                Text("LIBRARY")
                    .font(JSRType.motif)
                    .tracking(1.4)
                    .foregroundStyle(JSRColor.highlight)
                Text(projects.isEmpty ? "Empty Library" : "Your Library")
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                Text(
                    projects.isEmpty
                        ? "Seed starters below, or begin a blank stage — then refine in Studio."
                        : "\(projects.count) composition\(projects.count == 1 ? "" : "s") · \(favoritesCount) favorite\(favoritesCount == 1 ? "" : "s")."
                )
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
                .frame(maxWidth: 300, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            LibraryHeaderOrnament(reduceMotion: reduceMotion)
                .frame(width: 110)
                .opacity(0.88)
        }
        .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))
    }

    // MARK: Empty

    private var emptyArchive: some View {
        VStack(alignment: .leading, spacing: JSRSpace.lg) {
            emptyHero
                .padding(.horizontal, JSRSpace.md)
                .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))

            cueCard
                .padding(.horizontal, JSRSpace.md)
                .modifier(StageAppearModifier(index: 2, reduceMotion: reduceMotion))

            quickActions
                .padding(.horizontal, JSRSpace.md)
                .modifier(StageAppearModifier(index: 3, reduceMotion: reduceMotion))

            starterShelf(title: "STARTER SHELF", subtitle: "Pin curated motifs to begin your archive.")
                .modifier(StageAppearModifier(index: 4, reduceMotion: reduceMotion))
        }
    }

    private var emptyHero: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                PatternCanvasView(
                    parameters: MotifCatalog.all[0].parameters,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : .breathe,
                    reduceMotion: reduceMotion
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1.4, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(JSRColor.ink.opacity(0.45))
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.4), lineWidth: 1.2)
                }

                VStack(spacing: 8) {
                    Image(systemName: "rectangle.stack")
                        .font(.system(size: 28, weight: .light))
                        .foregroundStyle(JSRColor.highlight)
                    Text("Your Library is waiting")
                        .font(JSRFont.serif(size: 22, relativeTo: .title3, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                    Text("Start with a blank stage or pin a starter from the shelf.")
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: 260)
                }
                .padding()
            }
        }
    }

    private var cueCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TONIGHT'S CUE")
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(JSRColor.highlight)
            Text(dailyPrompt.title)
                .font(JSRFont.serif(size: 20, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
            Text(dailyPrompt.body)
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)

            Button {
                let project = makeProject(from: dailyPrompt)
                store.save(project)
                showToast("Cue pinned to Library")
                haptics.success()
                path.append(project.id)
            } label: {
                libraryCapsule(title: "Pin cue as composition", systemImage: "pin.fill", filled: true)
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
        }
        .padding(JSRSpace.md)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.35), lineWidth: 1)
                }
        }
    }

    private var quickActions: some View {
        HStack(spacing: 10) {
            Button {
                path.append(CollectionRoute.newStudio)
                haptics.select()
            } label: {
                libraryCapsule(title: "Blank stage", systemImage: "paintbrush.pointed", filled: true)
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))

            Button {
                seedStarterPack()
            } label: {
                libraryCapsule(title: "Seed 3 starters", systemImage: "sparkles", filled: false)
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
        }
    }

    // MARK: Filled

    private var filledArchive: some View {
        VStack(alignment: .leading, spacing: JSRSpace.lg) {
            statsRibbon
                .padding(.horizontal, JSRSpace.md)
                .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))

            if let spotlight, search.isEmpty, filter == .all {
                Button {
                    path.append(spotlight.id)
                    haptics.select()
                } label: {
                    LibrarySpotlightCard(project: spotlight, reduceMotion: reduceMotion)
                }
                .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                .contextMenu { contextMenu(for: spotlight) }
                .padding(.horizontal, JSRSpace.md)
                .modifier(StageAppearModifier(index: 2, reduceMotion: reduceMotion))
                .accessibilityLabel("Recently on stage: \(spotlight.title)")
            }

            filterChips
                .modifier(StageAppearModifier(index: 3, reduceMotion: reduceMotion))

            if filtered.isEmpty {
                filteredEmptyState
                    .padding(.horizontal, JSRSpace.md)
            } else if layout == .grid {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 156), spacing: 12)], spacing: 12) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, project in
                        LibraryProjectCard(project: project, reduceMotion: reduceMotion) {
                            toggleFavorite(project)
                        } onOpen: {
                            path.append(project.id)
                            haptics.select()
                        }
                        .modifier(StageCelebrateModifier(
                            active: celebratingID == project.id,
                            reduceMotion: reduceMotion
                        ))
                        .contextMenu { contextMenu(for: project) }
                        .modifier(StageAppearModifier(index: min(index, 8) + 4, reduceMotion: reduceMotion))
                    }
                }
                .padding(.horizontal, JSRSpace.md)
            } else {
                VStack(spacing: 10) {
                    ForEach(Array(filtered.enumerated()), id: \.element.id) { index, project in
                        Button {
                            path.append(project.id)
                            haptics.select()
                        } label: {
                            LibraryProjectRow(project: project, reduceMotion: reduceMotion)
                        }
                        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                        .modifier(StageCelebrateModifier(
                            active: celebratingID == project.id,
                            reduceMotion: reduceMotion
                        ))
                        .contextMenu { contextMenu(for: project) }
                        .modifier(StageAppearModifier(index: min(index, 8) + 4, reduceMotion: reduceMotion))
                    }
                }
                .padding(.horizontal, JSRSpace.md)
            }

            starterShelf(title: "FROM THE ATELIER", subtitle: "Pin more starters without leaving Library.")
                .modifier(StageAppearModifier(index: 12, reduceMotion: reduceMotion))
        }
    }

    private var statsRibbon: some View {
        HStack(spacing: 0) {
            statCell(value: "\(projects.count)", label: "Saved")
            divider
            statCell(value: "\(favoritesCount)", label: "Favorites")
            divider
            statCell(
                value: projects.first.map { $0.updatedAt.formatted(date: .abbreviated, time: .omitted) } ?? "—",
                label: "Latest"
            )
        }
        .padding(.vertical, 12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label.uppercased())
                .font(JSRType.motif)
                .tracking(0.9)
                .foregroundStyle(JSRStage.labelTertiary)
        }
        .frame(maxWidth: .infinity)
    }

    private var divider: some View {
        Rectangle()
            .fill(JSRStage.separator)
            .frame(width: 1, height: 36)
    }

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(CollectionFilter.allCases) { item in
                    let selected = filter == item
                    Button {
                        withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                            filter = item
                        }
                        haptics.select()
                    } label: {
                        Text(item.title)
                            .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .medium))
                            .foregroundStyle(selected ? JSRColor.ink : JSRStage.label)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selected ? JSRColor.highlight : JSRStage.chipFill)
                            .clipShape(Capsule())
                            .overlay {
                                Capsule().strokeBorder(selected ? Color.clear : JSRStage.chipStroke, lineWidth: 1)
                            }
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected ? .isSelected : [])
                }
            }
            .padding(.horizontal, JSRSpace.md)
        }
    }

    private var filteredEmptyState: some View {
        let copy: (title: String, body: String, action: String) = {
            if !search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return (
                    "No search results",
                    "Nothing in Library matches “\(search)”. Try another title or note fragment.",
                    "Clear search"
                )
            }
            if filter == .favorites {
                return (
                    "No favorites yet",
                    "Star a composition to keep it close — favorites appear here.",
                    "Show all"
                )
            }
            if filter == .notes {
                return (
                    "No noted compositions",
                    "Add notes in a preview or Studio, then filter by With Notes.",
                    "Show all"
                )
            }
            return (
                "No matches",
                "Try another filter chip, or clear filters to see the full Library.",
                "Clear filters"
            )
        }()

        return VStack(alignment: .leading, spacing: 10) {
            Text(copy.title)
                .font(JSRFont.serif(size: 20, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
            Text(copy.body)
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
            Button {
                search = ""
                filter = .all
                haptics.select()
            } label: {
                libraryCapsule(title: copy.action, systemImage: "xmark.circle", filled: false)
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }

    private var libraryMissingState: some View {
        VStack(spacing: JSRSpace.md) {
            Text("Composition missing")
                .font(JSRType.title)
                .foregroundStyle(JSRStage.label)
            Text("It may have been deleted. Return to Library and pick another.")
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .multilineTextAlignment(.center)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background { JSRStageAtmosphere() }
        .preferredColorScheme(.dark)
    }

    // MARK: Starter shelf

    private func starterShelf(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JSRType.motif)
                    .tracking(1.3)
                    .foregroundStyle(JSRColor.highlight)
                Text(subtitle)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelTertiary)
            }
            .padding(.horizontal, JSRSpace.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(MotifCatalog.all) { motif in
                        Button {
                            pinMotif(motif)
                        } label: {
                            LibraryStarterCard(motif: motif, reduceMotion: reduceMotion)
                                .modifier(StageCelebrateModifier(active: shelfPulse, reduceMotion: reduceMotion))
                        }
                        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                        .accessibilityLabel("Pin \(motif.title) to Library")
                    }
                }
                .padding(.horizontal, JSRSpace.md)
            }
        }
    }

    // MARK: Actions

    @ViewBuilder
    private func contextMenu(for project: StudioProject) -> some View {
        Button(project.isFavorite ? "Remove Favorite" : "Favorite", systemImage: project.isFavorite ? "star.slash" : "star") {
            toggleFavorite(project)
        }
        Button("Open in Studio", systemImage: "paintbrush.pointed") {
            path.append(CollectionRoute.studioProject(project.id))
        }
        Button("Rename", systemImage: "pencil") {
            renameText = project.title
            renameTarget = project
        }
        Button("Duplicate", systemImage: "plus.square.on.square") {
            let copy = store.duplicate(project)
            showToast("Duplicated")
            haptics.success()
            path.append(copy.id)
        }
        Button("Delete", systemImage: "trash", role: .destructive) {
            pendingDelete = project
        }
    }

    private func toggleFavorite(_ project: StudioProject) {
        project.isFavorite.toggle()
        store.save(project)
        celebrate(project.id)
        showToast(project.isFavorite ? "Favorited" : "Removed favorite")
        haptics.select()
    }

    private func pinMotif(_ motif: MotifPreset) {
        let project = makeProject(from: motif)
        store.save(project)
        celebrateShelf()
        celebrate(project.id)
        showToast("Pinned \(motif.title)")
        haptics.success()
    }

    private func seedStarterPack() {
        let picks = Array(MotifCatalog.all.prefix(3))
        var lastID: UUID?
        for motif in picks {
            let project = makeProject(from: motif)
            store.save(project)
            lastID = project.id
        }
        celebrateShelf()
        if let lastID { celebrate(lastID) }
        showToast("Seeded \(picks.count) starters")
        haptics.success()
    }

    private func celebrate(_ id: UUID) {
        celebratingID = id
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 420_000_000)
            if celebratingID == id { celebratingID = nil }
        }
    }

    private func celebrateShelf() {
        shelfPulse = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 380_000_000)
            shelfPulse = false
        }
    }

    private func makeProject(from motif: MotifPreset) -> StudioProject {
        let project = StudioProject(title: motif.title, parameters: motif.parameters)
        project.thumbnailData = ExportService.thumbnail(parameters: motif.parameters)
        project.notes = motif.subtitle
        return project
    }

    private func makeProject(from prompt: DailyPrompt) -> StudioProject {
        var params = PatternParameters.default
        params.geometry = prompt.suggestedGeometry
        params.symmetryCount = prompt.suggestedSymmetry
        params.asymmetry = prompt.suggestedAsymmetry
        params.layout = .radial
        params.clamp()
        let project = StudioProject(title: prompt.title, parameters: params)
        project.thumbnailData = ExportService.thumbnail(parameters: params)
        project.notes = prompt.body
        project.promptID = prompt.id
        return project
    }

    private func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_600_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }

    private func libraryCapsule(title: String, systemImage: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(JSRFont.serif(size: 14, relativeTo: .caption, weight: .semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 46)
        .foregroundStyle(filled ? JSRColor.ink : JSRStage.label)
        .background(filled ? JSRColor.highlight : JSRStage.chipFillStrong)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(filled ? Color.clear : JSRStage.chipStroke, lineWidth: 1)
        }
    }
}

// MARK: - Cards

struct LibrarySpotlightCard: View {
    let project: StudioProject
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack(alignment: .topLeading) {
                PatternCanvasView(
                    parameters: project.parameters,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : .breathe,
                    reduceMotion: reduceMotion
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1.35, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))

                HStack(spacing: 6) {
                    Text("ON STAGE")
                        .font(JSRType.motif)
                        .tracking(1.0)
                        .foregroundStyle(JSRColor.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(JSRColor.highlight)
                        .clipShape(Capsule())
                    if project.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(JSRColor.highlight)
                            .padding(6)
                            .background(JSRColor.ink.opacity(0.72))
                            .clipShape(Circle())
                    }
                }
                .padding(10)
            }
            .overlay {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .strokeBorder(JSRColor.highlight.opacity(0.5), lineWidth: 1.4)
            }

            Text(project.title)
                .font(JSRFont.serif(size: 22, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .lineLimit(1)
            Text("\(project.parameters.geometry.title) · updated \(project.updatedAt.formatted(date: .abbreviated, time: .omitted))")
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelSecondary)
        }
        .padding(14)
        .background {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.35), lineWidth: 1)
                }
                .shadow(color: JSRColor.highlight.opacity(0.16), radius: 16, y: 0)
        }
    }
}

struct LibraryProjectCard: View {
    let project: StudioProject
    var reduceMotion: Bool
    var onFavorite: () -> Void
    var onOpen: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack(alignment: .topTrailing) {
                Button(action: onOpen) {
                    PatternCanvasView(
                        parameters: project.parameters,
                        showChrome: false,
                        kinetic: .none,
                        reduceMotion: reduceMotion
                    )
                    .frame(maxWidth: .infinity)
                    .aspectRatio(1, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))

                Button(action: onFavorite) {
                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(project.isFavorite ? JSRColor.ink : JSRColor.highlight)
                        .padding(7)
                        .background(project.isFavorite ? JSRColor.highlight : JSRColor.ink.opacity(0.72))
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .padding(8)
                .accessibilityLabel(project.isFavorite ? "Remove favorite" : "Favorite")
            }
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        project.isFavorite ? JSRColor.highlight.opacity(0.55) : JSRStage.separator,
                        lineWidth: 1
                    )
            }

            Button(action: onOpen) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(project.title)
                        .font(JSRFont.serif(size: 16, relativeTo: .callout, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                        .lineLimit(1)
                    HStack(spacing: 4) {
                        Text(project.parameters.geometry.title)
                        if !project.notes.isEmpty {
                            Text("·")
                            Image(systemName: "note.text")
                                .font(.system(size: 9, weight: .semibold))
                        }
                    }
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelTertiary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("\(project.title), \(project.parameters.geometry.title)")
    }
}

struct LibraryProjectRow: View {
    let project: StudioProject
    var reduceMotion: Bool

    var body: some View {
        HStack(spacing: 12) {
            PatternCanvasView(
                parameters: project.parameters,
                showChrome: false,
                kinetic: .none,
                reduceMotion: reduceMotion
            )
            .frame(width: 68, height: 68)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(JSRStage.separator, lineWidth: 1)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text(project.title)
                        .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                        .lineLimit(1)
                    if project.isFavorite {
                        Image(systemName: "star.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(JSRColor.highlight)
                    }
                }
                Text("\(project.parameters.geometry.title) · \(project.parameters.symmetryCount)-fold")
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
                if !project.notes.isEmpty {
                    Text(project.notes)
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelTertiary)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JSRStage.labelTertiary)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

struct LibraryStarterCard: View {
    let motif: MotifPreset
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PatternCanvasView(
                parameters: motif.parameters,
                showChrome: false,
                kinetic: reduceMotion ? .none : .breathe,
                reduceMotion: reduceMotion
            )
            .frame(width: 132, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(JSRStage.chipStroke, lineWidth: 1)
            }

            Text(motif.title)
                .font(JSRFont.serif(size: 14, relativeTo: .caption, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .lineLimit(1)
                .frame(width: 132, alignment: .leading)

            HStack(spacing: 4) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 11))
                Text("Pin")
                    .font(JSRFont.serif(size: 12, relativeTo: .caption2, weight: .medium))
            }
            .foregroundStyle(JSRColor.highlight)
        }
        .padding(10)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

struct LibraryHeaderOrnament: View {
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let origin = CGPoint(x: size.width * 0.55, y: size.height * 0.4)
                for i in 0..<5 {
                    let y = origin.y + CGFloat(i) * 7 - 10
                    let w: CGFloat = 36 - CGFloat(i) * 4
                    var rect = Path(
                        roundedRect: CGRect(x: origin.x - w / 2, y: y, width: w, height: 5),
                        cornerRadius: 2
                    )
                    let pulse = 0.22 + 0.08 * sin(t * 1.4 + Double(i))
                    context.fill(rect, with: .color(JSRColor.highlight.opacity(pulse)))
                }
            }
        }
        .frame(height: 56)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Routes

enum CollectionRoute: Hashable {
    case newStudio
    case studioProject(UUID)
}

// MARK: - Detail

struct ProjectDetailView: View {
    var project: StudioProject
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var store: ProjectStore
    @EnvironmentObject private var haptics: HapticsClient

    @State private var notesDraft: String = ""
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?
    @State private var stagePulse = false
    @State private var celebrate = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JSRSpace.md) {
                VStack(alignment: .leading, spacing: JSRSpace.xs) {
                    Text(project.isFavorite ? "FAVORITE · LIBRARY" : "LIBRARY")
                        .font(JSRType.motif)
                        .tracking(1.3)
                        .foregroundStyle(JSRColor.highlight)
                    Text(project.title)
                        .font(JSRType.title)
                        .foregroundStyle(JSRStage.label)
                    Text("Updated \(project.updatedAt.formatted(date: .abbreviated, time: .shortened))")
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelSecondary)
                }
                .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))

                StudioStageChrome(pulse: stagePulse && !reduceMotion) {
                    PatternCanvasView(
                        parameters: project.parameters,
                        showChrome: false,
                        kinetic: reduceMotion ? .none : .breathe,
                        reduceMotion: reduceMotion
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .frame(minHeight: 300)
                }
                .modifier(StageCelebrateModifier(active: celebrate, reduceMotion: reduceMotion))
                .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))

                metaPanel
                    .modifier(StageAppearModifier(index: 2, reduceMotion: reduceMotion))

                notesPanel
                    .modifier(StageAppearModifier(index: 3, reduceMotion: reduceMotion))

                VStack(spacing: 10) {
                    NavigationLink {
                        StudioView(project: project)
                    } label: {
                        detailCapsule(title: "Open in Studio", systemImage: "paintbrush.pointed", filled: true)
                    }
                    .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                    .simultaneousGesture(TapGesture().onEnded { haptics.select() })

                    HStack(spacing: 10) {
                        Button {
                            project.isFavorite.toggle()
                            store.save(project)
                            showToast(project.isFavorite ? "Favorited" : "Removed favorite")
                            haptics.select()
                            pulseCelebrate()
                        } label: {
                            detailCapsule(
                                title: project.isFavorite ? "Unfavorite" : "Favorite",
                                systemImage: project.isFavorite ? "star.slash" : "star",
                                filled: false
                            )
                        }
                        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))

                        Button {
                            let copy = store.duplicate(project)
                            showToast("Duplicated")
                            haptics.success()
                            _ = copy
                            pulseCelebrate()
                        } label: {
                            detailCapsule(title: "Duplicate", systemImage: "plus.square.on.square", filled: false)
                        }
                        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                    }
                }
                .modifier(StageAppearModifier(index: 4, reduceMotion: reduceMotion))

                JSRScrollBottomSpacer()
            }
            .padding(JSRSpace.md)
        }
        .scrollIndicators(.hidden)
        .background { JSRStageAtmosphere(tint: JSRColor.secondaryAccent) }
        .preferredColorScheme(.dark)
        .toolbarBackground(JSRColor.ink.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("Preview")
                    .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    project.isFavorite.toggle()
                    store.save(project)
                    pulseCelebrate()
                    haptics.select()
                } label: {
                    Image(systemName: project.isFavorite ? "star.fill" : "star")
                        .foregroundStyle(JSRColor.highlight)
                }
                .accessibilityLabel(project.isFavorite ? "Remove favorite" : "Favorite")
            }
        }
        .overlay(alignment: .bottom) {
            if let toast {
                Text(toast)
                    .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .medium))
                    .foregroundStyle(JSRColor.ink)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(JSRColor.highlight)
                    .clipShape(Capsule())
                    .padding(.bottom, JSRSpace.md)
                    .transition(.opacity)
            }
        }
        .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: toast)
        .onAppear { notesDraft = project.notes }
    }

    private func pulseCelebrate() {
        pulse()
        celebrate = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 420_000_000)
            celebrate = false
        }
    }

    private var metaPanel: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("DETAILS")
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(JSRColor.highlight)
            Text("\(project.parameters.geometry.title) · \(project.parameters.layout.title) · \(project.parameters.symmetryCount)-fold · \(project.parameters.canvasRatio.title)")
                .font(JSRType.callout)
                .foregroundStyle(JSRStage.labelSecondary)
            HStack(spacing: 8) {
                swatch(project.parameters.foreground.color, label: "Foreground")
                swatch(project.parameters.secondary.color, label: "Secondary")
                swatch(project.parameters.background.color, label: "Background")
            }
            Text("Seed \(project.parameters.seed)")
                .font(JSRType.caption.monospacedDigit())
                .foregroundStyle(JSRStage.labelTertiary)
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }

    private var notesPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("NOTES")
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(JSRColor.highlight)
            TextField(
                "Private notes for this composition",
                text: $notesDraft,
                axis: .vertical
            )
            .font(JSRType.body)
            .foregroundStyle(JSRStage.label)
            .lineLimit(3...6)
            .onChange(of: notesDraft) { newValue in
                project.notes = newValue
                store.save(project)
            }
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }

    private func swatch(_ color: Color, label: String) -> some View {
        RoundedRectangle(cornerRadius: 8, style: .continuous)
            .fill(color)
            .frame(height: 32)
            .overlay {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .strokeBorder(JSRStage.chipStroke, lineWidth: 1)
            }
            .accessibilityLabel(label)
    }

    private func detailCapsule(title: String, systemImage: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(JSRFont.serif(size: 15, relativeTo: .callout, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 46)
        .foregroundStyle(filled ? JSRColor.ink : JSRStage.label)
        .background(filled ? JSRColor.highlight : JSRStage.chipFillStrong)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(filled ? Color.clear : JSRStage.chipStroke, lineWidth: 1)
        }
    }

    private func pulse() {
        guard !reduceMotion else { return }
        stagePulse = true
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 220_000_000)
            stagePulse = false
        }
    }

    private func showToast(_ text: String) {
        toast = text
        toastTask?.cancel()
        toastTask = Task { @MainActor in
            try? await Task.sleep(nanoseconds: 1_500_000_000)
            if !Task.isCancelled { toast = nil }
        }
    }
}

#Preview("Empty Library") {
    CollectionView()
        .environmentObject(ProjectStore())
        .environmentObject(HapticsClient())
        }
