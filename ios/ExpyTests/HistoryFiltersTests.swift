import Testing
@testable import Expy

@MainActor
struct HistoryFiltersTests {
    private let coffee = TestData.entry(120, category: "cat_food", note: "Café latte", date: TestData.date(2026, 11, 5), account: "acc_hdfc")
    private let refund = TestData.entry(703, kind: .credit, category: "cat_shopping", note: "Myntra refund", date: TestData.date(2026, 11, 20))

    @Test func emptyFiltersMatchEverything() {
        let f = HistoryFilters()
        #expect(!f.isActive)
        #expect(f.matches(coffee, categoryName: "Food"))
    }

    @Test func typeFilter() {
        var f = HistoryFilters()
        f.kind = .credit
        #expect(!f.matches(coffee, categoryName: "Food"))
        #expect(f.matches(refund, categoryName: "Shopping"))
    }

    @Test func amountRange() {
        var f = HistoryFilters()
        f.minAmount = 200
        #expect(!f.matches(coffee, categoryName: "Food"))
        f.minAmount = nil
        f.maxAmount = 500
        #expect(!f.matches(refund, categoryName: "Shopping"))
    }

    @Test func searchIgnoresCaseAndAccents() {
        var f = HistoryFilters()
        f.query = "cafe"
        #expect(f.matches(coffee, categoryName: "Food"))
        f.query = "SHOPPING"
        #expect(f.matches(refund, categoryName: "Shopping"))
    }

    @Test func dateRangeIncludesWholeEndDay() {
        var f = HistoryFilters()
        f.from = TestData.date(2026, 11, 1, 9)
        f.to = TestData.date(2026, 11, 5, 0)
        #expect(f.matches(coffee, categoryName: "Food"))
        #expect(!f.matches(refund, categoryName: "Shopping"))
    }

    @Test func accountAndCategorySubscript() {
        var f = HistoryFilters()
        f.toggleAccount("acc_hdfc")
        #expect(f.matches(coffee, categoryName: "Food"))
        #expect(!f.matches(refund, categoryName: "Shopping"))
        f[category: "cat_shopping"] = true
        #expect(f.categoryIds == ["cat_shopping"])
        f[category: "cat_shopping"] = false
        #expect(f.categoryIds.isEmpty)
    }
}
