import SwiftUI

/// Global stage motion amplitude (0…1) from Profile → Stage Feel.
private struct MotionIntensityKey: EnvironmentKey {
    static let defaultValue: Double = 1
}

extension EnvironmentValues {
    var motionIntensity: Double {
        get { self[MotionIntensityKey.self] }
        set { self[MotionIntensityKey.self] = newValue }
    }
}

enum MotionIntensity {
    /// Below this, kinetic styles effectively pause (still reads as intentional stillness).
    static let pauseThreshold: Double = 0.06

    static func clamped(_ value: Double) -> Double {
        min(1, max(0, value))
    }
}
