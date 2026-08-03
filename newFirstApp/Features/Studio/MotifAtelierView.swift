import SwiftUI

// MARK: - Shared stage motif card

struct StageMotifCard: View {
    let motif: MotifPreset
    var selected: Bool = false
    var kinetic: KineticStyle = .breathe
    var reduceMotion: Bool = false
    var showsOpenHint: Bool = false
    var featured: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: featured ? 12 : 10) {
            ZStack(alignment: .topTrailing) {
                PatternCanvasView(
                    parameters: motif.parameters,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : kinetic,
                    reduceMotion: reduceMotion
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(featured ? 1.15 : 1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: featured ? 18 : 14, style: .continuous))

                if featured {
                    badge("ON STAGE", ink: selected)
                } else if selected {
                    badge("ACTIVE", ink: true)
                }
            }
            .overlay {
                RoundedRectangle(cornerRadius: featured ? 18 : 14, style: .continuous)
                    .strokeBorder(borderGradient, lineWidth: selected || featured ? 1.6 : 1)
            }
            .shadow(
                color: (selected || featured) ? JSRColor.highlight.opacity(0.22) : .clear,
                radius: 12,
                y: 0
            )

            Text(motif.title)
                .font(JSRFont.serif(size: featured ? 22 : 18, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .lineLimit(1)

            Text(motif.subtitle)
                .font(JSRType.caption)
                .foregroundStyle(JSRStage.labelSecondary)
                .lineLimit(featured ? 3 : 2)
                .fixedSize(horizontal: false, vertical: true)

            if showsOpenHint {
                HStack(spacing: 4) {
                    Text(featured && selected ? "Now on the Studio stage" : (featured ? "Begin on this motif" : "Open in Studio"))
                        .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
                    Image(systemName: featured && selected ? "checkmark" : "arrow.up.right")
                        .font(.system(size: 10, weight: .semibold))
                }
                .foregroundStyle(JSRColor.highlight.opacity(0.95))
            }
        }
        .padding(featured ? 14 : 12)
        .background {
            RoundedRectangle(cornerRadius: featured ? 22 : 18, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: featured ? 22 : 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    JSRColor.highlight.opacity(featured ? 0.10 : 0.04),
                                    .clear
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                .overlay {
                    RoundedRectangle(cornerRadius: featured ? 22 : 18, style: .continuous)
                        .strokeBorder(
                            selected || featured ? JSRColor.highlight.opacity(0.5) : JSRStage.separator,
                            lineWidth: 1
                        )
                }
                .shadow(color: .black.opacity(0.3), radius: featured ? 20 : 14, y: 8)
        }
    }

    private var borderGradient: LinearGradient {
        LinearGradient(
            colors: selected || featured
                ? [JSRColor.highlight, JSRColor.highlight.opacity(0.4)]
                : [JSRColor.highlight.opacity(0.42), JSRColor.accent.opacity(0.22)],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func badge(_ text: String, ink: Bool) -> some View {
        Text(text)
            .font(JSRType.motif)
            .tracking(1.0)
            .foregroundStyle(ink ? JSRColor.ink : JSRColor.highlight)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(ink ? JSRColor.highlight : JSRColor.ink.opacity(0.72))
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(JSRColor.highlight.opacity(ink ? 0 : 0.45), lineWidth: 1)
            }
            .padding(8)
    }
}

// MARK: - Lift / press / pointer affordance

struct StageLiftButtonStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.975 : 1)
            .brightness(configuration.isPressed ? 0.04 : 0)
            .shadow(
                color: JSRColor.highlight.opacity(configuration.isPressed ? 0.28 : 0),
                radius: configuration.isPressed ? 16 : 0,
                y: configuration.isPressed ? 0 : 0
            )
            .animation(.easeOut(duration: 0.16), value: configuration.isPressed)
    }
}

/// Brief gold pulse after Save / Pin / Favorite.
struct StageCelebrateModifier: ViewModifier {
    var active: Bool
    var reduceMotion: Bool

