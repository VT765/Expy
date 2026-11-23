import Foundation
import SwiftData

/// Rupees only, exact paise, typed kinds, transfers and recurring rules
/// (Nov 2026). Frozen snapshot: never edit, it must match stores already on
/// devices. Stored properties only; behaviour lives on the current models.
enum SchemaV3: VersionedSchema {
    static let versionIdentifier = Schema.Version(3, 0, 0)
    static var models: [any PersistentModel.Type] {
        [Entry.self, ExpenseCategory.self, Account.self, Budget.self, AppSettings.self, RecurringRule.self]
    }

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
        var accountId: String?
        var toAccountId: String?
        var recurringRuleId: String?

        init(id: String, kindRaw: String, amountPaise: Int, categoryId: String, note: String, date: Date, createdAt: Date, updatedAt: Date) {
            self.id = id
            self.kindRaw = kindRaw
            self.amountPaise = amountPaise
            self.categoryId = categoryId
            self.note = note
            self.date = date
            self.createdAt = createdAt
            self.updatedAt = updatedAt
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

        init(id: String, name: String, emoji: String, colorHex: String, order: Int, updatedAt: Date) {
            self.id = id
            self.name = name
            self.emoji = emoji
            self.colorHex = colorHex
            self.order = order
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class Account {
        @Attribute(.unique) var id: String
        var name: String
        @Attribute(originalName: "kind") var kindRaw: String
        var openingBalancePaise: Int
        var openingDate: Date
        var order: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, name: String, kindRaw: String, openingBalancePaise: Int, openingDate: Date, order: Int, updatedAt: Date) {
            self.id = id
            self.name = name
            self.kindRaw = kindRaw
            self.openingBalancePaise = openingBalancePaise
            self.openingDate = openingDate
            self.order = order
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class Budget {
        @Attribute(.unique) var id: String
        var categoryId: String?
        var amountPaise: Int
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, categoryId: String?, amountPaise: Int, updatedAt: Date) {
            self.id = id
            self.categoryId = categoryId
            self.amountPaise = amountPaise
            self.updatedAt = updatedAt
        }
    }

    @Model
    final class AppSettings {
        @Attribute(.unique) var id: String
        var cycleStartDay: Int
        var updatedAt: Date

        init(id: String = "app", cycleStartDay: Int = 1, updatedAt: Date = .distantPast) {
            self.id = id
            self.cycleStartDay = cycleStartDay
            self.updatedAt = updatedAt
        }
    }

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
        var remind: Bool
        var isPaused: Bool
        var createdAt: Date
        var updatedAt: Date
        var deletedAt: Date?

        init(id: String, kindRaw: String, amountPaise: Int, categoryId: String, note: String, frequencyRaw: String,
             startDate: Date, remind: Bool, createdAt: Date) {
            self.id = id
            self.kindRaw = kindRaw
            self.amountPaise = amountPaise
            self.categoryId = categoryId
            self.note = note
            self.frequencyRaw = frequencyRaw
            self.startDate = startDate
            self.nextDate = startDate
            self.remind = remind
            self.isPaused = false
            self.createdAt = createdAt
            self.updatedAt = createdAt
        }
    }
}
