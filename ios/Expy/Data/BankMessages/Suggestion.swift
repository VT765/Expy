import Foundation

/// An entry suggested by a bank message, waiting in the review list.
struct Suggestion: Codable, Identifiable, Equatable {
    var id = UUID()
    var kind: TransactionKind
    var amount: Double
    var date: Date
    var accountId: String?
    var categoryId: String
    var note: String
    var last4: String?
    var bank: String?
    var reference: String?
    /// An entry with the same day, amount and kind already exists.
    var possibleDuplicate = false
    var receivedAt = Date.now
}
