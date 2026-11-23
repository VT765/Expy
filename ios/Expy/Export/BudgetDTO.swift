import Foundation

struct BudgetDTO: Codable {
    var id: String, categoryId: String?, amountPaise: Int
    var updatedAt: Int64
    var deletedAt: Int64?

    private enum CodingKeys: String, CodingKey {
        case id, categoryId, amountPaise, updatedAt, deletedAt
        case amount // version 1
    }

    init(_ b: Budget) {
        id = b.id; categoryId = b.categoryId; amountPaise = b.amountPaise
        updatedAt = b.updatedAt.epochMs; deletedAt = b.deletedAt?.epochMs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        categoryId = try c.decodeIfPresent(String.self, forKey: .categoryId)
        amountPaise = try LegacyAmount.paise(c, paise: .amountPaise, rupees: [.amount])
        updatedAt = try c.decode(Int64.self, forKey: .updatedAt)
        deletedAt = try c.decodeIfPresent(Int64.self, forKey: .deletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encodeIfPresent(categoryId, forKey: .categoryId)
        try c.encode(amountPaise, forKey: .amountPaise)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }

    func apply(to b: Budget) {
        b.categoryId = categoryId; b.amountPaise = amountPaise
        b.updatedAt = Date(epochMs: updatedAt); b.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> Budget {
        let b = Budget(id: id, categoryId: categoryId, amountPaise: amountPaise, updatedAt: Date(epochMs: updatedAt))
        apply(to: b)
        return b
    }
}
