import Foundation
import SwiftData

typealias RecurringRule = SchemaV4.RecurringRule

extension SchemaV4 {
    /// Rent, a subscription or an EMI: creates an entry on `nextDate`, then
    /// advances by `frequency`, until `endDate` (inclusive) if set.
    @Model
    final class RecurringRule {
        @Attribute(.unique) var id: String
        var kindRaw: String
        var amountPaise: Int
        var categoryId: String
        var accountId: String?
        var toAccountId: String?
        var note: String
        var frequencyRaw: String
        var startDate: Date
        var nextDate: Date
        var endDate: Date?
        /// Send a reminder notification on the due day.
        var remind: Bool
        var isPaused: Bool
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String = "rec_\(UUID().uuidString.lowercased())", kind: TransactionKind, amountPaise: Int, categoryId: String,
             accountId: String?, toAccountId: String? = nil, note: String, frequency: RecurrenceFrequency, startDate: Date,
             endDate: Date? = nil, remind: Bool = true, createdAt: Date = .now) {
            self.id = id
            self.kindRaw = kind.rawValue
            self.amountPaise = amountPaise
            self.categoryId = categoryId
            self.accountId = accountId
            self.toAccountId = toAccountId
            self.note = note
            self.frequencyRaw = frequency.rawValue
            self.startDate = startDate
            self.nextDate = startDate
            self.endDate = endDate
            self.remind = remind
            self.isPaused = false
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }

        var kind: TransactionKind {
            get { TransactionKind(rawValue: kindRaw) ?? .expense }
            set { kindRaw = newValue.rawValue }
        }

        var frequency: RecurrenceFrequency {
            get { RecurrenceFrequency(rawValue: frequencyRaw) ?? .monthly }
            set { frequencyRaw = newValue.rawValue }
        }

        /// Rupees.
        var amount: Double {
            get { Money.rupees(amountPaise) }
            set { amountPaise = Money.paise(newValue) }
        }
    }
}
