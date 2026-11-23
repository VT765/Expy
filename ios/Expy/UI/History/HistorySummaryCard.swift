import SwiftUI

/// Spent | Received | View (by day / by category).
struct HistorySummaryCard: View {
    let spent: Double
    let received: Double
    @Binding var grouping: String

    var body: some View {
        HStack(spacing: 0) {
            SummaryStat(label: "Spent", value: Fmt.money(spent), color: .white)
            Rectangle().fill(Theme.well).frame(width: 0.5, height: 30)
            SummaryStat(label: "Received", value: Fmt.money(received), color: Theme.positive)
            Rectangle().fill(Theme.well).frame(width: 0.5, height: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text("View").font(.app(12)).foregroundStyle(Theme.sub)
                Menu {
                    Picker("Group by", selection: $grouping) {
                        Label("By day", systemImage: "calendar").tag("day")
                        Label("By category", systemImage: "square.grid.2x2").tag("category")
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text(grouping == "day" ? "Day" : "Category").font(.app(15, .bold)).lineLimit(1)
                        Image(systemName: "chevron.up.chevron.down").font(.app(10, .bold)).accessibilityHidden(true)
                    }
                    .foregroundStyle(.white)
                    .frame(minHeight: 44, alignment: .leading)
                }
                .accessibilityLabel("Group by \(grouping == "day" ? "day" : "category")")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 12)
        }
        .padding(.vertical, 6).padding(.horizontal, 14)
        .background(RoundedRectangle(cornerRadius: 16).fill(Theme.card))
    }
}
