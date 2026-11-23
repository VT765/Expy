import SwiftData
import SwiftUI
import UniformTypeIdentifiers

/// Pick account → choose CSV/XLSX → review rows (categories guessed,
/// duplicates unticked) → import.
struct StatementImportView: View {
    @Query(filter: #Predicate<Account> { $0.deletedAt == nil }, sort: \Account.order) private var accounts: [Account]
    @Query(filter: #Predicate<ExpenseCategory> { $0.deletedAt == nil }, sort: \ExpenseCategory.order) private var categories: [ExpenseCategory]
    @Environment(\.dismiss) private var dismiss

    @State private var accountId: String?
    @State private var picking = false
    @State private var fileName: String?
    @State private var rows: [ReviewRow] = []
    @State private var error: String?

    struct ReviewRow: Identifiable {
        let id = UUID()
        let source: StatementRow
        var include: Bool
        var categoryId: String
        let duplicate: Bool
    }

    private var selected: [ReviewRow] { rows.filter(\.include) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                SettingsSection(title: "1 · Account") {
                    if accounts.isEmpty {
                        Text("Add a bank account in Settings → Accounts first.").font(.tBody).foregroundStyle(Theme.sub)
                    } else {
                        ScrollView(.horizontal) {
                            Pills(options: accounts.map { (Optional($0.id), $0.name) }, selection: $accountId)
                        }
                        .scrollIndicators(.hidden)
                    }
                }

                SettingsSection(title: "2 · Statement file", hint: "Download it from your bank's net banking as CSV or Excel (.xlsx).") {
                    SettingsRow(title: fileName ?? "Choose file", subtitle: fileName == nil ? "From Files, iCloud Drive or Downloads" : "\(rows.count) transactions found",
                                value: nil, action: { picking = true })
                    if let error { Text(error).font(.tFootnote).foregroundStyle(Theme.danger) }
                }

                if !rows.isEmpty {
                    SettingsSection(title: "3 · Review", hint: "Tap a category to change it. Likely duplicates are unticked.") {
                        HStack {
                            Button("Select all") { setAll(true) }
                            Spacer()
                            Button("Select none") { setAll(false) }
                        }
                        .font(.tFootnote).foregroundStyle(Theme.sub).padding(.bottom, 4)
                        LazyVStack(spacing: 0) {
                            ForEach($rows) { $row in StatementReviewRow(row: $row, categories: categories.filter { $0.isCredit == row.source.isCredit }) }
                        }
                        .background(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous).fill(Theme.card))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cardRadius, style: .continuous))
                    }
                }
            }
            .padding(.horizontal, Theme.gutter)
            .padding(.bottom, 120)
        }
        .background(Theme.canvas)
        .safeAreaInset(edge: .bottom) {
            if !rows.isEmpty {
                let debit = selected.filter { !$0.source.isCredit }.map(\.source.amount).reduce(0, +)
                let credit = selected.filter(\.source.isCredit).map(\.source.amount).reduce(0, +)
                VStack(spacing: 8) {
                    Text("\(selected.count) entries · −\(Fmt.money(debit)) · +\(Fmt.money(credit))")
                        .font(.tFootnote).foregroundStyle(Theme.sub)
                    PrimaryButton(title: "Import \(selected.count) entries", action: importRows)
                        .disabled(selected.isEmpty || accountId == nil)
                }
                .padding(.horizontal, Theme.gutter).padding(.vertical, 10)
                .background(Theme.canvas)
            }
        }
        .navigationTitle("Import statement")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { if accountId == nil { accountId = accounts.first { !$0.isCash }?.id ?? accounts.first?.id } }
        .fileImporter(isPresented: $picking, allowedContentTypes: [.commaSeparatedText, .tabSeparatedText, .plainText, .spreadsheet,
                                                                    UTType(filenameExtension: "xlsx") ?? .data, UTType(filenameExtension: "xls") ?? .data]) { result in
            load(result)
        }
    }

    private func setAll(_ on: Bool) { for i in rows.indices { rows[i].include = on } }

    private func load(_ result: Result<URL, Error>) {
        error = nil
        do {
            let url = try result.get()
            let parsed = try StatementParser.parse(url)
            let store = DataStore.shared
            let existing = store.fetch(Entry.self, #Predicate { $0.deletedAt == nil })
            // Past entries teach categories: note → most recent category.
            var history: [String: String] = [:]
            for e in existing.sorted(by: { $0.date < $1.date }) where !e.note.isEmpty { history[e.note.lowercased()] = e.categoryId }
            let validDebit = Set(categories.filter { !$0.isCredit }.map(\.id))
            let validCredit = Set(categories.filter(\.isCredit).map(\.id))
            let cal = Calendar.current
            let keys = Set(existing.map { "\(cal.startOfDay(for: $0.date).timeIntervalSince1970)|\($0.amountPaise)|\($0.kindRaw)" })
            rows = parsed.map { s in
                let key = "\(cal.startOfDay(for: s.date).timeIntervalSince1970)|\(Money.paise(s.amount))|\(s.isCredit ? TransactionKind.credit.rawValue : TransactionKind.expense.rawValue)"
                let dup = keys.contains(key)
                return ReviewRow(source: s, include: !dup,
                                 categoryId: CategoryGuesser.guess(s.narration, kind: s.isCredit ? .credit : .expense, history: history,
                                                                   valid: s.isCredit ? validCredit : validDebit), duplicate: dup)
            }
            .sorted { $0.source.date > $1.source.date }
            fileName = url.lastPathComponent
        } catch {
            rows = []
            fileName = nil
            self.error = error.localizedDescription
        }
    }

    private func importRows() {
        guard let accountId else { return }
        let items = selected.map { r in
            (kind: r.source.isCredit ? TransactionKind.credit : .expense, amount: r.source.amount, date: r.source.date,
             note: r.source.narration, categoryId: r.categoryId)
        }
        DataStore.shared.importEntries(items, accountId: accountId)
        Haptics.success()
        ToastCenter.shared.show("Imported \(items.count) entries")
        dismiss()
    }
}
