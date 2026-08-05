import WebKit

@MainActor
enum FootlightPlateRuntime {
    static let footlight_sharedPool = WKProcessPool()
    static let footlight_scriptHub = WKUserContentController()
    private static var footlight_standby: WKWebView?

    static func footlight_buildConfiguration() -> WKWebViewConfiguration {
        let cfg = WKWebViewConfiguration()
        cfg.processPool = footlight_sharedPool
        cfg.websiteDataStore = .default()
        cfg.userContentController = footlight_scriptHub
        cfg.defaultWebpagePreferences.allowsContentJavaScript = true
        cfg.allowsInlineMediaPlayback = true
        cfg.allowsPictureInPictureMediaPlayback = true
        cfg.allowsAirPlayForMediaPlayback = true
        cfg.mediaTypesRequiringUserActionForPlayback = []
        cfg.preferences.javaScriptCanOpenWindowsAutomatically = true
        if #available(iOS 15.4, *) {
            cfg.preferences.isElementFullscreenEnabled = true
        }
        return cfg
    }

    @discardableResult
    static func footlight_prime(with url: URL? = nil) -> WKWebView {
        let view = WKWebView(frame: .zero, configuration: footlight_buildConfiguration())
        if let url { view.load(URLRequest(url: url)) }
        footlight_standby = view
        return view
    }

    static func footlight_consumeStandby() -> WKWebView? {
        defer { footlight_standby = nil }
        return footlight_standby
    }

    static func footlight_dropStandby() {
        footlight_standby = nil
    }
}
