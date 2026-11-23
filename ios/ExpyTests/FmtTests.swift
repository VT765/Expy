import Testing
@testable import Expy

struct FmtTests {
    @Test func numberUsesIndianGrouping() {
        #expect(Fmt.number(1829) == "1,829")
        #expect(Fmt.number(1234567) == "12,34,567")
        #expect(Fmt.number(8687.17) == "8,687.17")
    }

    @Test func moneyIsSignedWithSymbol() {
        #expect(Fmt.money(80) == "₹80")
        #expect(Fmt.money(-703) == "-₹703")
    }

    @Test func compactUsesIndianUnits() {
        #expect(Fmt.compact(950) == "950")
        #expect(Fmt.compact(2_000) == "2K")
        #expect(Fmt.compact(120_000) == "1.2L")
        #expect(Fmt.compact(30_000_000) == "3Cr")
    }

    @Test(arguments: [(1, "1st"), (2, "2nd"), (3, "3rd"), (4, "4th"), (11, "11th"), (12, "12th"), (21, "21st"), (22, "22nd")])
    func ordinals(_ n: Int, _ expected: String) {
        #expect(Fmt.ordinal(n) == expected)
    }

    @Test func dayHeaderNamesTodayAndYesterday() {
        let now = TestData.date(2026, 11, 23, 18)
        #expect(Fmt.dayHeader(TestData.date(2026, 11, 23, 9), now: now) == "Today")
        #expect(Fmt.dayHeader(TestData.date(2026, 11, 22, 9), now: now) == "Yesterday")
    }

    @Test func flowShowsMoneyInWithPlus() {
        #expect(Fmt.flow(spending: 4_429) == "₹4,429")
        #expect(Fmt.flow(spending: -500) == "+₹500")
        #expect(Fmt.flow(spending: 0) == "₹0")
    }
}
