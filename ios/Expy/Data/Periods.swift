import Foundation

enum PeriodKind: String, CaseIterable, Identifiable {
    case today, week, month, year, all, custom
    var id: String { rawValue }
}

struct DateRange: Equatable {
    var start: Date
    var end: Date // exclusive
    var label: String
    func contains(_ d: Date) -> Bool { d >= start && d < end }
    static let allTime = DateRange(start: .distantPast, end: .distantFuture, label: "All time")
}

enum Periods {
    static var cal: Calendar {
        var c = Calendar.current
        c.firstWeekday = 2 // Monday
        return c
    }

    static func startOfCycle(_ date: Date, cycleDay: Int) -> Date {
        let c = cal
        var comps = c.dateComponents([.year, .month, .day], from: date)
        if (comps.day ?? 1) < cycleDay { comps.month! -= 1 }
        comps.day = cycleDay
        return c.date(from: comps)!
    }

    private static let monthYear: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMMM yyyy"
        return f
    }()

    /// "month" follows the budget cycle start day.
    static func range(_ kind: PeriodKind, offset: Int = 0, cycleDay: Int = 1, from: Date? = nil, to: Date? = nil, now: Date = Date()) -> DateRange {
        let c = cal
        let today = c.startOfDay(for: now)
        let short = Fmt.shortDate
        switch kind {
        case .today:
            let s = c.date(byAdding: .day, value: offset, to: today)!
            return DateRange(start: s, end: c.date(byAdding: .day, value: 1, to: s)!, label: short.string(from: s))
        case .week:
            let weekStart = c.dateInterval(of: .weekOfYear, for: today)!.start
            let s = c.date(byAdding: .day, value: offset * 7, to: weekStart)!
            let e = c.date(byAdding: .day, value: 7, to: s)!
            let label = offset == 0 ? "This week" : "\(short.string(from: s)) – \(short.string(from: c.date(byAdding: .day, value: -1, to: e)!))"
            return DateRange(start: s, end: e, label: label)
        case .month:
            let s = c.date(byAdding: .month, value: offset, to: startOfCycle(today, cycleDay: cycleDay))!
            let e = c.date(byAdding: .month, value: 1, to: s)!
            let label = cycleDay == 1 ? monthYear.string(from: s) : "\(short.string(from: s)) – \(short.string(from: c.date(byAdding: .day, value: -1, to: e)!))"
            return DateRange(start: s, end: e, label: label)
        case .year:
            let y = c.component(.year, from: today) + offset
            let s = c.date(from: DateComponents(year: y, month: 1, day: 1))!
            return DateRange(start: s, end: c.date(byAdding: .year, value: 1, to: s)!, label: String(y))
        case .custom:
            let s = c.startOfDay(for: from ?? c.date(byAdding: .day, value: -29, to: today)!)
            let e = c.date(byAdding: .day, value: 1, to: c.startOfDay(for: to ?? today))!
            return DateRange(start: s, end: max(e, s.addingTimeInterval(1)),
                             label: "\(short.string(from: s)) – \(short.string(from: c.date(byAdding: .day, value: -1, to: e)!))")
        case .all:
            return .allTime
        }
    }

    static func previous(_ kind: PeriodKind, offset: Int, cycleDay: Int, from: Date?, to: Date?) -> DateRange {
        if kind == .custom {
            let r = range(.custom, cycleDay: cycleDay, from: from, to: to)
            let len = r.end.timeIntervalSince(r.start)
            return DateRange(start: r.start.addingTimeInterval(-len), end: r.start, label: "")
        }
        return range(kind, offset: offset - 1, cycleDay: cycleDay)
    }

    static func days(_ start: Date, _ end: Date) -> Int {
        max(1, cal.dateComponents([.day], from: cal.startOfDay(for: start), to: cal.startOfDay(for: end)).day ?? 1)
    }
}
