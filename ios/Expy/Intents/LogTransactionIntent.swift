import AppIntents
import SwiftData

/// Shortcut flow: Credit/Debit → Amount → Account → Category → Note.
/// Each missing value is asked for explicitly, in this order.
struct LogTransactionIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Transaction"
    static var description = IntentDescription("Log a debit or credit to Expy: amount, account, category and an optional note.")
    static var openAppWhenRun = false

    @Parameter(title: "Type") var kind: EntryKind?
    @Parameter(title: "Amount") var amount: Double?
    @Parameter(title: "Account") var account: AccountEntity?
    @Parameter(title: "Category") var category: CategoryEntity?
    @Parameter(title: "Note") var note: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Log \(\.$kind) of \(\.$amount) from \(\.$account) in \(\.$category)") { \.$note }
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        var kind = self.kind
        if kind == nil { kind = try await $kind.requestDisambiguation(among: [.debit, .credit], dialog: "Credit or debit?") }
        let isCredit = kind == .credit

        var amount = self.amount
        if amount == nil { amount = try await $amount.requestValue(isCredit ? "How much came in?" : "How much did you spend?") }
        guard let amount, amount > 0 else { throw IntentError.invalidAmount }

        var account = self.account
        if account == nil {
            let accounts = try await AccountQuery().suggestedEntities()
            account = accounts.count <= 1
                ? accounts.first
                : try await $account.requestDisambiguation(among: accounts, dialog: isCredit ? "Credited to?" : "Debited from?")
        }

        var category = self.category
        if category == nil {
            let categories = CategoryQuery().entities(for: isCredit ? .credit : .expense)
            category = try await $category.requestDisambiguation(among: categories, dialog: "Choose a category")
        }
        guard let category else { throw IntentError.invalidAmount }

        var note = self.note ?? ""
        if self.note == nil {
            let typed = try await $note.requestValue("Add a note (type - to skip)")
            note = ["-", ".", "skip", "no"].contains(typed.trimmingCharacters(in: .whitespaces).lowercased()) ? "" : typed
        }

        let store = DataStore.shared
        let e = store.addEntry(kind: isCredit ? .credit : .expense, amount: amount, categoryId: category.id,
                               note: note, date: Date.now, accountId: account?.id)
        var text = "Saved \(isCredit ? "+" : "")\(Fmt.money(e.amount)) · \(category.name)"
        if let a = account.flatMap({ store.account($0.id) }) {
            let entries = store.fetch(Entry.self, #Predicate { $0.deletedAt == nil })
            text += " · \(a.name) \(Fmt.money(DataStore.balance(of: a, entries: entries)))"
        }
        return .result(value: text, dialog: "\(text)")
    }
}
