import SwiftUI

/// One-tap view chips: Debit · Credit | accounts | Categories ▾ | Clear.
struct QuickViewBar: View {
    @Binding var filters: HistoryFilters
    let accounts: [Account]
    let categories: [ExpenseCategory]

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                FilterChip(title: "Debit", icon: "arrow.up.right", on: filters.kind == .expense) { toggleKind(.expense) }
                FilterChip(title: "Credit", icon: "arrow.down.left", on: filters.kind == .credit) { toggleKind(.credit) }
                if !accounts.isEmpty {
                    divider
                    ForEach(accounts) { a in
                        FilterChip(title: a.name, icon: a.symbol, on: filters.accountIds.contains(a.id)) { filters.toggleAccount(a.id) }
                    }
                }
                divider
                Menu {
                    ForEach(categories) { c in
                        Toggle("\(c.emoji) \(c.name)", isOn: $filters[category: c.id])
                    }
                    if !filters.categoryIds.isEmpty {
                        Divider()
                        Button("All categories", action: clearCategories)
                    }
                } label: {
                    FilterChipLabel(title: categoryLabel, icon: "square.grid.2x2", on: !filters.categoryIds.isEmpty, menu: true)
                }
                .accessibilityLabel("Categories filter")
                if filters.isActive {
                    Button("Clear", action: clearAll)
                        .font(.app(14, .semibold)).foregroundStyle(Theme.danger)
                        .padding(.horizontal, 6).frame(minHeight: 44)
                }
            }
            .padding(.horizontal, Theme.gutter)
        }
        .scrollIndicators(.hidden)
        .excludedFromPageSwipe()
    }

    private var divider: some View {
        Rectangle().fill(Theme.well).frame(width: 1, height: 20).accessibilityHidden(true)
    }

    private var categoryLabel: String {
        let picked = categories.filter { filters.categoryIds.contains($0.id) }
        if picked.isEmpty { return "Categories" }
        return picked.count == 1 ? "\(picked[0].emoji) \(picked[0].name)" : "\(picked.count) categories"
    }

    private func toggleKind(_ kind: TransactionKind) { filters.kind = filters.kind == kind ? nil : kind }
    private func clearCategories() { filters.categoryIds = [] }
    private func clearAll() { filters = HistoryFilters() }
}
