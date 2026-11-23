import SwiftUI

/// iOS grouped settings in the reference style: grey uppercase section labels,
/// each row its own card, title left, grey value + › right. Lives in its own tab.
struct SettingsView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    SettingsSection(title: "Quick Launch", hint: "Log expenses from Siri, the Action button, Back Tap or a widget without opening Expy.") {
                        SettingsLinkRow(title: "Quick Launch setup", subtitle: "Siri, Shortcuts, Action button, Back Tap, widgets", route: .quickLaunch)
                        SettingsLinkRow(title: "Bank SMS & email", subtitle: "Suggest entries from bank messages", route: .bankMessages)
                    }
                    AccountsSection()
                    RecurringSection()
                    SecuritySettingsSection()
                    BudgetSettingsSection()
                    CategoriesSection()
                    DataSettingsSection()
                    Text("Expy \(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "") · data stays on this iPhone")
                        .font(.tFootnote).foregroundStyle(Theme.faint)
                        .frame(maxWidth: .infinity).padding(.vertical, 36)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .background(Theme.canvas)
            #if DEBUG
            .defaultScrollAnchor(Demo.value("-demoAnchor") == "mid" ? UnitPoint(x: 0.5, y: 0.3) : .top)
            #endif
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: SettingsRoute.self, destination: destination)
            .toolbar {
                ToolbarItem(placement: .principal) { Text("Settings").font(.tTitle) }
            }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
        }
    }

    @ViewBuilder private func destination(_ route: SettingsRoute) -> some View {
        switch route {
        case .quickLaunch: QuickLaunchView()
        case .bankMessages: BankMessagesView()
        case .categoryBudgets: CategoryBudgetsView()
        case .importStatement: StatementImportView()
        }
    }
}
