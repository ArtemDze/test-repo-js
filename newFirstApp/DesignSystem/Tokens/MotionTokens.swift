import SwiftUI

enum JSRMotion {
    static let launchDuration: TimeInterval = 5.0
    static let launchReturning: TimeInterval = 5.0
    static let immediate = Animation.easeOut(duration: 0.12)
    static let snappy = Animation.spring(response: 0.30, dampingFraction: 0.84)
    static let fluid = Animation.spring(response: 0.45, dampingFraction: 0.88)
    static let curtain = Animation.easeInOut(duration: 0.42)
    static let align = Animation.easeInOut(duration: 0.55)
    static let echo = Animation.spring(response: 0.52, dampingFraction: 0.78)
    static let morph = Animation.easeInOut(duration: 0.55)

    static func preferred(_ animation: Animation, reduceMotion: Bool) -> Animation? {
        reduceMotion ? nil : animation
    }
}
