import Foundation
import SwiftData

typealias Entry = SchemaV4.Entry

extension SchemaV4 {
    /// One expense, credit or transfer. Transfers move money from
    /// `accountId` to `toAccountId` and have no category.
    @Model
    final class Entry {
        @Attribute(.unique) var id: String
        @Attribute(originalName: "type") var kindRaw: String
        var amountPaise: Int
        var categoryId: String
        var note: String
        var date: Date
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?
        /// Account the money moved through (the source for transfers); nil = unassigned.
        var accountId: String?
        /// Destination account; transfers only.
        var toAccountId: String?
        /// The recurring rule that created this entry, if any.
        var recurringRuleId: String?

        init(id: String = "tx_\(UUID().uuidString.lowercased())", kind: TransactionKind, amountPaise: Int, categoryId: String,
             note: String = "", date: Date, accountId: String? = nil, toAccountId: String? = nil, recurringRuleId: String? = nil,
             createdAt: Date = .now, updatedAt: Date = .now, deletedAt: Date? = nil) {
            self.id = id
            self.kindRaw = kind.rawValue
            self.amountPaise = amountPaise
            self.categoryId = categoryId
            self.note = note
            self.date = date
            self.accountId = accountId
            self.toAccountId = toAccountId
            self.recurringRuleId = recurringRuleId
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }

        var kind: TransactionKind {
            get { TransactionKind(rawValue: kindRaw) ?? .expense }
            set { kindRaw = newValue.rawValue }
        }

        var isCredit: Bool { kind == .credit }
        var isTransfer: Bool { kind == .transfer }

        /// Rupees.
        var amount: Double {
            get { Money.rupees(amountPaise) }
            set { amountPaise = Money.paise(newValue) }
        }

        /// Effect on spending in paise: expenses add, credits subtract, transfers don't count.
        var spendPaise: Int {
            switch kind {
            case .expense: amountPaise
            case .credit: -amountPaise
            case .transfer: 0
            }
        }

        /// Effect on spending in rupees (see `spendPaise`).
        var signedAmount: Double { Money.rupees(spendPaise) }

        /// Change this entry makes to an account's balance, in paise.
        func balanceEffect(on accountId: String) -> Int {
            var delta = 0
            if self.accountId == accountId { delta += kind == .credit ? amountPaise : -amountPaise }
            if kind == .transfer, toAccountId == accountId { delta += amountPaise }
            return delta
        }
    }
}
