import Foundation

/// Filters applied on top of the History range. Unit-tested.
struct HistoryFilters: Equatable, Hashable {
    var categoryIds: Set<String> = []
    var accountIds: Set<String> = []
    /// nil = every kind.
    var kind: TransactionKind?
    var minAmount: Double?
    var maxAmount: Double?
    var from: Date?
    var to: Date?
    var query = ""

    var isActive: Bool {
        !categoryIds.isEmpty || !accountIds.isEmpty || kind != nil || minAmount != nil || maxAmount != nil
            || from != nil || to != nil || !trimmedQuery.isEmpty
    }

    private var trimmedQuery: String { query.trimmingCharacters(in: .whitespaces) }

    func matches(_ e: Entry, categoryName: String, calendar: Calendar = .current) -> Bool {
        if !categoryIds.isEmpty && !categoryIds.contains(e.categoryId) { return false }
        if !accountIds.isEmpty && !accountIds.contains(e.accountId ?? "") && !accountIds.contains(e.toAccountId ?? "") { return false }
        if let kind, e.kind != kind { return false }
        if let minAmount, e.amount < minAmount { return false }
        if let maxAmount, e.amount > maxAmount { return false }
        if let from, e.date < calendar.startOfDay(for: from) { return false }
        if let to, let end = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: to)), e.date >= end { return false }
        let q = trimmedQuery
        if !q.isEmpty && !e.note.localizedStandardContains(q) && !categoryName.localizedStandardContains(q) { return false }
        return true
    }

    /// Membership of one category, for `Toggle(isOn: $filters[category: id])`.
    subscript(category id: String) -> Bool {
        get { categoryIds.contains(id) }
        set { if newValue { categoryIds.insert(id) } else { categoryIds.remove(id) } }
    }

    mutating func toggleCategory(_ id: String) {
        if categoryIds.contains(id) { categoryIds.remove(id) } else { categoryIds.insert(id) }
    }

    mutating func toggleAccount(_ id: String) {
        if accountIds.contains(id) { accountIds.remove(id) } else { accountIds.insert(id) }
    }
}
