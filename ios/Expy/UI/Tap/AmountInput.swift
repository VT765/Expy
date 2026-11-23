import Foundation

/// Pure helpers for the numpad amount string ("1234.5"). Unit-tested.
enum AmountInput {
    /// Appends a key: max 9 integer digits and 2 decimals, one ".".
    static func press(_ current: String, _ key: String) -> String {
        if key == "." { return current.contains(".") ? current : (current.isEmpty ? "0" : current) + "." }
        let parts = current.split(separator: ".", omittingEmptySubsequences: false)
        if parts.count == 2 { return parts[1].count >= 2 ? current : current + key }
        if current == "0" || current.isEmpty { return key }
        return current.count >= 9 ? current : current + key
    }

    /// "1234567.5" → "12,34,567.5" (keeps a trailing "." or zeros as typed).
    static func display(_ current: String) -> String {
        if current.isEmpty { return "0" }
        let parts = current.split(separator: ".", omittingEmptySubsequences: false)
        let grouped = Fmt.number(Double(parts[0]) ?? 0)
        return parts.count == 2 ? "\(grouped).\(parts[1])" : grouped
    }

    static func value(_ current: String) -> Double { (Double(current) ?? 0).rounded(toPlaces: 2) }

    /// 80.0 → "80", 80.5 → "80.5"
    static func trimmed(_ v: Double) -> String {
        let r = v.rounded(toPlaces: 2)
        return r == r.rounded() ? String(Int(r)) : String(r)
    }

    /// Same calendar day as `day`, with the current time of day.
    static func withCurrentTime(_ day: Date, now: Date = .now, calendar: Calendar = .current) -> Date {
        let t = calendar.dateComponents([.hour, .minute, .second], from: now)
        return calendar.date(bySettingHour: t.hour ?? 12, minute: t.minute ?? 0, second: t.second ?? 0, of: day) ?? day
    }
}
