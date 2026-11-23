import Foundation

struct EntryDTO: Codable {
    var id: String, type: String, amountPaise: Int
    var categoryId: String, note: String
    var date: Int64, createdAt: Int64, updatedAt: Int64
    var deletedAt: Int64?
    var accountId: String?
    var toAccountId: String?
    var recurringRuleId: String?

    private enum CodingKeys: String, CodingKey {
        case id, type, amountPaise, categoryId, note, date, createdAt, updatedAt, deletedAt, accountId, toAccountId, recurringRuleId
        case amount, amountInBase // version 1
    }

    init(_ e: Entry) {
        id = e.id; type = e.kindRaw; amountPaise = e.amountPaise
        categoryId = e.categoryId; note = e.note
        date = e.date.epochMs; createdAt = e.createdAt.epochMs; updatedAt = e.updatedAt.epochMs
        deletedAt = e.deletedAt?.epochMs
        accountId = e.accountId; toAccountId = e.toAccountId; recurringRuleId = e.recurringRuleId
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        type = try c.decode(String.self, forKey: .type)
        // Version 1 kept the rupee value in amountInBase.
        amountPaise = try LegacyAmount.paise(c, paise: .amountPaise, rupees: [.amountInBase, .amount])
        categoryId = try c.decode(String.self, forKey: .categoryId)
        note = try c.decodeIfPresent(String.self, forKey: .note) ?? ""
        date = try c.decode(Int64.self, forKey: .date)
        createdAt = try c.decodeIfPresent(Int64.self, forKey: .createdAt) ?? date
        updatedAt = try c.decodeIfPresent(Int64.self, forKey: .updatedAt) ?? date
        deletedAt = try c.decodeIfPresent(Int64.self, forKey: .deletedAt)
        accountId = try c.decodeIfPresent(String.self, forKey: .accountId)
        toAccountId = try c.decodeIfPresent(String.self, forKey: .toAccountId)
        recurringRuleId = try c.decodeIfPresent(String.self, forKey: .recurringRuleId)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(type, forKey: .type)
        try c.encode(amountPaise, forKey: .amountPaise)
        try c.encode(categoryId, forKey: .categoryId)
        try c.encode(note, forKey: .note)
        try c.encode(date, forKey: .date)
        try c.encode(createdAt, forKey: .createdAt)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
        try c.encodeIfPresent(accountId, forKey: .accountId)
        try c.encodeIfPresent(toAccountId, forKey: .toAccountId)
        try c.encodeIfPresent(recurringRuleId, forKey: .recurringRuleId)
    }

    var kind: TransactionKind? { TransactionKind(rawValue: type) }

    func apply(to e: Entry) {
        e.kindRaw = type; e.amountPaise = amountPaise
        e.categoryId = categoryId; e.note = note
        e.date = Date(epochMs: date); e.createdAt = Date(epochMs: createdAt); e.updatedAt = Date(epochMs: updatedAt)
        e.deletedAt = deletedAt.map(Date.init(epochMs:))
        e.accountId = accountId; e.toAccountId = toAccountId; e.recurringRuleId = recurringRuleId
    }

    func make() -> Entry {
        let e = Entry(id: id, kind: kind ?? .expense, amountPaise: amountPaise, categoryId: categoryId, note: note,
                      date: Date(epochMs: date), createdAt: Date(epochMs: createdAt), updatedAt: Date(epochMs: updatedAt))
        apply(to: e)
        return e
    }
}
