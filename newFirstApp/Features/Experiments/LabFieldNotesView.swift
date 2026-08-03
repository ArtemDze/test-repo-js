import SwiftUI

/// Annotated teaching block for practice stages — checkable “what to notice”.
struct LabFieldNotesView: View {
    let kind: ExperimentKind

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(HapticsClient.self) private var haptics
    @AppStorage private var noteMask: Int

    private var notes: LabFieldNotes { LabCatalog.fieldNotes(for: kind) }

    init(kind: ExperimentKind) {
        self.kind = kind
        _noteMask = AppStorage(wrappedValue: 0, LabProgress.notesStorageKey(for: kind))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: JSRSpace.md) {
            Text("FIELD NOTES")
                .font(JSRType.motif)
                .tracking(1.2)
                .foregroundStyle(JSRColor.highlight)

            Text(notes.principle)
                .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                .foregroundStyle(JSRStage.label)
                .fixedSize(horizontal: false, vertical: true)

            VStack(alignment: .leading, spacing: 10) {
                Text("What to notice")
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)

                ForEach(Array(notes.notice.enumerated()), id: \.offset) { index, line in
                    let checked = LabProgress.isNoteChecked(index, mask: noteMask)
                    Button {
                        withAnimation(JSRMotion.preferred(JSRMotion.snappy, reduceMotion: reduceMotion)) {
                            noteMask = LabProgress.toggledNote(index: index, mask: noteMask)
                        }
                        haptics.select()
                    } label: {
                        HStack(alignment: .top, spacing: 10) {
                            Image(systemName: checked ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundStyle(checked ? JSRColor.highlight : JSRStage.labelTertiary)
                            Text(line)
                                .font(JSRType.body)
                                .foregroundStyle(checked ? JSRStage.labelSecondary : JSRStage.label)
                                .multilineTextAlignment(.leading)
                                .strikethrough(checked, color: JSRStage.labelTertiary)
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(checked ? .isSelected : [])
                }
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("CRAFT TIP")
                    .font(JSRType.motif)
                    .tracking(1.0)
                    .foregroundStyle(JSRColor.secondaryAccent)
                Text(notes.craftTip)
                    .font(JSRType.caption)
                    .foregroundStyle(JSRStage.labelSecondary)
                    .fixedSize(horizontal: false, vertical: true)
            }

            if let drillID = notes.relatedDrillID {
                NavigationLink(value: LabDestination.drill(drillID)) {
                    HStack(spacing: 6) {
                        Image(systemName: "eye")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Take the related eye drill")
                            .font(JSRFont.serif(size: 14, relativeTo: .caption, weight: .semibold))
                        Spacer()
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundStyle(JSRColor.highlight)
                    .padding(.top, 4)
                }
                .simultaneousGesture(TapGesture().onEnded { haptics.select() })
            }
        }
        .padding(JSRSpace.md)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(JSRStage.panel)
                .overlay {
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(JSRStage.separator, lineWidth: 1)
                }
        }
    }
}
