import Foundation
import Observation

/// Groups and totals History entries. Results are cached and only rebuilt
/// when an input changes, so `body` stays cheap during scrolling and taps.
@MainActor
@Observable
final class HistoryModel {
    struct Section: Identifiable {
        let id: String
        let title: String
        var items: [Entry] = []
        var total = 0.0
    }

    struct Result {
        var sections: [Section] = []
        var spent = 0.0
        var received = 0.0
        var count = 0
        var net: Double { spent - received }
    }

    /// Everything the result depends on.
    struct Key: Hashable {
        var range: String
        var cycleDay: Int
        var grouping: String
        var filters: HistoryFilters
        var entryCount: Int
        var entryStamp: Date
        var categoryStamp: Date
    }

    @ObservationIgnored private var cache: (key: Key, result: Result)?

    func result(entries: [Entry], categories: [String: ExpenseCategory], key: Key) -> Result {
        if let cache, cache.key == key { return cache.result }
        let result = Self.build(entries: entries, categories: categories, key: key)
        cache = (key, result)
        return result
    }

    static func key(range: String, cycleDay: Int, grouping: String, filters: HistoryFilters,
                    entries: [Entry], categories: [ExpenseCategory]) -> Key {
        Key(range: range, cycleDay: cycleDay, grouping: grouping, filters: filters,
            entryCount: entries.count, entryStamp: entries.map(\.updatedAt).max() ?? .distantPast,
            categoryStamp: categories.map(\.updatedAt).max() ?? .distantPast)
    }

    static func build(entries: [Entry], categories: [String: ExpenseCategory], key: Key) -> Result {
        let r = Periods.range(PeriodKind(rawValue: key.range) ?? .month, cycleDay: key.cycleDay)
        let byCategory = key.grouping == "category"
        let cal = Calendar.current
        var out = Result()
        var index: [String: Int] = [:]
        for e in entries where r.contains(e.date) && key.filters.matches(e, categoryName: categories[e.categoryId]?.name ?? "") {
            let sectionId: String
            let title: String
            if byCategory && e.isTransfer {
                sectionId = "__transfers"
                title = "⇄  Transfers"
            } else if byCategory {
                let c = categories[e.categoryId] ?? categories[Defaults.otherCategoryId]
                sectionId = c?.id ?? Defaults.otherCategoryId
                title = "\(c?.emoji ?? "✨")  \(c?.name ?? "Other")"
            } else {
                let day = cal.startOfDay(for: e.date)
                sectionId = "\(day.timeIntervalSince1970)"
                title = Fmt.dayHeader(day)
            }
            let i: Int
            if let existing = index[sectionId] {
                i = existing
            } else {
                i = out.sections.count
                index[sectionId] = i
                out.sections.append(Section(id: sectionId, title: title))
            }
            out.sections[i].items.append(e)
            out.sections[i].total += e.signedAmount
            switch e.kind {
            case .expense: out.spent += e.amount
            case .credit: out.received += e.amount
            case .transfer: break
            }
            out.count += 1
        }
        if byCategory { out.sections.sort { $0.total > $1.total } }
        return out
    }
}
