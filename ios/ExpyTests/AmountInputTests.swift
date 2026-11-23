import Testing
@testable import Expy

struct AmountInputTests {
    @Test func typingDigitsReplacesLeadingZero() {
        #expect(AmountInput.press("", "8") == "8")
        #expect(AmountInput.press("0", "5") == "5")
        #expect(AmountInput.press("8", "0") == "80")
    }

    @Test func decimalPointIsAddedOnceAndPrefixedWithZero() {
        #expect(AmountInput.press("", ".") == "0.")
        #expect(AmountInput.press("12.", ".") == "12.")
    }

    @Test func allowsAtMostTwoDecimals() {
        #expect(AmountInput.press("12.3", "4") == "12.34")
        #expect(AmountInput.press("12.34", "5") == "12.34")
    }

    @Test func capsIntegerDigitsAtNine() {
        #expect(AmountInput.press("123456789", "0") == "123456789")
    }

    @Test func displayUsesIndianGroupingAndKeepsTypedDecimals() {
        #expect(AmountInput.display("") == "0")
        #expect(AmountInput.display("1234567") == "12,34,567")
        #expect(AmountInput.display("1234.5") == "1,234.5")
        #expect(AmountInput.display("80.") == "80.")
    }

    @Test func trimmedDropsZeroDecimals() {
        #expect(AmountInput.trimmed(80) == "80")
        #expect(AmountInput.trimmed(80.5) == "80.5")
    }

    @Test func withCurrentTimeKeepsDayAndTakesClockTime() {
        let day = TestData.date(2026, 11, 1, 0, 0)
        let now = TestData.date(2026, 11, 23, 22, 40)
        let result = AmountInput.withCurrentTime(day, now: now)
        let c = TestData.calendar.dateComponents([.day, .hour, .minute], from: result)
        #expect(c.day == 1 && c.hour == 22 && c.minute == 40)
    }
}
