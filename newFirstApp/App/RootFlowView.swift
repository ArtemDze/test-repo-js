import SwiftUI
import SwiftData

struct RootFlowView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settingsList: [AppSettings]
    @State private var phase: Phase = .launch

    private enum Phase {
        case launch, onboarding, main
    }

    private var settings: AppSettings {
        if let s = settingsList.first { return s }
        let created = AppSettings()
        modelContext.insert(created)
        return created
    }

    var body: some View {
        Group {
            switch phase {
            case .launch:
                LaunchAlignmentView(isReturningUser: settings.hasCompletedOnboarding) {
                    advanceFromLaunch()
                }
            case .onboarding:
                OnboardingFlowView {
                    settings.hasCompletedOnboarding = true
                    try? modelContext.save()
                    phase = .main
                }
            case .main:
                MainTabView()
                    // Stage chrome is always ink — avoid system light plate flashing behind tabs.
                    .preferredColorScheme(.dark)
            }
        }
        .preferredColorScheme(phase == .main ? .dark : settings.appearance.colorScheme)
        .task {
            if settingsList.isEmpty {
                modelContext.insert(AppSettings())
                try? modelContext.save()
            }
        }
    }

    private func advanceFromLaunch() {
        // Returning users: skip prolonged ceremony after first alignment ever.
        if settings.hasCompletedOnboarding {
            phase = .main
        } else {
            phase = .onboarding
        }
    }
}
