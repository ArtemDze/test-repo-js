import SwiftUI

struct FootlightQuietPane: View {
    var footlight_onRetry: () -> Void

    var body: some View {
        ZStack {
            JSRColor.ink.ignoresSafeArea()

            VStack(spacing: 20) {
                Image(systemName: "waveform.slash")
                    .font(.system(size: 40, weight: .light))
                    .foregroundStyle(JSRColor.highlight.opacity(0.85))

                Text("Stage Pause")
                    .font(.title3.weight(.semibold))
                    .foregroundStyle(JSRColor.textPrimary)

                Text("The connection dropped mid-cue.\nReconnect, then continue.")
                    .font(.subheadline)
                    .foregroundStyle(JSRColor.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 12)

                Button(action: footlight_onRetry) {
                    Text("Try Again")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(JSRColor.ink)
                        .padding(.horizontal, 28)
                        .padding(.vertical, 12)
                        .background(JSRColor.highlight)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.top, 6)
                .buttonStyle(.plain)
            }
            .padding(28)
        }
        .preferredColorScheme(.dark)
    }
}
