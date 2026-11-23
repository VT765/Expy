import Foundation
import Testing
@testable import Expy

struct PeriodsTests {
    private let now = TestData.date(2026, 11, 25) // a Wednesday

    @Test func weekStartsOnMonday() {
        let r = Periods.range(.week, now: now)
        #expect(r.start == TestData.date(2026, 11, 23, 0))
        #expect(r.end == TestData.date(2026, 11, 30, 0))
    }

    @Test func monthFollowsCycleStartDay() {
        let afterStart = Periods.range(.month, cycleDay: 5, now: now)
        #expect(afterStart.start == TestData.date(2026, 11, 5, 0))
        #expect(afterStart.end == TestData.date(2026, 12, 5, 0))

        let beforeStart = Periods.range(.month, cycleDay: 28, now: now)
        #expect(beforeStart.start == TestData.date(2026, 10, 28, 0))
        #expect(beforeStart.end == TestData.date(2026, 11, 28, 0))
    }

    @Test func calendarMonthIsLabelledByName() {
        #expect(Periods.range(.month, cycleDay: 1, now: now).label == "November 2026")
    }

    @Test func offsetMovesWholePeriods() {
        let r = Periods.range(.month, offset: -1, cycleDay: 1, now: now)
        #expect(r.start == TestData.date(2026, 10, 1, 0))
    }

    @Test func rangeEndIsExclusive() {
        let r = Periods.range(.today, now: now)
        #expect(r.contains(TestData.date(2026, 11, 25, 23, 59)))
        #expect(!r.contains(TestData.date(2026, 11, 26, 0)))
    }

    @Test func customPreviousHasSameLength() {
        let from = TestData.date(2026, 11, 1), to = TestData.date(2026, 11, 10)
        let r = Periods.range(.custom, from: from, to: to)
        let prev = Periods.previous(.custom, offset: 0, cycleDay: 1, from: from, to: to)
        #expect(prev.end == r.start)
        #expect(r.end.timeIntervalSince(r.start) == prev.end.timeIntervalSince(prev.start))
    }
}
