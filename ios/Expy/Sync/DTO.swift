import Foundation

// Wire format matching shared/schemas.js (epoch-ms Int64 timestamps).

struct EntryDTO: Codable {
    var id: String, type: String, amount: Double, currency: String, amountInBase: Double
    var categoryId: String, note: String
    var date: Int64, createdAt: Int64, updatedAt: Int64
    var deletedAt: Int64?

    init(_ e: Entry) {
        id = e.id; type = e.type; amount = e.amount; currency = e.currency; amountInBase = e.amountInBase
        categoryId = e.categoryId; note = e.note
        date = e.date.epochMs; createdAt = e.createdAt.epochMs; updatedAt = e.updatedAt.epochMs
        deletedAt = e.deletedAt?.epochMs
    }

    func apply(to e: Entry) {
        e.type = type; e.amount = amount; e.currency = currency; e.amountInBase = amountInBase
        e.categoryId = categoryId; e.note = note
        e.date = Date(epochMs: date); e.createdAt = Date(epochMs: createdAt); e.updatedAt = Date(epochMs: updatedAt)
        e.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> Entry {
        let e = Entry(id: id, type: type, amount: amount, currency: currency, amountInBase: amountInBase, categoryId: categoryId,
                      note: note, date: Date(epochMs: date), createdAt: Date(epochMs: createdAt), updatedAt: Date(epochMs: updatedAt))
        e.deletedAt = deletedAt.map(Date.init(epochMs:))
        return e
    }
}

struct CategoryDTO: Codable {
    var id: String, name: String, emoji: String, color: String?, order: Int
    var updatedAt: Int64
    var deletedAt: Int64?

    init(_ c: ExpenseCategory) {
        id = c.id; name = c.name; emoji = c.emoji; color = c.colorHex; order = c.order
        updatedAt = c.updatedAt.epochMs; deletedAt = c.deletedAt?.epochMs
    }

    func apply(to c: ExpenseCategory) {
        c.name = name; c.emoji = emoji; c.colorHex = color ?? "#9DB0C4"; c.order = order
        c.updatedAt = Date(epochMs: updatedAt); c.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> ExpenseCategory {
        let c = ExpenseCategory(id: id, name: name, emoji: emoji, colorHex: color ?? "#9DB0C4", order: order, updatedAt: Date(epochMs: updatedAt))
        c.deletedAt = deletedAt.map(Date.init(epochMs:))
        return c
    }
}

struct BudgetDTO: Codable {
    var id: String, categoryId: String?, amount: Double
    var updatedAt: Int64
    var deletedAt: Int64?

    init(_ b: Budget) {
        id = b.id; categoryId = b.categoryId; amount = b.amount
        updatedAt = b.updatedAt.epochMs; deletedAt = b.deletedAt?.epochMs
    }

    func apply(to b: Budget) {
        b.categoryId = categoryId; b.amount = amount
        b.updatedAt = Date(epochMs: updatedAt); b.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> Budget {
        let b = Budget(id: id, categoryId: categoryId, amount: amount, updatedAt: Date(epochMs: updatedAt))
        b.deletedAt = deletedAt.map(Date.init(epochMs:))
        return b
    }

    // Encode categoryId as explicit null (the server schema requires the key).
    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(categoryId, forKey: .categoryId)
        try c.encode(amount, forKey: .amount)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encode(deletedAt, forKey: .deletedAt)
    }
}

struct SettingsDTO: Codable {
    var id: String = "app"
    var baseCurrency: String, cycleStartDay: Int, rateOverrides: [String: Double]
    var updatedAt: Int64

    init(_ s: AppSettings) {
        baseCurrency = s.baseCurrency; cycleStartDay = s.cycleStartDay; rateOverrides = s.rateOverrides
        updatedAt = max(0, s.updatedAt.epochMs)
    }

    func apply(to s: AppSettings) {
        s.baseCurrency = baseCurrency; s.cycleStartDay = cycleStartDay; s.rateOverrides = rateOverrides
        s.updatedAt = Date(epochMs: updatedAt)
    }
}

struct PullResponse: Decodable {
    let serverTime: Int64
    let transactions: [EntryDTO]
    let categories: [CategoryDTO]
    let budgets: [BudgetDTO]
    let settings: SettingsDTO?
}

struct BackupFile: Codable {
    var app = "expy"
    var version = 1
    var exportedAt: Int64
    var transactions: [EntryDTO]
    var categories: [CategoryDTO]
    var budgets: [BudgetDTO]
    var settings: SettingsDTO?
}
