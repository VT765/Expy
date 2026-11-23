import Foundation
import Testing
@testable import Expy

struct BackupCompatibilityTests {
    /// A backup written by the previous version (Double rupees, currencies).
    private let v1 = """
    {"app":"expy","version":1,"exportedAt":1763900000000,
     "transactions":[{"id":"tx_1","type":"expense","amount":12,"currency":"USD","amountInBase":1003.55,"categoryId":"cat_food",
                      "note":"Lunch","date":1763800000000,"createdAt":1763800000000,"updatedAt":1763800000000,"accountId":"acc_cash"}],
     "categories":[],
     "budgets":[{"id":"budget_total","categoryId":null,"amount":40000.5,"updatedAt":1763800000000,"deletedAt":null}],
     "settings":{"id":"app","baseCurrency":"INR","cycleStartDay":3,"rateOverrides":{},"updatedAt":0},
     "accounts":[{"id":"acc_cash","name":"Cash","kind":"cash","openingBalance":2000.25,"openingDate":0,"order":0,"updatedAt":0}]}
    """

    @Test func readsVersion1Backups() throws {
        let b = try JSONDecoder().decode(BackupFile.self, from: Data(v1.utf8))
        #expect(b.transactions.first?.amountPaise == 100_355)
        #expect(b.transactions.first?.kind == .expense)
        #expect(b.budgets.first?.amountPaise == 4_000_050)
        #expect(b.accounts?.first?.openingBalancePaise == 200_025)
        #expect(b.settings?.cycleStartDay == 3)
    }

    @Test func version2RoundTrips() throws {
        let b = try JSONDecoder().decode(BackupFile.self, from: Data(v1.utf8))
        let again = try JSONDecoder().decode(BackupFile.self, from: JSONEncoder().encode(b))
        #expect(again.transactions.first?.amountPaise == 100_355)
        #expect(again.accounts?.first?.openingBalancePaise == 200_025)
        let json = String(decoding: try JSONEncoder().encode(again), as: UTF8.self)
        #expect(!json.contains("currency") && !json.contains("amountInBase"))
    }
}
