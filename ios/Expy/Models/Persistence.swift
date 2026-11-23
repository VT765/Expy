import Foundation
import OSLog
import SwiftData

enum Persistence {
    static let schema = Schema(versionedSchema: SchemaV4.self)

    static let container: ModelContainer = {
        let config = ModelConfiguration(schema: schema)
        snapshotBeforeMigration(config.url)
        do {
            return try ModelContainer(for: schema, migrationPlan: ExpyMigrationPlan.self, configurations: config)
        } catch {
            fatalError("Could not open the Expy database: \(error)")
        }
    }()

    /// Copies the store files once before the first versioned open, so a
    /// failed migration can be recovered by hand from Application Support.
    private static func snapshotBeforeMigration(_ store: URL) {
        let fm = FileManager.default
        let dir = store.deletingLastPathComponent().appendingPathComponent("PreMigrationV4", isDirectory: true)
        guard fm.fileExists(atPath: store.path), !fm.fileExists(atPath: dir.path) else { return }
        do {
            try fm.createDirectory(at: dir, withIntermediateDirectories: true)
            for suffix in ["", "-wal", "-shm"] {
                let src = URL(filePath: store.path + suffix)
                if fm.fileExists(atPath: src.path) { try fm.copyItem(at: src, to: dir.appendingPathComponent(src.lastPathComponent)) }
            }
        } catch {
            Logger(subsystem: "com.varunthacker.expy", category: "db").error("Pre-migration snapshot failed: \(error)")
        }
    }
}
