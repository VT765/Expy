import Foundation

/// What a bank SMS or email says about one transaction.
struct ParsedBankMessage: Equatable {
    var kind: TransactionKind
    var amount: Double
    /// Last digits of the account or card ("6821").
    var last4: String?
    /// Short bank name when the text names one ("HDFC", "BoB").
    var bank: String?
    /// Who the money went to or came from ("Manish Jadeja", "Amazon").
    var counterparty: String?
    var date: Date
    /// UPI / bank reference, used to skip a message seen twice.
    var reference: String?
}
