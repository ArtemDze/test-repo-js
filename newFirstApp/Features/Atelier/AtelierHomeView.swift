import SwiftUI

/// Curated motif library — main Atelier tab, same stage language as All Motifs.
struct AtelierHomeView: View {
    /// Motif currently live on the Studio stage (synced from Studio).
    var stageMotifID: String? = nil
    var onOpenInStudio: (MotifPreset) -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @EnvironmentObject private var haptics: HapticsClient

    private let columns = [GridItem(.adaptive(minimum: 160), spacing: 14)]

    private var featured: MotifPreset {
        if let id = stageMotifID, let match = MotifCatalog.all.first(where: { $0.id == id }) {
            return match
        }
        let day = Calendar.current.ordinality(of: .day, in: .year, for: .now) ?? 1
        return MotifCatalog.all[day % MotifCatalog.all.count]
    }

    private var isFeaturedOnStage: Bool {
        stageMotifID == featured.id
    }

    private var collection: [MotifPreset] {
        MotifCatalog.all.filter { $0.id != featured.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: JSRSpace.lg) {
                    header
                        .padding(.horizontal, JSRSpace.md)
                        .padding(.top, JSRSpace.sm)

                    Button {
                        haptics.select()
                        onOpenInStudio(featured)
                    } label: {
                        StageMotifCard(
                            motif: featured,
                            selected: isFeaturedOnStage,
                            kinetic: reduceMotion ? .none : .orbit,
                            reduceMotion: reduceMotion,
                            showsOpenHint: true,
                            featured: true
                        )
                    }
                    .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                    .hoverEffect(.lift)
                    .modifier(StageAppearModifier(index: 0, reduceMotion: reduceMotion))
                    .padding(.horizontal, JSRSpace.md)
                    .accessibilityLabel("On stage: \(featured.title). Open in Studio")

                    Text("THE COLLECTION")
                        .font(JSRType.motif)
                        .tracking(1.3)
                        .foregroundStyle(JSRColor.highlight)
                        .padding(.horizontal, JSRSpace.md)

                    LazyVGrid(columns: columns, spacing: 14) {
                        ForEach(Array(collection.enumerated()), id: \.element.id) { index, motif in
                            Button {
                                haptics.select()
                                onOpenInStudio(motif)
                            } label: {
                                StageMotifCard(
                                    motif: motif,
                                    selected: stageMotifID == motif.id,
                                    kinetic: reduceMotion ? .none : .breathe,
                                    reduceMotion: reduceMotion,
                                    showsOpenHint: true
                                )
                            }
                            .buttonStyle(StageLiftButtonStyle(reduceMotion: reduceMotion))
                            .hoverEffect(.lift)
                            .modifier(StageAppearModifier(index: index + 1, reduceMotion: reduceMotion))
                            .accessibilityLabel("\(motif.title). \(motif.subtitle). Open in Studio")
                        }
                    }
                    .padding(.horizontal, JSRSpace.md)

                    JSRScrollBottomSpacer()
                }
            }
            .scrollIndicators(.hidden)
            .background { JSRStageAtmosphere(tint: JSRColor.secondaryAccent) }
            .preferredColorScheme(.dark)
            .toolbarBackground(JSRColor.ink.opacity(0.94), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Atelier")
                        .font(JSRFont.serif(size: 18, relativeTo: .headline, weight: .semibold))
                        .foregroundStyle(JSRStage.label)
                }
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
                Text("Motif Library")
                    .font(JSRType.title)
                    .foregroundStyle(JSRStage.label)
                Text("Choose a clean starting composition, then open it on the Studio stage.")
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
}

#Preview {
    AtelierHomeView(stageMotifID: MotifCatalog.all[0].id, onOpenInStudio: { _ in })
        .environmentObject(HapticsClient())
}
