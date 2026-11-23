import SwiftData
import SwiftUI

/// Monthly budget, category budgets and cycle start day.
struct BudgetSettingsSection: View {
    @Query private var settingsList: [AppSettings]
    @Query(filter: #Predicate<Budget> { $0.deletedAt == nil }) private var budgets: [Budget]
    @State private var editingMonthly = false
    @State private var pickingCycle = false
    @AppStorage(BudgetAlerts.enabledKey) private var alertsOn = true

    private var cycleDay: Int { settingsList.first?.cycleStartDay ?? 1 }
    private var total: Budget? { budgets.first { $0.id == "budget_total" } }
    private var categoryBudgetCount: Int { budgets.count { $0.categoryId != nil && $0.amount > 0 } }

    var body: some View {
        SettingsSection(title: "Budget") {
            SettingsRow(title: "Monthly Budget", value: total.map { Fmt.money($0.amount) } ?? "Not set", action: editMonthly)
            SettingsLinkRow(title: "Category budgets", value: categoryBudgetCount > 0 ? "\(categoryBudgetCount) set" : "None",
                            route: .categoryBudgets)
            SettingsRow(title: "Cycle starts on", subtitle: "Budget and monthly totals reset on this day",
                        value: Fmt.ordinal(cycleDay), action: pickCycle)
            SettingsRow(title: "Budget alerts", subtitle: "Notify at 80% and 100% of a budget", chevron: false, action: nil) {
                Toggle("Budget alerts", isOn: $alertsOn).labelsHidden().tint(Theme.positive)
            }
        }
        .onChange(of: alertsOn) { _, on in if on { askForNotifications() } }
        .sheet(isPresented: $editingMonthly) {
            AmountSheet(title: "Monthly budget", hint: "Spending across all categories per cycle.",
                        value: total?.amount ?? 0, onSave: saveMonthly)
        }
        .sheet(isPresented: $pickingCycle) {
            OptionList(title: "Cycle starts on", options: (1...28).map { ($0, "\(Fmt.ordinal($0)) of the month") },
                       selected: cycleDay, onSelect: saveCycle)
        }
    }

    private func editMonthly() { editingMonthly = true }
    private func pickCycle() { pickingCycle = true }
    private func saveMonthly(_ amount: Double) {
        DataStore.shared.setBudget(categoryId: nil, amount: amount)
        if amount > 0 && alertsOn { askForNotifications() }
    }

    private func askForNotifications() { Task { await Notifier.requestPermission() } }
    private func saveCycle(_ day: Int) { DataStore.shared.updateSettings { $0.cycleStartDay = day } }
}
