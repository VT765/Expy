import SwiftData
import SwiftUI

/// Suggested entries from bank messages: add, edit or dismiss each one.
struct ReviewInboxView: View {
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }) private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss
    @State private var inbox = ReviewInbox.shared
    @State private var editing: Suggestion?

    var body: some View {
        NavigationStack {
            List {
                ForEach(inbox.items) { s in
                    SuggestionRow(suggestion: s, category: categories.first { $0.id == s.categoryId },
                                  account: accounts.first { $0.id == s.accountId },
                                  add: { add(s) }, dismiss: { remove(s) }, edit: { editing = s })
                        .listRowBackground(Theme.card)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Theme.canvas)
            .overlay {
                if inbox.items.isEmpty {
                    ContentUnavailableView("All caught up", systemImage: "checkmark.circle",
                                           description: Text("Bank messages your Shortcuts automation sends to Expy appear here."))
                }
            }
            .navigationTitle("To review")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done", action: close).tint(Theme.sub) }
                if inbox.items.contains(where: { !$0.possibleDuplicate }) {
                    ToolbarItem(placement: .confirmationAction) { Button("Add all", action: addAll).tint(Theme.positive) }
                }
            }
            .sheet(item: $editing) { SuggestionEditor(suggestion: $0) }
        }
        .presentationBackground(Theme.canvas)
    }

    private func close() { dismiss() }

    private func add(_ s: Suggestion) {
        withAnimation { inbox.accept(s) }
        Haptics.success()
        ToastCenter.shared.show("Added \(Fmt.money(s.amount))")
    }

    private func remove(_ s: Suggestion) {
        withAnimation { inbox.dismiss(s) }
        Haptics.soft()
    }

    private func addAll() {
        let n = inbox.items.count { !$0.possibleDuplicate }
        withAnimation { inbox.acceptAll() }
        Haptics.success()
        ToastCenter.shared.show("Added \(n) \(n == 1 ? "entry" : "entries")")
    }
}