    func body(content: Content) -> some View {
        content
            .scaleEffect(active && !reduceMotion ? 1.035 : 1)
            .brightness(active ? 0.04 : 0)
            .shadow(
                color: JSRColor.highlight.opacity(active && !reduceMotion ? 0.38 : 0),
                radius: active ? 18 : 0,
                y: 0
            )
            .animation(JSRMotion.preferred(JSRMotion.echo, reduceMotion: reduceMotion), value: active)
    }
}

/// Staggered entrance for motif cards.
struct StageAppearModifier: ViewModifier {
    let index: Int
    let reduceMotion: Bool
    @State private var shown = false

    func body(content: Content) -> some View {
        content
            .opacity(shown || reduceMotion ? 1 : 0)
            .offset(y: shown || reduceMotion ? 0 : 14)
            .onAppear {
                guard !reduceMotion else {
                    shown = true
                    return
                }
                withAnimation(
                    .spring(response: 0.5, dampingFraction: 0.86)
                    .delay(0.04 + Double(index) * 0.045)
                ) {
                    shown = true
                }
            }
    }
}

// MARK: - Atelier header ornament

struct AtelierHeaderOrnament: View {
    var reduceMotion: Bool

    var body: some View {
        TimelineView(.animation(minimumInterval: 1 / 30, paused: reduceMotion)) { timeline in
            let t = timeline.date.timeIntervalSinceReferenceDate
            Canvas { context, size in
                let center = CGPoint(x: size.width * 0.82, y: size.height * 0.35)
                for i in 0..<7 {
                    let a = Double(i) / 7.0 * .pi * 2 + t * 0.18
                    let r: CGFloat = 18 + CGFloat(i % 3) * 7
                    let p = CGPoint(x: center.x + CGFloat(cos(a)) * r, y: center.y + CGFloat(sin(a)) * r)
                    var diamond = Path()
                    let s: CGFloat = 3.5
                    diamond.move(to: CGPoint(x: p.x, y: p.y - s))
                    diamond.addLine(to: CGPoint(x: p.x + s * 0.7, y: p.y))
                    diamond.addLine(to: CGPoint(x: p.x, y: p.y + s))
                    diamond.addLine(to: CGPoint(x: p.x - s * 0.7, y: p.y))
                    diamond.closeSubpath()
                    let color = i.isMultiple(of: 2) ? JSRColor.highlight : JSRColor.secondaryAccent
                    context.fill(diamond, with: .color(color.opacity(0.35)))
                }
            }
        }
        .frame(height: 56)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

// MARK: - Horizontal strip (Studio)

struct MotifAtelierStrip: View {
    let onSelect: (MotifPreset) -> Void
    var selectedID: String? = nil
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let card: CGFloat = 108

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xs) {
            HStack {
                Text("MOTIFS")
                    .font(JSRType.motif)
                    .tracking(1.2)
                    .foregroundStyle(JSRColor.highlight)
                Spacer()
            }
            .padding(.horizontal, JSRSpace.md)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: JSRSpace.sm) {
                    ForEach(Array(MotifCatalog.all.enumerated()), id: \.element.id) { index, motif in
                        Button {
                            onSelect(motif)
                        } label: {
                            stripCard(motif)
                        }
                        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                        .hoverEffect(.lift)
                        .modifier(StageAppearModifier(index: index, reduceMotion: reduceMotion))
                        .accessibilityLabel("\(motif.title). \(motif.subtitle)")
                        .accessibilityAddTraits(selectedID == motif.id ? .isSelected : [])
                    }
                }
                .padding(.horizontal, JSRSpace.md)
                .padding(.bottom, 4)
            }
        }
    }

    private func stripCard(_ motif: MotifPreset) -> some View {
        let selected = selectedID == motif.id
        return VStack(spacing: 6) {
            PatternCanvasView(
                parameters: motif.parameters,
                showChrome: false,
                kinetic: selected && !reduceMotion ? .breathe : .none,
                reduceMotion: reduceMotion
            )
            .frame(width: card, height: card)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .strokeBorder(
                        selected ? JSRColor.highlight : JSRStage.chipStroke,
                        lineWidth: selected ? 2 : 1
                    )
            }
            .shadow(color: selected ? JSRColor.highlight.opacity(0.25) : .clear, radius: 8, y: 0)

            Text(motif.title)
                .font(JSRFont.serif(size: 11, relativeTo: .caption2, weight: .semibold))
                .foregroundStyle(selected ? JSRStage.label : JSRStage.labelSecondary)
                .lineLimit(1)
                .frame(width: card, alignment: .leading)
        }
        .frame(width: card)
    }
}

