import Foundation
import Testing
@testable import Expy

@MainActor
struct AnalyticsTests {
    private let range = DateRange(start: TestData.date(2026, 11, 1, 0), end: TestData.date(2026, 12, 1, 0), label: "Nov")
    private let now = TestData.date(2026, 11, 10)

    private var entries: [Entry] {
        [
            TestData.entry(300, category: "cat_food", date: TestData.date(2026, 11, 2)),
            TestData.entry(100, category: "cat_food", date: TestData.date(2026, 11, 3)),
            TestData.entry(600, category: "cat_bills", date: TestData.date(2026, 11, 4)),
            TestData.entry(250, kind: .credit, category: "cat_shopping", date: TestData.date(2026, 11, 5)),
            TestData.entry(999, category: "cat_food", date: TestData.date(2026, 10, 30)), // outside range
        ]
    }

    @Test func totalsSplitDebitsAndCredits() {
        let s = Analytics.stats(entries, range: range, kind: .month, now: now)
        #expect(s.spent == 1000)
        #expect(s.credit == 250)
        #expect(s.net == 750)
        #expect(s.count == 4)
    }

    @Test func transfersAreNeitherSpendingNorIncome() {
        let withTransfer = entries + [TestData.entry(5_000, kind: .transfer, category: "", date: TestData.date(2026, 11, 6),
                                                     account: "acc_hdfc", to: "acc_cash")]
        let s = Analytics.stats(withTransfer, range: range, kind: .month, now: now)
        #expect(s.spent == 1000 && s.credit == 250 && s.count == 4)
    }

    @Test func totalsAreExactInPaise() {
        let tiny = (0..<1000).map { _ in TestData.entry(0.1, date: TestData.date(2026, 11, 2)) }
        #expect(Analytics.stats(tiny, range: range, kind: .month, now: now).spent == 100)
    }

    @Test func averageUsesDaysElapsedInCurrentPeriod() {
        let s = Analytics.stats(entries, range: range, kind: .month, now: now)
        #expect(s.days == 10)
        #expect(s.avgPerDay == 100)
    }

    @Test func categoriesAreSortedWithShares() {
        let s = Analytics.stats(entries, range: range, kind: .month, now: now)
        #expect(s.categories.map(\.categoryId) == ["cat_bills", "cat_food"])
        #expect(s.categories.first?.pct == 0.6)
    }

    @Test func topExpensesExcludeCredits() {
        let s = Analytics.stats(entries, range: range, kind: .month, now: now)
        #expect(s.top.map(\.amount) == [600, 300, 100])
    }

    @Test func spentCountsOnlyExpensesInRange() {
        let withTransfer = entries + [TestData.entry(5_000, kind: .transfer, category: "", date: TestData.date(2026, 11, 6),
                                                     account: "acc_hdfc", to: "acc_cash")]
        #expect(Analytics.spent(withTransfer, in: range) == 1000)
    }

    @MainActor
    @Test func trendCoversSixMonthsEndingWithTheSelectedOne() {
        #expect(AnalyticsModel.trendLength(.month) == 6)
        #expect(AnalyticsModel.trendLength(.custom) == nil)
        #expect(AnalyticsModel.trendLabel(TestData.date(2026, 11, 1), kind: .year) == "2026")
    }

    @Test func biggestChangeFindsLargestMove() {
        var now = Stats(), prev = Stats()
        now.spent = 500
        prev.spent = 900
        now.categories = [CategoryTotal(categoryId: "food", total: 400, pct: 0.8), CategoryTotal(categoryId: "bills", total: 100, pct: 0.2)]
        prev.categories = [CategoryTotal(categoryId: "food", total: 300, pct: 0.33), CategoryTotal(categoryId: "bills", total: 600, pct: 0.67)]
        let change = Analytics.biggestChange(now, prev)
        #expect(change?.categoryId == "bills")
        #expect(change?.delta == -500)
    }

    @Test func budgetFlagsOverspend() {
        let s = Analytics.stats(entries, range: range, kind: .month, now: now)
        let total = Budget(id: "budget_total", categoryId: nil, amountPaise: 80_000, updatedAt: now)
        let food = Budget(id: "budget_cat_food", categoryId: "cat_food", amountPaise: 100_000, updatedAt: now)
        let result = Analytics.budgets([total, food], stats: s, range: range, now: now)
        #expect(result.total?.over == true)
        #expect(result.total?.remaining == -200)
        #expect(result.categories.first?.remaining == 600)
        #expect(result.daysLeft == 21) // Nov 10 through Nov 30, today included
    }
}
