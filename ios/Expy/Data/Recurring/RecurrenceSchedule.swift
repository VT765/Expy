import Foundation

/// Date maths for recurring rules. Every occurrence is computed from the
/// start date (start + n periods), so a rule on the 31st lands on 30 Nov and
/// 28 Feb but still returns to the 31st, instead of drifting earlier.
enum RecurrenceSchedule {
    static func component(_ f: RecurrenceFrequency) -> (Calendar.Component, Int) {
        switch f {
        case .weekly: (.day, 7)
        case .monthly: (.month, 1)
        case .yearly: (.year, 1)
        }
    }

    /// The nth occurrence (0 = the start date itself).
    static func occurrence(_ n: Int, start: Date, frequency: RecurrenceFrequency, calendar: Calendar = .current) -> Date {
        let (unit, step) = component(frequency)
        return calendar.date(byAdding: unit, value: n * step, to: start) ?? start
    }

    /// First occurrence on or after `date`.
    static func first(onOrAfter date: Date, start: Date, frequency: RecurrenceFrequency, calendar: Calendar = .current) -> Date {
        guard date > start else { return start }
        let (unit, step) = component(frequency)
        // Jump close to the answer, then step: never more than a couple of iterations.
        let elapsed = calendar.dateComponents([unit], from: start, to: date).value(for: unit) ?? 0
        var n = max(0, elapsed / step - 1)
        while occurrence(n, start: start, frequency: frequency, calendar: calendar) < date { n += 1 }
        return occurrence(n, start: start, frequency: frequency, calendar: calendar)
    }

    /// Occurrences from `next` up to `now` (and `end`, inclusive by day), plus the following occurrence.
    static func due(next: Date, start: Date, end: Date?, frequency: RecurrenceFrequency, now: Date,
                    calendar: Calendar = .current, limit: Int = 400) -> (dates: [Date], next: Date) {
        var dates: [Date] = []
        var current = next
        let lastDay = end.flatMap { calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: $0)) }
        while current <= now, lastDay.map({ current < $0 }) ?? true, dates.count < limit {
            dates.append(current)
            current = first(onOrAfter: current.addingTimeInterval(1), start: start, frequency: frequency, calendar: calendar)
        }
        return (dates, current)
    }

    /// Whether the rule has passed its end date.
    static func hasEnded(next: Date, end: Date?, calendar: Calendar = .current) -> Bool {
        guard let end, let lastDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: end)) else { return false }
        return next >= lastDay
    }
}
