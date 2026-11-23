import SwiftUI

/// Where the money went: every category ranked by spend, with its share as
/// a single-colour bar (the chart and its table in one) and the change
/// versus the previous period.
struct CategoryBreakdownList: View {
    let totals: [CategoryTotal]
    let previous: [CategoryTotal]
    let categories: [String: ExpenseCategory]

    var body: some View {
        let before = Dictionary(previous.map { ($0.categoryId, $0.total) }, uniquingKeysWith: +)
        let largest = totals.first?.total ?? 1
        VStack(spacing: 14) {
            ForEach(totals) { t in
                CategoryBreakdownRow(total: t, category: categories[t.categoryId],
                                     barFraction: largest > 0 ? t.total / largest : 0, previous: before[t.categoryId])
            }
        }
    }
}
