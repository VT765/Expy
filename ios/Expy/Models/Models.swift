import Foundation
import SwiftData

// SwiftData models mirror the server documents (shared/schemas.js) so they sync
// 1:1 with the Vercel API. Timestamps are Dates locally, epoch ms on the wire.

@Model
final class Entry {
    @Attribute(.unique) var id: String
    var type: String // "expense" | "credit"
    var amount: Double
    var currency: String
    var amountInBase: Double
    var categoryId: String
    var note: String
    var date: Date
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

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

    var isCredit: Bool { type == "credit" }
    /// Credits count negative in totals.
    var signedBase: Double { isCredit ? -amountInBase : amountInBase }
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
final class Budget {
    @Attribute(.unique) var id: String
    var categoryId: String? // nil = overall monthly budget
    var amount: Double
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
    @Attribute(.unique) var id: String // always "app"
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

/// Local change waiting to be pushed. Keyed by collection + id, so repeated
/// edits to one record collapse into a single pending write.
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

enum Persistence {
    static let schema = Schema([Entry.self, ExpenseCategory.self, Budget.self, AppSettings.self, OutboxItem.self])

    static let container: ModelContainer = {
        do {
            return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema))
        } catch {
            fatalError("Could not open the Expy database: \(error)")
        }
    }()
}
