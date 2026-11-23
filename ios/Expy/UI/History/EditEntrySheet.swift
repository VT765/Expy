import SwiftData
import SwiftUI

/// Edit an entry: rupee amount, debit/credit/transfer, category (or the
/// From and To accounts for a transfer), date, note.
struct EditEntrySheet: View {
    let entry: Entry
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss

    @State private var amount: Double?
    @State private var kind = TransactionKind.expense
    @State private var categoryId = ""
    @State private var date = Date.now
    @State private var note = ""
    @State private var accountId: String?
    @State private var toAccountId: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    HStack(spacing: 8) {
                        Text("₹").font(.app(22, .bold)).foregroundStyle(Theme.sub).padding(.leading, 16)
                        TextField("Amount", value: $amount, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .font(.app(22, .bold))
                            .padding(.trailing, 16).frame(minHeight: 48)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
                    Pills(options: kindOptions, selection: $kind)
                    if kind == .transfer {
                        AccountMenuField(title: "From", selection: $accountId, accounts: accounts)
                        AccountMenuField(title: "To", selection: $toAccountId, accounts: accounts)
                    } else {
                        ScrollView(.horizontal) {
                            HStack(spacing: 10) {
                                ForEach(shownCategories) { c in
                                    CategoryChip(category: c, selected: c.id == categoryId) { categoryId = c.id }
                                }
                            }
                        }
                        .scrollIndicators(.hidden)
                        AccountMenuField(title: "Account", selection: $accountId, accounts: accounts, allowsNone: true)
                    }
                    DatePicker("Date & time", selection: $date).tint(.white).font(.tBody)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Note").font(.tFootnote).foregroundStyle(Theme.sub)
                        TextField("Add a note", text: $note).fieldStyle()
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    PrimaryButton(title: "Delete", role: .destructive, action: delete).frame(width: 120)
                    PrimaryButton(title: "Save", action: save)
                }
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle("Edit entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel).tint(Theme.sub) }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Theme.card)
        .onAppear(perform: load)
        .onChange(of: kind) { _, _ in matchCategoryToKind() }
    }

    private func load() {
        amount = entry.amount
        kind = entry.kind
        categoryId = entry.categoryId
        date = entry.date
        note = entry.note
        accountId = entry.accountId
        toAccountId = entry.toAccountId
    }

    private func cancel() { dismiss() }

    /// Categories for the chosen kind, plus the entry's own if it's from the other list
    /// (older credits were logged with debit categories).
    private var shownCategories: [ExpenseCategory] {
        categories.filter { $0.isCredit == (kind == .credit) || ($0.id == entry.categoryId && kind == entry.kind) }
    }

    private func matchCategoryToKind() {
        guard kind != .transfer, !shownCategories.contains(where: { $0.id == categoryId }) else { return }
        categoryId = shownCategories.first?.id ?? Defaults.fallbackCategoryId(for: kind)
    }

    private var kindOptions: [(TransactionKind, String)] {
        [(.expense, "Debit"), (.credit, "Credit")] + (accounts.count > 1 || entry.isTransfer ? [(.transfer, "Transfer")] : [])
    }

    private func delete() {
        let e = entry
        DataStore.shared.deleteEntry(e)
        ToastCenter.shared.show("Entry deleted", action: ("Undo", { DataStore.shared.restoreEntry(e) }))
        dismiss()
    }

    private func save() {
        guard let amount, amount > 0 else {
            ToastCenter.shared.error("Enter an amount greater than 0")
            return
        }
        if kind == .transfer && (accountId == nil || toAccountId == nil || accountId == toAccountId) {
            ToastCenter.shared.error("Pick two different accounts")
            return
        }
        // An entry that stops being a transfer needs a category again.
        let category = kind == .transfer ? Defaults.transferCategoryId
            : categoryId == Defaults.transferCategoryId ? Defaults.fallbackCategoryId(for: kind) : categoryId
        DataStore.shared.updateEntry(entry, kind: kind, amount: amount, categoryId: category,
                                     note: note, date: date, accountId: accountId, toAccountId: toAccountId)
        ToastCenter.shared.show("Changes saved")
        dismiss()
    }
}
