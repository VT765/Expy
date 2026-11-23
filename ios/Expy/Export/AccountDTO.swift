import Foundation

struct AccountDTO: Codable {
    var id: String, name: String, kind: String, openingBalancePaise: Int
    var openingDate: Int64, order: Int, updatedAt: Int64
    var deletedAt: Int64?

    private enum CodingKeys: String, CodingKey {
        case id, name, kind, openingBalancePaise, openingDate, order, updatedAt, deletedAt
        case openingBalance // version 1
    }

    init(_ a: Account) {
        id = a.id; name = a.name; kind = a.kindRaw; openingBalancePaise = a.openingBalancePaise
        openingDate = a.openingDate.epochMs; order = a.order; updatedAt = a.updatedAt.epochMs; deletedAt = a.deletedAt?.epochMs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(String.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        kind = try c.decode(String.self, forKey: .kind)
        openingBalancePaise = try LegacyAmount.paise(c, paise: .openingBalancePaise, rupees: [.openingBalance])
        openingDate = try c.decode(Int64.self, forKey: .openingDate)
        order = try c.decode(Int.self, forKey: .order)
        updatedAt = try c.decode(Int64.self, forKey: .updatedAt)
        deletedAt = try c.decodeIfPresent(Int64.self, forKey: .deletedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(kind, forKey: .kind)
        try c.encode(openingBalancePaise, forKey: .openingBalancePaise)
        try c.encode(openingDate, forKey: .openingDate)
        try c.encode(order, forKey: .order)
        try c.encode(updatedAt, forKey: .updatedAt)
        try c.encodeIfPresent(deletedAt, forKey: .deletedAt)
    }

    func apply(to a: Account) {
        a.name = name; a.kindRaw = kind; a.openingBalancePaise = openingBalancePaise; a.openingDate = Date(epochMs: openingDate)
        a.order = order; a.updatedAt = Date(epochMs: updatedAt); a.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> Account {
        let a = Account(id: id, name: name, kind: AccountKind(rawValue: kind) ?? .bank, openingBalancePaise: openingBalancePaise,
                        openingDate: Date(epochMs: openingDate), order: order)
        apply(to: a)
        return a
    }
}
