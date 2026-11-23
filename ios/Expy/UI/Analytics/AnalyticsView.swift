import SwiftData
import SwiftUI

/// Week / Month / Year / Custom with ‹ › navigation, balances, stat tiles,
/// budgets, bar chart, recap, greyscale donut, breakdown, top 5, export.
struct AnalyticsView: View {
    @Query(filter: #Predicate<Entry> { $0.deletedAt == nil }) private var entries: [Entry]
    @Query private var allCategories: [ExpenseCategory]
    @Query(filter: #Predicate<Budget> { $0.deletedAt == nil }) private var budgets: [Budget]
    @Query private var settingsList: [AppSettings]
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Environment(\.appRouter) private var router

    @State private var model = AnalyticsModel()
    @State private var kind: PeriodKind = .month
    @State private var offset = 0
    @State private var customFrom = Calendar.current.date(byAdding: .day, value: -29, to: .now) ?? .now
    @State private var customTo = Date.now
    @State private var selectedBar: Date?

    private var categories: [String: ExpenseCategory] { Dictionary(allCategories.map { ($0.id, $0) }, uniquingKeysWith: { a, _ in a }) }

    private var key: AnalyticsModel.Key {
        AnalyticsModel.Key(kind: kind, offset: offset, from: customFrom, to: customTo, cycleDay: settingsList.first?.cycleStartDay ?? 1,
                           entryCount: entries.count, entryStamp: entries.map(\.updatedAt).max() ?? .distantPast,
                           budgetStamp: budgets.map(\.updatedAt).max() ?? .distantPast,
                           accountStamp: accounts.map(\.updatedAt).max() ?? .distantPast)
    }

    var body: some View {
        let snap = model.snapshot(entries: entries, budgets: budgets, accounts: accounts, key: key)
        let cats = categories
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Analytics").font(.tTitle).frame(maxWidth: .infinity).frame(height: 56).accessibilityAddTraits(.isHeader)
                ScrollView(.horizontal) {
                    Pills(options: [(PeriodKind.week, "Week"), (.month, "Month"), (.year, "Year"), (.custom, "Custom")], selection: $kind)
                }
                .scrollIndicators(.hidden)
                if !accounts.isEmpty {
                    AccountBalancesStrip(accounts: accounts, balances: snap.balances).padding(.top, 16)
                }
                PeriodSelector(kind: kind, label: snap.range.label, offset: $offset, from: $customFrom, to: $customTo,
                               onChange: clearSelection)
                    .padding(.top, 16)
                StatGrid(stats: snap.stats, previous: snap.previous).padding(.top, 20)
                if let budget = snap.budget, budget.total != nil || !budget.categories.isEmpty {
                    AnalyticsCard(title: "Budget") {
                        BudgetCard(total: budget.total, categoryLines: budget.categories, daysLeft: budget.daysLeft,
                                   categories: cats)
                    }
                }
                if snap.stats.count == 0 {
                    ContentUnavailableView("No data for this period", systemImage: "chart.bar",
                                           description: Text("Entries you log will show up here."))
                        .padding(.vertical, 24)
                } else {
                    PeriodDetails(snap: snap, categories: cats, kind: kind,
                                  selectedBar: $selectedBar)
                }
                if kind == .month && offset == 0 && snap.budget?.total == nil {
                    Button("Set a monthly budget in Settings ›", action: openSettings)
                        .font(.tFootnote).foregroundStyle(Theme.sub)
                        .frame(maxWidth: .infinity, minHeight: 44).padding(.top, 16)
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 32)
        }
        .scrollContentBackground(.visible)
        .background(Theme.canvas)
        .onChange(of: kind) { _, _ in kindChanged() }
        #if DEBUG
        .defaultScrollAnchor(UnitPoint(x: 0.5, y: Demo.value("-demoAnchor").flatMap(Double.init) ?? (Demo.value("-demoAnchor") == "mid" ? 0.55 : 0)))
        .onAppear { applyDemoState(snap) }
        #endif
    }

    private func clearSelection() {
        selectedBar = nil
    }

    private func kindChanged() {
        offset = 0
        clearSelection()
    }

    private func openSettings() { router?.showSettings() }

    #if DEBUG
    private func applyDemoState(_ snap: AnalyticsModel.Snapshot) {
        guard Demo.has("-demoSelect") else { return }
        selectedBar = Calendar.current.date(byAdding: .day, value: -1, to: .now)
    }
    #endif
}
