import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// iOS grouped settings in the reference style: grey uppercase section labels,
/// each row its own card, title left, grey value + › right.
struct SettingsView: View {
    @Query private var settingsList: [AppSettings]
    @Query(filter: #Predicate<Budget> { $0.deletedAt == nil }) private var budgets: [Budget]
    @Environment(\.dismiss) private var dismiss
    @State private var session = Session.shared
    @State private var lock = LockManager.shared
    @State private var sync = SyncEngine.shared

    @State private var sheet: SheetKind?
    @State private var confirm: ConfirmKind?
    @State private var shareURL: ShareItem?
    @State private var importing = false
    @State private var pendingRestore: BackupFile?
    @State private var busy: ExportKind?

    enum SheetKind: String, Identifiable {
        case baseCurrency, monthlyBudget, cycle, exportXlsx, exportCsv, changePassword, pinCreate, pinChange, pinVerifyDisable, server
        var id: String { rawValue }
    }

    enum ConfirmKind: String, Identifiable {
        case signOut, erase1, erase2, restore
        var id: String { rawValue }
    }

    private var settings: AppSettings? { settingsList.first }
    private var base: String { settings?.baseCurrency ?? "INR" }
    private var total: Budget? { budgets.first { $0.id == "budget_total" } }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    account
                    security
                    SettingsSection(title: "Quick Logging", hint: "Log from Siri, Back Tap, the Action button or a widget without opening Expy.") {
                        SettingsRow(title: "Shortcuts actions", subtitle: "“Log Expense” and “Log Credit” are ready in the Shortcuts app.", value: nil, chevron: false)
                        SettingsRow(title: "Open Shortcuts app") {
                            if let url = URL(string: "shortcuts://") { UIApplication.shared.open(url) }
                        }
                    }
                    SettingsSection(title: "Currency") {
                        SettingsRow(title: "Currency", value: "\(Currencies.symbol(base)) \(Currencies.info(base).name)") { sheet = .baseCurrency }
                        NavigationLink { ExchangeRatesView() } label: {
                            SettingsRow(title: "Exchange rates", subtitle: "Live rates with manual overrides", chevron: true, action: nil) {
                                Image(systemName: "chevron.right").font(.system(size: 15, weight: .semibold)).foregroundStyle(Theme.sub)
                            }
                        }
                        .buttonStyle(RowPressStyle())
                    }
                    SettingsSection(title: "Budget") {
                        SettingsRow(title: "Monthly Budget", value: total.map { Fmt.money($0.amount, base) } ?? "Not set") { sheet = .monthlyBudget }
                        NavigationLink { CategoryBudgetsView() } label: {
                            SettingsRow(title: "Category budgets", value: nil, chevron: false, action: nil) {
                                let n = budgets.filter { $0.categoryId != nil && $0.amount > 0 }.count
                                Text(n > 0 ? "\(n) set ›" : "None ›").font(.tBody).foregroundStyle(Theme.sub)
                            }
                        }
                        .buttonStyle(RowPressStyle())
                        SettingsRow(title: "Cycle starts on", subtitle: "Budget and monthly totals reset on this day",
                                    value: Fmt.ordinal(settings?.cycleStartDay ?? 1)) { sheet = .cycle }
                    }
                    CategoriesSection()
                    data
                    syncSection
                    Text("Expy · everything unlocked").font(.tFootnote).foregroundStyle(Theme.faint)
                        .frame(maxWidth: .infinity).padding(.vertical, 36)
                }
                .padding(.horizontal, Theme.gutter)
            }
            .background(Theme.canvas)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "chevron.left").font(.system(size: 18, weight: .semibold)) }
                        .tint(.white)
                        .accessibilityLabel("Close settings")
                }
                ToolbarItem(placement: .principal) { Text("Settings").font(.tTitle) }
            }
            .toolbarBackground(Theme.canvas, for: .navigationBar)
        }
        .sheet(item: $sheet, content: sheetView)
        .sheet(item: $shareURL) { ShareSheet(items: [$0.url]) }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.json]) { result in
            do {
                pendingRestore = try Exporter.readBackup(try result.get())
                confirm = .restore
            } catch { ToastCenter.shared.error(error.localizedDescription) }
        }
        .alert(item: $confirm, content: alert)
    }

    // MARK: - Sections

    @ViewBuilder private var account: some View {
        SettingsSection(title: "Account") {
            if session.isSignedIn {
                SettingsRow(title: "Change password") { sheet = .changePassword }
                SettingsRow(title: "Sign out", subtitle: "Removes data from this device after syncing", destructive: true, chevron: false) { confirm = .signOut }
            } else {
                SettingsRow(title: "Sign in to sync", subtitle: "Back up to your server and sync with the web app") {
                    session.offlineMode = false
                    dismiss()
                }
            }
            SettingsRow(title: "Server", value: URL(string: APIClient.shared.serverURL)?.host ?? "—") { sheet = .server }
        }
    }

    @ViewBuilder private var security: some View {
        SettingsSection(title: "Security") {
            SettingsRow(title: "App Lock", subtitle: "Require a PIN to open Expy", chevron: false, action: nil) {
                Toggle("", isOn: Binding(get: { lock.enabled }, set: { sheet = $0 ? .pinCreate : .pinVerifyDisable }))
                    .labelsHidden().tint(.white)
            }
            if lock.enabled {
                SettingsRow(title: "Change PIN") { sheet = .pinChange }
                if lock.biometryAvailable {
                    SettingsRow(title: lock.biometryName, subtitle: "Unlock with \(lock.biometryName), PIN as fallback", chevron: false, action: nil) {
                        Toggle("", isOn: Binding(get: { lock.faceIdEnabled }, set: { on in Task { _ = await lock.setFaceId(on) } }))
                            .labelsHidden().tint(.white)
                    }
                }
                Menu {
                    Picker("Auto-lock", selection: $lock.autoLock) {
                        ForEach(LockManager.AutoLock.allCases) { Text($0.label).tag($0) }
                    }
                } label: {
                    SettingsRow(title: "Auto-lock", value: lock.autoLock.label, chevron: false, action: nil) { EmptyView() }
                }
            }
        }
    }

    @ViewBuilder private var data: some View {
        SettingsSection(title: "Data") {
            SettingsRow(title: "Export to Excel", value: busy == .xlsx ? "Preparing…" : nil) { sheet = .exportXlsx }
            SettingsRow(title: "Export CSV", value: busy == .csv ? "Preparing…" : nil) { sheet = .exportCsv }
            SettingsRow(title: "Back up (JSON)", subtitle: "Everything, for restoring later") { runExport(.backup, range: .allTime) }
            SettingsRow(title: "Restore from backup") { importing = true }
            SettingsRow(title: "Erase all data", destructive: true, chevron: false) { confirm = .erase1 }
        }
    }

    @ViewBuilder private var syncSection: some View {
        SettingsSection(title: "Sync status") {
            if session.isSignedIn {
                SettingsRow(title: "Status", subtitle: sync.state == .error ? sync.lastError : nil, value: sync.label, chevron: false)
                SettingsRow(title: "Last synced", value: sync.lastSyncedAt.map { $0.formatted(.relative(presentation: .named)) } ?? "Never", chevron: false)
                SettingsRow(title: "Sync now") { sync.sync() }
            } else {
                SettingsRow(title: "Local only", subtitle: "Data lives on this device. Sign in above to sync.", chevron: false)
            }
        }
    }

    // MARK: - Sheets & alerts

    @ViewBuilder private func sheetView(_ kind: SheetKind) -> some View {
        switch kind {
        case .baseCurrency:
            CurrencyPicker(selected: base) { code in
                sheet = nil
                changeBase(to: code)
            }
        case .monthlyBudget:
            AmountSheet(title: "Monthly budget", hint: "Spending across all categories per cycle.", currency: base, value: total?.amount ?? 0) {
                DataStore.shared.setBudget(categoryId: nil, amount: $0)
            }
        case .cycle:
            OptionList(title: "Cycle starts on", options: (1...28).map { ($0, "\(Fmt.ordinal($0)) of the month") }, selected: settings?.cycleStartDay ?? 1) { d in
                DataStore.shared.updateSettings { $0.cycleStartDay = d }
            }
        case .exportXlsx, .exportCsv:
            let k: ExportKind = kind == .exportXlsx ? .xlsx : .csv
            let current = Periods.range(.month, cycleDay: settings?.cycleStartDay ?? 1)
            OptionList(title: kind == .exportXlsx ? "Export to Excel" : "Export CSV",
                       options: [(0, "Current cycle · \(current.label)"), (1, "All time")], selected: -1) { choice in
                runExport(k, range: choice == 0 ? current : .allTime)
            }
        case .changePassword: ChangePasswordView()
        case .pinCreate: PinSetupView(mode: .create)
        case .pinChange: PinSetupView(mode: .change)
        case .pinVerifyDisable: PinSetupView(mode: .verify) { LockManager.shared.disable() }
        case .server: ServerSheet()
        }
    }

    private func alert(_ kind: ConfirmKind) -> Alert {
        switch kind {
        case .signOut:
            return Alert(title: Text("Sign out?"), message: Text("Pending changes sync first, then this device is cleared. Sign in again to get your data back."),
                         primaryButton: .destructive(Text("Sign out")) {
                             Task {
                                 if await session.signOutFlushing() {
                                     ToastCenter.shared.show("Signed out")
                                     dismiss()
                                 } else {
                                     ToastCenter.shared.error("Couldn't sync \(sync.pendingCount) change(s). Try again when online.")
                                 }
                             }
                         },
                         secondaryButton: .cancel())
        case .erase1:
            return Alert(title: Text("Erase all data?"), message: Text("Every entry, budget and custom category will be deleted on all your devices."),
                         primaryButton: .destructive(Text("Erase")) {
                             DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { confirm = .erase2 }
                         },
                         secondaryButton: .cancel())
        case .erase2:
            return Alert(title: Text("Are you absolutely sure?"), message: Text("This cannot be undone. Consider exporting a backup first."),
                         primaryButton: .destructive(Text("Erase everything")) {
                             DataStore.shared.eraseAll()
                             ToastCenter.shared.show("All data erased")
                         },
                         secondaryButton: .cancel())
        case .restore:
            let n = pendingRestore?.transactions.count ?? 0
            return Alert(title: Text("Restore \(n) entries?"), message: Text("Entries and categories from the backup will be added. Matching entries are overwritten."),
                         primaryButton: .default(Text("Restore")) {
                             if let b = pendingRestore { DataStore.shared.importBackup(b); ToastCenter.shared.show("Backup restored") }
                             pendingRestore = nil
                         },
                         secondaryButton: .cancel { pendingRestore = nil })
        }
    }

    // MARK: - Actions

    private func runExport(_ kind: ExportKind, range: DateRange) {
        busy = kind
        Task {
            defer { busy = nil }
            // Let the option sheet finish dismissing before presenting the share sheet.
            try? await Task.sleep(for: .milliseconds(350))
            do { shareURL = ShareItem(url: try Exporter.export(kind, range: range)) }
            catch { ToastCenter.shared.error(error.localizedDescription) }
        }
    }

    private func changeBase(to code: String) {
        guard code != base else { return }
        let previous = base
        Task {
            do {
                try await RatesService.shared.refresh(base: code, force: true)
                DataStore.shared.updateSettings { $0.baseCurrency = code; $0.rateOverrides = [:] }
                DataStore.shared.rebaseEntries()
                ToastCenter.shared.show("Base currency is now \(code)")
            } catch {
                DataStore.shared.updateSettings { $0.baseCurrency = previous }
                ToastCenter.shared.error("Connect to the internet to change base currency")
            }
        }
    }
}

