import SwiftUI

// MARK: - Daily cue

struct StudioCueRibbon: View {
    let prompt: DailyPrompt
    var onApply: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        HStack(alignment: .top, spacing: JSRSpace.sm) {
            VStack(alignment: .leading, spacing: 3) {
                Text("TODAY’S CUE")
                    .font(JSRType.motif)
                    .tracking(1.2)
                    .foregroundStyle(JSRColor.highlight)
                Text(prompt.title)
                    .font(JSRFont.serif(size: 16, relativeTo: .callout, weight: .semibold))
                    .foregroundStyle(JSRStage.label)
                Text(prompt.body)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 8)
            VStack(spacing: 6) {
                Button(action: onApply) {
                    Text("Apply")
                        .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .semibold))
                        .foregroundStyle(JSRColor.ink)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(JSRColor.highlight)
                        .clipShape(Capsule())
                }
                .buttonStyle(.plain)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundStyle(JSRStage.labelTertiary)
                        .frame(width: 28, height: 28)
                        .background(JSRStage.chipFill)
                        .clipShape(Circle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Dismiss cue")
            }
        }
        .padding(JSRSpace.sm)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panelElevated)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRColor.highlight.opacity(0.4), lineWidth: 1)
                }
        }
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Chips

struct StudioChip: View {
    let title: String
    var selected: Bool
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .semibold))
                .padding(.horizontal, 11)
                .padding(.vertical, 7)
                .foregroundStyle(selected ? JSRStage.label : JSRStage.labelSecondary)
                .background(selected ? JSRStage.accentFill : JSRStage.chipFill)
                .clipShape(Capsule())
                .overlay {
                    Capsule()
                        .strokeBorder(
                            selected ? JSRColor.highlight.opacity(0.55) : JSRStage.chipStroke,
                            lineWidth: 1
                        )
                }
        }
        .buttonStyle(SoftPressStyle())
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}

// MARK: - Stage chrome

struct StudioStageChrome<Content: View>: View {
    var pulse: Bool
    var compareLabel: String?
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(12)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: 18, style: .continuous)
                    .fill(JSRColor.ink)
                    .overlay {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .strokeBorder(
                                LinearGradient(
                                    colors: [
                                        JSRColor.highlight.opacity(pulse ? 0.75 : 0.42),
                                        JSRColor.accent.opacity(0.28),
                                        JSRColor.secondaryAccent.opacity(0.35)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: pulse ? 1.6 : 1.1
                            )
                    }
                    .shadow(color: .black.opacity(0.28), radius: pulse ? 26 : 18, y: 10)
                    .shadow(color: JSRColor.highlight.opacity(pulse ? 0.18 : 0), radius: 16, y: 0)
            }
            .overlay(alignment: .topTrailing) {
                if let compareLabel {
                    Text(compareLabel.uppercased())
                        .font(JSRType.motif)
                        .tracking(1.1)
                        .foregroundStyle(JSRColor.highlight)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(JSRColor.ink.opacity(0.72))
                        .clipShape(Capsule())
                        .padding(10)
                }
            }
            .animation(JSRMotion.snappy, value: pulse)
    }
}

// MARK: - Tool strip

struct StudioToolStrip: View {
    let seedLocked: Bool
    let hasPinnedA: Bool
    let compareMode: StudioCompareMode
    var onSeedLock: () -> Void
    var onReseed: () -> Void
    var onPinA: () -> Void
    var onCompare: () -> Void
    var onNotes: () -> Void
    var onPremiere: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                toolButton("theatermasks.fill", title: "Premiere", accent: true, action: onPremiere)
                toolButton(
                    seedLocked ? "lock.fill" : "lock.open",
                    title: "Seed",
                    accent: seedLocked,
                    action: onSeedLock
                )
                toolButton("dice", title: "Reseed", action: onReseed)
                toolButton("pin.fill", title: "Pin A", accent: hasPinnedA, action: onPinA)
                toolButton(
                    compareMode == .off ? "rectangle.split.2x1" : "rectangle.split.2x1.fill",
                    title: compareMode.title,
                    accent: compareMode != .off,
                    action: onCompare
                )
                toolButton("note.text", title: "Notes", action: onNotes)
            }
            .padding(.horizontal, JSRSpace.md)
        }
    }

    private func toolButton(
        _ system: String,
        title: String,
        accent: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 5) {
                Image(systemName: system)
                    .font(.system(size: 12, weight: .semibold))
                Text(title)
                    .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
            }
            .foregroundStyle(accent ? JSRColor.highlight : JSRStage.labelSecondary)
            .padding(.horizontal, 11)
            .padding(.vertical, 8)
            .background(accent ? JSRColor.accent.opacity(0.28) : JSRStage.chipFill)
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .strokeBorder(
                        accent ? JSRColor.highlight.opacity(0.45) : JSRStage.chipStroke,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(SoftPressStyle())
        .accessibilityLabel(title)
    }
}

