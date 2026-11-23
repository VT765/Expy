import Foundation

struct CategoryDTO: Codable {
    var id: String, name: String, emoji: String, color: String?, order: Int
    /// "expense" or "credit"; missing in older backups (= expense).
    var kind: String?
    var updatedAt: Int64
    var deletedAt: Int64?

    init(_ c: ExpenseCategory) {
        id = c.id; name = c.name; emoji = c.emoji; color = c.colorHex; order = c.order; kind = c.kindRaw
        updatedAt = c.updatedAt.epochMs; deletedAt = c.deletedAt?.epochMs
    }

    func apply(to c: ExpenseCategory) {
        c.kindRaw = kind ?? TransactionKind.expense.rawValue
        c.name = name; c.emoji = emoji; c.colorHex = color ?? "#9DB0C4"; c.order = order
        c.updatedAt = Date(epochMs: updatedAt); c.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> ExpenseCategory {
        let c = ExpenseCategory(id: id, kind: TransactionKind(rawValue: kind ?? "") ?? .expense, name: name, emoji: emoji, colorHex: color ?? "#9DB0C4", order: order, updatedAt: Date(epochMs: updatedAt))
        c.deletedAt = deletedAt.map(Date.init(epochMs:))
        return c
    }
}
