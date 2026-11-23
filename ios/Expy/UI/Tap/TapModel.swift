import Foundation
import Observation
import SwiftUI

/// State and actions for the Tap (quick add) screen.
@MainActor
@Observable
final class TapModel {
    enum DateMode { case today, yesterday, pick }

    var amount = ""
    var dateMode = DateMode.today
    var pickedDay = Date.now
    var note = ""
    var noteOpen = false
    var kind = TransactionKind.expense
    private(set) var savePulse = false
    private(set) var justSaved = false
    private(set) var savedCount = 0

    @ObservationIgnored private var notesCache: (key: String, notes: [String])?

    var value: Double { AmountInput.value(amount) }

    func press(_ key: String) { amount = AmountInput.press(amount, key) }
    func backspace() { if !amount.isEmpty { amount.removeLast() } }
    func clear() { amount = "" }

    func useNote(_ text: String) {
        Haptics.selection()
        note = text
        noteOpen = true
    }

    /// Recent distinct notes for a category; refetched after each save.
    func recentNotes(categoryId: String?) -> [String] {
        guard let categoryId else { return [] }
        let key = "\(categoryId)#\(savedCount)"
        if let cache = notesCache, cache.key == key { return cache.notes }
        let notes = DataStore.shared.recentNotes(categoryId: categoryId)
        notesCache = (key, notes)
        return notes
    }

    func entryDate(now: Date = .now) -> Date {
        switch dateMode {
        case .today: now
        case .yesterday: Calendar.current.date(byAdding: .day, value: -1, to: now) ?? now
        case .pick: AmountInput.withCurrentTime(pickedDay, now: now)
        }
    }

    var credit: Bool { kind == .credit }
    var isTransfer: Bool { kind == .transfer }

    /// Debit → Credit → Transfer pills: tapping the active one goes back to Debit.
    func toggle(_ k: TransactionKind) {
        Haptics.selection()
        kind = kind == k ? .expense : k
    }

    /// Whether Save can run: an amount, and for transfers two different accounts.
    func canSave(from: Account?, to: Account?) -> Bool {
        guard value > 0 else { return false }
        return !isTransfer || (from != nil && to != nil && from?.id != to?.id)
    }

    /// Saves the entry, shows feedback, then resets the form.
    func save(category: ExpenseCategory, account: Account?, toAccount: Account?) {
        guard canSave(from: account, to: toAccount) else { return }
        let e = DataStore.shared.addEntry(kind: kind, amount: value,
                                          categoryId: isTransfer ? Defaults.transferCategoryId : category.id, note: note,
                                          date: entryDate(), accountId: account?.id, toAccountId: toAccount?.id)
        savedCount += 1
        Haptics.success()
        if isTransfer, let account, let toAccount {
            ToastCenter.shared.show("Moved \(Fmt.money(e.amount)) · \(account.name) → \(toAccount.name)")
        } else {
            ToastCenter.shared.show("Saved \(credit ? "+" : "")\(Fmt.money(e.amount)) · \(category.name)" + (account.map { " · \($0.name)" } ?? ""))
        }

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { justSaved = true }
        withAnimation(.easeOut(duration: 0.18)) {
            savePulse = true
        } completion: {
            self.resetForm()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { self.savePulse = false }
        }
        Task {
            try? await Task.sleep(for: .seconds(1.1))
            withAnimation(.easeOut(duration: 0.2)) { justSaved = false }
        }
    }

    private func resetForm() {
        amount = ""
        note = ""
        noteOpen = false
        kind = .expense
        dateMode = .today
    }

    /// Applies a URL prefill; returns the matched category id, if any.
    func apply(_ p: Prefill, categories: [ExpenseCategory]) -> String? {
        if let a = p.amount, a > 0 { amount = AmountInput.trimmed(a) }
        if let k = p.kind { kind = k }
        if let n = p.note, !n.isEmpty { note = n; noteOpen = true }
        guard let c = p.category?.lowercased() else { return nil }
        return categories.first { $0.isCredit == credit && ($0.id == c || $0.name.lowercased() == c) }?.id
    }

    #if DEBUG
    func applyDemoState() {
        if let a = Demo.value("-demoAmount") { amount = a }
        if Demo.has("-demoSaved") { justSaved = true }
        if Demo.has("-demoTransfer") { kind = .transfer }
        if Demo.has("-demoCredit") { kind = .credit }
    }
    #endif
}
