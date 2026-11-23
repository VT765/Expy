import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Excel / CSV export, JSON backup and restore, erase everything.
struct DataSettingsSection: View {
    @Query private var settingsList: [AppSettings]
    @State private var exportChoice: ExportKind?
    @State private var busy: ExportKind?
    @State private var shareURL: ShareItem?
    @State private var importing = false
    @State private var confirmation: Confirmation?
    @State private var isConfirming = false

    /// The destructive or bulk actions that ask first.
    enum Confirmation {
        case erase, eraseFinal, restore(BackupFile)

        var title: String {
            switch self {
            case .erase: "Erase all data?"
            case .eraseFinal: "Are you absolutely sure?"
            case .restore(let b): "Restore \(b.transactions.count) entries?"
            }
        }

        var message: String {
            switch self {
            case .erase: "Every entry, budget and custom category on this iPhone will be deleted."
            case .eraseFinal: "This cannot be undone. Consider exporting a backup first."
            case .restore: "Entries and categories from the backup will be added. Matching entries are overwritten."
            }
        }
    }

    private var currentCycle: DateRange { Periods.range(.month, cycleDay: settingsList.first?.cycleStartDay ?? 1) }

    var body: some View {
        SettingsSection(title: "Data") {
            SettingsRow(title: "Export to Excel", value: busy == .xlsx ? "Preparing…" : nil) { exportChoice = .xlsx }
            SettingsRow(title: "Export CSV", value: busy == .csv ? "Preparing…" : nil) { exportChoice = .csv }
            SettingsRow(title: "Back up (JSON)", subtitle: "Everything, for restoring later", action: backup)
            SettingsRow(title: "Restore from backup", action: pickBackup)
            SettingsRow(title: "Erase all data", destructive: true, chevron: false) { ask(.erase) }
        }
        .sheet(item: $exportChoice) { kind in
            OptionList(title: kind == .xlsx ? "Export to Excel" : "Export CSV",
                       options: [(0, "Current cycle · \(currentCycle.label)"), (1, "All time")], selected: -1) { choice in
                runExport(kind, range: choice == 0 ? currentCycle : .allTime)
            }
        }
        .sheet(item: $shareURL) { ShareSheet(items: [$0.url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json], onCompletion: backupPicked)
        .alert(confirmation?.title ?? "", isPresented: $isConfirming, presenting: confirmation) { kind in
            confirmButtons(kind)
        } message: { kind in
            Text(kind.message)
        }
    }

    @ViewBuilder private func confirmButtons(_ kind: Confirmation) -> some View {
        switch kind {
        case .erase:
            Button("Erase", role: .destructive, action: confirmFirstErase)
        case .eraseFinal:
            Button("Erase everything", role: .destructive, action: eraseEverything)
        case .restore(let backup):
            Button("Restore") { restore(backup) }
        }
        Button("Cancel", role: .cancel) {}
    }

    // MARK: - Actions

    private func ask(_ kind: Confirmation) {
        confirmation = kind
        isConfirming = true
    }

    /// Second confirmation once the first alert has finished dismissing.
    private func confirmFirstErase() {
        Task {
            try? await Task.sleep(for: .milliseconds(400))
            ask(.eraseFinal)
        }
    }

    private func eraseEverything() {
        DataStore.shared.eraseAll()
        ToastCenter.shared.show("All data erased")
    }

    private func restore(_ backup: BackupFile) {
        DataStore.shared.importBackup(backup)
        ToastCenter.shared.show("Backup restored")
    }

    private func backup() { runExport(.backup, range: .allTime) }
    private func pickBackup() { importing = true }

    private func backupPicked(_ result: Result<URL, Error>) {
        do {
            ask(.restore(try Exporter.readBackup(try result.get())))
        } catch {
            ToastCenter.shared.error(error.localizedDescription)
        }
    }

    private func runExport(_ kind: ExportKind, range: DateRange) {
        busy = kind
        Task {
            defer { busy = nil }
            // Let the option sheet finish dismissing before presenting the share sheet.
            try? await Task.sleep(for: .milliseconds(350))
            do { shareURL = ShareItem(url: try Exporter.export(kind, range: range)) }
            catch { ToastCenter.shared.error(error.localizedDescription) }
        }
    }
}
