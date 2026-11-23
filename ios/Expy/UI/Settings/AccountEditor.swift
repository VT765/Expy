import SwiftData
import SwiftUI
import UniformTypeIdentifiers

struct AccountEditor: View {
    let account: Account?
    @State private var name = ""
    @State private var kind = AccountKind.bank
    @State private var balance: Double?
    /// Overdrawn / borrowed: the number pad has no minus key, so sign is a toggle.
    @State private var negative = false
    @State private var asOf = Date.now
    @State private var confirmDelete = false
    @Environment(\.dismiss) private var dismiss


    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    Pills(options: [(AccountKind.bank, "Bank"), (.cash, "Cash")], selection: $kind)
                    TitledGroup(title: "Name") {
                        TextField(kind == .cash ? "Cash" : "e.g. HDFC Bank", text: $name).fieldStyle()
                    }
                    TitledGroup(title: "Current balance") {
                        HStack(spacing: 8) {
                            Text(negative ? "−₹" : "₹").font(.app(20, .bold)).foregroundStyle(negative ? Theme.danger : Theme.sub)
                            TextField("0", value: $balance, format: .number.precision(.fractionLength(0...2)))
                                .keyboardType(.decimalPad).font(.app(20, .bold))
                            Button(negative ? "Make balance positive" : "Make balance negative", systemImage: "plus.forwardslash.minus",
                                   action: toggleSign)
                                .labelStyle(.iconOnly)
                                .font(.app(16, .semibold))
                                .foregroundStyle(negative ? Theme.danger : Theme.sub)
                                .frame(width: 44, height: 44)
                        }
                        .padding(.horizontal, 16).frame(height: 52)
                        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Theme.raised))
                    }
                    TitledGroup(title: "Balance as of") {
                        DatePicker("", selection: $asOf, in: ...Date.now).labelsHidden().tint(.white)
                    }
                    Text("Entries on this account dated after this moment adjust the balance. Older entries, like a past statement you import, don't change it.")
                        .font(.tFootnote).foregroundStyle(Theme.sub)
                    if account != nil {
                        Button("Delete account", role: .destructive) { confirmDelete = true }
                            .font(.tBodySemibold).foregroundStyle(Theme.danger).padding(.top, 8)
                    }
                }
                .padding(Theme.gutter)
            }
            .safeAreaInset(edge: .bottom) {
                PrimaryButton(title: account == nil ? "Add account" : "Save") {
                    let opening = (negative ? -1 : 1) * (balance ?? 0)
                    DataStore.shared.saveAccount(id: account?.id, name: name.trimmingCharacters(in: .whitespaces),
                                                 kind: kind, openingBalance: opening, openingDate: asOf)
                    Haptics.success()
                    dismiss()
                }
                .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, Theme.gutter).padding(.bottom, 8)
            }
            .navigationTitle(account == nil ? "New account" : "Edit account")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.tint(Theme.sub) } }
            .alert("Delete \(account?.name ?? "account")?", isPresented: $confirmDelete) {
                Button("Delete", role: .destructive) {
                    if let account { DataStore.shared.deleteAccount(account) }
                    dismiss()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Its entries stay in History but won't be linked to an account.")
            }
        }
        .presentationBackground(Theme.card)
        .onAppear(perform: load)
        .onChange(of: kind) { _, k in if k == .cash && name.isEmpty { name = "Cash" } }
    }

    private func toggleSign() {
        Haptics.selection()
        negative.toggle()
    }

    /// Editing shows today's computed balance; saving re-anchors it to now.
    private func load() {
        guard let a = account else { return }
        let entries = DataStore.shared.fetch(Entry.self, #Predicate { $0.deletedAt == nil })
        name = a.name
        kind = a.kind
        let current = DataStore.balance(of: a, entries: entries)
        negative = current < 0
        balance = current == 0 ? nil : abs(current)
        asOf = .now
    }
}