// MARK: - Reusable sheets

/// Single-amount editor (budgets, rate overrides).
struct AmountSheet: View {
    let title: String
    var hint: String?
    let currency: String
    let value: Double
    var removeLabel = "Remove"
    var onSave: (Double) -> Void
    @State private var text = ""
    @FocusState private var focused: Bool
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 16) {
            Text(title).font(.tHeadline).padding(.top, 20)
            if let hint { Text(hint).font(.tFootnote).foregroundStyle(Theme.sub).multilineTextAlignment(.center) }
            HStack(spacing: 8) {
                Text(Currencies.symbol(currency)).font(.system(size: 34, weight: .bold)).foregroundStyle(Theme.sub)
                TextField("0", text: $text)
                    .keyboardType(.decimalPad)
                    .focused($focused)
                    .font(.system(size: 40, weight: .bold))
                    .fixedSize()
            }
            .padding(.vertical, 12)
            Spacer()
            HStack(spacing: 12) {
                if value > 0 {
                    PrimaryButton(title: removeLabel, role: .destructive) { onSave(0); dismiss() }.frame(width: 130)
                }
                PrimaryButton(title: "Save") {
                    onSave(((Double(text) ?? 0) * 100).rounded() / 100)
                    dismiss()
                }
                .disabled((Double(text) ?? 0) <= 0)
            }
        }
        .padding(.horizontal, Theme.gutter).padding(.bottom, 12)
        .presentationDetents([.medium])
        .presentationBackground(Theme.card)
        .onAppear {
            text = value > 0 ? TapView.trimmed(value) : ""
            focused = true
        }
    }
}

