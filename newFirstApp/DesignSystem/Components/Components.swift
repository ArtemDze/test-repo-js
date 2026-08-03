import SwiftUI

struct JSRPrimaryAction: View {
    let title: String
    var systemImage: String? = nil
    var role: Role = .primary
    var isEnabled: Bool = true
    let action: () -> Void

    enum Role { case primary, secondary, destructive }

    var body: some View {
        Button(action: action) {
            HStack(spacing: JSRSpace.xs) {
                if let systemImage { Image(systemName: systemImage) }
                Text(title).font(JSRType.callout)
            }
            .frame(maxWidth: .infinity)
            .frame(minHeight: JSRControl.minHit - 8)
            .padding(.horizontal, JSRSpace.md)
            .background(background)
            .foregroundStyle(foreground)
            .clipShape(RoundedRectangle(cornerRadius: JSRRadius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.45)
        .accessibilityLabel(title)
    }

    private var background: Color {
        switch role {
        case .primary: JSRColor.accent
        case .secondary: JSRColor.fill
        case .destructive: JSRColor.danger.opacity(0.14)
        }
    }

    private var foreground: Color {
        switch role {
        case .primary: JSRColor.ivory
        case .secondary: JSRColor.textPrimary
        case .destructive: JSRColor.danger
        }
    }
}

struct JSRIconAction: View {
    let systemImage: String
    let label: String
    var isSelected: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: systemImage)
                .font(.system(size: JSRIconSize.md, weight: .medium))
                .frame(width: JSRControl.minHit, height: JSRControl.minHit)
                .foregroundStyle(isSelected ? JSRColor.highlight : JSRColor.textPrimary)
                .background(isSelected ? JSRColor.accentMuted : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: JSRRadius.control, style: .continuous))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

struct JSRSectionLabel: View {
    let title: String
    var subtitle: String? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xxs) {
            Text(title.uppercased())
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(JSRColor.highlight)
            if let subtitle {
                Text(subtitle)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRColor.textSecondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct JSRParameterSlider: View {
    let title: String
    @Binding var value: Double
    var range: ClosedRange<Double>
    var step: Double? = nil
    var valueLabel: ((Double) -> String)? = nil
    var onEditingChanged: ((Bool) -> Void)? = nil
    /// Use ivory/gold labels on ink stages (onboarding, studio chrome).
    var stageChrome: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xxs) {
            HStack {
                Text(title)
                    .font(JSRType.caption)
                    .foregroundStyle(stageChrome ? JSRStage.labelSecondary : JSRColor.textSecondary)
                Spacer()
                Text(valueLabel?(value) ?? String(format: "%.2f", value))
                    .font(JSRType.caption.monospacedDigit())
                    .foregroundStyle(stageChrome ? JSRStage.label : JSRColor.textPrimary)
            }
            Slider(
                value: $value,
                in: range,
                step: step ?? 0.01,
                onEditingChanged: { onEditingChanged?($0) }
            )
            .tint(stageChrome ? JSRColor.highlight : JSRColor.accent)
            .accessibilityLabel(title)
            .accessibilityValue(valueLabel?(value) ?? "\(value)")
        }
    }
}

struct JSRSegmentedControl<T: Hashable & Identifiable>: View where T: CustomStringConvertible {
    @Binding var selection: T
    let items: [T]

    var body: some View {
        Picker("", selection: $selection) {
            ForEach(items) { item in
                Text(String(describing: item)).tag(item)
            }
        }
        .pickerStyle(.segmented)
    }
}

struct JSRInspectorGroup<Content: View>: View {
    let title: String
    @State private var expanded = true
    @ViewBuilder var content: Content

    var body: some View {
        DisclosureGroup(isExpanded: $expanded) {
            content.padding(.top, JSRSpace.xs)
        } label: {
            Text(title).font(JSRType.headline).foregroundStyle(JSRColor.textPrimary)
        }
        .padding(JSRSpace.sm)
        .background(JSRColor.surface)
        .clipShape(RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous))
    }
}

struct JSRProjectThumbnail: View {
    let project: StudioProject

    var body: some View {
        Group {
            if let image = project.thumbnailImage {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                PatternCanvasView(parameters: project.parameters, showChrome: false)
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                .strokeBorder(JSRColor.separator, lineWidth: JSRStroke.hairline)
        }
        .accessibilityHidden(true)
    }
}

struct JSRExperimentHeader: View {
    let title: String
    let blurb: String

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.xs) {
            Text(title).font(JSRType.title).foregroundStyle(JSRColor.textPrimary)
            Text(blurb).font(JSRType.body).foregroundStyle(JSRColor.textSecondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

struct JSREmptyState: View {
    let title: String
    let message: String
    var systemImage: String = "rectangle.dashed"
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        VStack(spacing: JSRSpace.md) {
            Image(systemName: systemImage)
                .font(.system(size: 36, weight: .light))
                .foregroundStyle(JSRColor.highlight)
                .accessibilityHidden(true)
            Text(title).font(JSRType.title).multilineTextAlignment(.center)
            Text(message)
                .font(JSRType.body)
                .foregroundStyle(JSRColor.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 320)
            if let actionTitle, let action {
                JSRPrimaryAction(title: actionTitle, systemImage: "plus", action: action)
                    .frame(maxWidth: 260)
            }
        }
        .padding(JSRSpace.lg)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct JSRToast: View {
    let text: String
    var tone: Tone = .neutral
    enum Tone { case neutral, success, warning }

    var body: some View {
        Text(text)
            .font(JSRType.caption)
            .foregroundStyle(foreground)
            .padding(.horizontal, JSRSpace.sm)
            .padding(.vertical, JSRSpace.xs)
            .background(background)
            .clipShape(Capsule())
            .accessibilityLabel(text)
    }

    private var foreground: Color {
        switch tone {
        case .neutral: JSRColor.textSecondary
        case .success: JSRColor.success
        case .warning: JSRColor.warning
        }
    }

    private var background: Color {
        switch tone {
        case .neutral: JSRColor.fill
        case .success: JSRColor.success.opacity(0.14)
        case .warning: JSRColor.warning.opacity(0.14)
        }
    }
}

struct JSRConfirmationPanel: View {
    let title: String
    let message: String
    let confirmTitle: String
    var isDestructive: Bool = true
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.md) {
            Text(title).font(JSRType.title)
            Text(message).font(JSRType.body).foregroundStyle(JSRColor.textSecondary)
            HStack {
                JSRPrimaryAction(title: "Cancel", role: .secondary, action: onCancel)
                JSRPrimaryAction(
                    title: confirmTitle,
                    role: isDestructive ? .destructive : .primary,
                    action: onConfirm
                )
            }
        }
        .padding(JSRSpace.lg)
        .background(JSRColor.surfaceElevated)
        .clipShape(RoundedRectangle(cornerRadius: JSRRadius.sheet, style: .continuous))
    }
}

struct StageFrame<Content: View>: View {
    var padding: CGFloat = JSRSpace.sm
    @ViewBuilder var content: Content

    var body: some View {
        content
            .padding(padding)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                    .fill(JSRColor.surfaceElevated)
                    .overlay {
                        RoundedRectangle(cornerRadius: JSRRadius.container, style: .continuous)
                            .strokeBorder(JSRColor.separator, lineWidth: 1)
                    }
                    .shadow(color: Color.black.opacity(0.16), radius: 18, y: 8)
            }
    }
}
