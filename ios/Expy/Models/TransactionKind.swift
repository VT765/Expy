/// What an entry does to money: spend it, receive it, or move it between
/// two of your accounts (never counted as spending or income).
enum TransactionKind: String, CaseIterable, Codable, Sendable {
    case expense, credit, transfer
}
