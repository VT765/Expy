import Foundation
import Observation
import OSLog

/// Automatic backups to a folder the user picks once in iCloud Drive (or
/// anywhere in Files). Works with a free Apple ID: no iCloud entitlement,
/// just a bookmark to the chosen folder. Saves ~30 s after changes, when
/// the app goes to the background, and daily at the latest; keeps 30 days.
@MainActor
@Observable
final class CloudBackup {
    static let shared = CloudBackup()
    static let keepDays = 30
    private static let bookmarkKey = "backupFolderBookmark"
    private static let lastBackupKey = "backupLastAt"

    private(set) var folderName: String?
    private(set) var lastBackupAt: Date?
    private(set) var lastError: String?

    @ObservationIgnored private let defaults: UserDefaults
    @ObservationIgnored private var pending: Task<Void, Never>?
    @ObservationIgnored private let log = Logger(subsystem: "com.varunthacker.expy", category: "backup")

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        lastBackupAt = defaults.object(forKey: Self.lastBackupKey) as? Date
        folderName = defaults.data(forKey: Self.bookmarkKey) == nil ? nil : resolveFolder()?.lastPathComponent
    }

    var isEnabled: Bool { defaults.data(forKey: Self.bookmarkKey) != nil }

    /// Remembers the picked folder and backs up straight away.
    func chooseFolder(_ url: URL) {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }
        do {
            defaults.set(try url.bookmarkData(), forKey: Self.bookmarkKey)
            folderName = url.lastPathComponent
            lastError = nil
            backupNow()
        } catch {
            lastError = "Couldn't use that folder. Pick another one."
            log.error("Bookmark failed: \(error)")
        }
    }

    func turnOff() {
        pending?.cancel()
        defaults.removeObject(forKey: Self.bookmarkKey)
        folderName = nil
        lastError = nil
    }

    /// Called after every saved change; bursts collapse into one backup.
    func scheduleBackup() {
        guard isEnabled else { return }
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .seconds(30))
            guard !Task.isCancelled else { return }
            backupNow()
        }
    }

    /// At launch / foreground: back up if the last one is over a day old.
    func backupIfStale(now: Date = .now) {
        guard isEnabled, lastBackupAt.map({ now.timeIntervalSince($0) > 86_400 }) ?? true else { return }
        backupNow(now: now)
    }

    @discardableResult
    func backupNow(now: Date = .now) -> Bool {
        pending?.cancel()
        guard let folder = resolveFolder() else { return false }
        let access = folder.startAccessingSecurityScopedResource()
        defer { if access { folder.stopAccessingSecurityScopedResource() } }
        do {
            let data = try JSONEncoder().encode(DataStore.shared.backup())
            try CoordinatedFile.write(data, to: folder.appending(path: BackupNaming.fileName(for: now)))
            prune(folder)
            lastBackupAt = now
            defaults.set(now, forKey: Self.lastBackupKey)
            lastError = nil
            return true
        } catch {
            lastError = "Last backup failed. Check iCloud Drive has space and the folder still exists."
            log.error("Backup failed: \(error)")
            return false
        }
    }

    /// The newest backup in the folder (downloaded from iCloud if needed).
    func latestBackup() throws -> BackupFile? {
        guard let folder = resolveFolder() else { return nil }
        let access = folder.startAccessingSecurityScopedResource()
        defer { if access { folder.stopAccessingSecurityScopedResource() } }
        let names = try FileManager.default.contentsOfDirectory(atPath: folder.path)
        guard let name = BackupNaming.newest(in: names) else { return nil }
        return try Exporter.decodeBackup(CoordinatedFile.read(folder.appending(path: name)))
    }

    private func prune(_ folder: URL) {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: folder.path)) ?? []
        for name in BackupNaming.expired(in: names, keep: Self.keepDays) {
            do { try CoordinatedFile.delete(folder.appending(path: name)) } catch { log.error("Pruning \(name) failed: \(error)") }
        }
    }

    private func resolveFolder() -> URL? {
        guard let data = defaults.data(forKey: Self.bookmarkKey) else { return nil }
        var stale = false
        guard let url = try? URL(resolvingBookmarkData: data, bookmarkDataIsStale: &stale) else {
            lastError = "The backup folder can't be found. Choose it again."
            return nil
        }
        if stale {
            let access = url.startAccessingSecurityScopedResource()
            if let fresh = try? url.bookmarkData() { defaults.set(fresh, forKey: Self.bookmarkKey) }
            if access { url.stopAccessingSecurityScopedResource() }
        }
        return url
    }
}
