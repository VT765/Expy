import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct CategoryBudgetsView: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Budget> { $0.deletedAt == nil }) private var budgets: [Budget]
    @State private var editing: ExpenseCategory?

    private func amount(_ id: String) -> Double { budgets.first { $0.categoryId == id }?.amount ?? 0 }

    var body: some View {
        ScrollView {
            VStack(spacing: 6) {
                Text("Monthly limits per category. Progress shows on Analytics.")
                    .font(.tFootnote).foregroundStyle(Theme.sub).padding(.bottom, 10)
                ForEach(categories.filter { !$0.isCredit }) { c in
                    let a = amount(c.id)
                    SettingsRow(title: "\(c.emoji)  \(c.name)", value: a > 0 ? Fmt.money(a) : "Not set") { editing = c }
                }
            }
            .padding(Theme.gutter)
        }
        .background(Theme.canvas)
        .navigationTitle("Category budgets")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $editing) { c in
            AmountSheet(title: "\(c.emoji) \(c.name)", value: amount(c.id)) {
                DataStore.shared.setBudget(categoryId: c.id, amount: $0)
                if $0 > 0 && BudgetAlerts.shared.isEnabled { Task { await Notifier.requestPermission() } }
            }
        }
    }
}
