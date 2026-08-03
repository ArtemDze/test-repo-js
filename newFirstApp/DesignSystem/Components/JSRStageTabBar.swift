import SwiftUI

/// Floating theatrical tab bar — ink stage, sliding gold selection, Cormorant labels.
struct JSRStageTabBar: View {
    @Binding var selection: AppTab
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(HapticsClient.self) private var haptics
    @Namespace private var selectionNS

    var body: some View {
        HStack(spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                tabButton(tab)
            }
        }
        .padding(.horizontal, 5)
        .padding(.vertical, 5)
        .background { barChrome }
        .padding(.horizontal, JSRSpace.md)
        .padding(.bottom, 2)
        // Pill / footlight glide — driven by selection changes from outside.
        .animation(selectionAnimation, value: selection)
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Main tabs")
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let selected = selection == tab

        return Button {
            guard selection != tab else { return }
            haptics.select()
            // Animation comes from MainTabView / binding — avoid nested spring jumps.
            selection = tab
        } label: {
            VStack(spacing: 3) {
                Image(systemName: selected ? tab.symbolSelected : tab.symbol)
                    .font(.system(size: 16, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? JSRColor.highlight : JSRColor.ivory.opacity(0.40))
                    .frame(height: 22)
                    .contentTransition(.symbolEffect(.replace.downUp.byLayer))

                Text(tab.title)
                    .font(JSRFont.serif(size: 10, relativeTo: .caption2, weight: selected ? .semibold : .regular))
                    .foregroundStyle(selected ? JSRColor.ivory.opacity(0.95) : JSRColor.ivory.opacity(0.38))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 8)
            .padding(.bottom, 7)
            .background {
                ZStack {
                    if selected {
                        // Soft stage light behind the active tab.
                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        JSRColor.highlight.opacity(0.18),
                                        JSRColor.accent.opacity(0.06),
                                        .clear
                                    ],
                                    center: .top,
                                    startRadius: 2,
                                    endRadius: 36
                                )
                            )
                            .matchedGeometryEffect(id: "tabLight", in: selectionNS)

                        RoundedRectangle(cornerRadius: 15, style: .continuous)
                            .fill(JSRColor.ivory.opacity(0.06))
                            .overlay {
                                RoundedRectangle(cornerRadius: 15, style: .continuous)
                                    .strokeBorder(JSRColor.highlight.opacity(0.28), lineWidth: 1)
                            }
                            .matchedGeometryEffect(id: "tabPill", in: selectionNS)
                    }
                }
            }
            .overlay(alignment: .bottom) {
                if selected {
                    // Fine gold footlight — slides with selection.
                    Capsule()
                        .fill(
                            LinearGradient(
                                colors: [
                                    JSRColor.highlight.opacity(0.15),
                                    JSRColor.highlight,
                                    JSRColor.highlight.opacity(0.15)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: 18, height: 2)
                        .padding(.bottom, 3)
                        .matchedGeometryEffect(id: "tabTick", in: selectionNS)
                        .shadow(color: JSRColor.highlight.opacity(0.55), radius: 4, y: 0)
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(TabPressStyle(reduceMotion: reduceMotion))
        .accessibilityLabel(tab.accessibilityTitle)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private var selectionAnimation: Animation? {
        JSRMotion.preferred(
            .easeInOut(duration: 0.34),
            reduceMotion: reduceMotion
        )
    }

    private var barChrome: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(JSRColor.ink.opacity(0.92))

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(.ultraThinMaterial)
                .environment(\.colorScheme, .dark)
                .opacity(0.55)

            // Inner stage rim.
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(JSRColor.ivory.opacity(0.06), lineWidth: 1)
                .padding(1)

            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(
                    LinearGradient(
                        colors: [
                            JSRColor.highlight.opacity(0.50),
                            JSRColor.accent.opacity(0.22),
                            JSRColor.secondaryAccent.opacity(0.32)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )

            // Footlight wash from above.
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .fill(
                    LinearGradient(
                        colors: [JSRColor.highlight.opacity(0.10), .clear],
                        startPoint: .top,
                        endPoint: UnitPoint(x: 0.5, y: 0.55)
                    )
                )
                .allowsHitTesting(false)
        }
        .shadow(color: .black.opacity(0.45), radius: 20, y: 10)
        .shadow(color: JSRColor.highlight.opacity(0.08), radius: 12, y: 0)
    }
}

private struct TabPressStyle: ButtonStyle {
    var reduceMotion: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.94 : 1)
            .opacity(configuration.isPressed ? 0.88 : 1)
            .animation(.easeOut(duration: 0.14), value: configuration.isPressed)
    }
}

#Preview {
    ZStack(alignment: .bottom) {
        JSRColor.ink.ignoresSafeArea()
        JSRStageTabBar(selection: .constant(.studio))
    }
    .environment(HapticsClient())
}
