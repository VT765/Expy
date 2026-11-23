import SwiftUI

/// "₹19,692 this month · 12% below your 5-month average", or the tapped bar's value.
struct TrendHeadline: View {
    let current: TrendPoint?
    let selected: TrendPoint?
    let average: Double?
    let unitName: String

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            if let selected {
                Text(selected.label).font(.tFootnote).foregroundStyle(Theme.sub)
                Text(Fmt.money(selected.total)).font(.tHeadline)
            } else if let current {
                Text("This \(unitName)").font(.tFootnote).foregroundStyle(Theme.sub)
                Text(Fmt.money(current.total)).font(.tHeadline)
                if let average, average > 0 {
                    ComparisonLabel(change: (current.total - average) / average, against: "average")
                }
            }
        }
        .accessibilityElement(children: .combine)
    }
}
