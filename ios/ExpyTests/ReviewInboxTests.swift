import Foundation
import Testing
@testable import Expy

@MainActor
struct ReviewInboxTests {
    private let sms = "Sent Rs.1950.00\nFrom HDFC Bank A/C *6821\nTo MANISH JADEJA\nOn 23/11/26\nRef 007303004202"

    @Test func sameReferenceIsSuggestedOnce() throws {
        let inbox = ReviewInbox(url: nil)
        let parsed = try #require(BankMessageParser.parse(sms))
        let s = try #require(inbox.suggestion(from: parsed))
        #expect(s.note == "Manish Jadeja")
        #expect(s.kind == .expense)
        inbox.add(s)
        #expect(inbox.count == 1)
        #expect(inbox.suggestion(from: parsed) == nil)
        inbox.dismiss(s)
        #expect(inbox.count == 0)
        #expect(inbox.suggestion(from: parsed) == nil) // dismissed messages stay handled
    }
}

@MainActor
struct BankAccountMatcherTests {
    private let hdfc = Account(id: "acc_h", name: "HDFC Bank", kind: .bank, openingBalancePaise: 0, openingDate: .distantPast, order: 0)
    private let bob = Account(id: "acc_b", name: "Bank of Baroda", kind: .bank, openingBalancePaise: 0, openingDate: .distantPast, order: 1)
    private let cash = Account(id: "acc_cash", name: "Cash", kind: .cash, openingBalancePaise: 0, openingDate: .distantPast, order: 2)

    private func defaults() -> UserDefaults {
        let d = UserDefaults(suiteName: "matcher-\(UUID().uuidString)")!
        return d
    }

    @Test func matchesBankNameThenRemembersDigits() {
        let d = defaults()
        let all = [hdfc, bob, cash]
        #expect(BankAccountMatcher.account(last4: "6821", bank: "HDFC", among: all, defaults: d)?.id == "acc_h")
        #expect(BankAccountMatcher.account(last4: "4417", bank: "BoB", among: all, defaults: d)?.id == "acc_b")
        #expect(BankAccountMatcher.account(last4: "9999", bank: nil, among: all, defaults: d) == nil)
        BankAccountMatcher.remember(last4: "9999", accountId: "acc_b", defaults: d)
        #expect(BankAccountMatcher.account(last4: "9999", bank: nil, among: all, defaults: d)?.id == "acc_b")
    }

    @Test func singleBankAccountIsTheFallback() {
        #expect(BankAccountMatcher.account(last4: nil, bank: nil, among: [hdfc, cash], defaults: defaults())?.id == "acc_h")
    }
}
