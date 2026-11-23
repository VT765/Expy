import SwiftUI

/// Emoji, category/note, amount and account · time. Transfers show
/// "From → To" with a neutral, unsigned amount.
struct HistoryRow: View {
    let entry: Entry
    let category: ExpenseCategory?
    let accountName: String?
    let toAccountName: String?
    let byCategory: Bool
    let edit: () -> Void

    var body: some View {
        Button(action: edit) {
            HStack(spacing: 14) {
                if entry.isTransfer {
                    TransferCircle()
                } else {
                    EmojiCircle(emoji: category?.emoji ?? "✨", colorHex: category?.colorHex ?? "#9DB0C4")
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(.tHeadline).lineLimit(1)
                    Text(subtitle).font(.tBody).foregroundStyle(Theme.sub).lineLimit(1)
                }
                Spacer(minLength: 8)
                VStack(alignment: .trailing, spacing: 2) {
                    Text(entry.isCredit ? "+" + Fmt.money(entry.amount) : Fmt.money(entry.amount)).font(.tHeadline).monospacedDigit()
                        .foregroundStyle(entry.isTransfer ? Theme.sub : entry.isCredit ? Theme.positive : .white)
                    Text(detail).font(.tFootnote).foregroundStyle(Theme.sub).monospacedDigit().lineLimit(1)
                }
            }
            .padding(.horizontal, 12)
            .frame(minHeight: 72)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(spokenLabel)
        .accessibilityHint("Opens the entry to edit")
    }

    private var route: String { "\(accountName ?? "?") → \(toAccountName ?? "?")" }

    private var title: String {
        if entry.isTransfer { return route }
        return byCategory && !entry.note.isEmpty ? entry.note : (category?.name ?? "Other")
    }

    private var subtitle: String {
        if entry.isTransfer { return entry.note.isEmpty ? "Transfer" : entry.note }
        if byCategory { return entry.isCredit ? "Credit" : "Debit" }
        return entry.note.isEmpty ? " " : entry.note
    }

    private var detail: String {
        let when = (entry.recurringRuleId == nil ? "" : "↻ ")
            + (byCategory ? "\(Fmt.shortDate(entry.date)), \(Fmt.time(entry.date))" : Fmt.time(entry.date))
        return (entry.isTransfer ? [when] : [accountName, when]).compactMap { $0 }.joined(separator: " · ")
    }

    /// "Debit ₹80, Food, Panipuri, HDFC Bank, 10:40 PM".
    private var spokenLabel: String {
        if entry.isTransfer {
            return ["Transfer \(Fmt.money(entry.amount)) from \(accountName ?? "unknown") to \(toAccountName ?? "unknown")",
                    entry.note, Fmt.time(entry.date)].filter { !$0.isEmpty }.joined(separator: ", ")
        }
        var parts = [(entry.isCredit ? "Credit " : "Debit ") + Fmt.money(entry.amount), category?.name ?? "Other"]
        if !entry.note.isEmpty { parts.append(entry.note) }
        if let accountName { parts.append(accountName) }
        parts.append(Fmt.time(entry.date))
        return parts.joined(separator: ", ")
    }
}
