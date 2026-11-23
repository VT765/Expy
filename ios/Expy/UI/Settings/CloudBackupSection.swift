import SwiftUI
import UniformTypeIdentifiers

/// Settings → iCloud Drive backup: pick a folder once, then Expy keeps a
/// rolling 30 days of backups there. Restore the latest on a new phone.
struct CloudBackupSection: View {
    @State private var backup = CloudBackup.shared
    @State private var choosingFolder = false
    @State private var restoring: BackupFile?
    @State private var isConfirmingRestore = false
    @State private var isConfirmingOff = false

    var body: some View {
        SettingsSection(title: "iCloud Drive backup",
                        hint: "Pick a folder in iCloud Drive once. Expy saves a backup there after changes and keeps the last 30 days. Works with a free Apple ID.") {
            if let folder = backup.folderName {
                SettingsRow(title: "Backup folder", subtitle: lastBackupText, value: folder, action: chooseFolder)
                SettingsRow(title: "Back up now", action: backUpNow)
                SettingsRow(title: "Restore latest backup", subtitle: "For a new or reset iPhone", action: loadLatest)
                SettingsRow(title: "Turn off automatic backups", destructive: true, chevron: false) { isConfirmingOff = true }
            } else {
                SettingsRow(title: "Choose iCloud Drive folder",
                            subtitle: "Tip: tap New Folder and name it “Expy Backups”. On a new iPhone, pick the same folder to restore.",
                            action: chooseFolder)
            }
            if let error = backup.lastError {
                Label(error, systemImage: "exclamationmark.triangle.fill")
                    .font(.tFootnote).foregroundStyle(Theme.danger)
                    .padding(.top, 4)
            }
        }
        .fileImporter(isPresented: $choosingFolder, allowedContentTypes: [.folder], onCompletion: folderPicked)
        .alert(restoreTitle, isPresented: $isConfirmingRestore, presenting: restoring) { file in
            Button("Restore") { restore(file) }
            Button("Cancel", role: .cancel) {}
        } message: { _ in
            Text("Entries and categories from the backup are added. Matching entries are overwritten.")
        }
        .alert("Turn off automatic backups?", isPresented: $isConfirmingOff) {
            Button("Turn off", role: .destructive, action: backup.turnOff)
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Backups already in iCloud Drive stay there.")
        }
    }

    private var lastBackupText: String {
        guard let date = backup.lastBackupAt else { return "Not backed up yet" }
        return "Last backup \(date.formatted(.relative(presentation: .named)))"
    }

    private var restoreTitle: String {
        guard let file = restoring else { return "Restore backup?" }
        let when = Date(epochMs: file.exportedAt).formatted(date: .abbreviated, time: .shortened)
        return "Restore \(file.transactions.count) entries from \(when)?"
    }

    private func chooseFolder() { choosingFolder = true }

    private func folderPicked(_ result: Result<URL, Error>) {
        guard let url = try? result.get() else { return }
        backup.chooseFolder(url)
        if backup.lastError == nil { ToastCenter.shared.show("Backing up to \(url.lastPathComponent)") }
    }

    private func backUpNow() {
        if backup.backupNow() {
            Haptics.success()
            ToastCenter.shared.show("Backed up to iCloud Drive")
        }
    }

    private func loadLatest() {
        do {
            guard let file = try backup.latestBackup() else {
                ToastCenter.shared.error("No Expy backups in that folder yet")
                return
            }
            restoring = file
            isConfirmingRestore = true
        } catch {
            ToastCenter.shared.error(error.localizedDescription)
        }
    }

    private func restore(_ file: BackupFile) {
        DataStore.shared.importBackup(file)
        Haptics.success()
        ToastCenter.shared.show("Backup restored")
    }
}
