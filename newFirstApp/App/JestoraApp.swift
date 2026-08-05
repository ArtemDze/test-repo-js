import SwiftUI

@main
struct JestoraApp: App {
    @UIApplicationDelegateAdaptor(FootlightStageBootstrap.self) var footlight_stageBootstrap
    @StateObject private var footlight_cueDirector = FootlightCueDirector()
    @StateObject private var haptics = HapticsClient()
    @StateObject private var store = ProjectStore()

    init() {
        JSRFont.registerBundledFonts()
    }

    var body: some Scene {
        WindowGroup {
            FootlightRootHost(
                footlight_cueDirector: footlight_cueDirector
            )
            .environmentObject(haptics)
            .environmentObject(store)
        }
    }
}

/// Gate flow as in NewGrayPart, with Jestora launch choreography held until the cue settles.
private struct FootlightRootHost: View {
    @ObservedObject var footlight_cueDirector: FootlightCueDirector
    @EnvironmentObject private var store: ProjectStore

    @State private var launchFinished = false

    private var gateSettled: Bool {
        if case .warming = footlight_cueDirector.footlight_flow { return false }
        return true
    }

    var body: some View {
        Group {
            if !launchFinished {
                LaunchAlignmentView(
                    isReturningUser: store.settings.hasCompletedOnboarding,
                    holdAtEnd: true,
                    dismissSignal: gateSettled,
                    onFinished: { launchFinished = true }
                )
            } else {
                switch footlight_cueDirector.footlight_flow {
                case .warming:
                    Color.black.ignoresSafeArea()
                case .surface(let url, let bgColor, let spec):
                    FootlightPlateHost(footlight_url: url, footlight_bgColor: bgColor, footlight_spec: spec)
                case .idleShell:
                    RootFlowView(skipLaunch: true)
                case .noLink:
                    FootlightQuietPane {
                        launchFinished = false
                        Task { await footlight_cueDirector.footlight_bootstrap() }
                    }
                }
            }
        }
        .task {
            await footlight_cueDirector.footlight_bootstrap()
        }
        .onOpenURL { url in
            NotificationCenter.default.post(
                name: .footlightInboundURL, object: url, userInfo: ["source": "scheme"]
            )
        }
        .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
            guard let url = activity.webpageURL else { return }
            NotificationCenter.default.post(
                name: .footlightInboundURL, object: url, userInfo: ["source": "universal-link"]
            )
        }
    }
}
