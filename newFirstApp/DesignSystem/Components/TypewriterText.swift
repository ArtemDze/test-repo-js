import SwiftUI

/// Smooth text reveal: full string is always laid out (no reflow).
/// Only a soft mask / fade animates — nothing jumps.
struct TypewriterText: View {
    let fullText: String
    var font: Font = JSRType.display
    var foreground: Color = JSRColor.textPrimary
    var alignment: TextAlignment = .center
    var duration: TimeInterval = 0.6
    var startDelay: TimeInterval = 0.04
    var showCaret: Bool = false
    var reduceMotion: Bool = false
    var isActive: Bool = true
    var onComplete: (() -> Void)? = nil

    @State private var progress: CGFloat = 0
    @State private var finished = false
    @State private var task: Task<Void, Never>?
    @State private var didComplete = false

    private var frameAlignment: Alignment {
        alignment == .leading ? .leading : (alignment == .trailing ? .trailing : .center)
    }

    var body: some View {
        Text(fullText)
            .font(font)
            .foregroundStyle(foreground)
            .multilineTextAlignment(alignment)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
            .modifier(SoftTextReveal(progress: reduceMotion || finished ? 1 : (isActive ? progress : 0)))
            .overlay(alignment: .bottom) {
                if showCaret && isActive && !finished && !reduceMotion {
                    Capsule()
                        .fill(foreground.opacity(0.35 + 0.35 * Double(progress)))
                        .frame(width: 22 + 10 * progress, height: 1.5)
                        .padding(.bottom, -2)
                        .opacity(progress > 0.08 && progress < 0.98 ? 1 : 0)
                }
            }
            .accessibilityLabel(fullText)
            .onAppear { startIfNeeded() }
            .onDisappear { task?.cancel() }
            .onChange(of: fullText) { _ in resetAndStart() }
            .onChange(of: isActive) { active in
                if active { startIfNeeded() }
            }
    }

    private func resetAndStart() {
        task?.cancel()
        progress = 0
        finished = false
        didComplete = false
        startIfNeeded()
    }

    private func startIfNeeded() {
        guard isActive else { return }
        task?.cancel()

        if reduceMotion || fullText.isEmpty {
            progress = 1
            finished = true
            completeOnce()
            return
        }

        if finished {
            progress = 1
            return
        }

        task = Task { @MainActor in
            progress = 0
            try? await Task.sleep(nanoseconds: UInt64(startDelay * 1_000_000_000))
            guard !Task.isCancelled else { return }

            let run = min(duration, 0.35 + Double(fullText.count) * 0.008)
            withAnimation(.easeInOut(duration: run)) {
                progress = 1
            }

            try? await Task.sleep(nanoseconds: UInt64((run + 0.02) * 1_000_000_000))
            guard !Task.isCancelled else { return }

            progress = 1
            finished = true
            completeOnce()
        }
    }

    private func completeOnce() {
        guard !didComplete else { return }
        didComplete = true
        onComplete?()
    }
}

/// Animatable reveal — SwiftUI interpolates every frame without rebuilding glyphs.
private struct SoftTextReveal: ViewModifier, Animatable {
    var progress: CGFloat

    var animatableData: CGFloat {
        get { progress }
        set { progress = newValue }
    }

    func body(content: Content) -> some View {
        let p = min(max(progress, 0), 1)
        let ease = p * p * (3 - 2 * p)

        content
            .opacity(ease)
            .blur(radius: (1 - ease) * 1.6)
            .offset(y: (1 - ease) * 4)
            .mask {
                GeometryReader { geo in
                    // Soft leading edge — reads like ink settling, never reflows text.
                    Rectangle()
                        .fill(
                            LinearGradient(
                                stops: [
                                    .init(color: .black, location: 0),
                                    .init(color: .black, location: max(0, ease - 0.04)),
                                    .init(color: .black.opacity(0.35), location: min(1, ease + 0.08)),
                                    .init(color: .clear, location: min(1, ease + 0.22))
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geo.size.width, height: geo.size.height)
                }
            }
    }
}
