import Foundation

/// One transaction read from a bank statement.
struct StatementRow: Identifiable, Hashable {
    let id = UUID()
    let date: Date
    let narration: String
    let amount: Double
    let isCredit: Bool
}