/// Single-choice list in a sheet.
struct OptionList<T: Hashable>: View {
    let title: String
    let options: [(T, String)]
    let selected: T
    var onSelect: (T) -> Void
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List(options.indices, id: \.self) { i in
                let (value, label) = options[i]
                Button {
                    onSelect(value)
                    dismiss()
                } label: {
                    HStack {
                        Text(label).foregroundStyle(.white)
                        Spacer()
                        if value == selected { Image(systemName: "checkmark").foregroundStyle(.white) }
                    }
                }
                .listRowBackground(Theme.raised)
            }
            .scrollContentBackground(.hidden)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
        .presentationBackground(Theme.card)
    }
}

struct ServerSheet: View {
    @State private var url = APIClient.shared.serverURL
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Server").font(.tHeadline).frame(maxWidth: .infinity).padding(.top, 20)
            Text("Your Expy backend (the Vercel deployment).").font(.tFootnote).foregroundStyle(Theme.sub)
            TextField("https://…", text: $url)
                .keyboardType(.URL).textInputAutocapitalization(.never).autocorrectionDisabled()
                .fieldStyle()
            Spacer()
            PrimaryButton(title: "Save") {
                APIClient.shared.serverURL = url
                dismiss()
            }
            .disabled(URL(string: url)?.scheme?.hasPrefix("http") != true)
        }
        .padding(.horizontal, Theme.gutter).padding(.bottom, 12)
        .presentationDetents([.medium])
        .presentationBackground(Theme.card)
    }
}

