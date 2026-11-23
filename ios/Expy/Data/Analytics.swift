import Foundation

enum Analytics {
    static func buckets(for r: DateRange, kind: PeriodKind) -> [Bucket] {
        let c = Periods.cal
        let days = Periods.days(r.start, r.end)
        let narrowMonth = Date.FormatStyle.dateTime.month(.narrow)
        let longMonth = Date.FormatStyle.dateTime.month(.abbreviated).year()
        let longDay = Date.FormatStyle.dateTime.weekday(.abbreviated).month(.abbreviated).day()
        let narrowDay = Date.FormatStyle.dateTime.weekday(.narrow)
        var out: [Bucket] = []
        var t = r.start
        if kind == .year || days > 180 {
            while t < r.end {
                let n = min(c.date(byAdding: .month, value: 1, to: t)!, r.end)
                out.append(Bucket(start: t, end: n, short: t.formatted(narrowMonth), long: t.formatted(longMonth)))
                t = n
            }
        } else if days > 45 {
            while t < r.end {
                let n = min(c.date(byAdding: .day, value: 7, to: t)!, r.end)
                out.append(Bucket(start: t, end: n, short: "", long: "Week of \(t.formatted(longDay))"))
                t = n
            }
        } else {
            while t < r.end {
                let n = c.date(byAdding: .day, value: 1, to: t)!
                let short = kind == .week ? t.formatted(narrowDay) : String(c.component(.day, from: t))
                out.append(Bucket(start: t, end: n, short: short, long: t.formatted(longDay)))
                t = n
            }
        }
        return out
    }

    /// Totals for a period, summed in exact paise. Transfers move money between
    /// your own accounts, so they never count as spending or income.
    static func stats(_ entries: [Entry], range r: DateRange, kind: PeriodKind, now: Date = Date.now) -> Stats {
        var s = Stats()
        let list = entries.filter { $0.deletedAt == nil && !$0.isTransfer && r.contains($0.date) }
        s.count = list.count
        var spent = 0, credit = 0
        var byCat: [String: Int] = [:]
        for e in list {
            if e.isCredit { credit += e.amountPaise } else {
                spent += e.amountPaise
                byCat[e.categoryId, default: 0] += e.amountPaise
            }
        }
        s.spent = Money.rupees(spent)
        s.credit = Money.rupees(credit)
        if r.end != .distantFuture {
            let tomorrow = Periods.cal.date(byAdding: .day, value: 1, to: Periods.cal.startOfDay(for: now))!
            s.days = Periods.days(r.start, max(min(r.end, tomorrow), r.start.addingTimeInterval(1)))
            var b = buckets(for: r, kind: kind)
            var totals = Array(repeating: 0, count: b.count)
            for e in list where !e.isCredit {
                if let i = b.lastIndex(where: { $0.start <= e.date }) { totals[i] += e.amountPaise }
            }
            for i in b.indices { b[i].total = Money.rupees(totals[i]) }
            s.buckets = b
        }
        s.categories = byCat.map { CategoryTotal(categoryId: $0.key, total: Money.rupees($0.value), pct: spent > 0 ? Double($0.value) / Double(spent) : 0) }
            .sorted { $0.total > $1.total }
        s.top = Array(list.filter { !$0.isCredit }.sorted { $0.amountPaise > $1.amountPaise }.prefix(5))
        return s
    }

    /// Total spent (expenses only) in a range, summed in paise.
    static func spent(_ entries: [Entry], in r: DateRange) -> Double {
        Money.rupees(entries.reduce(0) { $0 + ($1.deletedAt == nil && $1.kind == .expense && r.contains($1.date) ? $1.amountPaise : 0) })
    }

    /// Category whose spending moved most vs the previous period.
    static func biggestChange(_ now: Stats, _ prev: Stats) -> (categoryId: String, delta: Double)? {
        guard prev.spent > 0 else { return nil }
        let before = Dictionary(uniqueKeysWithValues: prev.categories.map { ($0.categoryId, $0.total) })
        let after = Dictionary(uniqueKeysWithValues: now.categories.map { ($0.categoryId, $0.total) })
        return Set(before.keys).union(after.keys)
            .map { ($0, (after[$0] ?? 0) - (before[$0] ?? 0)) }
            .max { abs($0.1) < abs($1.1) }
            .flatMap { abs($0.1) >= 1 ? (categoryId: $0.0, delta: $0.1) : nil }
    }

    static func budgets(_ budgets: [Budget], stats: Stats, range r: DateRange, now: Date = Date.now) -> (total: BudgetLine?, categories: [BudgetLine], daysLeft: Int) {
        let active = budgets.filter { $0.deletedAt == nil && $0.amount > 0 }
        let daysLeft = max(1, Periods.days(max(Periods.cal.startOfDay(for: now), r.start), r.end))
        let spentByCat = Dictionary(uniqueKeysWithValues: stats.categories.map { ($0.categoryId, $0.total) })
        func line(_ b: Budget, _ spent: Double) -> BudgetLine {
            BudgetLine(id: b.id, categoryId: b.categoryId, amount: b.amount, spent: spent, perDay: max(0, b.amount - spent) / Double(daysLeft))
        }
        let total = active.first { $0.categoryId == nil }.map { line($0, stats.spent) }
        let cats = active.filter { $0.categoryId != nil }.map { line($0, spentByCat[$0.categoryId!] ?? 0) }
        return (total, cats, daysLeft)
    }
}
