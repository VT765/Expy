import Foundation

/// Reads CSV / TSV / XLSX bank statements. Finds the header row among the
/// preamble, maps date / narration / debit / credit (or amount + Dr/Cr)
/// columns, and parses Indian date and amount formats.
enum StatementParser {
    static func parse(_ url: URL) throws -> [StatementRow] {
        let ok = url.startAccessingSecurityScopedResource()
        defer { if ok { url.stopAccessingSecurityScopedResource() } }
        let data = try Data(contentsOf: url)
        let table: [[String]]
        switch url.pathExtension.lowercased() {
        case "xlsx": table = try XLSXReader.firstSheet(data)
        case "xls": throw StatementError(message: "Old .xls files aren't supported. Export the statement as CSV or .xlsx from your bank.")
        case "pdf": throw StatementError(message: "PDF statements aren't supported. Download the statement as CSV or Excel (.xlsx) instead.")
        default:
            guard let text = String(data: data, encoding: .utf8) ?? String(data: data, encoding: .isoLatin1) else {
                throw StatementError(message: "Couldn't read that file as text.")
            }
            table = csv(text)
        }
        return try rows(from: table)
    }

    // MARK: Table → rows

    private struct Columns {
        var date: Int?, narration: Int?, debit: Int?, credit: Int?, amount: Int?, drcr: Int?
    }

    private static func detect(_ header: [String]) -> Columns? {
        var c = Columns()
        for (i, raw) in header.enumerated() {
            let h = raw.lowercased().trimmingCharacters(in: .whitespaces)
            if c.date == nil, h.contains("date"), !h.contains("value") || header.count < 4 { c.date = i }
            else if c.narration == nil, ["narration", "description", "particulars", "details", "remarks", "transaction"].contains(where: h.contains) { c.narration = i }
            else if c.debit == nil, ["withdrawal", "debit", "dr amount", "paid out", "dr."].contains(where: h.contains) || h == "dr" { c.debit = i }
            else if c.credit == nil, ["deposit", "credit", "cr amount", "paid in", "cr."].contains(where: h.contains) || h == "cr" { c.credit = i }
            else if c.drcr == nil, h == "dr/cr" || h == "cr/dr" || h == "type" || h.contains("dr / cr") { c.drcr = i }
            else if c.amount == nil, h.contains("amount") && !h.contains("balance") { c.amount = i }
        }
        guard c.date != nil, c.debit != nil || c.credit != nil || c.amount != nil else { return nil }
        return c
    }

    static func rows(from table: [[String]]) throws -> [StatementRow] {
        guard let headerIndex = table.prefix(40).firstIndex(where: { detect($0) != nil }), let cols = detect(table[headerIndex]) else {
            throw StatementError(message: "Couldn't find the transaction table. The file needs Date, Narration and Debit/Credit (or Amount) columns.")
        }
        var out: [StatementRow] = []
        for r in table[(headerIndex + 1)...] {
            func cell(_ i: Int?) -> String { i.flatMap { $0 < r.count ? r[$0] : nil }?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "" }
            guard let date = parseDate(cell(cols.date)) else { continue }
            let note = cleanNarration(cell(cols.narration))
            if let d = parseAmount(cell(cols.debit)), d != 0 {
                out.append(StatementRow(date: date, narration: note, amount: abs(d), isCredit: false))
            } else if let c = parseAmount(cell(cols.credit)), c != 0 {
                out.append(StatementRow(date: date, narration: note, amount: abs(c), isCredit: true))
            } else if let a = parseAmount(cell(cols.amount)), a != 0 {
                let marker = (cell(cols.drcr) + " " + cell(cols.amount)).lowercased()
                let credit = marker.contains("cr") ? true : marker.contains("dr") ? false : a > 0
                out.append(StatementRow(date: date, narration: note, amount: abs(a), isCredit: credit))
            }
        }
        guard !out.isEmpty else { throw StatementError(message: "No transactions found in that file.") }
        return out
    }

    // MARK: Values

    private static let dateFormats = ["dd/MM/yy", "dd/MM/yyyy", "dd-MM-yyyy", "dd-MM-yy", "dd-MMM-yyyy", "dd-MMM-yy", "dd MMM yyyy",
                                      "dd MMM yy", "d MMM yyyy", "yyyy-MM-dd", "dd.MM.yyyy", "dd.MM.yy", "MMM d, yyyy", "dd/MMM/yyyy"]
    private static let formatters: [DateFormatter] = dateFormats.map {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_IN")
        f.dateFormat = $0
        f.isLenient = false
        return f
    }

