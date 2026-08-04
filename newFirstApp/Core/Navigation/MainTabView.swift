import SwiftUI
import SwiftData

struct MainTabView: View {
    @State private var tab: AppTab = .studio
    @State private var motifToApply: MotifPreset?
    /// Mirrors Studio’s active motif so Atelier “On Stage” stays in sync.
    @State private var stageMotifID: String? = MotifCatalog.all.first?.id
    @Query private var projects: [StudioProject]
    @Query private var settingsList: [AppSettings]
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var motionIntensity: Double {
        MotionIntensity.clamped(settingsList.first?.motionIntensity ?? 1)
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            // Always-ink stage plate — prevents system white flash during crossfades.
            JSRColor.ink
                .ignoresSafeArea()

            // Keep roots alive so switching tabs never remounts heavy screens.
            tabRoot(.studio) {
                NavigationStack { studioRoot }
            }
            tabRoot(.atelier) {
                AtelierHomeView(stageMotifID: stageMotifID) { motif in
                    motifToApply = motif
                    stageMotifID = motif.id
                    selectTab(.studio)
                }
            }
            tabRoot(.experiments) {
                ExperimentsHomeView()
            }
            tabRoot(.collection) {
                CollectionView()
            }
            tabRoot(.profile) {
                ProfileSettingsView {
                    selectTab(.studio)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Inset (not overlay) so ScrollViews / controls never sit under the floating bar —
        // critical on iPad where overlay cropping fails App Review guideline 4.
        .safeAreaInset(edge: .bottom, spacing: 0) {
            JSRStageTabBar(selection: tabBinding)
                .padding(.top, 6)
                .padding(.bottom, 10)
                .background {
                    LinearGradient(
                        colors: [JSRColor.ink.opacity(0), JSRColor.ink.opacity(0.92), JSRColor.ink],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                    .ignoresSafeArea(edges: .bottom)
                    .allowsHitTesting(false)
                }
        }
        .preferredColorScheme(.dark)
        .background(JSRColor.ink.ignoresSafeArea())
        .tint(JSRColor.highlight)
        .environment(\.motionIntensity, motionIntensity)
    }

    /// Binding that animates content with a calm crossfade (tab bar uses its own spring).
    private var tabBinding: Binding<AppTab> {
        Binding(
            get: { tab },
            set: { selectTab($0) }
        )
    }

    private func selectTab(_ next: AppTab) {
        guard tab != next else { return }
        if reduceMotion {
            tab = next
            return
        }
        withAnimation(tabCrossfade) {
            tab = next
        }
    }

    private var tabCrossfade: Animation {
        .easeInOut(duration: 0.34)
    }

    @ViewBuilder
    private func tabRoot<Content: View>(_ id: AppTab, @ViewBuilder content: () -> Content) -> some View {
        let active = tab == id
        content()
            // Flatten each tab into one layer so fade doesn't reveal system chrome mid-blend.
            .compositingGroup()
            .opacity(active ? 1 : 0)
            .offset(y: reduceMotion ? 0 : (active ? 0 : 8))
            .allowsHitTesting(active)
            .accessibilityHidden(!active)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .zIndex(active ? 1 : 0)
            // Soften UIKit nav bar flashes while fading.
            .background(JSRColor.ink.ignoresSafeArea())
    }

    @ViewBuilder
    private var studioRoot: some View {
        if let id = settingsList.first?.lastProjectID,
           let project = projects.first(where: { $0.id == id }) {
            StudioView(project: project, motifToApply: $motifToApply, stageMotifID: $stageMotifID)
        } else {
            StudioView(motifToApply: $motifToApply, stageMotifID: $stageMotifID)
        }
    }
}
