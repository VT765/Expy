import Foundation

/// Reads Indian bank transaction alerts (SMS or email): UPI, IMPS/NEFT,
/// card spends and credits from HDFC, BoB, SBI, ICICI, Axis and similar.
/// Returns nil for anything that isn't a completed transaction: OTPs,
/// payment requests, upcoming mandates, bill reminders, balance alerts,
/// failed or declined payments and offers. A real alert must also name the
/// account/card digits or carry a reference number.
enum BankMessageParser {
    private static let notTransactions = [
        // Not money that moved yet
        "otp", "one time password", "will be debited", "will be credited", "has requested", "requested money",
        "is due", "due date", "autopay set", "mandate created",
        // Attempts that didn't go through
        "failed", "declined", "unsuccessful", "could not be processed", "not processed", "insufficient",
        // Marketing
        "pre-approved", "pre approved", "loan offer", "offer", "eligible for", "on your next", "get rs", "get flat", "win rs",
    ]

    private static let banks: [(key: String, words: [String])] = [
        ("HDFC", ["hdfc"]), ("BoB", ["bank of baroda", "bob", "baroda"]), ("SBI", ["state bank", "sbi"]),
        ("ICICI", ["icici"]), ("Axis", ["axis"]), ("Kotak", ["kotak"]), ("PNB", ["punjab national", "pnb"]),
        ("Yes Bank", ["yes bank"]), ("IDFC", ["idfc"]), ("IndusInd", ["indusind"]), ("Canara", ["canara"]),
        ("Union Bank", ["union bank"]), ("Federal", ["federal bank"]), ("AU Bank", ["au small", "au bank"]),
    ]

    static func parse(_ raw: String, now: Date = .now, calendar: Calendar = .current) -> ParsedBankMessage? {
        let text = raw.replacing("\r", with: "\n")
        let lower = text.lowercased()
        guard !notTransactions.contains(where: lower.contains),
              let kind = kind(in: lower), let amount = amount(in: text), amount > 0 else { return nil }
        // Real alerts name your account/card or carry a reference; promotions rarely do.
        let digits = last4(in: text), ref = reference(in: text)
        guard digits != nil || ref != nil else { return nil }
        return ParsedBankMessage(kind: kind, amount: amount, last4: digits, bank: bank(in: lower),
                                 counterparty: counterparty(in: text, kind: kind), date: date(in: text, now: now, calendar: calendar),
                                 reference: ref)
    }

    /// Debit or credit, whichever word comes first ("Rs.500 Dr. from A/C … and Cr. to x@upi" is a debit).
    static func kind(in lower: String) -> TransactionKind? {
        let debit = lower.firstMatch(of: /\b(debited|sent|spent|paid|withdrawn|withdrawal|purchased?|transferred|dr\.?)(?=\s|$|\.|,|:)/)
        let credit = lower.firstMatch(of: /\b(credited|received|deposited|refunded|refund|reversed|cr\.?)(?=\s|$|\.|,|:)/)
        switch (debit, credit) {
        case let (d?, c?): return d.range.lowerBound <= c.range.lowerBound ? .expense : .credit
        case (_?, nil): return .expense
        case (nil, _?): return .credit
        default: return nil
        }
    }

    /// The first rupee amount that isn't a balance or limit.
    static func amount(in text: String) -> Double? {
        for m in text.matches(of: /(?i)(?:rs\.?|inr|₹)\s*([0-9][0-9,]*(?:\.[0-9]{1,2})?)/) {
            let before = text[text.index(m.range.lowerBound, offsetBy: -min(24, text.distance(from: text.startIndex, to: m.range.lowerBound)))..<m.range.lowerBound]
                .lowercased()
            if before.contains("bal") || before.contains("limit") { continue }
            if let v = Double(m.output.1.replacing(",", with: "")) { return v }
        }
        return nil
    }

