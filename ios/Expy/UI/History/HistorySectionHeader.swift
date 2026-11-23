import SwiftUI

/// Day header ("TODAY … ₹1,829") or category header with count and share bar.
struct HistorySectionHeader: View {
    let title: String
    let count: Int
    let total: Double
    let share: Double
    let colorHex: String?
    let byCategory: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(byCategory ? title : title.uppercased())
                    .tracking(byCategory ? 0 : 1)
                    .font(.app(13, byCategory ? .semibold : .regular))
                    .foregroundStyle(byCategory ? .white : Theme.faint)
                if byCategory {
                    Text("· \(count)").font(.app(13)).foregroundStyle(Theme.faint)
                }
                Spacer()
                Text(Fmt.flow(spending: total)).font(.app(13, byCategory ? .semibold : .regular))
                    .foregroundStyle(total < -0.004 ? Theme.positive : byCategory ? .white : Theme.faint)
            }
            if byCategory, share > 0 {
                FractionBar(fraction: share, color: Color(hex: colorHex ?? "#9DB0C4"), height: 4)
            }
        }
        .padding(.top, 10)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}
