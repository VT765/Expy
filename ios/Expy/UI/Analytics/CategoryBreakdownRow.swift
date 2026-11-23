import SwiftUI

/// Emoji, name, amount; a bar scaled to the top category; share and the
/// change since the previous period.
struct CategoryBreakdownRow: View {
    let total: CategoryTotal
    let category: ExpenseCategory?
    /// Bar length relative to the biggest category, so the top one fills the row.
    let barFraction: Double
    /// Spend in the previous period, if any.
    let previous: Double?

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(category?.emoji ?? "✨").font(.app(20)).frame(width: 28).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(category?.name ?? "Other").font(.tBodySemibold).lineLimit(1)
                    Spacer()
                    Text(Fmt.money(total.total)).font(.tBodySemibold).monospacedDigit()
                }
                FractionBar(fraction: barFraction, color: .white, height: 6)
                HStack {
                    Text("\(total.pct, format: .percent.precision(.fractionLength(0))) of spending")
                        .foregroundStyle(Theme.sub)
                    Spacer()
                    CategoryChange(now: total.total, before: previous)
                }
                .font(.tFootnote)
            }
        }
        .accessibilityElement(children: .combine)
    }
}
