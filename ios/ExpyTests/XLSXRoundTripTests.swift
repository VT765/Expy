import Foundation
import Testing
@testable import Expy

struct XLSXRoundTripTests {
    @Test func crc32MatchesReferenceValue() {
        #expect(ZipWriter.crc32(Data("123456789".utf8)) == 0xCBF4_3926)
    }

    @Test func workbookReadsBackThroughStatementReader() throws {
        let rows = [
            ExportRow(date: TestData.date(2026, 11, 20, 20, 8), time: "8:08 PM", type: "Credit", category: "Shopping",
                      account: "HDFC Bank", note: "Myntra Refund", amount: 703),
            ExportRow(date: TestData.date(2026, 11, 22, 22, 40), time: "10:40 PM", type: "Expense", category: "Food",
                      account: "Cash", note: "Panipuri & chai <3", amount: 80),
        ]
        let range = DateRange(start: TestData.date(2026, 11, 1, 0), end: TestData.date(2026, 12, 1, 0), label: "November 2026")
        let data = try XLSX.workbook(rows: rows, label: range.label, range: range, categories: ["Food", "Shopping"])
        let sheet = try XLSXReader.firstSheet(data)
        #expect(sheet.first?.prefix(3) == ["Date", "Time", "Type"])
        #expect(sheet.count == 3)
        #expect(sheet[2][5] == "Panipuri & chai <3") // XML escaping survives
        #expect(sheet[2][6] == "80.0")
    }
}
