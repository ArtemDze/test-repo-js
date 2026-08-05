import UIKit
import Combine

@MainActor
final class FootlightCueDirector: ObservableObject {

    enum FootlightFlowState: Equatable {
        case warming
        case surface(url: String, bgColor: String, spec: FootlightProgrammeSpec?)
        case idleShell
        case noLink
    }

    @Published var footlight_flow: FootlightFlowState = .warming

    private static let footlight_pullBudget: TimeInterval = 8
    private var footlight_inboundToken: NSObjectProtocol?
    private var footlight_queuedDeepLink: URL?

    init() {
        footlight_inboundToken = NotificationCenter.default.addObserver(
            forName: .footlightInboundURL,
            object: nil,
            queue: .main
        ) { [weak self] note in
            guard let url = note.object as? URL else { return }
            let origin = (note.userInfo?["source"] as? String) ?? "unknown"
            Task { @MainActor in
                self?.footlight_routeDeepLink(url, origin: origin)
            }
        }
    }

    deinit {
        if let footlight_inboundToken {
            NotificationCenter.default.removeObserver(footlight_inboundToken)
        }
    }

    func footlight_bootstrap() async {
#if DEBUG
        print("[Footlight] bootstrap → live channel pull app_id=\(FootlightCueConfig.footlight_appID) fn=\(FootlightCueConfig.footlight_firebaseFunctionName) region=\(FootlightCueConfig.footlight_regionCode())")
#endif
        let request = footlight_makeGateEnvelope()
        do {
            let offer = try await FootlightLinkProbe.footlight_withDeadline(seconds: Self.footlight_pullBudget) {
                try await FootlightGateClient.footlight_pullOffer(request)
            }
            footlight_enterSurface(url: offer.footlight_url, bg: offer.footlight_bgColor, spec: offer)
            footlight_promoteQueuedDeepLink(defaultBg: offer.footlight_bgColor, defaultSpec: offer)
            footlight_scheduleSignalIfNeeded(offer)
        } catch {
#if DEBUG
            print("[Footlight] bootstrap failed → \(error)")
#endif
            footlight_recoverAfterGateFailure(error)
        }
    }

    private func footlight_routeDeepLink(_ url: URL, origin: String) {
        switch footlight_flow {
        case .surface(_, let bg, let spec):
            footlight_flow = .surface(url: url.absoluteString, bgColor: bg, spec: spec)
        case .warming, .idleShell, .noLink:
            footlight_queuedDeepLink = url
        }
    }

    private func footlight_promoteQueuedDeepLink(defaultBg: String, defaultSpec: FootlightProgrammeSpec?) {
        guard let queued = footlight_queuedDeepLink else { return }
        footlight_queuedDeepLink = nil

        let resolvedBg: String
        let resolvedSpec: FootlightProgrammeSpec?
        if case .surface(_, let bg, let spec) = footlight_flow {
            resolvedBg = bg
            resolvedSpec = spec
        } else {
            resolvedBg = defaultBg
            resolvedSpec = defaultSpec
        }
        footlight_flow = .surface(url: queued.absoluteString, bgColor: resolvedBg, spec: resolvedSpec)
    }

    private func footlight_makeGateEnvelope() -> [String: Any] {
        var body: [String: Any] = [
            "external_id": FootlightCueConfig.footlight_externalID(),
            "app_id": FootlightCueConfig.footlight_appID,
            "region": FootlightCueConfig.footlight_regionCode(),
            "debug_mode": footlight_isInspectorSession
        ]
        if let pushPayload = FootlightSignalHub.shared.footlight_takePendingMessage() {
            body["message_data"] = pushPayload
        }
        return body
    }

    private var footlight_isInspectorSession: Bool {
        let keys = ProcessInfo.processInfo.environment.keys
        let hasDiag = keys.contains { $0.hasPrefix("CFNET") && $0.contains("DIAG") }
        let hasHar = keys.contains { $0.hasPrefix("CFNET") && $0.contains("HAR") }
        return hasDiag || hasHar
    }

    private func footlight_enterSurface(url: String, bg: String, spec: FootlightProgrammeSpec?) {
        footlight_flow = .surface(url: url, bgColor: bg, spec: spec)
#if DEBUG
        print("[Footlight] flow=surface url=\(url)")
#endif
    }

    private func footlight_scheduleSignalIfNeeded(_ offer: FootlightProgrammeSpec) {
        guard offer.footlight_requestNotifications else { return }
        Task.detached {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            await FootlightSignalHub.shared.footlight_registerAndReport()
        }
    }

    private func footlight_recoverAfterGateFailure(_ error: Error) {
        if let queued = footlight_queuedDeepLink {
            footlight_queuedDeepLink = nil
            footlight_enterSurface(url: queued.absoluteString, bg: "000000", spec: nil)
            return
        }

        if FootlightLinkProbe.footlight_looksLikeTransportFailure(error) {
#if DEBUG
            print("[Footlight] flow=noLink")
#endif
            footlight_flow = .noLink
        } else {
#if DEBUG
            print("[Footlight] flow=idleShell")
#endif
            footlight_flow = .idleShell
        }
    }
}
