#if DEBUG
import Foundation

extension DataStore {
    /// Sample accounts and ~2 months of entries for simulator screenshots.
    /// Debug builds only; triggered by the -seedDemo launch argument.
    func seedDemo() {
        seedDemoTransfer()
        seedDemoRecurring()
        guard fetch(Entry.self).isEmpty else { return }
        let cal = Calendar.current
        let start = cal.date(byAdding: .day, value: -60, to: Date.now)!
        saveAccount(id: nil, name: "HDFC Bank", kind: .bank, openingBalance: 48_750, openingDate: start)
        saveAccount(id: nil, name: "BoB", kind: .bank, openingBalance: 12_300, openingDate: start)
        if let cash = account(Defaults.cashAccountId) { cash.openingBalance = 2_000; cash.openingDate = start }
        let accounts = activeAccounts.map(\.id)
        let samples: [(String, String, ClosedRange<Double>)] = [
            ("cat_food", "Panipuri madhuli", 40...180), ("cat_food", "Swiggy dinner", 250...650),
            ("cat_transport", "Uber to office", 120...420), ("cat_groceries", "DMart run", 600...2400),
            ("cat_subscriptions", "Mobile recharge", 299...899), ("cat_shopping", "Myntra", 700...3200),
            ("cat_bills", "Electricity bill", 900...2600), ("cat_personal_care", "Haircut", 200...450),
            ("cat_entertainment", "Movie", 300...800), ("cat_health", "Pharmacy", 90...600), ("cat_other", "Rahil project print", 60...200),
        ]
        var rng = SystemRandomNumberGenerator()
        for day in 0..<60 {
            let date = cal.date(byAdding: .day, value: -day, to: Date.now)!
            for _ in 0..<Int.random(in: 0...3, using: &rng) {
                let s = samples.randomElement(using: &rng)!
                let t = cal.date(bySettingHour: Int.random(in: 8...22), minute: Int.random(in: 0...59), second: 0, of: date)!
                addEntry(kind: .expense, amount: Double(Int.random(in: Int(s.2.lowerBound)...Int(s.2.upperBound))),
                         categoryId: s.0, note: s.1, date: t, accountId: accounts.randomElement(using: &rng))
            }
        }
        addEntry(kind: .credit, amount: 703, categoryId: "cat_shopping", note: "Myntra Refund",
                 date: cal.date(byAdding: .day, value: -2, to: Date.now)!, accountId: accounts.first { $0 != Defaults.cashAccountId })
        addEntry(kind: .credit, amount: 85_000, categoryId: "cat_other", note: "Salary",
                 date: cal.date(byAdding: .day, value: -20, to: Date.now)!, accountId: accounts.first { $0 != Defaults.cashAccountId })
        setBudget(categoryId: nil, amount: 40_000)
        seedDemoTransfer()
    }

    /// Rent and Netflix, next due in the future so they don't change the demo totals.
    private func seedDemoRecurring() {
        guard fetch(RecurringRule.self).isEmpty, let bank = activeAccounts.first(where: { !$0.isCash }) else { return }
        let cal = Calendar.current
        let firstOfNext = cal.date(from: cal.dateComponents([.year, .month], from: cal.date(byAdding: .month, value: 1, to: .now)!))!
        let rent = RecurringRule(kind: .expense, amountPaise: 1_500_000, categoryId: "cat_bills", accountId: bank.id, note: "Rent",
                                 frequency: .monthly, startDate: RecurringEngine.atNine(firstOfNext))
        let netflix = RecurringRule(kind: .expense, amountPaise: 64_900, categoryId: "cat_subscriptions", accountId: bank.id, note: "Netflix",
                                    frequency: .monthly, startDate: RecurringEngine.atNine(cal.date(byAdding: .day, value: 14, to: firstOfNext)!))
        context.insert(rent)
        context.insert(netflix)
        save()
    }

    /// The sample HDFC UPI SMS, waiting in the review list (-demoInbox).
    func seedDemoInbox() {
        let sms = "Sent Rs.1950.00\nFrom HDFC Bank A/C *6821\nTo MANISH JADEJA\nOn 23/11/26\nRef 007303004202"
        guard let p = BankMessageParser.parse(sms), let s = ReviewInbox.shared.suggestion(from: p) else { return }
        ReviewInbox.shared.add(s)
    }

    /// An ATM withdrawal (bank → cash), added once.
    private func seedDemoTransfer() {
        let transfer = TransactionKind.transfer.rawValue
        guard fetch(Entry.self, #Predicate { $0.kindRaw == transfer }).isEmpty,
              let bank = activeAccounts.first(where: { !$0.isCash }) else { return }
        addEntry(kind: .transfer, amount: 5_000, categoryId: Defaults.transferCategoryId, note: "ATM withdrawal",
                 date: Calendar.current.date(byAdding: .hour, value: -3, to: .now)!, accountId: bank.id, toAccountId: Defaults.cashAccountId)
    }
}
#endif
