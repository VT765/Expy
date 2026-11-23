import Foundation
import SwiftData

/// Transitional: V1 plus exact paise columns, filled in by the V1 → V2
/// migration from the old Double amounts. Frozen.
enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Entry.self, ExpenseCategory.self, Account.self, Budget.self, AppSettings.self, OutboxItem.self]
    }

    @Model
    final class Entry {
        @Attribute(.unique) var id: String
        var type: String
        var amount: Double
        var currency: String
        var amountInBase: Double
        var categoryId: String
        var note: String
        var date: Date
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?
        var accountId: String? = nil
        var amountPaise: Int = 0

        init(id: String, type: String, amount: Double, currency: String, amountInBase: Double,
             categoryId: String, note: String, date: Date, createdAt: Date, updatedAt: Date, deletedAt: Date? = nil) {
            self.id = id
            self.type = type
            self.amount = amount
            self.currency = currency
            self.amountInBase = amountInBase
            self.categoryId = categoryId
            self.note = note
            self.date = date
            self.createdAt = createdAt
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }
    }

    @Model
    final class ExpenseCategory {
        @Attribute(.unique) var id: String
        var name: String
        var emoji: String
        var colorHex: String
        var order: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, name: String, emoji: String, colorHex: String, order: Int, updatedAt: Date, deletedAt: Date? = nil) {
            self.id = id
            self.name = name
            self.emoji = emoji
            self.colorHex = colorHex
            self.order = order
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }
    }

    @Model
    final class Account {
        @Attribute(.unique) var id: String
        var name: String
        var kind: String
        var openingBalance: Double
        var openingBalancePaise: Int = 0
        var openingDate: Date
        var order: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, name: String, kind: String, openingBalance: Double, openingDate: Date, order: Int, updatedAt: Date = Date.now) {
            self.id = id
            self.name = name
            self.kind = kind
            self.openingBalance = openingBalance
            self.openingDate = openingDate
            self.order = order
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class Budget {
        @Attribute(.unique) var id: String
        var categoryId: String?
        var amount: Double
        var amountPaise: Int = 0
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, categoryId: String?, amount: Double, updatedAt: Date, deletedAt: Date? = nil) {
            self.id = id
            self.categoryId = categoryId
            self.amount = amount
            self.updatedAt = updatedAt
            self.deletedAt = deletedAt
        }
    }

    @Model
    final class AppSettings {
        @Attribute(.unique) var id: String
        var baseCurrency: String
        var cycleStartDay: Int
        var rateOverrides: [String: Double]
        var updatedAt: Date

        init(id: String = "app", baseCurrency: String = "INR", cycleStartDay: Int = 1, rateOverrides: [String: Double] = [:], updatedAt: Date = .distantPast) {
            self.id = id
            self.baseCurrency = baseCurrency
            self.cycleStartDay = cycleStartDay
            self.rateOverrides = rateOverrides
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class OutboxItem {
        @Attribute(.unique) var key: String
        var collection: String
        var payload: Data
        var updatedAt: Int64

        init(key: String, collection: String, payload: Data, updatedAt: Int64) {
            self.key = key
            self.collection = collection
            self.payload = payload
            self.updatedAt = updatedAt
        }
    }
}
