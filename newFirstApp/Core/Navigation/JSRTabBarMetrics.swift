import CoreGraphics
import SwiftUI

enum JSRTabBarMetrics {
    /// Space reserved for the floating tab bar + home indicator (explicit — do not rely on inset inheritance).
    static let barClearance: CGFloat = 118
    /// Extra air after the last item once the bar is cleared.
    static let scrollTail: CGFloat = 28
    /// Use this on scroll content bottoms across main tabs.
    static var scrollBottom: CGFloat { barClearance + scrollTail }
    /// Studio needs more room for the inspector / system block.
    static var studioScrollBottom: CGFloat { barClearance + 120 }
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
