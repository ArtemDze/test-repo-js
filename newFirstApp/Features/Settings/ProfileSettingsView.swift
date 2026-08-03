import SwiftUI
import SwiftData

struct ProfileSettingsView: View {
    /// Switches to the shared Studio tab root (same instance as the Studio tab).
    var onOpenStudio: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(ProjectStore.self) private var store
    @Environment(HapticsClient.self) private var haptics
    @Query private var settingsList: [AppSettings]
    @Query private var projects: [StudioProject]

    @State private var showClearConfirm = false
    @State private var showOnboarding = false
    @State private var toast: String?
    @State private var toastTask: Task<Void, Never>?

    private var settings: AppSettings {
        if let s = settingsList.first { return s }
        let created = AppSettings()
        modelContext.insert(created)
        return created
    }

    private var appVersion: String {
        let short = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(short) (\(build))"
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: JSRSpace.lg) {
                    header
                        .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))

                    studioDefaultsPanel
                        .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))

                    stageFeelPanel
                        .modifier(StageAppearModifier(index: 2, reduceMotion: reduceMotion))

                    craftPanel
                        .modifier(StageAppearModifier(index: 3, reduceMotion: reduceMotion))

                    archivePanel
                        .modifier(StageAppearModifier(index: 4, reduceMotion: reduceMotion))

                    aboutPanel
                        .modifier(StageAppearModifier(index: 5, reduceMotion: reduceMotion))

                    JSRScrollBottomSpacer()
                }
                .padding(.horizontal, JSRSpace.md)
                .padding(.top, JSRSpace.sm)
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
                    Text("Profile")
                        .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
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
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .animation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion), value: toast)
            .onAppear {
                haptics.isEnabled = settings.hapticsEnabled
            }
            .alert("Clear Library?", isPresented: $showClearConfirm) {
                Button("Clear Library", role: .destructive) {
                    store.clearAll(projects: projects, context: modelContext)
                    settings.lastProjectID = nil
                    settings.completedPromptDates = []
                    persist()
                    showToast("Library cleared")
                    haptics.warning()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Removes saved compositions from this device. Studio settings stay as they are.")
            }
            .fullScreenCover(isPresented: $showOnboarding) {
                OnboardingFlowView {
                    settings.hasCompletedOnboarding = true
                    persist()
                    showOnboarding = false
                }
            }
        }
    }

    // MARK: Header

    private var header: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: JSRSpace.xs) {
                Text("PROFILE")
                    .font(JSRType.motif)
                    .tracking(1.4)
                    .foregroundStyle(JSRColor.highlight)
                Text("Stage Preferences")
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                Text("Tune how \(AppBrand.name) looks and feels while you craft.")
                    .font(JSRType.body)
                    .foregroundStyle(JSRStage.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 300, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            ProfileHeaderOrnament(reduceMotion: reduceMotion)
                .frame(width: 108)
                .opacity(0.9)
        }
    }

    // MARK: Panels

    private var studioDefaultsPanel: some View {
        ProfilePanel(title: "STUDIO DEFAULTS", subtitle: "Applied when you open a fresh stage.") {
            ProfileChipPicker(
                title: "Canvas ratio",
                items: CanvasRatio.allCases.map { ($0, $0.title) },
                selection: Binding(
                    get: { settings.defaultRatio },
                    set: { settings.defaultRatio = $0; persist(); haptics.select() }
                ),
                reduceMotion: reduceMotion
            )
        }
    }

    private var stageFeelPanel: some View {
        ProfilePanel(title: "STAGE FEEL", subtitle: "Haptics and motion for the craft.") {
            ProfileToggleRow(
                title: "Haptic feedback",
                subtitle: "Light taps when tools respond.",
                isOn: Binding(
                    get: { settings.hapticsEnabled },
                    set: {
                        settings.hapticsEnabled = $0
                        haptics.isEnabled = $0
                        persist()
                        if $0 { haptics.select() }
                    }
                )
            )

            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Motion intensity")
                            .font(JSRFont.serif(size: 16, relativeTo: .body, weight: .semibold))
                            .foregroundStyle(JSRStage.label)
                        Text(motionLabel)
                            .font(JSRType.caption)
                            .foregroundStyle(JSRStage.labelSecondary)
                    }
                    Spacer()
                    Text("\(Int((settings.motionIntensity * 100).rounded()))%")
                        .font(JSRType.caption.monospacedDigit())
                        .foregroundStyle(JSRColor.highlight)
                }

                // Live preview of how lively the stage feels.
                PatternCanvasView(
                    parameters: MotifCatalog.all[0].parameters,
                    showChrome: false,
                    kinetic: reduceMotion || settings.motionIntensity < 0.08 ? .none : .breathe,
                    reduceMotion: reduceMotion
                )
                .frame(maxWidth: .infinity)
                .frame(height: 96)
                .opacity(0.55 + settings.motionIntensity * 0.45)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.35), lineWidth: 1)
                }
                .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: settings.motionIntensity)

                Slider(
                    value: Binding(
                        get: { settings.motionIntensity },
                        set: { settings.motionIntensity = $0; persist() }
                    ),
                    in: 0...1,
                    onEditingChanged: { editing in
                        if !editing { haptics.select() }
                    }
                )
                .tint(JSRColor.highlight)
                .accessibilityLabel("Motion intensity")
                .accessibilityValue(motionLabel)

                HStack {
                    Text("Still")
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelTertiary)
                    Spacer()
                    Text("Full")
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelTertiary)
                }
            }
            .padding(.top, 4)
        }
    }

    private var motionLabel: String {
        switch settings.motionIntensity {
        case ..<0.2: "Quiet stage"
        case ..<0.55: "Measured"
        case ..<0.85: "Lively"
        default: "Full ceremony"
        }
    }

    private var craftPanel: some View {
        ProfilePanel(title: "CRAFT AIDS", subtitle: "Shortcuts for focused work.") {
            Button {
                haptics.select()
                onOpenStudio?()
            } label: {
                ProfileNavRow(
                    title: "Open Studio",
                    subtitle: "Return to the Studio stage.",
                    systemImage: "paintbrush.pointed"
                )
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))

            Text("\(AppBrand.name) respects system Dynamic Type, VoiceOver labels on studio controls, and Reduce Motion for launch and transitions.")
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelTertiary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var archivePanel: some View {
        ProfilePanel(title: "LIBRARY", subtitle: "Compositions saved on this device.") {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Compositions")
                        .font(JSRFont.serif(size: 16, relativeTo: .body, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                    Text("In Library")
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelSecondary)
                }
                Spacer()
                Text("\(projects.count)")
                    .font(JSRFont.serif(size: 28, relativeTo: .title, weight: .semibold))
                    .foregroundStyle(JSRColor.highlight)
                    .contentTransition(.numericText())
            }
            .accessibilityElement(children: .combine)

            Button {
                settings.hasCompletedOnboarding = false
                persist()
                showOnboarding = true
                haptics.select()
            } label: {
                ProfileActionRow(
                    title: "Replay prologue",
                    subtitle: "Walk through the opening acts again.",
                    systemImage: "sparkles.rectangle.stack",
                    destructive: false
                )
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))

            Button {
                showClearConfirm = true
            } label: {
                ProfileActionRow(
                    title: "Clear Library",
                    subtitle: "Remove all saved compositions.",
                    systemImage: "trash",
                    destructive: true
                )
            }
            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
            .disabled(projects.isEmpty)
            .opacity(projects.isEmpty ? 0.45 : 1)
        }
    }

    private var aboutPanel: some View {
        ProfilePanel(title: "ABOUT", subtitle: nil) {
            HStack(alignment: .top, spacing: 14) {
                PatternCanvasView(
                    parameters: MotifCatalog.all[3].parameters,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : .orbit,
                    reduceMotion: reduceMotion
                )
                .frame(width: 72, height: 72)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.4), lineWidth: 1)
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(AppBrand.name)
                        .font(JSRFont.serif(size: 22, relativeTo: .title3, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                    Text(AppBrand.studioLine)
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelSecondary)
                    Text("Version \(appVersion)")
                        .font(JSRType.caption.monospacedDigit())
                        .foregroundStyle(JSRStage.labelTertiary)
                }
                .accessibilityElement(children: .combine)
                .accessibilityLabel(AppBrand.fullName)
            }

            Text("\(AppBrand.fullName) — a theatrical studio for geometric composition: symmetry, illusion, and color on your stage.")
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    // MARK: Helpers

    private func persist() {
        try? modelContext.save()
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

// MARK: - Chrome

private struct ProfilePanel<Content: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.md) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JSRType.motif)
                    .tracking(1.3)
                    .foregroundStyle(JSRColor.highlight)
                if let subtitle {
                    Text(subtitle)
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelTertiary)
                }
            }
            content
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

