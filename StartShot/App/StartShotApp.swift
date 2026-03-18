import SwiftUI
import SwiftData

@main
struct StartShotApp: App {
    @State private var settingsStore = SettingsStore()
    @State private var dateProvider = AppDateProvider()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            DailyMissionRecord.self,
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(settingsStore)
                .environment(dateProvider)
                .onAppear {
                    HapticFeedback.prepare()
                }
        }
        .modelContainer(sharedModelContainer)
    }
}
