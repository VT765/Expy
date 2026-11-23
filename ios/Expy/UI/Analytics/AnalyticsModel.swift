import Foundation
import Observation

/// Computes everything Analytics shows for a period. Cached per input key,
/// so selecting a bar or slice doesn't recompute the stats.
@MainActor
@Observable
final class AnalyticsModel {
    struct Snapshot {
        var range: DateRange
        var stats: Stats
        var previous: Stats
        var budget: (total: BudgetLine?, categories: [BudgetLine], daysLeft: Int)?
        /// Spending for this and the previous periods (oldest first); nil for custom ranges.
        var trend: [TrendPoint]?
        var insight: (categoryId: String, delta: Double)?
        var balances: [String: Double]
        var dailyBudget: Double?
    }

    struct Key: Hashable {
        var kind: PeriodKind
        var offset: Int
        var from: Date
        var to: Date
        var cycleDay: Int
        var entryCount: Int
        var entryStamp: Date
        var budgetStamp: Date
        var accountStamp: Date
    }

    @ObservationIgnored private var cache: (key: Key, snapshot: Snapshot)?

    func snapshot(entries: [Entry], budgets: [Budget], accounts: [Account], key: Key) -> Snapshot {
        if let cache, cache.key == key { return cache.snapshot }
        let snap = Self.build(entries: entries, budgets: budgets, accounts: accounts, key: key)
        cache = (key, snap)
        return snap
    }

    static func build(entries: [Entry], budgets: [Budget], accounts: [Account], key: Key) -> Snapshot {
        let range = Periods.range(key.kind, offset: key.offset, cycleDay: key.cycleDay, from: key.from, to: key.to)
        let stats = Analytics.stats(entries, range: range, kind: key.kind)
        let previous = Analytics.stats(entries, range: Periods.previous(key.kind, offset: key.offset, cycleDay: key.cycleDay,
                                                                         from: key.from, to: key.to), kind: key.kind)
        let budget = key.kind == .month && key.offset == 0 ? Analytics.budgets(budgets, stats: stats, range: range) : nil
        let perDay = budget?.total.map { $0.amount / Double(max(1, Periods.days(range.start, range.end))) }
        let trend = trendLength(key.kind).map { n in
            (0..<n).reversed().map { i in
                let r = Periods.range(key.kind, offset: key.offset - i, cycleDay: key.cycleDay)
                return TrendPoint(start: r.start, label: trendLabel(r.start, kind: key.kind),
                                  total: Analytics.spent(entries, in: r), isCurrent: i == 0)
            }
        }
        return Snapshot(range: range, stats: stats, previous: previous, budget: budget, trend: trend,
                        insight: Analytics.biggestChange(stats, previous),
                        balances: Dictionary(uniqueKeysWithValues: accounts.map { ($0.id, DataStore.balance(of: $0, entries: entries)) }),
                        dailyBudget: stats.buckets.count <= 45 ? perDay : nil)
    }

    /// How many periods the trend shows: 6 months, 8 weeks or 4 years.
    static func trendLength(_ kind: PeriodKind) -> Int? {
        switch kind {
        case .month: 6
        case .week: 8
        case .year: 4
        default: nil
        }
    }

    static func trendLabel(_ start: Date, kind: PeriodKind) -> String {
        switch kind {
        case .year: start.formatted(.dateTime.year())
        case .week: start.formatted(.dateTime.day().month(.abbreviated))
        default: start.formatted(.dateTime.month(.abbreviated))
        }
    }
}