private struct ProfileToggleRow: View {
    let title: String
    let subtitle: String
    @Binding var isOn: Bool

    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(JSRFont.serif(size: 16, relativeTo: .body, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                Text(subtitle)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
            }
        }
        .tint(JSRColor.highlight)
        .padding(.vertical, 4)
        .accessibilityLabel(title)
        .accessibilityHint(subtitle)
    }
}

private struct ProfileChipPicker<T: Hashable & Identifiable>: View {
    let title: String
    let items: [(T, String)]
    @Binding var selection: T
    var reduceMotion: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.0.id) { item, label in
                        let selected = selection == item
                        Button {
                            withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                                selection = item
                            }
                        } label: {
                            Text(label)
                                .font(JSRFont.serif(size: 14, relativeTo: .caption, weight: .semibold))
                                .foregroundStyle(selected ? JSRColor.ink : JSRStage.label)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(selected ? JSRColor.highlight : JSRStage.chipFillStrong)
                                .clipShape(Capsule())
                                .overlay {
                                    Capsule()
                                        .strokeBorder(
                                            selected ? Color.clear : JSRStage.chipStroke,
                                            lineWidth: 1
                                        )
                                }
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(selected ? .isSelected : [])
                    }
                }
            }
        }
    }
}

private struct ProfileNavRow: View {
    let title: String
    let subtitle: String
    let systemImage: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(JSRColor.ink)
                .frame(width: 36, height: 36)
                .background(JSRColor.highlight)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(JSRFont.serif(size: 16, relativeTo: .body, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                Text(subtitle)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(JSRStage.labelTertiary)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(JSRStage.chipFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(JSRStage.chipStroke, lineWidth: 1)
                }
        }
    }
}

