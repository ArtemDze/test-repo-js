import UIKit
import WebKit

enum FootlightPresentHub {

    static func footlight_foremost(anchor: UIViewController, webView: WKWebView?) -> UIViewController {
        var cursor: UIViewController =
            webView?.window?.rootViewController
            ?? UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first(where: \.isKeyWindow)?
                .rootViewController
            ?? anchor

        while let next = cursor.presentedViewController, !next.isBeingDismissed {
            cursor = next
        }
        return cursor
    }

    static func footlight_present(_ controller: UIViewController, anchor: UIViewController, webView: WKWebView?, animated: Bool = true) {
        DispatchQueue.main.async {
            footlight_foremost(anchor: anchor, webView: webView).present(controller, animated: animated)
        }
    }
}
