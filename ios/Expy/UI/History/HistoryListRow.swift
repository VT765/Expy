import SwiftUI

/// A History row with long-press actions. (Horizontal swipes change page,
/// so delete and duplicate live in the menu.)
struct HistoryListRow: View {
    let entry: Entry
    let category: ExpenseCategory?
    let accountName: String?
    let toAccountName: String?
    let accounts: [Account]
    let byCategory: Bool
    let edit: () -> Void
    @State private var makingRecurring = false

    var body: some View {
        HistoryRow(entry: entry, category: category, accountName: accountName, toAccountName: toAccountName, byCategory: byCategory, edit: edit)
            .listRowBackground(Theme.canvas)
            .listRowInsets(EdgeInsets(top: 0, leading: Theme.gutter, bottom: 0, trailing: Theme.gutter))
            .listRowSeparatorTint(Theme.well)
            .contextMenu {
                Button("Edit", systemImage: "pencil", action: edit)
                Button("Log again now", systemImage: "plus.square.on.square", action: duplicate)
                Button("Make recurring…", systemImage: "arrow.triangle.2.circlepath", action: makeRecurring)
                if !accounts.isEmpty && !entry.isTransfer {
                    Menu("Move to account", systemImage: "arrow.left.arrow.right") {
                        ForEach(accounts) { a in
                            Button { move(to: a.id) } label: {
                                if entry.accountId == a.id { Label(a.name, systemImage: "checkmark") } else { Text(a.name) }
                            }
                        }
                    }
                }
                Divider()
                Button("Delete", systemImage: "trash", role: .destructive, action: delete)
            }
            .sheet(isPresented: $makingRecurring) { RecurringRuleEditor(target: .new(template: entry)) }
    }

    private func makeRecurring() { makingRecurring = true }

    private func move(to accountId: String) { DataStore.shared.moveEntry(entry, toAccount: accountId) }

    private func duplicate() {
        let copy = DataStore.shared.duplicateEntry(entry)
        Haptics.success()
        ToastCenter.shared.show("Logged again · \(Fmt.money(copy.amount))",
                                action: ("Undo", { DataStore.shared.deleteEntry(copy) }))
    }

    private func delete() {
        let e = entry
        DataStore.shared.deleteEntry(e)
        Haptics.soft()
        ToastCenter.shared.show("Entry deleted", action: ("Undo", { DataStore.shared.restoreEntry(e) }))
    }
}
