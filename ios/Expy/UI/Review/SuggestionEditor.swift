import SwiftData
import SwiftUI

/// Adjust a suggestion before adding it: debit/credit, amount, category,
/// account, date and note.
struct SuggestionEditor: View {
    @State var suggestion: Suggestion
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss
    @State private var amount: Double?

    private var shownCategories: [ExpenseCategory] { categories.filter { $0.isCredit == (suggestion.kind == .credit) } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Pills(options: [(TransactionKind.expense, "Debit"), (.credit, "Credit")], selection: $suggestion.kind)
                    HStack(spacing: 8) {
                        Text("₹").font(.app(22, .bold)).foregroundStyle(Theme.sub).padding(.leading, 16)
                        TextField("Amount", value: $amount, format: .number.precision(.fractionLength(0...2)))
                            .keyboardType(.decimalPad)
                            .font(.app(22, .bold))
                            .padding(.trailing, 16).frame(minHeight: 48)
                    }
                    .background(RoundedRectangle(cornerRadius: 14).fill(Theme.raised))
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(shownCategories) { c in
                                CategoryChip(category: c, selected: c.id == suggestion.categoryId) { suggestion.categoryId = c.id }
                            }
                        }
                    }
                    .scrollIndicators(.hidden)
                    AccountMenuField(title: suggestion.last4.map { "Account (ends \($0))" } ?? "Account",
                                     selection: $suggestion.accountId, accounts: accounts, allowsNone: true)
                    DatePicker("Date & time", selection: $suggestion.date).tint(.white).font(.tBody)
                    TitledGroup(title: "Note") {
                        TextField("Add a note", text: $suggestion.note).fieldStyle()
                    }
                    if suggestion.last4 != nil {
                        Text("Expy will remember this account for messages about ·\(suggestion.last4 ?? "").")
                            .font(.tFootnote).foregroundStyle(Theme.sub)
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                HStack(spacing: 12) {
                    PrimaryButton(title: "Dismiss", role: .destructive, action: remove).frame(width: 130)
                    PrimaryButton(title: "Add entry", action: add).disabled((amount ?? 0) <= 0)
                }
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle("Review entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel", action: cancel).tint(Theme.sub) } }
        }
        .presentationBackground(Theme.card)
        .onAppear { amount = suggestion.amount }
        .onChange(of: suggestion.kind) { _, _ in matchCategoryToKind() }
    }

    private func matchCategoryToKind() {
        guard !shownCategories.contains(where: { $0.id == suggestion.categoryId }) else { return }
        suggestion.categoryId = shownCategories.first?.id ?? Defaults.fallbackCategoryId(for: suggestion.kind)
    }

    private func cancel() { dismiss() }

    private func remove() {
        ReviewInbox.shared.dismiss(suggestion)
        dismiss()
    }

    private func add() {
        var s = suggestion
        s.amount = amount ?? s.amount
        s.note = s.note.trimmingCharacters(in: .whitespaces)
        ReviewInbox.shared.accept(s)
        Haptics.success()
        ToastCenter.shared.show("Added \(Fmt.money(s.amount))")
        dismiss()
    }
}
