import Foundation

/// Writes a .xlsx (SpreadsheetML) with styled header, frozen row, autofilter,
/// ₹ formats and live formulas (with cached results for previews).
enum XLSX {
    private enum Cell {
        case text(String), number(Double, style: Int), date(Date, style: Int), formula(String, cached: Double, style: Int)
    }

    private static func col(_ i: Int) -> String { String(UnicodeScalar(UInt8(65 + i))) }
    private static func xml(_ s: String) -> String {
        s.replacing("&", with: "&amp;").replacing("<", with: "&lt;")
            .replacing(">", with: "&gt;").replacing("\"", with: "&quot;")
    }

    /// Excel serial day for the local calendar date.
    private static func serial(_ d: Date) -> Double {
        let c = Calendar.current.dateComponents([.year, .month, .day], from: d)
        var utc = Calendar(identifier: .gregorian); utc.timeZone = TimeZone(identifier: "UTC")!
        let day = utc.date(from: c)!
        return day.timeIntervalSince1970 / 86400 + 25569
    }

    private static func sheet(_ rows: [[Cell]], widths: [Double], styleRow: [Int: Int] = [:], autoFilter: String? = nil) -> String {
        var s = #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?><worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/></sheetView></sheetViews><cols>"#
        for (i, w) in widths.enumerated() { s += #"<col min="\#(i + 1)" max="\#(i + 1)" width="\#(w)" customWidth="1"/>"# }
        s += "</cols><sheetData>"
        for (r, row) in rows.enumerated() {
            let rowStyle = styleRow[r]
            s += #"<row r="\#(r + 1)">"#
            for (c, cell) in row.enumerated() {
                let ref = "\(col(c))\(r + 1)"
                switch cell {
                case .text(let t):
                    s += #"<c r="\#(ref)" t="inlineStr"\#(rowStyle.map { " s=\"\($0)\"" } ?? "")><is><t xml:space="preserve">\#(xml(t))</t></is></c>"#
                case .number(let n, let st):
                    s += #"<c r="\#(ref)" s="\#(rowStyle ?? st)"><v>\#(n)</v></c>"#
                case .date(let d, let st):
                    s += #"<c r="\#(ref)" s="\#(st)"><v>\#(serial(d))</v></c>"#
                case .formula(let f, let v, let st):
                    s += #"<c r="\#(ref)" s="\#(rowStyle == 6 ? (st == 3 ? 7 : st == 4 ? 8 : 6) : st)"><f>\#(xml(f))</f><v>\#(v)</v></c>"#
                }
            }
            s += "</row>"
        }
        s += "</sheetData>"
        if let autoFilter { s += #"<autoFilter ref="\#(autoFilter)"/>"# }
        return s + "</worksheet>"
    }

    static func workbook(rows: [ExportRow], label: String, range: DateRange, categories: [String]) throws -> Data {
        let n = rows.count
        let last = max(2, n + 1)
        func T(_ c: String) -> String { "Transactions!$\(c)$2:$\(c)$\(last)" }
        let spent = rows.filter { $0.type == "Expense" }.map(\.amount).reduce(0, +)
        let credit = rows.filter { $0.type == "Credit" }.map(\.amount).reduce(0, +)
        let days = range.end == .distantFuture
            ? max(1, (rows.last.map { Periods.days(rows[0].date, $0.date) } ?? 0) + 1)
            : Periods.days(range.start, min(range.end, Date.now))

        // Transactions
        var tx: [[Cell]] = [["Date", "Time", "Type", "Category", "Account", "Note", "Amount"].map { .text($0) }]
        for r in rows {
            tx.append([.date(r.date, style: 2), .text(r.time), .text(r.type), .text(r.category), .text(r.account), .text(r.note),
                       .number(r.amount, style: 3)])
        }

        // Summary
        let summary: [[Cell]] = [
            [.text("Metric"), .text("Value")],
            [.text("Period"), .text(label)],
            [.text("Generated"), .text(DateFormatter.localizedString(from: Date.now, dateStyle: .medium, timeStyle: .short))],
            [.text("Total expenses"), .formula("SUMIFS(\(T("G")),\(T("C")),\"Expense\")", cached: spent, style: 3)],
            [.text("Total credits"), .formula("SUMIFS(\(T("G")),\(T("C")),\"Credit\")", cached: credit, style: 3)],
            [.text("Net spent"), .formula("B4-B5", cached: spent - credit, style: 3)],
            [.text("Entries"), .formula("COUNTA(\(T("A")))", cached: Double(n), style: 0)],
            [.text("Days"), .number(Double(days), style: 0)],
            [.text("Average per day"), .formula("B4/B8", cached: spent / Double(days), style: 3)],
        ]

        // By Category
        var byCat: [[Cell]] = [["Category", "Expenses", "% of total", "Entries"].map { .text($0) }]
        let catEnd = categories.count + 1
        for (i, name) in categories.enumerated() {
            let r = i + 2
            let total = rows.filter { $0.type == "Expense" && $0.category == name }.map(\.amount).reduce(0, +)
            let count = rows.filter { $0.type == "Expense" && $0.category == name }.count
            byCat.append([.text(name),
                          .formula("SUMIFS(\(T("G")),\(T("C")),\"Expense\",\(T("D")),A\(r))", cached: total, style: 3),
                          .formula("IF($B$\(catEnd + 1)=0,0,B\(r)/$B$\(catEnd + 1))", cached: spent > 0 ? total / spent : 0, style: 4),
                          .formula("COUNTIFS(\(T("C")),\"Expense\",\(T("D")),A\(r))", cached: Double(count), style: 0)])
        }
        byCat.append([.text("Total"), .formula("SUM(B2:B\(catEnd))", cached: spent, style: 3),
                      .formula("SUM(C2:C\(catEnd))", cached: spent > 0 ? 1 : 0, style: 4),
                      .formula("SUM(D2:D\(catEnd))", cached: Double(rows.filter { $0.type == "Expense" }.count), style: 0)])

        // Daily (≤ 92 days) or Monthly
        let span = (rows.last?.date.timeIntervalSince(rows.first!.date) ?? 0) / 86400
        let daily = span <= 92
        let cal = Calendar.current
        var groups: [Date: (e: Double, c: Double)] = [:]
        for r in rows {
            let key = daily ? cal.startOfDay(for: r.date) : cal.date(from: cal.dateComponents([.year, .month], from: r.date))!
            var g = groups[key] ?? (0, 0)
            if r.type == "Expense" { g.e += r.amount } else if r.type == "Credit" { g.c += r.amount }
            groups[key] = g
        }
        let keys = groups.keys.sorted()
        var per: [[Cell]] = [[daily ? "Date" : "Month", "Expenses", "Credits", "Net"].map { .text($0) }]
        for (i, k) in keys.enumerated() {
            let r = i + 2
            let g = groups[k]!
            let match = daily ? "\(T("A")),A\(r)" : "\(T("A")),\">=\"&A\(r),\(T("A")),\"<\"&EDATE(A\(r),1)"
            per.append([.date(k, style: daily ? 2 : 5),
                        .formula("SUMIFS(\(T("G")),\(T("C")),\"Expense\",\(match))", cached: g.e, style: 3),
                        .formula("SUMIFS(\(T("G")),\(T("C")),\"Credit\",\(match))", cached: g.c, style: 3),
                        .formula("B\(r)-C\(r)", cached: g.e - g.c, style: 3)])
        }
        let pEnd = keys.count + 1
        per.append([.text("Total"), .formula("SUM(B2:B\(pEnd))", cached: spent, style: 3),
                    .formula("SUM(C2:C\(pEnd))", cached: credit, style: 3), .formula("SUM(D2:D\(pEnd))", cached: spent - credit, style: 3)])

        let sheets: [(String, String)] = [
            ("Transactions", sheet(tx, widths: [13, 10, 10, 18, 18, 36, 14], styleRow: [0: 1], autoFilter: "A1:G\(max(1, n + 1))")),
            ("Summary", sheet(summary, widths: [22, 22], styleRow: [0: 1])),
            ("By Category", sheet(byCat, widths: [20, 16, 12, 10], styleRow: [0: 1, byCat.count - 1: 6])),
            (daily ? "Daily" : "Monthly", sheet(per, widths: [14, 16, 16, 16], styleRow: [0: 1, per.count - 1: 6])),
        ]

        // Indian grouping (12,34,567.00); quotes inside the formatCode attribute must be &quot;.
        let q = "&quot;₹&quot;"
        let money = "[&gt;=10000000]\(q)##\\,##\\,##\\,##0.00;[&gt;=100000]\(q)##\\,##\\,##0.00;\(q)#,##0.00"

        var zip = ZipWriter()
        zip.add("[Content_Types].xml", #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types"><Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/><Default Extension="xml" ContentType="application/xml"/><Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/><Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>"# +
            (1...sheets.count).map { #"<Override PartName="/xl/worksheets/sheet\#($0).xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>"# }.joined() + "</Types>")
        zip.add("_rels/.rels", #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships"><Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/></Relationships>"#)
        zip.add("xl/workbook.xml", #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?><workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>"# +
            sheets.enumerated().map { #"<sheet name="\#(xml($0.element.0))" sheetId="\#($0.offset + 1)" r:id="rId\#($0.offset + 1)"/>"# }.joined() +
            #"</sheets><definedNames><definedName name="_xlnm._FilterDatabase" localSheetId="0" hidden="1">Transactions!$A$1:$G$\#(max(1, n + 1))</definedName></definedNames><calcPr calcId="191029" fullCalcOnLoad="1"/></workbook>"#)
        zip.add("xl/_rels/workbook.xml.rels", #"<?xml version="1.0" encoding="UTF-8" standalone="yes"?><Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">"# +
            (1...sheets.count).map { #"<Relationship Id="rId\#($0)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet\#($0).xml"/>"# }.joined() +
            #"<Relationship Id="rId\#(sheets.count + 1)" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/></Relationships>"#)
        // Styles: 0 default, 1 header, 2 date, 3 money, 4 %, 5 month, 6 bold, 7 bold money, 8 bold %, 9 plain amount
        zip.add("xl/styles.xml", ##"<?xml version="1.0" encoding="UTF-8" standalone="yes"?><styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"><numFmts count="5"><numFmt numFmtId="164" formatCode="dd-mmm-yyyy"/><numFmt numFmtId="165" formatCode="\##(money)"/><numFmt numFmtId="166" formatCode="0.0%"/><numFmt numFmtId="167" formatCode="mmm yyyy"/><numFmt numFmtId="168" formatCode="#,##0.00"/></numFmts><fonts count="3"><font><sz val="11"/><name val="Calibri"/></font><font><b/><sz val="11"/><color rgb="FFFFFFFF"/><name val="Calibri"/></font><font><b/><sz val="11"/><name val="Calibri"/></font></fonts><fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill><fill><patternFill patternType="solid"><fgColor rgb="FF000000"/><bgColor indexed="64"/></patternFill></fill></fills><borders count="1"><border/></borders><cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs><cellXfs count="10"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/><xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/><xf numFmtId="164" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="165" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="166" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="167" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/><xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/><xf numFmtId="165" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1"/><xf numFmtId="166" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1" applyNumberFormat="1"/><xf numFmtId="168" fontId="0" fillId="0" borderId="0" xfId="0" applyNumberFormat="1"/></cellXfs></styleSheet>"##)
        for (i, s) in sheets.enumerated() { zip.add("xl/worksheets/sheet\(i + 1).xml", s.1) }
        return zip.finish()
    }
}
