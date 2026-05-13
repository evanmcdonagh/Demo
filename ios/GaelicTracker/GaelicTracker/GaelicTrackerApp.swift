import SwiftUI
import SwiftData

@main
struct GaelicTrackerApp: App {
    let container: ModelContainer = makeContainer()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(container)
    }
}

private func makeContainer() -> ModelContainer {
    let schema = Schema([
        Team.self,
        Player.self,
        Game.self,
        GameEvent.self,
        Substitution.self,
        PlayerGameStat.self
    ])
    let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

    do {
        return try ModelContainer(for: schema, configurations: [config])
    } catch {
        // Schema changed (e.g. a new field was added). Wipe the store and start fresh.
        // In a shipping app replace this with a VersionedSchema + SchemaMigrationPlan.
        wipeStore()
        do {
            return try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Cannot create ModelContainer after wipe: \(error)")
        }
    }
}

private func wipeStore() {
    let fm = FileManager.default
    guard let appSupport = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return }
    for suffix in ["default.store", "default.store-shm", "default.store-wal"] {
        let url = appSupport.appending(path: suffix)
        try? fm.removeItem(at: url)
    }
}
