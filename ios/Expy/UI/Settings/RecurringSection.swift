import SwiftData
import SwiftUI

/// Settings → Recurring: rent, subscriptions, EMIs, salary. Each rule shows
/// its amount, frequency and next date; tap to edit.
struct RecurringSection: View {
    @Query(filter: #Predicate<RecurringRule> { $0.deletedAt == nil }, sort: \RecurringRule.nextDate) private var rules: [RecurringRule]
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }) private var categories: [ExpenseCategory]
    @State private var editing: RecurringTarget?

    var body: some View {
        SettingsSection(title: "Recurring", hint: "Added automatically on their date, with a reminder that morning.") {
            VStack(spacing: 0) {
                ForEach(rules) { r in
                    RecurringRuleRow(rule: r, category: categories.first { $0.id == r.categoryId }) { editing = .existing(r) }
                    Rectangle().fill(Theme.well).frame(height: 0.5).padding(.leading, 66)
                }
                Button(action: add) {
                    HStack(spacing: 14) {
                        Image(systemName: "plus").font(.app(17, .semibold)).frame(width: 36)
                        Text("Add recurring").font(.app(16, .semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).frame(minHeight: 56)
                    .contentShape(.rect)
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius).fill(Theme.card))
        }
        .sheet(item: $editing) { RecurringRuleEditor(target: $0) }
    }

    private func add() { editing = .new(template: nil) }
}
