import Foundation

/// Notifies once per budget cycle when spending reaches 80% and 100% of
/// the monthly budget or a category budget.
@MainActor
final class BudgetAlerts {
    static let shared = BudgetAlerts()
    static let enabledKey = "budgetAlertsOn"
    static let thresholds = [80, 100]

    private let defaults: UserDefaults
    private var pending: Task<Void, Never>?

    init(defaults: UserDefaults = .standard) { self.defaults = defaults }

    var isEnabled: Bool { defaults.object(forKey: Self.enabledKey) as? Bool ?? true }

    /// Coalesces bursts of saves (a statement import, recurring catch-up) into one check.
    func scheduleCheck() {
        pending?.cancel()
        pending = Task {
            try? await Task.sleep(for: .milliseconds(400))
            guard !Task.isCancelled else { return }
            check()
        }
    }

    func check(now: Date = .now) {
        guard isEnabled else { return }
        let store = DataStore.shared
        let range = Periods.range(.month, cycleDay: store.settings.cycleStartDay, now: now)
        let stats = Analytics.stats(store.fetch(Entry.self, #Predicate { $0.deletedAt == nil }), range: range, kind: .month, now: now)
        let lines = Analytics.budgets(store.fetch(Budget.self, #Predicate { $0.deletedAt == nil }), stats: stats, range: range, now: now)
        let names = Dictionary(store.activeCategories.map { ($0.id, "\($0.emoji) \($0.name)") }, uniquingKeysWith: { a, _ in a })
        for line in [lines.total].compactMap({ $0 }) + lines.categories {
            let key = "budgetAlert.\(line.id).\(Int(range.start.timeIntervalSince1970))"
            let sent = Set(defaults.array(forKey: key) as? [Int] ?? [])
            guard let threshold = Self.newThreshold(fraction: line.pct, alreadySent: sent) else { continue }
            defaults.set(Array(sent.union(Self.thresholds.filter { $0 <= threshold })), forKey: key)
            let message = Self.message(line: line, name: line.categoryId.flatMap { names[$0] }, threshold: threshold, daysLeft: lines.daysLeft)
            Notifier.post(id: "\(key).\(threshold)", title: message.title, body: message.body)
        }
    }

    /// The highest threshold reached that hasn't been announced this cycle.
    static func newThreshold(fraction: Double, alreadySent: Set<Int>) -> Int? {
        thresholds.filter { fraction * 100 >= Double($0) && !alreadySent.contains($0) }.max()
            .flatMap { t in alreadySent.contains(where: { $0 >= t }) ? nil : t }
    }

    static func message(line: BudgetLine, name: String?, threshold: Int, daysLeft: Int) -> (title: String, body: String) {
        let what = name ?? "Monthly budget"
        let usage = "\(Fmt.money(line.spent)) of \(Fmt.money(line.amount))"
        if threshold >= 100 {
            return ("\(what): over budget", "\(usage) spent, \(Fmt.money(-line.remaining)) over with \(daysLeft) \(daysLeft == 1 ? "day" : "days") left.")
        }
        return ("\(what): \(threshold)% used", "\(usage) spent. \(Fmt.money(line.remaining)) left for \(daysLeft) \(daysLeft == 1 ? "day" : "days").")
    }
}
