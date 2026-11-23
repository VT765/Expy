import Foundation

struct RecurringRuleDTO: Codable {
    var id: String, type: String, amountPaise: Int, categoryId: String
    var accountId: String?, toAccountId: String?, note: String
    var frequency: String, startDate: Int64, nextDate: Int64, endDate: Int64?
    var remind: Bool, isPaused: Bool
    var createdAt: Int64, updatedAt: Int64, deletedAt: Int64?

    init(_ r: RecurringRule) {
        id = r.id; type = r.kindRaw; amountPaise = r.amountPaise; categoryId = r.categoryId
        accountId = r.accountId; toAccountId = r.toAccountId; note = r.note
        frequency = r.frequencyRaw; startDate = r.startDate.epochMs; nextDate = r.nextDate.epochMs; endDate = r.endDate?.epochMs
        remind = r.remind; isPaused = r.isPaused
        createdAt = r.createdAt.epochMs; updatedAt = r.updatedAt.epochMs; deletedAt = r.deletedAt?.epochMs
    }

    func apply(to r: RecurringRule) {
        r.kindRaw = type; r.amountPaise = amountPaise; r.categoryId = categoryId
        r.accountId = accountId; r.toAccountId = toAccountId; r.note = note
        r.frequencyRaw = frequency; r.startDate = Date(epochMs: startDate); r.nextDate = Date(epochMs: nextDate)
        r.endDate = endDate.map(Date.init(epochMs:))
        r.remind = remind; r.isPaused = isPaused
        r.createdAt = Date(epochMs: createdAt); r.updatedAt = Date(epochMs: updatedAt); r.deletedAt = deletedAt.map(Date.init(epochMs:))
    }

    func make() -> RecurringRule {
        let r = RecurringRule(id: id, kind: TransactionKind(rawValue: type) ?? .expense, amountPaise: amountPaise, categoryId: categoryId,
                              accountId: accountId, note: note, frequency: RecurrenceFrequency(rawValue: frequency) ?? .monthly,
                              startDate: Date(epochMs: startDate))
        apply(to: r)
        return r
    }
}
