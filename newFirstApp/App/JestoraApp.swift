import SwiftUI
import SwiftData

@main
struct JestoraApp: App {
    @State private var haptics = HapticsClient()
    @State private var store = ProjectStore()
    private let container: ModelContainer

    init() {
        JSRFont.registerBundledFonts()
        let schema = Schema([StudioProject.self, AppSettings.self])
        do {
            container = try ModelContainer(for: schema, configurations: [ModelConfiguration(isStoredInMemoryOnly: false)])
        } catch {
            // Fallback in-memory store so the UI can still explain recovery.
            container = try! ModelContainer(
                for: schema,
                configurations: [ModelConfiguration(isStoredInMemoryOnly: true)]
            )
        }
    }

    var body: some Scene {
        WindowGroup {
            RootFlowView()
                .environment(haptics)
                .environment(store)
        }
        .modelContainer(container)
    }
}
