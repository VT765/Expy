import Foundation
import SwiftData

/// All writes go through here: they land in SwiftData immediately and are
/// queued in the outbox for the sync engine. Reads in views use @Query.
@MainActor
final class DataStore {
    static let shared = DataStore()
    let context: ModelContext
    private let encoder = JSONEncoder()

    private init() {
        context = Persistence.container.mainContext
        context.autosaveEnabled = true
        seedIfNeeded()
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

    var activeCategories: [ExpenseCategory] {
        fetch(ExpenseCategory.self, #Predicate { $0.deletedAt == nil }).sorted { $0.order < $1.order }
    }

    private func seedIfNeeded() {
        let existing = Set(fetch(ExpenseCategory.self).map(\.id))
        for (i, d) in Defaults.categories.enumerated() where !existing.contains(d.id) {
            context.insert(ExpenseCategory(id: d.id, name: d.name, emoji: d.emoji, colorHex: d.color, order: i, updatedAt: Defaults.epoch))
        }
        _ = settings
        save()
    }

    func save() { try? context.save() }

    // MARK: - Outbox

    private func enqueue(_ collection: String, id: String, updatedAt: Date, _ payload: some Encodable) {
        guard let data = try? encoder.encode(payload) else { return }
        let key = "\(collection):\(id)"
        if let item = fetch(OutboxItem.self, #Predicate { $0.key == key }).first {
            item.payload = data
            item.updatedAt = updatedAt.epochMs
        } else {
            context.insert(OutboxItem(key: key, collection: collection, payload: data, updatedAt: updatedAt.epochMs))
        }
    }

    private func touched(_ e: Entry) { enqueue("transactions", id: e.id, updatedAt: e.updatedAt, EntryDTO(e)) }
    private func touched(_ c: ExpenseCategory) { enqueue("categories", id: c.id, updatedAt: c.updatedAt, CategoryDTO(c)) }
    private func touched(_ b: Budget) { enqueue("budgets", id: b.id, updatedAt: b.updatedAt, BudgetDTO(b)) }
    private func touchedSettings() { enqueue("settings", id: "app", updatedAt: settings.updatedAt, SettingsDTO(settings)) }

    private func commit() {
        save()
        SyncEngine.shared.scheduleSync()
    }

    // MARK: - Currency

    func rate(for currency: String) -> Double? {
        let s = settings
        if currency == s.baseCurrency { return 1 }
        if let o = s.rateOverrides[currency] { return o }
        return RatesService.shared.rate(currency, base: s.baseCurrency)
    }

    func toBase(_ amount: Double, _ currency: String) -> (value: Double, missingRate: Bool) {
        let r = rate(for: currency)
        return (((amount * (r ?? 1)) * 100).rounded() / 100, r == nil)
    }

    // MARK: - Entries

    @discardableResult
    func addEntry(type: String, amount: Double, currency: String?, categoryId: String, note: String, date: Date) -> Entry {
        let now = Date()
        let cur = currency ?? settings.baseCurrency
        let e = Entry(id: "tx_\(UUID().uuidString.lowercased())", type: type, amount: (amount * 100).rounded() / 100, currency: cur,
                      amountInBase: toBase(amount, cur).value, categoryId: categoryId,
                      note: note.trimmingCharacters(in: .whitespacesAndNewlines), date: date, createdAt: now, updatedAt: now)
        context.insert(e)
        touched(e)
        commit()
        return e
    }

    func updateEntry(_ e: Entry, type: String, amount: Double, currency: String, categoryId: String, note: String, date: Date) {
        e.type = type
        e.amount = (amount * 100).rounded() / 100
        e.currency = currency
        e.amountInBase = toBase(e.amount, currency).value
        e.categoryId = categoryId
        e.note = note.trimmingCharacters(in: .whitespacesAndNewlines)
        e.date = date
        e.updatedAt = Date()
        touched(e)
        commit()
    }

    func deleteEntry(_ e: Entry) {
        e.deletedAt = Date()
        e.updatedAt = Date()
        touched(e)
        commit()
    }

    func restoreEntry(_ e: Entry) {
        e.deletedAt = nil
        e.updatedAt = Date()
        touched(e)
        commit()
    }

    // MARK: - Categories

    func saveCategory(id: String?, name: String, emoji: String, colorHex: String) {
        let now = Date()
        if let id, let c = category(id) {
            c.name = name; c.emoji = emoji; c.colorHex = colorHex; c.updatedAt = now; c.deletedAt = nil
            touched(c)
        } else {
            let order = (fetch(ExpenseCategory.self).map(\.order).max() ?? -1) + 1
            let c = ExpenseCategory(id: "cat_\(UUID().uuidString.lowercased())", name: name, emoji: emoji, colorHex: colorHex, order: order, updatedAt: now)
            context.insert(c)
            touched(c)
        }
        commit()
    }

    /// Soft-deletes a category; its entries move to "Other".
    func deleteCategory(_ c: ExpenseCategory) {
        guard c.id != Defaults.otherCategoryId else { return }
        let now = Date()
        c.deletedAt = now; c.updatedAt = now
        touched(c)
        let cid = c.id
        for e in fetch(Entry.self, #Predicate { $0.categoryId == cid && $0.deletedAt == nil }) {
            e.categoryId = Defaults.otherCategoryId; e.updatedAt = now
            touched(e)
        }
        if let b = budget("budget_\(cid)"), b.deletedAt == nil {
            b.deletedAt = now; b.updatedAt = now
            touched(b)
        }
        commit()
    }

    func reorderCategories(_ ordered: [ExpenseCategory]) {
        let now = Date()
        for (i, c) in ordered.enumerated() where c.order != i {
            c.order = i; c.updatedAt = now
            touched(c)
        }
        commit()
    }

    // MARK: - Budgets & settings

    /// categoryId nil = overall monthly budget; amount 0 removes it.
    func setBudget(categoryId: String?, amount: Double) {
        let id = categoryId.map { "budget_\($0)" } ?? "budget_total"
        let now = Date()
        let b = budget(id) ?? {
            let nb = Budget(id: id, categoryId: categoryId, amount: 0, updatedAt: now)
            context.insert(nb)
            return nb
        }()
        b.amount = (amount * 100).rounded() / 100
        b.updatedAt = now
        b.deletedAt = amount > 0 ? nil : now
        touched(b)
        commit()
    }

    func updateSettings(_ change: (AppSettings) -> Void) {
        let s = settings
        change(s)
        s.updatedAt = Date()
        touchedSettings()
        commit()
    }

    /// Re-prices every entry in the current base currency.
    func rebaseEntries() {
        let now = Date()
        for e in fetch(Entry.self) {
            let v = toBase(e.amount, e.currency).value
            if v != e.amountInBase { e.amountInBase = v; e.updatedAt = now; touched(e) }
        }
        commit()
    }

    // MARK: - Sync / backup / reset

    /// Applies server docs, last-write-wins. Nothing is queued.
    func applyRemote(_ r: PullResponse) {
        for d in r.transactions {
            let id = d.id
            if let e = fetch(Entry.self, #Predicate { $0.id == id }).first {
                if d.updatedAt >= e.updatedAt.epochMs { d.apply(to: e) }
            } else { context.insert(d.make()) }
        }
        for d in r.categories {
            if let c = category(d.id) {
                if d.updatedAt >= c.updatedAt.epochMs { d.apply(to: c) }
            } else { context.insert(d.make()) }
        }
        for d in r.budgets {
            if let b = budget(d.id) {
                if d.updatedAt >= b.updatedAt.epochMs { d.apply(to: b) }
            } else { context.insert(d.make()) }
        }
        if let d = r.settings, d.updatedAt >= settings.updatedAt.epochMs { d.apply(to: settings) }
        save()
    }

    func importBackup(_ b: BackupFile) {
        let now = Date().epochMs
        let stamped = PullResponse(
            serverTime: 0,
            transactions: b.transactions.map { var d = $0; d.updatedAt = now; return d },
            categories: b.categories.map { var d = $0; d.updatedAt = now; return d },
            budgets: b.budgets.map { var d = $0; d.updatedAt = now; return d },
            settings: b.settings.map { var d = $0; d.updatedAt = now; return d })
        applyRemote(stamped)
        // Queue everything that was imported.
        for e in fetch(Entry.self) where e.updatedAt.epochMs == now { touched(e) }
        for c in fetch(ExpenseCategory.self) where c.updatedAt.epochMs == now { touched(c) }
        for x in fetch(Budget.self) where x.updatedAt.epochMs == now { touched(x) }
        if settings.updatedAt.epochMs == now { touchedSettings() }
        commit()
    }

    func backup() -> BackupFile {
        BackupFile(exportedAt: Date().epochMs,
                   transactions: fetch(Entry.self, #Predicate { $0.deletedAt == nil }).map(EntryDTO.init),
                   categories: activeCategories.map(CategoryDTO.init),
                   budgets: fetch(Budget.self, #Predicate { $0.deletedAt == nil }).map(BudgetDTO.init),
                   settings: SettingsDTO(settings))
    }

    /// Soft-deletes everything (so it syncs) and resets categories/settings.
    func eraseAll() {
        let now = Date()
        for e in fetch(Entry.self, #Predicate { $0.deletedAt == nil }) { e.deletedAt = now; e.updatedAt = now; touched(e) }
        for b in fetch(Budget.self, #Predicate { $0.deletedAt == nil }) { b.deletedAt = now; b.updatedAt = now; touched(b) }
        let defaults = Dictionary(uniqueKeysWithValues: Defaults.categories.enumerated().map { ($0.element.id, ($0.offset, $0.element)) })
        for c in fetch(ExpenseCategory.self) {
            if let (i, d) = defaults[c.id] {
                c.name = d.name; c.emoji = d.emoji; c.colorHex = d.color; c.order = i; c.deletedAt = nil
            } else { c.deletedAt = now }
            c.updatedAt = now
            touched(c)
        }
        let s = settings
        s.baseCurrency = "INR"; s.cycleStartDay = 1; s.rateOverrides = [:]; s.updatedAt = now
        touchedSettings()
        commit()
    }

    /// Wipes the device copy (sign-out / forgot PIN). Nothing is queued.
    func resetLocal() {
        try? context.delete(model: Entry.self)
        try? context.delete(model: ExpenseCategory.self)
        try? context.delete(model: Budget.self)
        try? context.delete(model: AppSettings.self)
        try? context.delete(model: OutboxItem.self)
        save()
        seedIfNeeded()
    }
}
