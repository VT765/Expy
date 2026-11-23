import Foundation

/// Backup JSON. Version 2 stores amounts as paise and adds transfers and
/// recurring rules; version 1 files (Double rupee amounts) still decode.
struct BackupFile: Codable {
    static let currentVersion = 2

    var app = "expy"
    var version = BackupFile.currentVersion
    var exportedAt: Int64
    var transactions: [EntryDTO]
    var categories: [CategoryDTO]
    var budgets: [BudgetDTO]
    var settings: SettingsDTO?
    var accounts: [AccountDTO]? = nil
    var recurring: [RecurringRuleDTO]? = nil
}
