import SwiftUI

/// One budget: spent / limit, progress bar, remaining or over-budget warning.
struct BudgetBarView: View {
    let line: BudgetLine
    let label: String
    let big: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline) {
                Text(label).font(.app(big ? 16 : 15, .semibold)).lineLimit(1)
                Spacer()
                Text("\(Fmt.money(line.spent)) / \(Fmt.money(line.amount))").font(.tFootnote).monospacedDigit()
                    .foregroundStyle(line.over ? Theme.danger : Theme.sub)
            }
            FractionBar(fraction: line.pct, color: line.over ? Theme.danger : .white, height: big ? 10 : 6)
            Label {
                Text(line.over ? "Over budget by \(Fmt.money(-line.remaining))"
                               : "\(Fmt.money(line.remaining)) left · \(Fmt.money(line.perDay))/day")
            } icon: {
                Image(systemName: "exclamationmark.triangle.fill").opacity(line.over ? 1 : 0)
            }
            .labelStyle(BudgetStatusLabelStyle(showsIcon: line.over))
            .font(.app(13, line.over ? .semibold : .regular))
            .foregroundStyle(line.over ? Theme.danger : Theme.sub)
        }
        .accessibilityElement(children: .combine)
    }
}