// MARK: - Full grid (All Motifs sheet)

struct MotifAtelierGrid: View {
    let onSelect: (MotifPreset) -> Void
    var selectedID: String? = nil
    var title: String = "All Motifs"
    var subtitle: String = "Curated starting compositions for the Studio stage."

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dismiss) private var dismiss

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    /// Spotlight follows the motif currently live in Studio.
    private var featured: MotifPreset {
        if let id = selectedID, let match = MotifCatalog.all.first(where: { $0.id == id }) {
            return match
        }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return MotifCatalog.all[day % MotifCatalog.all.count]
    }

    private var collection: [MotifPreset] {
        MotifCatalog.all.filter { $0.id != featured.id }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JSRSpace.lg) {
                header

                featuredBlock

                Text("THE COLLECTION")
                    .font(JSRType.motif)
                    .tracking(1.3)
                    .foregroundStyle(JSRColor.highlight)

                LazyVGrid(columns: columns, spacing: 14) {
                    ForEach(Array(collection.enumerated()), id: \.element.id) { index, motif in
                        Button {
                            onSelect(motif)
                        } label: {
                            StageMotifCard(
                                motif: motif,
                                selected: selectedID == motif.id,
                                kinetic: reduceMotion ? .none : (selectedID == motif.id ? .orbit : .breathe),
                                reduceMotion: reduceMotion
                            )
                        }
                        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                        .hoverEffect(.lift)
                        .modifier(StageAppearModifier(index: index + 1, reduceMotion: reduceMotion))
                        .accessibilityLabel("\(motif.title). \(motif.subtitle)")
                        .accessibilityAddTraits(selectedID == motif.id ? .isSelected : [])
                    }
                }
            }
            .padding(JSRSpace.md)
            .jsrScrollBottomTail(JSRSpace.xxl)
        }
        .scrollIndicators(.hidden)
        .background { JSRStageAtmosphere(tint: JSRColor.highlight) }
        .preferredColorScheme(.dark)
        .toolbarBackground(JSRColor.ink.opacity(0.94), for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("All Motifs")
                    .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button("Done") { dismiss() }
                    .font(JSRFont.serif(size: 16, relativeTo: .callout, weight: .semibold))
                    .foregroundStyle(JSRColor.highlight)
            }
        }
    }

    private var header: some View {
        ZStack(alignment: .trailing) {
            VStack(alignment: .leading, spacing: JSRSpace.xs) {
                Text("ATELIER")
                    .font(JSRType.motif)
                    .tracking(1.4)
                    .foregroundStyle(JSRColor.highlight)
                Text(title)
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                Text(subtitle)
                    .font(JSRType.body)
                    .foregroundStyle(JSRStage.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: 280, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            AtelierHeaderOrnament(reduceMotion: reduceMotion)
                .frame(width: 120)
                .opacity(0.85)
        }
    }

    private var featuredBlock: some View {
        Button {
            onSelect(featured)
        } label: {
            StageMotifCard(
                motif: featured,
                selected: selectedID == featured.id,
                kinetic: reduceMotion ? .none : .orbit,
                reduceMotion: reduceMotion,
                showsOpenHint: true,
                featured: true
            )
        }
        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
        .hoverEffect(.lift)
        .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))
        .accessibilityLabel("On stage: \(featured.title). \(featured.subtitle)")
    }
}

struct SoftPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1)
            .opacity(configuration.isPressed ? 0.92 : 1)
            .animation(.easeOut(duration: 0.15), value: configuration.isPressed)
    }
}

#Preview("All Motifs") {
    NavigationStack {
        MotifAtelierGrid(onSelect: { _ in }, selectedID: MotifCatalog.all[0].id)
    }
}
