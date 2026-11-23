import AppIntents
import SwiftData

/// Categories exposed to Shortcuts/Siri ("Choose from List" is built in).
struct CategoryEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Category"
    static var defaultQuery = CategoryQuery()
    let id: String
    let name: String
    let emoji: String
    var displayRepresentation: DisplayRepresentation { DisplayRepresentation(title: "\(emoji) \(name)") }
}

struct CategoryQuery: EntityQuery {
    @MainActor
    func entities(for identifiers: [String]) async throws -> [CategoryEntity] {
        DataStore.shared.activeCategories.filter { identifiers.contains($0.id) }.map { .init(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }

    @MainActor
    func suggestedEntities() async throws -> [CategoryEntity] {
        DataStore.shared.activeCategories.map { .init(id: $0.id, name: $0.name, emoji: $0.emoji) }
    }
}

@MainActor
private func logEntry(type: String, amount: Double, category: CategoryEntity?, note: String?) throws -> String {
    guard amount > 0 else { throw IntentError.invalidAmount }
    let store = DataStore.shared
    let cat = category.flatMap { store.category($0.id) } ?? store.category(Defaults.otherCategoryId)
    let e = store.addEntry(type: type, amount: amount, currency: nil, categoryId: cat?.id ?? Defaults.otherCategoryId,
                           note: note ?? "", date: Date())
    return "Saved \(type == "credit" ? "+" : "")\(Fmt.money(e.amount, e.currency)) · \(cat?.name ?? "Other")"
}

enum IntentError: Error, CustomLocalizedStringResourceConvertible {
    case invalidAmount
    var localizedStringResource: LocalizedStringResource { "Enter an amount greater than 0." }
}

/// Logs straight into Expy's database (no server or API key needed); it syncs
/// next time the app is open and online.
struct LogExpenseIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Expense"
    static var description = IntentDescription("Add an expense to Expy.")
    static var openAppWhenRun = false

    @Parameter(title: "Category", requestValueDialog: "Choose a category") var category: CategoryEntity?
    @Parameter(title: "Amount", requestValueDialog: "How much did you spend?") var amount: Double
    @Parameter(title: "Note", requestValueDialog: "Add a note (optional)") var note: String?

    static var parameterSummary: some ParameterSummary { Summary("Log \(\.$amount) in \(\.$category)") { \.$note } }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let text = try logEntry(type: "expense", amount: amount, category: category, note: note)
        SyncEngine.shared.sync()
        return .result(value: text, dialog: "\(text)")
    }
}

struct LogCreditIntent: AppIntent {
    static var title: LocalizedStringResource = "Log Credit"
    static var description = IntentDescription("Add money that came in (refund, repayment…) to Expy.")
    static var openAppWhenRun = false

    @Parameter(title: "Category", requestValueDialog: "Choose a category") var category: CategoryEntity?
    @Parameter(title: "Amount", requestValueDialog: "How much came in?") var amount: Double
    @Parameter(title: "Note", requestValueDialog: "Add a note (optional)") var note: String?

    static var parameterSummary: some ParameterSummary { Summary("Log credit of \(\.$amount) in \(\.$category)") { \.$note } }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog & ReturnsValue<String> {
        let text = try logEntry(type: "credit", amount: amount, category: category, note: note)
        SyncEngine.shared.sync()
        return .result(value: text, dialog: "\(text)")
    }
}

/// Zero-setup shortcuts: appear in the Shortcuts app and Siri automatically.
struct ExpyShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: LogExpenseIntent(),
                    phrases: ["Log expense in \(.applicationName)", "Log an expense in \(.applicationName)", "\(.applicationName) expense"],
                    shortTitle: "Log Expense", systemImageName: "plus.circle")
        AppShortcut(intent: LogCreditIntent(),
                    phrases: ["Log credit in \(.applicationName)", "\(.applicationName) credit"],
                    shortTitle: "Log Credit", systemImageName: "arrow.down.circle")
    }
}
