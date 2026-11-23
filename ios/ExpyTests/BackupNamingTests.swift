import Foundation
import Testing
@testable import Expy

struct BackupNamingTests {
    @Test func oneFilePerDaySortsByDate() {
        #expect(BackupNaming.fileName(for: TestData.date(2026, 11, 3, 21)) == "Expy-backup-2026-11-03.json")
        #expect(BackupNaming.fileName(for: TestData.date(2026, 11, 3, 8)) == BackupNaming.fileName(for: TestData.date(2026, 11, 3, 23)))
    }

    @Test func readsICloudPlaceholdersAndIgnoresOtherFiles() {
        #expect(BackupNaming.backupName(".Expy-backup-2026-11-03.json.icloud") == "Expy-backup-2026-11-03.json")
        #expect(BackupNaming.backupName("Expy-backup-2026-11-03.json") == "Expy-backup-2026-11-03.json")
        #expect(BackupNaming.backupName("notes.txt") == nil)
        #expect(BackupNaming.backupName("Expy-backup-2026-11-03 2.json") == "Expy-backup-2026-11-03 2.json") // still a backup
    }

    @Test func newestIncludesFilesStillInICloud() {
        let names = ["Expy-backup-2026-11-01.json", ".Expy-backup-2026-11-23.json.icloud", "photo.jpg"]
        #expect(BackupNaming.newest(in: names) == "Expy-backup-2026-11-23.json")
    }

    @Test func pruningKeepsTheNewestDays() {
        let names = (1...5).map { "Expy-backup-2026-11-0\($0).json" } + ["readme.txt", ".Expy-backup-2026-10-30.json.icloud"]
        let expired = BackupNaming.expired(in: names, keep: 3)
        #expect(Set(expired) == ["Expy-backup-2026-11-01.json", "Expy-backup-2026-11-02.json", ".Expy-backup-2026-10-30.json.icloud"])
    }
}

@MainActor
struct CloudBackupRoundTripTests {
    @Test func backsUpToAFolderAndRestoresTheLatest() throws {
        let folder = FileManager.default.temporaryDirectory.appending(path: "expy-backups-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        let defaults = UserDefaults(suiteName: "backup-\(UUID().uuidString)")!
        let backup = CloudBackup(defaults: defaults)
        backup.chooseFolder(folder)
        #expect(backup.lastError == nil)
        #expect(backup.backupNow(now: TestData.date(2026, 11, 22)))
        #expect(backup.backupNow(now: TestData.date(2026, 11, 23)))
        let files = try FileManager.default.contentsOfDirectory(atPath: folder.path).sorted()
        #expect(files == ["Expy-backup-2026-11-22.json", "Expy-backup-2026-11-23.json"])
        let latest = try #require(try backup.latestBackup())
        #expect(latest.app == "expy")
        #expect(latest.version == BackupFile.currentVersion)
        try? FileManager.default.removeItem(at: folder)
    }
}
