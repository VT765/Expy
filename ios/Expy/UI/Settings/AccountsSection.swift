import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Settings → Accounts: balances, add/edit/delete, statement import.
struct AccountsSection: View {
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Query(filter: #Predicate<Entry> { $0.deletedAt == nil }) private var entries: [Entry]
    @State private var editing: AccountTarget?
    @State private var importing = false


    var body: some View {
        SettingsSection(title: "Accounts", hint: "Balances update from your debits and credits.") {
            VStack(spacing: 0) {
                ForEach(accounts) { a in
                    Button { editing = .existing(a) } label: {
                        HStack(spacing: 14) {
                            Image(systemName: a.symbol).font(.app(17, .medium))
                                .frame(width: 36, height: 36)
                                .background(Circle().fill(Theme.raised))
                            Text(a.name).font(.app(16, .semibold)).lineLimit(1)
                            Spacer()
                            let bal = DataStore.balance(of: a, entries: entries)
                            Text(Fmt.money(bal)).font(.app(16, .semibold)).monospacedDigit()
                                .foregroundStyle(bal < 0 ? Theme.danger : .white)
                            Image(systemName: "chevron.right").font(.app(13, .semibold)).foregroundStyle(Theme.faint)
                        }
                        .padding(.horizontal, 16).frame(height: 60)
                        .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    Rectangle().fill(Theme.well).frame(height: 0.5).padding(.leading, 66)
                }
                Button { editing = .new } label: {
                    HStack(spacing: 14) {
                        Image(systemName: "plus").font(.app(17, .semibold)).frame(width: 36)
                        Text("Add account").font(.app(16, .semibold))
                        Spacer()
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 16).frame(height: 56)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .background(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.card))

            SettingsLinkRow(title: "Import bank statement", subtitle: "CSV or Excel (.xlsx) → entries in bulk", route: .importStatement)
        }
        .sheet(item: $editing) { AccountEditor(account: $0.account) }
    }
}
