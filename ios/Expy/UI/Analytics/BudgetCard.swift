import SwiftUI

/// Monthly and per-category budget progress.
struct BudgetCard: View {
    let total: BudgetLine?
    let categoryLines: [BudgetLine]
    let daysLeft: Int
    let categories: [String: ExpenseCategory]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let total { BudgetBarView(line: total, label: "Monthly budget", big: true) }
            ForEach(categoryLines) { b in
                let c = b.categoryId.flatMap { categories[$0] }
                BudgetBarView(line: b, label: "\(c?.emoji ?? "") \(c?.name ?? "")", big: false)
            }
            Text("\(daysLeft) days left in this cycle").font(.tFootnote).foregroundStyle(Theme.sub)
        }
    }
}
