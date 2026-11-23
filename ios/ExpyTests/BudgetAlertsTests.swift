import Testing
@testable import Expy

@MainActor
struct BudgetAlertsTests {
    @Test func announcesEachThresholdOncePerCycle() {
        #expect(BudgetAlerts.newThreshold(fraction: 0.5, alreadySent: []) == nil)
        #expect(BudgetAlerts.newThreshold(fraction: 0.8, alreadySent: []) == 80)
        #expect(BudgetAlerts.newThreshold(fraction: 0.85, alreadySent: [80]) == nil)
        #expect(BudgetAlerts.newThreshold(fraction: 1.0, alreadySent: [80]) == 100)
        #expect(BudgetAlerts.newThreshold(fraction: 1.3, alreadySent: [80, 100]) == nil)
    }

    @Test func jumpingPastBothSendsOnlyTheOverBudgetAlert() {
        #expect(BudgetAlerts.newThreshold(fraction: 1.2, alreadySent: []) == 100)
    }

    @Test func noEightyPercentAlertAfterOverBudget() {
        // Spending fell (an entry was deleted) after the 100% alert went out.
        #expect(BudgetAlerts.newThreshold(fraction: 0.9, alreadySent: [80, 100]) == nil)
    }

    @Test func messagesSayWhatIsLeft() {
        let line = BudgetLine(id: "budget_total", categoryId: nil, amount: 40_000, spent: 32_100, perDay: 0)
        let m = BudgetAlerts.message(line: line, name: nil, threshold: 80, daysLeft: 8)
        #expect(m.title == "Monthly budget: 80% used")
        #expect(m.body == "₹32,100 of ₹40,000 spent. ₹7,900 left for 8 days.")
        let over = BudgetLine(id: "budget_cat_food", categoryId: "cat_food", amount: 6_000, spent: 6_200, perDay: 0)
        #expect(BudgetAlerts.message(line: over, name: "🍔 Food", threshold: 100, daysLeft: 1).body
                == "₹6,200 of ₹6,000 spent, ₹200 over with 1 day left.")
    }
}
