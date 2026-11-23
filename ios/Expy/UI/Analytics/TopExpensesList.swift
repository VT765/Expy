import SwiftUI

/// Five largest expenses in the period.
struct TopExpensesList: View {
    let entries: [Entry]
    let categories: [String: ExpenseCategory]

    var body: some View {
        VStack(spacing: 0) {
            ForEach(entries) { e in
                TopExpenseRow(entry: e, category: categories[e.categoryId])
                if e.id != entries.last?.id {
                    Rectangle().fill(Theme.well).frame(height: 0.5).padding(.leading, 16)
                }
            }
        }
    }
}
