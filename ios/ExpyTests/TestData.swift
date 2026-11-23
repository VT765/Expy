import Foundation
@testable import Expy

/// Builders for test fixtures.
enum TestData {
    static let calendar = Calendar.current

    static func date(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min)) ?? .distantPast
    }

    static func entry(_ amount: Double, kind: TransactionKind = .expense, category: String = "cat_food", note: String = "",
                      date: Date, account: String? = nil, to: String? = nil) -> Entry {
        Entry(kind: kind, amountPaise: Money.paise(amount), categoryId: category, note: note, date: date,
              accountId: account, toAccountId: to, createdAt: date, updatedAt: date)
    }
}
