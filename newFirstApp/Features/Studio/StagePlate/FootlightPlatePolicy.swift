import Foundation
import WebKit

enum FootlightPlatePolicy {

    private static let footlight_inPageSchemes: Set<String> = [
        "http", "https", "about", "blob", "data", "file"
    ]

    enum FootlightNavigationVerdict {
        case allowInWebView
        case openExternally(URL)
        case reject
    }

    static func footlight_verdict(for url: URL?, isMainFrame: Bool) -> FootlightNavigationVerdict {
        guard isMainFrame else { return .allowInWebView }
        guard let url else { return .reject }

        let scheme = (url.scheme ?? "").lowercased()
        if footlight_inPageSchemes.contains(scheme) {
            return .allowInWebView
        }
        return .openExternally(url)
    }

    static func footlight_shouldSpawnSheet(targetFrame: WKFrameInfo?) -> Bool {
        guard let targetFrame else { return true }
        return !targetFrame.isMainFrame
    }
}
