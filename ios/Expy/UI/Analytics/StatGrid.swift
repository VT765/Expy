import SwiftUI

/// Spent (full width, with change badge), Credit, Net, Avg/day, Entries.
struct StatGrid: View {
    let stats: Stats
    let previous: Stats

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            GridRow {
                StatTile(label: "Spent", value: Fmt.money(stats.spent), big: true) {
                    if previous.spent > 0 {
                        ChangeBadge(change: (stats.spent - previous.spent) / previous.spent)
                    }
                }
                .gridCellColumns(2)
            }
            GridRow {
                StatTile(label: "Credit", value: Fmt.money(stats.credit))
                StatTile(label: "Net", value: Fmt.flow(spending: stats.net))
            }
            GridRow {
                StatTile(label: "Avg / day", value: Fmt.money(stats.avgPerDay.rounded()))
                StatTile(label: "Entries", value: "\(stats.count)")
            }
        }
    }
}