// MARK: - Inspector section

struct StudioInspectorSection<Content: View>: View {
    let title: String
    @State private var expanded = true
    @ViewBuilder var content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.sm) {
            Button {
                withAnimation(JSRMotion.snappy) { expanded.toggle() }
            } label: {
                HStack {
                    Text(title.uppercased())
                        .font(JSRType.motif)
                        .tracking(1.2)
                        .foregroundStyle(JSRColor.highlight)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(JSRStage.labelTertiary)
                        .rotationEffect(.degrees(expanded ? 0 : -90))
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            if expanded {
                content
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(JSRSpace.sm)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}

// MARK: - Stage slider / stepper

struct StudioSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double = 0.01
    var valueLabel: ((Double) -> String)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(title)
                    .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
                    .foregroundStyle(JSRStage.labelSecondary)
                Spacer()
                Text(valueLabel?(value) ?? String(format: "%.2f", value))
                    .font(JSRType.caption.monospacedDigit())
                    .foregroundStyle(JSRStage.label)
                                }
            Slider(value: $value, in: range, step: step, onEditingChanged: { editing in
                onEditingChanged?(editing)
            })
                .tint(JSRColor.highlight)
                .accessibilityLabel(title)
        }
    }
}

struct StudioToast: View {
    let text: String

    var body: some View {
        Text(text)
            .font(JSRFont.serif(size: 13, relativeTo: .caption, weight: .semibold))
            .foregroundStyle(JSRColor.ink)
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(JSRColor.highlight)
            .clipShape(Capsule())
            .shadow(color: .black.opacity(0.35), radius: 10, y: 4)
            .accessibilityLabel(text)
    }
}

struct StudioStepperRow: View {
    let title: String
    let value: Int
    let range: ClosedRange<Int>
    var onChange: (Int) -> Void

    var body: some View {
        HStack {
            Text(title)
                .font(JSRFont.serif(size: 12, relativeTo: .caption, weight: .medium))
                .foregroundStyle(JSRStage.labelSecondary)
            Spacer()
            Text("\(value)")
                .font(JSRType.callout.monospacedDigit())
                .foregroundStyle(JSRStage.label)
                .frame(minWidth: 28, alignment: .trailing)

            HStack(spacing: 0) {
                stepButton("minus", enabled: value > range.lowerBound) {
                    onChange(max(range.lowerBound, value - 1))
                }
                stepButton("plus", enabled: value < range.upperBound) {
                    onChange(min(range.upperBound, value + 1))
                }
            }
            .background(JSRStage.chipFill)
            .clipShape(Capsule())
            .overlay {
                Capsule().strokeBorder(JSRStage.chipStroke, lineWidth: 1)
            }
        }
    }

    private func stepButton(_ system: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: system)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(enabled ? JSRStage.label : JSRStage.labelTertiary)
                .frame(width: 34, height: 30)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }
}

struct StudioGhostButton: View {
    let title: String
    var systemImage: String? = nil
    var emphasized: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let systemImage {
                    Image(systemName: systemImage)
                }
                Text(title)
                    .font(JSRFont.serif(size: 14, relativeTo: .callout, weight: .semibold))
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: 40)
            .foregroundStyle(emphasized ? JSRColor.ink : JSRStage.label)
            .background(emphasized ? JSRColor.highlight : JSRStage.chipFillStrong)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(
                        emphasized ? Color.clear : JSRStage.chipStroke,
                        lineWidth: 1
                    )
            }
        }
        .buttonStyle(SoftPressStyle())
    }
}
