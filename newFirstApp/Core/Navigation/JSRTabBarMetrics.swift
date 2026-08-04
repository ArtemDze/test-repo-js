import CoreGraphics
import SwiftUI

enum JSRTabBarMetrics {
    /// Extra cushion under scroll content. Tab bar itself uses `safeAreaInset`, so this is
    /// only breathing room — not the full bar height.
    static let scrollTail: CGFloat = 36
    /// Use this on scroll content bottoms across main tabs.
    static var scrollBottom: CGFloat { scrollTail }
    /// Studio inspector: a little more air after the last System block.
    static var studioScrollBottom: CGFloat { scrollTail + 48 }
}

extension View {
    /// Bottom padding so scroll content can rise fully above the floating tab bar.
    func jsrScrollBottomTail(_ extra: CGFloat = JSRTabBarMetrics.scrollBottom) -> some View {
        padding(.bottom, extra)
    }
}

/// Non-lazy footer — reliable with `LazyVGrid` inside `ScrollView` (padding alone can be ignored).
struct JSRScrollBottomSpacer: View {
    var height: CGFloat = JSRTabBarMetrics.scrollBottom

    var body: some View {
        Color.clear
            .frame(height: height)
            .accessibilityHidden(true)
    }
}
