import Foundation

/// Builds export files into the temp directory and returns their URL
/// for the share sheet.
@MainActor
enum Exporter {
    static func export(_ kind: ExportKind, range: DateRange) throws -> URL {
        let store = DataStore.shared
        let stamp = ISO8601DateFormatter().string(from: Date.now).prefix(10)
        let slug = range.label.lowercased().replacing(/[^a-z0-9]+/, with: "-")
        let dir = FileManager.default.temporaryDirectory

        if kind == .backup {
            let url = dir.appendingPathComponent("expy-backup-\(stamp).json")
            try JSONEncoder().encode(store.backup()).write(to: url)
            return url
        }

        let rows = self.rows(range: range)
        guard !rows.isEmpty else { throw ExportError(message: "Nothing to export in this period") }
        if kind == .csv {
            let url = dir.appendingPathComponent("expy-\(slug).csv")
            try csv(rows).write(to: url, atomically: true, encoding: .utf8)
            return url
        }
        let url = dir.appendingPathComponent("expy-\(slug).xlsx")
        let names = store.activeCategories.map(\.name)
        let used = Set(rows.map(\.category))
        let order = names.filter(used.contains) + used.subtracting(names).sorted()
        try XLSX.workbook(rows: rows, label: range.label, range: range, categories: order).write(to: url)
        return url
    }

    static func rows(range: DateRange) -> [ExportRow] {
        let store = DataStore.shared
        let cats = Dictionary(store.fetch(ExpenseCategory.self).map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        let accounts = Dictionary(store.fetch(Account.self).map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a })
        return store.fetch(Entry.self, #Predicate { $0.deletedAt == nil })
            .filter { range.contains($0.date) }
            .sorted { $0.date < $1.date }
            .map { e in
                let account = e.accountId.flatMap { accounts[$0] } ?? ""
                return ExportRow(date: e.date, time: Fmt.time(e.date), type: e.kind.rawValue.capitalized,
                                 category: e.isTransfer ? "Transfer" : cats[e.categoryId] ?? "Other",
                                 account: e.isTransfer ? "\(account) → \(e.toAccountId.flatMap { accounts[$0] } ?? "")" : account,
                                 note: e.note, amount: e.amount)
            }
    }

    static func csv(_ rows: [ExportRow]) -> String {
        func esc(_ s: String) -> String { s.contains(where: { $0 == "," || $0 == "\"" || $0 == "\n" }) ? "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\"" : s }
        let day = DateFormatter(); day.dateFormat = "yyyy-MM-dd"
        let header = "Date,Time,Type,Category,Account,Note,Amount (INR)"
        let lines = rows.map { r in
            [day.string(from: r.date), r.time, r.type, r.category, r.account, r.note, String(r.amount)].map(esc).joined(separator: ",")
        }
        return "\u{FEFF}" + ([header] + lines).joined(separator: "\n")
    }

    static func readBackup(_ url: URL) throws -> BackupFile {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        guard let b = try? JSONDecoder().decode(BackupFile.self, from: data), b.app == "expy" else {
            throw ExportError(message: "That file isn't a valid Expy backup")
        }
        guard b.version <= BackupFile.currentVersion else {
            throw ExportError(message: "This backup is from a newer version of Expy")
        }
        guard b.transactions.allSatisfy({ $0.amountPaise > 0 && $0.kind != nil }) else {
            throw ExportError(message: "Invalid backup: some entries have bad amounts or types")
        }
        return b
    }
}
