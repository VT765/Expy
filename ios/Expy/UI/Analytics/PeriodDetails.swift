import SwiftUI

/// Everything below the stat tiles once a period has data.
struct PeriodDetails: View {
    let snap: AnalyticsModel.Snapshot
    let categories: [String: ExpenseCategory]
    let kind: PeriodKind
    @Binding var selectedBar: Date?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !snap.stats.buckets.isEmpty {
                AnalyticsCard(title: "Spending over time") {
                    SpendingBarChart(buckets: snap.stats.buckets, kind: kind, dailyBudget: snap.dailyBudget,
                                     selectedBar: $selectedBar)
                }
            }
            if let trend = snap.trend, trend.contains(where: { $0.total > 0 }) {
                AnalyticsCard(title: "Trend · last \(trend.count) \(unitName)s") {
                    TrendChart(points: trend, unitName: unitName)
                }
            }
            if let insight = snap.insight {
                ChangeRecapCard(category: categories[insight.categoryId], delta: insight.delta).padding(.top, 12)
            }
            if !snap.stats.categories.isEmpty {
                AnalyticsCard(title: "Where it went") {
                    CategoryBreakdownList(totals: snap.stats.categories, previous: snap.previous.categories, categories: categories)
                }
            }
            if !snap.stats.top.isEmpty {
                AnalyticsCard(title: "Top expenses", padded: false) {
                    TopExpensesList(entries: snap.stats.top, categories: categories)
                }
            }
            ExportButtonsRow(range: snap.range).padding(.top, 28)
        }
    }

    private var unitName: String {
        switch kind {
        case .week: "week"
        case .year: "year"
        default: "month"
        }
    }
}