private struct ProfileActionRow: View {
    let title: String
    let subtitle: String
    let systemImage: String
    var destructive: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: systemImage)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(destructive ? JSRColor.danger : JSRColor.highlight)
                .frame(width: 36, height: 36)
                .background(
                    (destructive ? JSRColor.danger : JSRColor.highlight).opacity(0.14)
                )
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(JSRFont.serif(size: 16, relativeTo: .body, weight: .semibold))
                    .foregroundStyle(destructive ? JSRColor.danger : JSRStage.label)
                Text(subtitle)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
            }
            Spacer()
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(JSRStage.chipFill)
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(
                            destructive ? JSRColor.danger.opacity(0.35) : JSRStage.chipStroke,
                            lineWidth: 1
                        )
                }
        }
    }
}

private struct ProfileHeaderOrnament: View {
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let c = CGPoint(x: size.width * 0.7, y: size.height * 0.42)
                for i in 0..<6 {
                    let a = Double(i) / 6.0 * .pi * 2 + t * 0.15
                    let r: CGFloat = 16 + CGFloat(i % 3) * 5
                    let p = CGPoint(x: c.x + CGFloat(cos(a)) * r, y: c.y + CGFloat(sin(a)) * r * 0.75)
                    var path = Path()
                    path.addEllipse(in: CGRect(x: p.x - 2.2, y: p.y - 2.2, width: 4.4, height: 4.4))
                    context.fill(path, with: .color(JSRColor.highlight.opacity(0.28 + Double(i % 2) * 0.08)))
                }
            }
        }
        .frame(height: 56)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

#Preview {
    ProfileSettingsView()
        .environment(ProjectStore())
        .environment(HapticsClient())
        .modelContainer(for: [StudioProject.self, AppSettings.self], inMemory: true)
}