struct ChangePasswordView: View {
    @State private var current = ""
    @State private var next = ""
    @State private var confirm = ""
    @State private var error = ""
    @State private var busy = false
    @Environment(\.dismiss) private var dismiss

    private struct Payload: Encodable { let current: String; let next: String }
    private struct Reply: Decodable { let token: String }

    var body: some View {
        VStack(spacing: 12) {
            Text("Change password").font(.tHeadline).padding(.top, 20).padding(.bottom, 8)
            NumericSecureField(placeholder: "Current password", text: $current)
            NumericSecureField(placeholder: "New password (8+ digits)", text: $next)
            NumericSecureField(placeholder: "Confirm new password", text: $confirm)
            Text(error).font(.tFootnote).foregroundStyle(Theme.danger).frame(maxWidth: .infinity, alignment: .leading)
            Spacer()
            PrimaryButton(title: "Update password", isLoading: busy) {
                guard next == confirm else { error = "New passwords don't match"; return }
                busy = true
                Task {
                    defer { busy = false }
                    do {
                        let r: Reply = try await APIClient.shared.request("auth/password", method: "POST", body: Payload(current: current, next: next))
                        APIClient.shared.token = r.token
                        ToastCenter.shared.show("Password changed · other devices signed out")
                        dismiss()
                    } catch { self.error = error.localizedDescription }
                }
            }
            .disabled(current.isEmpty || next.count < 8)
        }
        .padding(.horizontal, Theme.gutter).padding(.bottom, 12)
        .presentationDetents([.large])
        .presentationBackground(Theme.card)
    }
}

/// Secure field that opens the number pad and keeps digits only.
struct NumericSecureField: View {
    let placeholder: String
    @Binding var text: String
    var body: some View {
        SecureField(placeholder, text: Binding(get: { text }, set: { text = $0.filter(\.isNumber) }))
            .keyboardType(.numberPad)
            .textContentType(.password)
            .font(.tBody)
            .padding(.horizontal, 16).frame(height: 56)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Theme.raised))
    }
}
