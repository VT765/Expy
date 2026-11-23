import Foundation

/// One spreadsheet row; `type` is "Expense", "Credit" or "Transfer".
struct ExportRow {
    let date: Date, time: String, type: String, category: String, account: String, note: String
    let amount: Double
}
