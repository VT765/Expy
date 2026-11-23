import SwiftUI

/// What Expy read from a bank message, as label/value rows.
struct ParsedMessageSummary: View {
    let message: ParsedBankMessage

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            SummaryLine(label: "Type", value: message.kind == .credit ? "Credit" : "Debit")
            SummaryLine(label: "Amount", value: Fmt.money(message.amount))
            SummaryLine(label: message.kind == .credit ? "From" : "To", value: message.counterparty ?? "—")
            SummaryLine(label: "Account", value: [message.bank, message.last4.map { "·\($0)" }].compactMap { $0 }.joined(separator: " "))
            SummaryLine(label: "Date", value: message.date.formatted(date: .abbreviated, time: .shortened))
            if let ref = message.reference { SummaryLine(label: "Reference", value: ref) }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Theme.card))
    }
}
