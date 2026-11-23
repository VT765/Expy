import Foundation

struct Bucket: Identifiable {
    let start: Date
    let end: Date
    let short: String
    let long: String
    var total: Double = 0
    var id: Date { start }
}

struct CategoryTotal: Identifiable {
    let categoryId: String
    let total: Double
    let pct: Double
    var id: String { categoryId }
}

struct Stats {
    var count = 0
    var spent = 0.0
    var credit = 0.0
    var net: Double { spent - credit }
    var days = 1
    var avgPerDay: Double { spent / Double(max(days, 1)) }
    var categories: [CategoryTotal] = []
    var buckets: [Bucket] = []
    var top: [Entry] = []
}

struct BudgetLine: Identifiable {
    let id: String
    let categoryId: String?
    let amount: Double
    let spent: Double
    var remaining: Double { amount - spent }
    var pct: Double { amount > 0 ? spent / amount : 0 }
    var over: Bool { remaining < 0 }
    let perDay: Double
}

enum Analytics {
    static func buckets(for r: DateRange, kind: PeriodKind) -> [Bucket] {
        let c = Periods.cal
        let days = Periods.days(r.start, r.end)
        let narrowMonth = DateFormatter(); narrowMonth.dateFormat = "MMMMM"
        let longMonth = DateFormatter(); longMonth.dateFormat = "MMM yyyy"
        let longDay = DateFormatter(); longDay.dateFormat = "EEE, MMM d"
        let narrowDay = DateFormatter(); narrowDay.dateFormat = "EEEEE"
        var out: [Bucket] = []
        var t = r.start
        if kind == .year || days > 180 {
            while t < r.end {
                let n = min(c.date(byAdding: .month, value: 1, to: t)!, r.end)
                out.append(Bucket(start: t, end: n, short: narrowMonth.string(from: t), long: longMonth.string(from: t)))
                t = n
            }
        } else if days > 45 {
            while t < r.end {
                let n = min(c.date(byAdding: .day, value: 7, to: t)!, r.end)
                out.append(Bucket(start: t, end: n, short: "", long: "Week of \(longDay.string(from: t))"))
                t = n
            }
        } else {
            while t < r.end {
                let n = c.date(byAdding: .day, value: 1, to: t)!
                let short = kind == .week ? narrowDay.string(from: t) : String(c.component(.day, from: t))
                out.append(Bucket(start: t, end: n, short: short, long: longDay.string(from: t)))
                t = n
            }
        }
        return out
    }

    static func stats(_ entries: [Entry], range r: DateRange, kind: PeriodKind, now: Date = Date()) -> Stats {
        var s = Stats()
        let list = entries.filter { $0.deletedAt == nil && r.contains($0.date) }
        s.count = list.count
        var byCat: [String: Double] = [:]
        for e in list {
            if e.isCredit { s.credit += e.amountInBase } else {
                s.spent += e.amountInBase
                byCat[e.categoryId, default: 0] += e.amountInBase
            }
        }
        if r.end != .distantFuture {
            let tomorrow = Periods.cal.date(byAdding: .day, value: 1, to: Periods.cal.startOfDay(for: now))!
            s.days = Periods.days(r.start, max(min(r.end, tomorrow), r.start.addingTimeInterval(1)))
            var b = buckets(for: r, kind: kind)
            for e in list where !e.isCredit {
                if let i = b.lastIndex(where: { $0.start <= e.date }) { b[i].total += e.amountInBase }
            }
            s.buckets = b
        }
        s.categories = byCat.map { CategoryTotal(categoryId: $0.key, total: $0.value, pct: s.spent > 0 ? $0.value / s.spent : 0) }
            .sorted { $0.total > $1.total }
        s.top = Array(list.filter { !$0.isCredit }.sorted { $0.amountInBase > $1.amountInBase }.prefix(5))
        return s
    }

    static func budgets(_ budgets: [Budget], stats: Stats, range r: DateRange, now: Date = Date()) -> (total: BudgetLine?, categories: [BudgetLine], daysLeft: Int) {
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
