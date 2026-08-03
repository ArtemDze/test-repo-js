import SwiftUI

/// Shared theatrical stage backdrop — ink + footlight + vignette (onboarding / studio).
struct JSRStageAtmosphere: View {
    var tint: Color = JSRColor.highlight
    var intensity: Double = 1

    var body: some View {
        ZStack {
            JSRColor.ink

            RadialGradient(
                colors: [
                    tint.opacity(0.20 * intensity),
                    JSRColor.accent.opacity(0.08 * intensity),
                    .clear
                ],
                center: UnitPoint(x: 0.5, y: 0.28),
                startRadius: 12,
                endRadius: 380
            )
            .blendMode(.plusLighter)

            RadialGradient(
                colors: [.clear, .black.opacity(0.55 * intensity)],
                center: UnitPoint(x: 0.5, y: 0.35),
                startRadius: 120,
                endRadius: 620
            )
        }
        .ignoresSafeArea()
    }
}
