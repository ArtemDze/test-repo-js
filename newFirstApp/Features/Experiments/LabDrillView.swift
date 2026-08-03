import SwiftUI

/// A/B perception mini-test — the distinctive Labs interaction.
struct LabDrillView: View {
    let drill: LabDrill
    var onOpenPractice: ((ExperimentKind) -> Void)? = nil

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(HapticsClient.self) private var haptics
    @AppStorage(LabProgress.drillsStorageKey) private var clearedRaw = ""

    @State private var selection: LabChoice?
    @State private var revealed = false
    @State private var pulseCorrect = false

    private var isCleared: Bool {
        LabProgress.isCleared(drill.id, raw: clearedRaw)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: JSRSpace.lg) {
                header
                    .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))

                questionBlock
                    .modifier(StageAppearModifier(index: 1, reduceMotion: reduceMotion))

                HStack(spacing: 12) {
                    choiceCard(.a, parameters: drill.optionA, caption: drill.labelA)
                    choiceCard(.b, parameters: drill.optionB, caption: drill.labelB)
                }
                .modifier(StageAppearModifier(index: 2, reduceMotion: reduceMotion))

                if revealed, let selection {
                    revealCard(wasCorrect: selection == drill.correct)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .modifier(StageAppearModifier(index: 3, reduceMotion: reduceMotion))
                } else {
                    Text("Tap the panel that answers the question.")
                        .font(JSRType.caption)
                        .foregroundStyle(JSRStage.labelTertiary)
                }

                if revealed {
                    actionRow
                        .modifier(StageAppearModifier(index: 4, reduceMotion: reduceMotion))
                }

                JSRScrollBottomSpacer()
            }
            .padding(JSRSpace.md)
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
                Text(drill.title)
                    .font(JSRFont.serif(size: 17, relativeTo: .headline, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
            }
        }
        .animation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion), value: revealed)
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xs) {
            HStack(spacing: 8) {
                Text(drill.actLabel)
                    .font(JSRType.motif)
                    .tracking(1.3)
                    .foregroundStyle(JSRColor.highlight)
                if isCleared {
                    Text("CLEARED")
                        .font(JSRType.motif)
                        .tracking(1.0)
                        .foregroundStyle(JSRColor.ink)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(JSRColor.highlight)
                        .clipShape(Capsule())
                }
            }
            Text("Eye Drill")
                .font(JSRType.title)
                .foregroundStyle(JSRStage.label)
            Text(drill.context)
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var questionBlock: some View {
        Text(drill.question)
            .font(JSRFont.serif(size: 22, relativeTo: .title3, weight: .semibold))
            .foregroundStyle(JSRStage.label)
            .fixedSize(horizontal: false, vertical: true)
            .padding(JSRSpace.md)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(JSRStage.panel)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(JSRColor.highlight.opacity(0.35), lineWidth: 1)
                    }
            }
            .accessibilityAddTraits(.isHeader)
    }

    private func choiceCard(_ choice: LabChoice, parameters: PatternParameters, caption: String) -> some View {
        let isSelected = selection == choice
        let showResult = revealed
        let isCorrectChoice = choice == drill.correct
        let borderColor: Color = {
            guard showResult else {
                return isSelected ? JSRColor.highlight : JSRStage.separator
            }
            if isCorrectChoice { return JSRColor.highlight }
            if isSelected { return JSRColor.danger }
            return JSRStage.separator
        }()

        return Button {
            guard !revealed else { return }
            selection = choice
            withAnimation(JSRMotion.preferred(JSRMotion.fluid, reduceMotion: reduceMotion)) {
                revealed = true
            }
            if choice == drill.correct {
                haptics.success()
                pulseCorrect = true
            } else {
                haptics.warning()
            }
            LabProgress.markCleared(drill.id, raw: &clearedRaw)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                PatternCanvasView(
                    parameters: parameters,
                    showChrome: false,
                    kinetic: reduceMotion ? .none : (isSelected || !revealed ? drill.kinetic : .none),
                    reduceMotion: reduceMotion
                )
                .frame(maxWidth: .infinity)
                .aspectRatio(1, contentMode: .fit)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(borderColor, lineWidth: showResult && isCorrectChoice ? 2 : 1.2)
                }
                .shadow(
                    color: showResult && isCorrectChoice && pulseCorrect
                        ? JSRColor.highlight.opacity(0.35)
                        : .clear,
                    radius: 14,
                    y: 0
                )

                HStack {
                    Text(caption)
                        .font(JSRFont.serif(size: 14, relativeTo: .caption, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                    Spacer()
                    if showResult, isCorrectChoice {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(JSRColor.highlight)
                    } else if showResult, isSelected {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(JSRColor.danger)
                    }
                }
            }
            .padding(10)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(JSRStage.panel)
            }
        }
        .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
        .disabled(revealed)
        .accessibilityLabel("Option \(caption)")
        .accessibilityHint(revealed ? (isCorrectChoice ? "Correct" : "Not the answer") : "Select this option")
    }

    private func revealCard(wasCorrect: Bool) -> some View {
        VStack(alignment: .leading, spacing: JSRSpace.sm) {
            Text(wasCorrect ? "Sharp eye" : "Worth another look")
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(wasCorrect ? JSRColor.highlight : JSRColor.secondaryAccent)

            Text(drill.revealTitle)
                .font(JSRFont.serif(size: 20, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)

            Text(drill.revealBody)
                .font(JSRType.body)
                .foregroundStyle(JSRStage.labelSecondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(JSRStage.panelElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(
                            (wasCorrect ? JSRColor.highlight : JSRColor.secondaryAccent).opacity(0.45),
                            lineWidth: 1
                        )
                }
        }
        .accessibilityElement(children: .combine)
    }

    private var actionRow: some View {
        VStack(spacing: JSRSpace.sm) {
            Button {
                withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                    selection = nil
                    revealed = false
                    pulseCorrect = false
                }
                haptics.select()
            } label: {
                labelCapsule(title: "Try again", systemImage: "arrow.counterclockwise", filled: false)
            }
            .buttonStyle(.plain)

            if let practice = drill.relatedPractice, let onOpenPractice {
                Button {
                    haptics.select()
                    onOpenPractice(practice)
                } label: {
                    labelCapsule(title: "Open related practice", systemImage: "paintbrush.pointed", filled: true)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func labelCapsule(title: String, systemImage: String, filled: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: systemImage)
                .font(.system(size: 13, weight: .semibold))
            Text(title)
                .font(JSRFont.serif(size: 15, relativeTo: .callout, weight: .semibold))
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: 46)
        .foregroundStyle(filled ? JSRColor.ink : JSRStage.label)
        .background(filled ? JSRColor.highlight : JSRStage.chipFillStrong)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(filled ? Color.clear : JSRStage.chipStroke, lineWidth: 1)
        }
    }
}

#Preview {
    NavigationStack {
        LabDrillView(drill: LabCatalog.drills[0])
    }
    .environment(HapticsClient())
}
