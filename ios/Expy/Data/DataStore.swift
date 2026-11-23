import Foundation
import SwiftData

/// All writes go through here and land in SwiftData immediately (on-device
/// only). Reads in views use @Query.
@MainActor
final class DataStore {
    static let shared = DataStore()
    let context: ModelContext

    private init() {
        context = Persistence.container.mainContext
        context.autosaveEnabled = true
        seedIfNeeded()
        // Leftover login token from the server-sync era.
        Keychain.set(nil as Data?, for: "jwt")
    }

    // MARK: - Lookups

    func fetch<T: PersistentModel>(_ type: T.Type, _ predicate: Predicate<T>? = nil) -> [T] {
        (try? context.fetch(FetchDescriptor<T>(predicate: predicate))) ?? []
    }

    var settings: AppSettings {
        if let s = fetch(AppSettings.self).first { return s }
        let s = AppSettings()
        context.insert(s)
        return s
    }

    func entry(_ id: String) -> Entry? { fetch(Entry.self, #Predicate { $0.id == id }).first }
    func category(_ id: String) -> ExpenseCategory? { fetch(ExpenseCategory.self, #Predicate { $0.id == id }).first }
    func budget(_ id: String) -> Budget? { fetch(Budget.self, #Predicate { $0.id == id }).first }
    func recurringRule(_ id: String) -> RecurringRule? { fetch(RecurringRule.self, #Predicate { $0.id == id }).first }

    /// Live categories of one kind, in their order.
    func categories(_ kind: TransactionKind) -> [ExpenseCategory] {
        activeCategories.filter { $0.kind == kind }
    }

    var activeCategories: [ExpenseCategory] {
        fetch(ExpenseCategory.self, #Predicate { $0.deletedAt == nil }).sorted { $0.order < $1.order }
    }

    private func seedIfNeeded() {
        let existing = Set(fetch(ExpenseCategory.self).map(\.id))
        for d in Defaults.allCategories where !existing.contains(d.id) {
            context.insert(ExpenseCategory(id: d.id, kind: d.kind, name: d.name, emoji: d.emoji, colorHex: d.color, order: d.order,
                                           updatedAt: Defaults.epoch))
        }
        if fetch(Account.self).isEmpty {
            context.insert(Account(id: Defaults.cashAccountId, name: "Cash", kind: .cash, openingBalancePaise: 0, openingDate: Defaults.epoch, order: 0))
        }
        _ = settings
        save()
    }

    func save() { try? context.save() }

    /// Saves a user-visible change and re-checks budget alerts.
    private func commit() {
        save()
        BudgetAlerts.shared.scheduleCheck()
    }

    // MARK: - Entries

    /// Logs an expense, credit or transfer. Amounts are rupees, stored as paise.
    @discardableResult
    func addEntry(kind: TransactionKind, amount: Double, categoryId: String, note: String, date: Date,
                  accountId: String? = nil, toAccountId: String? = nil, recurringRuleId: String? = nil) -> Entry {
        let now = Date.now
        let e = Entry(kind: kind, amountPaise: Money.paise(amount), categoryId: categoryId,
                      note: note.trimmingCharacters(in: .whitespacesAndNewlines), date: date, accountId: accountId,
                      toAccountId: kind == .transfer ? toAccountId : nil, recurringRuleId: recurringRuleId,
                      createdAt: now, updatedAt: now)
        context.insert(e)
        commit()
        return e
    }

    func updateEntry(_ e: Entry, kind: TransactionKind, amount: Double, categoryId: String, note: String, date: Date,
                     accountId: String?, toAccountId: String? = nil) {
        e.kind = kind
        e.amount = amount
        e.categoryId = categoryId
        e.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        e.date = date
        e.accountId = accountId
        e.toAccountId = kind == .transfer ? toAccountId : nil
        e.updatedAt = Date.now
        commit()
    }

    /// Re-logs the same expense now (swipe right / context menu).
    @discardableResult
    func duplicateEntry(_ e: Entry) -> Entry {
        addEntry(kind: e.kind, amount: e.amount, categoryId: e.categoryId, note: e.note, date: Date.now,
                 accountId: e.accountId, toAccountId: e.toAccountId)
    }

    func moveEntry(_ e: Entry, toAccount accountId: String?) {
        e.accountId = accountId
        e.updatedAt = Date.now
        commit()
    }

    /// Most recent distinct notes used with a category, newest first.
    func recentNotes(categoryId: String, limit: Int = 4) -> [String] {
        var d = FetchDescriptor<Entry>(predicate: #Predicate { $0.categoryId == categoryId && $0.deletedAt == nil && $0.note != "" },
                                       sortBy: [SortDescriptor(\.date, order: .reverse)])
        d.fetchLimit = 40
        var seen = Set<String>()
        return ((try? context.fetch(d)) ?? []).compactMap { e in
            let key = e.note.lowercased()
            return seen.insert(key).inserted ? e.note : nil
        }
        .prefix(limit).map { $0 }
    }

    func deleteEntry(_ e: Entry) {
        e.deletedAt = Date.now
        e.updatedAt = Date.now
        commit()
    }

    func restoreEntry(_ e: Entry) {
        e.deletedAt = nil
        e.updatedAt = Date.now
        commit()
    }

    // MARK: - Categories

    func saveCategory(id: String?, kind: TransactionKind, name: String, emoji: String, colorHex: String) {
        let now = Date.now
        if let id, let c = category(id) {
            c.name = name; c.emoji = emoji; c.colorHex = colorHex; c.updatedAt = now; c.deletedAt = nil
        } else {
            let order = (fetch(ExpenseCategory.self).filter { $0.kind == kind }.map(\.order).max() ?? -1) + 1
            let prefix = kind == .credit ? "inc" : "cat"
            let c = ExpenseCategory(id: "\(prefix)_\(UUID().uuidString.lowercased())", kind: kind, name: name, emoji: emoji,
                                    colorHex: colorHex, order: order, updatedAt: now)
            context.insert(c)
        }
        commit()
    }

    /// Soft-deletes a category; its entries move to "Other" (or "Other income").
    func deleteCategory(_ c: ExpenseCategory) {
        guard !Defaults.isFallback(c.id) else { return }
        let fallback = Defaults.fallbackCategoryId(for: c.kind)
        let now = Date.now
        c.deletedAt = now; c.updatedAt = now
        let cid = c.id
        for e in fetch(Entry.self, #Predicate { $0.categoryId == cid && $0.deletedAt == nil }) {
            e.categoryId = fallback; e.updatedAt = now
        }
        if let b = budget("budget_\(cid)"), b.deletedAt == nil {
            b.deletedAt = now; b.updatedAt = now
        }
        commit()
    }

    func reorderCategories(_ ordered: [ExpenseCategory]) {
        let now = Date.now
        for (i, c) in ordered.enumerated() where c.order != i {
            c.order = i; c.updatedAt = now
        }
        commit()
    }

    // MARK: - Accounts

    var activeAccounts: [Account] {
        fetch(Account.self, #Predicate { $0.deletedAt == nil }).sorted { $0.order < $1.order }
    }

    func account(_ id: String) -> Account? { fetch(Account.self, #Predicate { $0.id == id }).first }

    func saveAccount(id: String?, name: String, kind: AccountKind, openingBalance: Double, openingDate: Date) {
        let now = Date.now
        if let id, let a = account(id) {
            a.name = name; a.kind = kind; a.openingBalance = openingBalance; a.openingDate = openingDate; a.updatedAt = now
        } else {
            let order = (fetch(Account.self).map(\.order).max() ?? -1) + 1
            context.insert(Account(name: name, kind: kind, openingBalancePaise: Money.paise(openingBalance),
                                   openingDate: openingDate, order: order))
        }
        commit()
    }

    /// Removes the account; its entries stay but become unassigned.
    func deleteAccount(_ a: Account) {
        let id = a.id
        for e in fetch(Entry.self, #Predicate { $0.accountId == id }) { e.accountId = nil }
        for e in fetch(Entry.self, #Predicate { $0.toAccountId == id }) { e.toAccountId = nil }
        a.deletedAt = Date.now
        commit()
    }

    /// Opening balance plus the effect of every live entry dated on/after the opening date, in exact paise.
    static func balancePaise(of a: Account, entries: [Entry]) -> Int {
        entries.reduce(a.openingBalancePaise) { sum, e in
            guard e.deletedAt == nil, e.date >= a.openingDate else { return sum }
            return sum + e.balanceEffect(on: a.id)
        }
    }

    /// Rupees (see `balancePaise`).
    static func balance(of a: Account, entries: [Entry]) -> Double { Money.rupees(balancePaise(of: a, entries: entries)) }

    /// Bulk insert from a bank statement import.
    func importEntries(_ rows: [(kind: TransactionKind, amount: Double, date: Date, note: String, categoryId: String)], accountId: String) {
        let now = Date.now
        for r in rows {
            context.insert(Entry(kind: r.kind, amountPaise: Money.paise(r.amount), categoryId: r.categoryId, note: r.note, date: r.date,
                                 accountId: accountId, createdAt: now, updatedAt: now))
        }
        commit()
    }

    // MARK: - Budgets & settings

    /// categoryId nil = overall monthly budget; amount 0 removes it.
    func setBudget(categoryId: String?, amount: Double) {
        let id = categoryId.map { "budget_\($0)" } ?? "budget_total"
        let now = Date.now
        let b = budget(id) ?? {
            let nb = Budget(id: id, categoryId: categoryId, amountPaise: 0, updatedAt: now)
            context.insert(nb)
            return nb
        }()
        b.amount = amount
        b.updatedAt = now
        b.deletedAt = amount > 0 ? nil : now
        commit()
    }

    func updateSettings(_ change: (AppSettings) -> Void) {
        let s = settings
        change(s)
        s.updatedAt = Date.now
        commit()
    }

    // MARK: - Backup / reset

    /// Merges a validated backup; newer copies win, backup entries are stamped now.
    func importBackup(_ b: BackupFile) {
        let now = Date.now.epochMs
        for var d in b.transactions {
            d.updatedAt = now
            if let e = entry(d.id) { d.apply(to: e) } else { context.insert(d.make()) }
        }
        for var d in b.categories {
            d.updatedAt = now
            if let c = category(d.id) { d.apply(to: c) } else { context.insert(d.make()) }
        }
        for var d in b.budgets {
            d.updatedAt = now
            if let x = budget(d.id) { d.apply(to: x) } else { context.insert(d.make()) }
        }
        if var d = b.settings {
            d.updatedAt = now
            d.apply(to: settings)
        }
        for var d in b.accounts ?? [] {
            d.updatedAt = now
            if let a = account(d.id) { d.apply(to: a) } else { context.insert(d.make()) }
        }
        for var d in b.recurring ?? [] {
            d.updatedAt = now
            if let r = recurringRule(d.id) { d.apply(to: r) } else { context.insert(d.make()) }
        }
        commit()
    }

    func backup() -> BackupFile {
        BackupFile(exportedAt: Date.now.epochMs,
                   transactions: fetch(Entry.self, #Predicate { $0.deletedAt == nil }).map(EntryDTO.init),
                   categories: activeCategories.map(CategoryDTO.init),
                   budgets: fetch(Budget.self, #Predicate { $0.deletedAt == nil }).map(BudgetDTO.init),
                   settings: SettingsDTO(settings),
                   accounts: activeAccounts.map(AccountDTO.init),
                   recurring: fetch(RecurringRule.self, #Predicate { $0.deletedAt == nil }).map(RecurringRuleDTO.init))
    }

    /// Deletes all entries and budgets and resets categories/settings.
    func eraseAll() {
        let now = Date.now
        for e in fetch(Entry.self, #Predicate { $0.deletedAt == nil }) { e.deletedAt = now; e.updatedAt = now }
        for b in fetch(Budget.self, #Predicate { $0.deletedAt == nil }) { b.deletedAt = now; b.updatedAt = now }
        for r in fetch(RecurringRule.self, #Predicate { $0.deletedAt == nil }) { r.deletedAt = now; r.updatedAt = now }
        let defaults = Dictionary(uniqueKeysWithValues: Defaults.allCategories.map { ($0.id, ($0.order, $0)) })
        for c in fetch(ExpenseCategory.self) {
            if let (i, d) = defaults[c.id] {
                c.kind = d.kind; c.name = d.name; c.emoji = d.emoji; c.colorHex = d.color; c.order = i; c.deletedAt = nil
            } else { c.deletedAt = now }
            c.updatedAt = now
        }
        let s = settings
        s.cycleStartDay = 1; s.updatedAt = now
        commit()
    }

    /// Wipes everything on this device (forgot PIN).
    func resetLocal() {
        try? context.delete(model: Entry.self)
        try? context.delete(model: ExpenseCategory.self)
        try? context.delete(model: Budget.self)
        try? context.delete(model: Account.self)
        try? context.delete(model: AppSettings.self)
        try? context.delete(model: RecurringRule.self)
        save()
        seedIfNeeded()
    }
}
