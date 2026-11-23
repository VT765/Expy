import SwiftData
import SwiftUI

/// Full filter editor: search, type, accounts, categories, amount and date range.
struct FilterSheet: View {
    @Binding var filters: HistoryFilters
    @State private var draft = HistoryFilters()
    @State private var useFrom = false
    @State private var useTo = false
    @State private var fromDate = Date.now
    @State private var toDate = Date.now
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order)
    private var categories: [ExpenseCategory]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HStack {
                        Image(systemName: "magnifyingglass").foregroundStyle(Theme.faint).accessibilityHidden(true)
                        TextField("Search notes", text: $draft.query)
                    }
                    .fieldStyle()

                    TitledGroup(title: "Type") {
                        Pills(options: [(nil, "All"), (TransactionKind.expense, "Debits"), (.credit, "Credits"), (.transfer, "Transfers")], selection: $draft.kind)
                    }

                    if !accounts.isEmpty {
                        TitledGroup(title: "Accounts") {
                            FlowLayout(spacing: 8) {
                                ForEach(accounts) { a in
                                    FilterChip(title: a.name, icon: a.symbol, on: draft.accountIds.contains(a.id)) { draft.toggleAccount(a.id) }
                                }
                            }
                        }
                    }

                    TitledGroup(title: "Categories") {
                        FlowLayout(spacing: 8) {
                            ForEach(categories) { c in
                                CategoryChip(category: c, selected: draft.categoryIds.contains(c.id)) { draft.toggleCategory(c.id) }
                            }
                        }
                    }

                    TitledGroup(title: "Amount range") {
                        HStack(spacing: 12) {
                            TextField("Min", value: $draft.minAmount, format: .number).keyboardType(.decimalPad).fieldStyle()
                            Text("–").foregroundStyle(Theme.sub)
                            TextField("Max", value: $draft.maxAmount, format: .number).keyboardType(.decimalPad).fieldStyle()
                        }
                    }

                    TitledGroup(title: "Date range") {
                        FilterDateRow(title: "From", isOn: $useFrom, date: $fromDate)
                        FilterDateRow(title: "To", isOn: $useTo, date: $toDate)
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: "Apply", action: apply)
                    .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle("Filters")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Close", action: close).tint(Theme.sub) }
                ToolbarItem(placement: .confirmationAction) { Button("Reset", action: reset).tint(Theme.sub) }
            }
        }
        .presentationBackground(Theme.card)
        .onAppear(perform: load)
    }

    private func load() {
        draft = filters
        useFrom = filters.from != nil
        useTo = filters.to != nil
        fromDate = filters.from ?? .now
        toDate = filters.to ?? .now
    }

    private func apply() {
        draft.from = useFrom ? fromDate : nil
        draft.to = useTo ? toDate : nil
        filters = draft
        dismiss()
    }

    private func reset() {
        draft = HistoryFilters()
        useFrom = false
        useTo = false
    }

    private func close() { dismiss() }
}
