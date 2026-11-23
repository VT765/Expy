import SwiftUI

/// "₹4,974 less on Bills" vs the previous period.
struct ChangeRecapCard: View {
    let category: ExpenseCategory?
    let delta: Double

    var body: some View {
        let less = delta < 0
        let amount = Text("\(Fmt.money(abs(delta))) \(less ? "less" : "more")").bold()
        HStack(spacing: 12) {
            EmojiCircle(emoji: category?.emoji ?? "✨", colorHex: category?.colorHex ?? "#9DB0C4", size: 40)
            VStack(alignment: .leading, spacing: 2) {
                Text("Biggest change vs previous").font(.tFootnote).foregroundStyle(Theme.sub)
                Text("\(amount) on \(category?.name ?? "Other")").font(.app(15))
            }
            Spacer()
            Image(systemName: less ? "arrow.down.right" : "arrow.up.right")
                .font(.app(16, .bold))
                .foregroundStyle(less ? Theme.positive : Theme.danger)
                .accessibilityHidden(true)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
        .accessibilityElement(children: .combine)
    }
}
