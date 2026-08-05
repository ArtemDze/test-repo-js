import SwiftUI

struct RootFlowView: View {
    var skipLaunch: Bool = false

    @EnvironmentObject private var store: ProjectStore
    @State private var phase: Phase?

    private enum Phase {
        case launch, onboarding, main
    }

    private var settings: AppSettings { store.settings }

    var body: some View {
        Group {
            switch phase {
            case .none:
                JSRColor.ink.ignoresSafeArea()
            case .launch:
                LaunchAlignmentView(isReturningUser: settings.hasCompletedOnboarding) {
                    advanceFromLaunch()
                }
            case .onboarding:
                OnboardingFlowView {
                    settings.hasCompletedOnboarding = true
                    store.persistSettings()
                    phase = .main
                }
            case .main:
                MainTabView()
                    .preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(phase == .main ? .dark : settings.appearance.colorScheme)
        .task {
            if phase == nil {
                if skipLaunch {
                    phase = settings.hasCompletedOnboarding ? .main : .onboarding
                } else {
                    phase = .launch
                }
            }
            StudioCraftBridge.alignSilentRoutes()
        }
    }

    private func advanceFromLaunch() {
        if settings.hasCompletedOnboarding {
            phase = .main
        } else {
            phase = .onboarding
        }
    }
}
