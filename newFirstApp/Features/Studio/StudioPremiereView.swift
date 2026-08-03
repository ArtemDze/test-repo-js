import SwiftUI

/// Full-stage ceremonial presentation — curtains, title card, living motif, programme note.
struct StudioPremiereView: View {
    let title: String
    let parameters: PatternParameters
    var kinetic: KineticStyle = .breathe
    let onClose: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(HapticsClient.self) private var haptics

    @State private var curtainOpen: CGFloat = 0
    @State private var canvasOpacity: CGFloat = 0
    @State private var cardOpacity: CGFloat = 0
    @State private var cardOffset: CGFloat = 18
    @State private var glow: CGFloat = 0
    @State private var closing = false

    private var note: ProgrammeNote {
        ProgrammeNoteService.note(for: parameters, title: title)
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                JSRColor.ink.ignoresSafeArea()

                // Living stage
                PatternCanvasView(
                    parameters: parameters,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : kinetic,
                    reduceMotion: reduceMotion
                )
                .padding(JSRSpace.lg)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .opacity(canvasOpacity)
                .scaleEffect(0.96 + 0.04 * curtainOpen)
                .shadow(color: JSRColor.highlight.opacity(0.22 * glow), radius: 36, y: 0)

                // Programme card
                VStack {
                    Spacer()
                    programmeCard
                        .padding(.horizontal, JSRSpace.lg)
                        .padding(.bottom, 28)
                        .opacity(cardOpacity)
                        .offset(y: cardOffset)
                }
                .safeAreaPadding(.horizontal)
                .safeAreaPadding(.bottom)

                // Curtains
                HStack(spacing: 0) {
                    curtainPanel(leading: true, width: geo.size.width)
                    curtainPanel(leading: false, width: geo.size.width)
                }
                .allowsHitTesting(false)
            }
            .contentShape(Rectangle())
            .onTapGesture {
                // Soft dismiss only after curtains are open.
                guard curtainOpen > 0.85, !closing else { return }
                beginClose()
            }
        }
        .safeAreaInset(edge: .top, spacing: 0) {
            premiereTopBar
        }
        .background(JSRColor.ink.ignoresSafeArea())
        .preferredColorScheme(.dark)
        .onAppear { runOpen() }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Premiere of \(title). \(note.headline)")
    }

    private var premiereTopBar: some View {
        HStack(spacing: JSRSpace.sm) {
            Text("PREMIERE")
                .font(JSRType.motif)
                .tracking(1.6)
                .foregroundStyle(JSRColor.highlight.opacity(0.9 * canvasOpacity))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            Spacer(minLength: JSRSpace.sm)
            Button {
                beginClose()
            } label: {
                Text("Close")
                    .font(JSRFont.serif(size: 15, relativeTo: .callout, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(JSRStage.chipFillStrong)
                    .clipShape(Capsule())
                    .overlay {
                        Capsule().strokeBorder(JSRStage.chipStroke, lineWidth: 1)
                    }
            }
            .buttonStyle(.plain)
            .opacity(cardOpacity)
            .fixedSize()
            .accessibilityLabel("Close premiere")
        }
        .padding(.horizontal, JSRSpace.lg)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(JSRColor.ink.opacity(0.001)) // keep hit-testing in the inset region
    }

    private var programmeCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(note.actLabel)
                .font(JSRType.motif)
                .tracking(1.3)
                .foregroundStyle(JSRColor.highlight)
            Text(note.headline)
                .font(JSRFont.serif(size: 22, relativeTo: .title3, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.body)
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(JSRColor.ink.opacity(0.78))
                .background(.ultraThinMaterial.opacity(0.35), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.45), lineWidth: 1)
                }
                .shadow(color: .black.opacity(0.35), radius: 20, y: 10)
        }
        .accessibilityElement(children: .combine)
    }

    private func curtainPanel(leading: Bool, width: CGFloat) -> some View {
        let travel = width * 0.56 * curtainOpen
        return ZStack {
            LinearGradient(
                colors: leading
                    ? [JSRColor.accent.opacity(0.55), JSRColor.ink, JSRColor.ink]
                    : [JSRColor.ink, JSRColor.ink, JSRColor.accent.opacity(0.45)],
                startPoint: leading ? .leading : .trailing,
                endPoint: leading ? .trailing : .leading
            )
            // Soft pleat lines
            HStack(spacing: width * 0.035) {
                ForEach(0..<6, id: \.self) { i in
                    Rectangle()
                        .fill(JSRColor.highlight.opacity(0.04 + Double(i % 2) * 0.02))
                        .frame(width: 1)
                }
            }
            .opacity(0.7)
        }
        .frame(width: width * 0.52)
        .offset(x: leading ? -travel : travel)
        .shadow(color: .black.opacity(0.5), radius: 18, y: 0)
    }

    private func runOpen() {
        haptics.select()
        if reduceMotion {
            curtainOpen = 1
            canvasOpacity = 1
            cardOpacity = 1
            cardOffset = 0
            glow = 1
            return
        }
        withAnimation(.easeInOut(duration: 0.85)) {
            curtainOpen = 1
        }
        withAnimation(.easeOut(duration: 0.55).delay(0.35)) {
            canvasOpacity = 1
            glow = 1
        }
        withAnimation(.spring(response: 0.55, dampingFraction: 0.86).delay(0.55)) {
            cardOpacity = 1
            cardOffset = 0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 700_000_000)
            haptics.success()
        }
    }

    private func beginClose() {
        guard !closing else { return }
        closing = true
        haptics.select()
        if reduceMotion {
            onClose()
            return
        }
        withAnimation(.easeIn(duration: 0.28)) {
            cardOpacity = 0
            cardOffset = 12
            canvasOpacity = 0.35
            glow = 0
        }
        withAnimation(.easeInOut(duration: 0.55).delay(0.12)) {
            curtainOpen = 0
        }
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 720_000_000)
            onClose()
        }
    }
}

// MARK: - Compact programme note (Studio inspector / sheet)

struct ProgrammeNotePanel: View {
    let parameters: PatternParameters
    let title: String

    private var note: ProgrammeNote {
        ProgrammeNoteService.note(for: parameters, title: title)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("PROGRAMME")
                    .font(JSRType.motif)
                    .tracking(1.2)
                    .foregroundStyle(JSRColor.highlight)
                Spacer()
                Text(note.actLabel)
                    .font(JSRType.motif)
                    .tracking(0.8)
                    .foregroundStyle(JSRStage.labelTertiary)
            }
            Text(note.headline)
                .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .fixedSize(horizontal: false, vertical: true)
            Text(note.body)
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

#Preview("Premiere") {
    StudioPremiereView(
        title: MotifCatalog.all[0].title,
        parameters: MotifCatalog.all[0].parameters,
        kinetic: .orbit,
        onClose: {}
    )
    .environment(HapticsClient())
}
