import Foundation
import Testing
@testable import Expy

struct StatementParserTests {
    private let hdfc = """
    HDFC BANK Ltd.,,,,,,
    Account No : 50100123456789,,,,,,
    ,,,,,,
    Date,Narration,Chq./Ref.No.,Value Dt,Withdrawal Amt.,Deposit Amt.,Closing Balance
    01/11/26,UPI-SWIGGY-swiggy@icici-ICIC0000103-631234567890-Payment,0000631234567890,01/11/26,"1,250.00",,"48,750.00"
    02/11/26,NEFT CR-SBIN0001234-ACME PAYROLL-SALARY NOV,N123456,02/11/26,,"85,000.00","1,33,750.00"
    """

    @Test func parsesHdfcStyleCsvWithPreamble() throws {
        let rows = try StatementParser.rows(from: StatementParser.csv(hdfc))
        #expect(rows.count == 2)
        #expect(rows[0].amount == 1250 && !rows[0].isCredit && rows[0].narration == "Swiggy")
        #expect(rows[1].amount == 85000 && rows[1].isCredit && rows[1].narration == "Acme Payroll")
    }

    @Test func parsesAmountWithDrCrColumn() throws {
        let table = [["Txn Date", "Description", "Amount", "Dr/Cr"],
                     ["05-Nov-2026", "IMPS/ZOMATO LTD/123", "540.00", "DR"],
                     ["06-Nov-2026", "REFUND MYNTRA", "1,299.00", "CR"]]
        let rows = try StatementParser.rows(from: table)
        #expect(rows.map(\.isCredit) == [false, true])
        #expect(rows.map(\.amount) == [540, 1299])
    }

    @Test func rejectsFilesWithoutTransactionTable() {
        #expect(throws: StatementError.self) { try StatementParser.rows(from: [["hello", "world"]]) }
    }

    @Test(arguments: ["01/11/26", "01/11/2026", "01-Nov-2026", "2026-11-01", "01.11.2026", "46327", "01/11/2026 10:23:00"])
    func parsesDateFormats(_ text: String) {
        let d = StatementParser.parseDate(text)
        let c = d.map { Calendar.current.dateComponents([.year, .month, .day], from: $0) }
        #expect(c?.year == 2026 && c?.month == 11 && c?.day == 1)
    }

    @Test func parsesAmounts() {
        #expect(StatementParser.parseAmount("1,250.00") == 1250)
        #expect(StatementParser.parseAmount("₹ 99.50") == 99.5)
        #expect(StatementParser.parseAmount("45.50 Cr") == 45.5)
        #expect(StatementParser.parseAmount("(500.00)") == -500)
        #expect(StatementParser.parseAmount("") == nil)
    }

    @Test func csvHandlesQuotedCommas() {
        let rows = StatementParser.csv("a,\"b,c\",d\n1,2,3")
        #expect(rows[0] == ["a", "b,c", "d"])
        #expect(rows[1] == ["1", "2", "3"])
    }
}
