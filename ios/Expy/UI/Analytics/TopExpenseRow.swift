import SwiftUI

/// One top-expense row.
struct TopExpenseRow: View {
    let entry: Entry
    let category: ExpenseCategory?

    var body: some View {
        HStack(spacing: 12) {
            EmojiCircle(emoji: category?.emoji ?? "✨", colorHex: category?.colorHex ?? "#9DB0C4", size: 38)
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.note.isEmpty ? (category?.name ?? "Other") : entry.note).font(.tBodySemibold).lineLimit(1)
                Text("\(category?.name ?? "Other") · \(Fmt.shortDate(entry.date)), \(Fmt.time(entry.date))")
                    .font(.tFootnote).foregroundStyle(Theme.sub)
            }
            Spacer()
            Text(Fmt.money(entry.amount)).font(.app(15, .bold)).monospacedDigit()
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .accessibilityElement(children: .combine)
    }
}
