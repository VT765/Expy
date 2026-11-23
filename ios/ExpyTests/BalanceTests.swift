import Testing
@testable import Expy

@MainActor
struct BalanceTests {
    @Test func balanceCountsOnlyEntriesAfterOpening() {
        let opened = TestData.date(2026, 11, 10)
        let hdfc = Account(id: "acc_hdfc", name: "HDFC", kind: .bank, openingBalancePaise: 100_000, openingDate: opened, order: 0)
        let entries = [
            TestData.entry(200, date: TestData.date(2026, 11, 11), account: "acc_hdfc"),
            TestData.entry(500, kind: .credit, date: TestData.date(2026, 11, 12), account: "acc_hdfc"),
            TestData.entry(300, date: TestData.date(2026, 11, 9), account: "acc_hdfc"), // before opening: already in the balance
            TestData.entry(50, date: TestData.date(2026, 11, 12), account: "acc_cash"), // another account
        ]
        #expect(DataStore.balance(of: hdfc, entries: entries) == 1300)
    }

    @Test func deletedEntriesAreIgnored() {
        let cash = Account(id: "acc_cash", name: "Cash", kind: .cash, openingBalancePaise: 10_000, openingDate: .distantPast, order: 0)
        let spent = TestData.entry(40, date: TestData.date(2026, 11, 1), account: "acc_cash")
        spent.deletedAt = .now
        #expect(DataStore.balance(of: cash, entries: [spent]) == 100)
    }

    @Test func transferMovesMoneyBetweenAccounts() {
        let hdfc = Account(id: "acc_hdfc", name: "HDFC", kind: .bank, openingBalancePaise: 1_000_000, openingDate: .distantPast, order: 0)
        let cash = Account(id: "acc_cash", name: "Cash", kind: .cash, openingBalancePaise: 0, openingDate: .distantPast, order: 1)
        let atm = TestData.entry(2_000, kind: .transfer, category: "", date: TestData.date(2026, 11, 3), account: "acc_hdfc", to: "acc_cash")
        #expect(DataStore.balance(of: hdfc, entries: [atm]) == 8_000)
        #expect(DataStore.balance(of: cash, entries: [atm]) == 2_000)
        #expect(atm.spendPaise == 0)
    }
}
