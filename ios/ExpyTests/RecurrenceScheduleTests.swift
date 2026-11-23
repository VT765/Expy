import Foundation
import Testing
@testable import Expy

struct RecurrenceScheduleTests {
    @Test func monthEndRuleClampsWithoutDrifting() {
        let start = TestData.date(2026, 1, 31, 9)
        let dates = (0..<4).map { RecurrenceSchedule.occurrence($0, start: start, frequency: .monthly) }
        let days = dates.map { TestData.calendar.component(.day, from: $0) }
        #expect(days == [31, 28, 31, 30]) // Jan 31, Feb 28, Mar 31, Apr 30
    }

    @Test func firstOnOrAfterFindsNextOccurrence() {
        let start = TestData.date(2026, 1, 5, 9)
        #expect(RecurrenceSchedule.first(onOrAfter: TestData.date(2026, 11, 23), start: start, frequency: .monthly) == TestData.date(2026, 12, 5, 9))
        #expect(RecurrenceSchedule.first(onOrAfter: TestData.date(2026, 11, 5, 9), start: start, frequency: .monthly) == TestData.date(2026, 11, 5, 9))
        #expect(RecurrenceSchedule.first(onOrAfter: TestData.date(2025, 6, 1), start: start, frequency: .monthly) == start)
    }

    @Test func dueCatchesUpEveryMissedOccurrence() {
        let start = TestData.date(2026, 9, 1, 9)
        let due = RecurrenceSchedule.due(next: start, start: start, end: nil, frequency: .monthly, now: TestData.date(2026, 11, 23))
        #expect(due.dates == [TestData.date(2026, 9, 1, 9), TestData.date(2026, 10, 1, 9), TestData.date(2026, 11, 1, 9)])
        #expect(due.next == TestData.date(2026, 12, 1, 9))
    }

    @Test func nothingDueBeforeNineOnTheDay() {
        let start = TestData.date(2026, 11, 23, 9)
        #expect(RecurrenceSchedule.due(next: start, start: start, end: nil, frequency: .weekly, now: TestData.date(2026, 11, 23, 8)).dates.isEmpty)
    }

    @Test func endDateIsInclusiveAndStopsTheRule() {
        let start = TestData.date(2026, 11, 2, 9)
        let end = TestData.date(2026, 11, 16, 0)
        let due = RecurrenceSchedule.due(next: start, start: start, end: end, frequency: .weekly, now: TestData.date(2026, 12, 31))
        #expect(due.dates.count == 3) // 2, 9, 16 Nov
        #expect(RecurrenceSchedule.hasEnded(next: due.next, end: end))
    }

    @Test func yearlyFollowsTheCalendar() {
        let start = TestData.date(2024, 2, 29, 9)
        #expect(RecurrenceSchedule.occurrence(1, start: start, frequency: .yearly) == TestData.date(2025, 2, 28, 9))
        #expect(RecurrenceSchedule.occurrence(4, start: start, frequency: .yearly) == TestData.date(2028, 2, 29, 9))
    }
}
