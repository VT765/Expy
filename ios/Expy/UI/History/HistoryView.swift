import SwiftData
import SwiftUI

/// "Expenses": quick view chips (debit / credit / account / category),
/// summary strip, grouped by day or by category, swipe actions, tap to edit.
struct HistoryView: View {
    @Query(filter: #Predicate<Entry> { $0.deletedAt == nil }, sort: \Entry.date, order: .reverse)
    private var entries: [Entry]
    @Query private var allCategories: [ExpenseCategory]
    @Query private var settingsList: [AppSettings]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]

    @AppStorage("historyRange") private var range = PeriodKind.month.rawValue
    @AppStorage("historyGrouping") private var grouping = "day" // day | category
    @State private var model = HistoryModel()
    @State private var filters = HistoryFilters()
    @State private var showFilters = false
    @State private var editing: Entry?
    @State private var searching = false
    @State private var inbox = ReviewInbox.shared
    @State private var reviewing = false

    private var categoryById: [String: ExpenseCategory] { Dictionary(allCategories.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }
    private var accountNames: [String: String] { Dictionary(accounts.map { ($0.id, $0.name) }, uniquingKeysWith: { a, _ in a }) }

    var body: some View {
        let categories = categoryById
        let key = HistoryModel.key(range: range, cycleDay: settingsList.first?.cycleStartDay ?? 1, grouping: grouping,
                                   filters: filters, entries: entries, categories: allCategories)
        let res = model.result(entries: entries, categories: categories, key: key)
        let names = accountNames
        VStack(spacing: 0) {
            HistoryHeader(searching: $searching, filtersActive: filters.isActive, showFilters: openFilters, endSearch: endSearch)
            if searching {
                HistorySearchField(query: $filters.query)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
            ScrollView(.horizontal) {
                Pills(options: [("today", "Today"), ("week", "This Week"), ("month", "This Month"), ("all", "All")], selection: $range)
                    .padding(.horizontal, Theme.gutter)
            }
            .scrollIndicators(.hidden)
            QuickViewBar(filters: $filters, accounts: accounts,
                         categories: allCategories.filter { $0.deletedAt == nil }.sorted { $0.order < $1.order })
                .padding(.top, 10)
            if inbox.count > 0 {
                ReviewBanner(count: inbox.count, action: openReview)
                    .padding(.horizontal, Theme.gutter).padding(.top, 12)
            }
            HistorySummaryCard(spent: res.spent, received: res.received, grouping: $grouping)
                .padding(.horizontal, Theme.gutter).padding(.top, 12)

            if res.count == 0 {
                HistoryEmptyState(filtering: filters.isActive, clear: clearFilters)
            } else {
                List {
                    ForEach(res.sections) { section in
                        Section {
                            ForEach(section.items) { e in
                                HistoryListRow(entry: e, category: categories[e.categoryId] ?? categories[Defaults.otherCategoryId],
                                               accountName: e.accountId.flatMap { names[$0] },
                                               toAccountName: e.toAccountId.flatMap { names[$0] }, accounts: accounts,
                                               byCategory: grouping == "category") { editing = e }
                            }
                        } header: {
                            HistorySectionHeader(title: section.title, count: section.items.count, total: section.total,
                                                 share: res.spent > 0 ? section.total / res.spent : 0,
                                                 colorHex: categories[section.id]?.colorHex, byCategory: grouping == "category")
                        }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .environment(\.defaultMinListHeaderHeight, 1)
                .contentMargins(.top, 0, for: .scrollContent)
                .listSectionSpacing(0)
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if res.count > 0 { HistoryTotalBar(spent: res.spent, received: res.received) }
        }
        .background(Theme.canvas)
        .animation(.easeOut(duration: 0.2), value: filters)
        .animation(.easeOut(duration: 0.2), value: grouping)
        .sheet(isPresented: $showFilters) { FilterSheet(filters: $filters) }
        .sheet(item: $editing) { EditEntrySheet(entry: $0) }
        .sheet(isPresented: $reviewing) { ReviewInboxView() }
        .onReceive(NotificationCenter.default.publisher(for: .openReviewInbox)) { _ in openReview() }
        #if DEBUG
        .onAppear(perform: applyDemoState)
        #endif
    }

    private func openReview() { reviewing = true }
    private func openFilters() { showFilters = true }

    private func endSearch() { filters.query = "" }

    private func clearFilters() {
        withAnimation {
            filters = HistoryFilters()
            searching = false
        }
    }

    #if DEBUG
    private func applyDemoState() {
        if let q = Demo.value("-demoSearch") { searching = true; filters.query = q }
        if let g = Demo.value("-demoGroup") { grouping = g }
    }
    #endif
}
