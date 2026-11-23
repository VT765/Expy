import Foundation
import SwiftData

typealias ExpenseCategory = SchemaV4.ExpenseCategory

extension SchemaV4 {
    /// A debit (expense) or credit (income) category.
    @Model
    final class ExpenseCategory {
        @Attribute(.unique) var id: String
        /// "expense" or "credit"; transfers have no category.
        var kindRaw: String = TransactionKind.expense.rawValue
        var name: String
        var emoji: String
        var colorHex: String
        var order: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, kind: TransactionKind = .expense, name: String, emoji: String, colorHex: String, order: Int,
             updatedAt: Date, deletedAt: Date? = nil) {
            self.id = id
            self.kindRaw = kind.rawValue
            self.name = name
            self.emoji = emoji
            self.colorHex = colorHex
            self.order = order
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }

        var kind: TransactionKind {
            get { TransactionKind(rawValue: kindRaw) ?? .expense }
            set { kindRaw = newValue.rawValue }
        }

        var isCredit: Bool { kind == .credit }
    }
}
