import Foundation

enum Currencies {
    struct Info: Identifiable, Hashable {
        let code: String
        let name: String
        let symbol: String
        var id: String { code }
    }

    static let all: [Info] = [
        ("INR", "Indian Rupee", "₹"), ("USD", "US Dollar", "$"), ("EUR", "Euro", "€"),
        ("GBP", "British Pound", "£"), ("AED", "UAE Dirham", "AED"), ("AUD", "Australian Dollar", "A$"),
        ("CAD", "Canadian Dollar", "C$"), ("CHF", "Swiss Franc", "CHF"), ("CNY", "Chinese Yuan", "¥"),
        ("HKD", "Hong Kong Dollar", "HK$"), ("IDR", "Indonesian Rupiah", "Rp"), ("JPY", "Japanese Yen", "¥"),
        ("KRW", "South Korean Won", "₩"), ("MYR", "Malaysian Ringgit", "RM"), ("NZD", "New Zealand Dollar", "NZ$"),
        ("PHP", "Philippine Peso", "₱"), ("SGD", "Singapore Dollar", "S$"), ("THB", "Thai Baht", "฿"),
        ("TRY", "Turkish Lira", "₺"), ("ZAR", "South African Rand", "R"),
    ].map { Info(code: $0.0, name: $0.1, symbol: $0.2) }

    static func info(_ code: String) -> Info { all.first { $0.code == code } ?? Info(code: code, name: code, symbol: code) }
    static func symbol(_ code: String) -> String { info(code).symbol }
}

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

    /// Signed money: "-₹703"
    static func money(_ value: Double, _ currency: String = "INR") -> String {
        let sign = value < -0.004 ? "-" : ""
        return "\(sign)\(Currencies.symbol(currency))\(number(value))"
    }

    static func compact(_ v: Double) -> String {
        let n = abs(v)
        func trim(_ x: Double) -> String { x == x.rounded() ? String(Int(x)) : String(format: "%.1f", x) }
        if n >= 1e7 { return trim((n / 1e7 * 10).rounded() / 10) + "Cr" }
        if n >= 1e5 { return trim((n / 1e5 * 10).rounded() / 10) + "L" }
        if n >= 1e3 { return trim((n / 1e3 * 10).rounded() / 10) + "K" }
        return String(Int(n.rounded()))
    }

    static let time: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "h:mm a"
        return f
    }()

    static let shortDate: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = "MMM d"
        return f
    }()

    static func dayHeader(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "Today" }
        if cal.isDateInYesterday(date) { return "Yesterday" }
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US")
        f.dateFormat = cal.isDate(date, equalTo: Date(), toGranularity: .year) ? "EEEE, MMM d" : "EEEE, MMM d, yyyy"
        return f.string(from: date)
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

extension Date {
    var epochMs: Int64 { Int64((timeIntervalSince1970 * 1000).rounded()) }
    init(epochMs: Int64) { self.init(timeIntervalSince1970: Double(epochMs) / 1000) }
}
