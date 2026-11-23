import Foundation

enum Fmt {
    private static let whole: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.numberStyle = .decimal
        f.maximumFractionDigits = 0
        return f
    }()

    private static let fraction: NumberFormatter = {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.numberStyle = .decimal
        f.minimumFractionDigits = 2
        f.maximumFractionDigits = 2
        return f
    }()

    /// 1829 → "1,829", 8687.17 → "8,687.17", 1234567 → "12,34,567"
    static func number(_ value: Double) -> String {
        let rounded = (abs(value) * 100).rounded() / 100
        let isWhole = rounded == rounded.rounded()
        return (isWhole ? whole : fraction).string(from: NSNumber(value: rounded)) ?? "0"
    }

    /// Signed rupees: "-₹703"
    static func money(_ value: Double) -> String {
        let sign = value < -0.004 ? "-" : ""
        return "\(sign)₹\(number(value))"
    }

    /// Net of a list from spending (debits − credits): money out shows plain
    /// ("₹4,429"), money in shows with a plus ("+₹500").
    static func flow(spending: Double) -> String {
        spending < -0.004 ? "+" + money(-spending) : money(spending)
    }

    /// Axis labels: 1.2K, 3.4L, 1.1Cr.
    static func compact(_ v: Double) -> String {
        let n = abs(v)
        func trim(_ x: Double) -> String { x.formatted(.number.precision(.fractionLength(0...1))) }
        if n >= 1e7 { return trim(n / 1e7) + "Cr" }
        if n >= 1e5 { return trim(n / 1e5) + "L" }
        if n >= 1e3 { return trim(n / 1e3) + "K" }
        return n.formatted(.number.precision(.fractionLength(0)))
    }

    /// "10:40 PM" in the user's locale.
    static func time(_ date: Date) -> String { date.formatted(date: .omitted, time: .shortened) }

    /// "Nov 21"
    static func shortDate(_ date: Date) -> String { date.formatted(.dateTime.month(.abbreviated).day()) }

    /// "Today", "Yesterday", "Friday, Nov 20" (year added when not this year).
    static func dayHeader(_ date: Date, now: Date = .now, calendar: Calendar = .current) -> String {
        if calendar.isDate(date, inSameDayAs: now) { return "Today" }
        if let y = calendar.date(byAdding: .day, value: -1, to: now), calendar.isDate(date, inSameDayAs: y) { return "Yesterday" }
        let style = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        return calendar.isDate(date, equalTo: now, toGranularity: .year) ? date.formatted(style) : date.formatted(style.year())
    }

    static func ordinal(_ n: Int) -> String {
        if (11...13).contains(n % 100) { return "\(n)th" }
        switch n % 10 {
        case 1: return "\(n)st"
        case 2: return "\(n)nd"
        case 3: return "\(n)rd"
        default: return "\(n)th"
        }
    }
}