    static func last4(in text: String) -> String? {
        guard let m = text.firstMatch(of: /(?i)\b(?:a\/c|ac|acct|account|card)(?:\s*no\.?)?[\s:]*(?:ending\s*(?:with)?\s*)?[x*.]*\s*(\d{3,6})\b/)
        else { return nil }
        return String(m.output.1.suffix(4))
    }

    static func bank(in lower: String) -> String? {
        banks.first { b in b.words.contains { w in lower.firstMatch(of: try! Regex("\\b\(NSRegularExpression.escapedPattern(for: w))\\b")) != nil } }?.key
    }

    /// "To X" for money out (or "at X" for card spends), "from/by X" for money in;
    /// the earliest usable mention wins.
    static func counterparty(in text: String, kind: TransactionKind) -> String? {
        let stop = #"(?=\s+on\b|\s+ref\b|\s+upi\b|\s*\(|\.\s|\.$|\n|,|$)"#
        let patterns = kind == .credit
            ? [#"(?i)\b(?:from|by)\s+(?:vpa\s+)?(.+?)"# + stop]
            : [#"(?i)\bto\s+(?:vpa\s+)?(.+?)"# + stop, #"(?i)\bat\s+(.+?)"# + stop]
        let skip = ["a/c", "account", "your", "card", "block", "call", "not you", "bank"]
        let candidates = patterns.flatMap { p in
            text.matches(of: try! Regex<(Substring, Substring)>(p)).map { (at: $0.range.lowerBound, text: String($0.output.1)) }
        }
        for c in candidates.sorted(by: { $0.at < $1.at }) {
            // "by NEFT from ACME LTD" → "ACME LTD"
            let candidate = c.text.replacing(/(?i)^(?:neft|imps|rtgs|upi)\s+(?:from\s+)?/, with: "")
            // Judge a UPI handle by its name part: "swiggy@axisbank" isn't a bank account.
            let l = candidate.lowercased().split(separator: "@").first.map(String.init) ?? ""
            if skip.contains(where: l.contains) { continue }
            if let name = clean(candidate) { return name }
        }
        return nil
    }

    /// "MANISH JADEJA" → "Manish Jadeja", "rahul.shah@okicici" → "Rahul Shah"; vowel-less
    /// capitals such as PVT and LTD stay as they are.
    static func clean(_ s: String) -> String? {
        var t = s.trimmingCharacters(in: .whitespacesAndNewlines.union(.punctuationCharacters))
        if let at = t.firstIndex(of: "@") { t = String(t[..<at]) }
        t = t.replacing(/[._\-]+/, with: " ").trimmingCharacters(in: .whitespaces)
        guard t.count >= 2, t.rangeOfCharacter(from: .letters) != nil else { return nil }
        let words = t.split(separator: " ").prefix(5).map { w in
            w.uppercased() == w && w.rangeOfCharacter(from: CharacterSet(charactersIn: "AEIOU")) == nil ? String(w) : w.capitalized
        }
        return String(words.joined(separator: " ").prefix(40))
    }

    /// "on 23/11/26", "On 2026-11-23:10:20"; today's messages keep the current time.
    static func date(in text: String, now: Date, calendar: Calendar) -> Date {
        guard let m = text.firstMatch(of: /(?i)\bon\s+(\d{1,4}[\/\-.][0-9a-z]{1,3}[\/\-.]\d{2,4})/),
              let d = StatementParser.parseDate(String(m.output.1)) else { return now }
        if calendar.isDate(d, inSameDayAs: now) { return now }
        return d > now ? now : calendar.date(bySettingHour: 12, minute: 0, second: 0, of: d) ?? d
    }

    static func reference(in text: String) -> String? {
        let m = text.firstMatch(of: /(?i)\b(?:ref(?:erence)?|upi|rrn|txn(?:\s*id)?|utr)(?:\s*(?:ref|no|number|id))?\.?[\s:#\-]*([0-9]{6,})/)
        return m.map { String($0.output.1) }
    }
}
