import Foundation

/// File names for automatic backups: one file per day
/// ("Expy-backup-2026-11-23.json"), so they sort by date and a day's
/// later backups replace its earlier one.
enum BackupNaming {
    static let prefix = "Expy-backup-"
    static let ext = ".json"

    static func fileName(for date: Date, calendar: Calendar = .current) -> String {
        let c = calendar.dateComponents([.year, .month, .day], from: date)
        let two = IntegerFormatStyle<Int>.number.precision(.integerLength(2)).grouping(.never)
        return "\(prefix)\((c.year ?? 0).formatted(.number.grouping(.never)))-\((c.month ?? 0).formatted(two))-\((c.day ?? 0).formatted(two))\(ext)"
    }

    /// The backup's real name, also for an iCloud placeholder of a file not
    /// downloaded yet (".Expy-backup-2026-11-23.json.icloud"); nil for other files.
    static func backupName(_ fileName: String) -> String? {
        var n = fileName
        if n.hasPrefix(".") && n.hasSuffix(".icloud") { n = String(n.dropFirst().dropLast(".icloud".count)) }
        return n.hasPrefix(prefix) && n.hasSuffix(ext) ? n : nil
    }

    /// Newest backup's real name in a folder listing.
    static func newest(in names: [String]) -> String? { names.compactMap(backupName).max() }

    /// Listing entries (as they appear on disk) older than the newest `keep` days.
    static func expired(in names: [String], keep: Int) -> [String] {
        let kept = Set(names.compactMap(backupName).sorted(by: >).prefix(keep))
        return names.filter { name in backupName(name).map { !kept.contains($0) } ?? false }
    }
}