    static func parseDate(_ s: String) -> Date? {
        let t = s.components(separatedBy: " ").count > 3 ? s.components(separatedBy: " ").prefix(3).joined(separator: " ") : s
        if let n = Double(t), n > 20000, n < 80000 { // Excel serial date
            var c = Calendar(identifier: .gregorian); c.timeZone = .current
            return c.date(byAdding: .day, value: Int(n) - 25569, to: Date(timeIntervalSince1970: 0)).map { c.startOfDay(for: $0) }
                .flatMap { Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: $0) }
        }
        let trimmed = t.trimmingCharacters(in: .whitespaces)
        // Try the whole value, then just the date part of "01/11/2026 10:23:00".
        for candidate in [trimmed, String(trimmed.split(separator: " ").first ?? "")] where !candidate.isEmpty {
            for f in formatters {
                if let d = f.date(from: candidate) { return Calendar.current.date(bySettingHour: 12, minute: 0, second: 0, of: d) }
            }
        }
        return nil
    }

    static func parseAmount(_ s: String) -> Double? {
        let cleaned = s.replacing(",", with: "").replacing("₹", with: "")
            .replacing(/INR/.ignoresCase(), with: "")
            .replacing(/(cr|dr)\.?$/.ignoresCase(), with: "")
            .trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return nil }
        if cleaned.hasPrefix("("), cleaned.hasSuffix(")") { return Double(cleaned.dropFirst().dropLast()).map { -$0 } }
        return Double(cleaned)
    }

    /// "UPI-SWIGGY-swiggy@icici-ICIC0000103-123456789-Payment" → "SWIGGY"
    static func cleanNarration(_ s: String) -> String {
        let parts = s.components(separatedBy: CharacterSet(charactersIn: "-/")).map { $0.trimmingCharacters(in: .whitespaces) }
        let upiPrefixes = ["upi", "imps", "neft", "rtgs", "pos", "ach", "nach", "mmt"]
        if let first = parts.first?.lowercased(), upiPrefixes.contains(where: first.hasPrefix), parts.count > 1,
           let name = parts.dropFirst().first(where: isNameLike) {
            return String(name.prefix(60)).capitalized
        }
        return String(s.trimmingCharacters(in: .whitespaces).prefix(60))
    }

    /// Skips VPAs, IFSC codes (SBIN0001234) and reference numbers.
    private static func isNameLike(_ t: String) -> Bool {
        guard t.count > 2, !t.contains("@") else { return false }
        if t.range(of: "^[A-Za-z]{4}0[A-Za-z0-9]{6}$", options: .regularExpression) != nil { return false }
        let letters = t.unicodeScalars.filter(CharacterSet.letters.contains).count
        let digits = t.unicodeScalars.filter(CharacterSet.decimalDigits.contains).count
        return letters > 2 && letters > digits
    }

    // MARK: CSV

    static func csv(_ text: String) -> [[String]] {
        let firstLines = text.split(whereSeparator: \.isNewline).prefix(20).joined()
        let delim: Character = [",", ";", "\t", "|"].max { a, b in firstLines.filter { $0 == a }.count < firstLines.filter { $0 == b }.count }!
        var rows: [[String]] = []
        var row: [String] = []
        var field = ""
        var quoted = false
        var it = text.makeIterator()
        while let ch = it.next() {
            if quoted {
                if ch == "\"" {
                    if let next = it.next() {
                        if next == "\"" { field.append("\"") }
                        else {
                            quoted = false
                            if next == delim { row.append(field); field = "" }
                            else if next.isNewline { row.append(field); rows.append(row); row = []; field = "" }
                            else { field.append(next) }
                        }
                    } else { quoted = false }
                } else { field.append(ch) }
            } else if ch == "\"" && field.isEmpty {
                quoted = true
            } else if ch == delim {
                row.append(field); field = ""
            } else if ch.isNewline {
                row.append(field); rows.append(row); row = []; field = ""
            } else { field.append(ch) }
        }
        if !field.isEmpty || !row.isEmpty { row.append(field); rows.append(row) }
        return rows
    }
}
