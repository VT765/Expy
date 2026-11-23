import Foundation
import Observation
import OSLog

/// Bank-message suggestions waiting for a tap. Kept in a small JSON file
/// beside the database (no schema change), with the references already
/// handled so a forwarded or repeated SMS isn't suggested twice.
@MainActor
@Observable
final class ReviewInbox {
    static let shared = ReviewInbox()
    /// Log straight into History instead of waiting for review.
    static let autoLogKey = "bankMessagesAutoLog"

    private(set) var items: [Suggestion] = []
    @ObservationIgnored private var seenRefs: [String] = []
    @ObservationIgnored private let url: URL?

    private struct Stored: Codable {
        var items: [Suggestion]
        var seenRefs: [String]
    }

    init(url: URL? = URL.applicationSupportDirectory.appending(path: "review-inbox.json")) {
        self.url = url
        guard let url, let data = try? Data(contentsOf: url), let s = try? JSONDecoder().decode(Stored.self, from: data) else { return }
        items = s.items
        seenRefs = s.seenRefs
    }

    var count: Int { items.count }

    /// Turns a parsed message into a suggestion: account, category guess, duplicate check.
    /// Returns nil when the same reference was already handled.
    func suggestion(from p: ParsedBankMessage, now: Date = .now) -> Suggestion? {
        if let ref = p.reference, seenRefs.contains(ref) { return nil }
        let store = DataStore.shared
        let account = BankAccountMatcher.account(last4: p.last4, bank: p.bank, among: store.activeAccounts)
        let entries = store.fetch(Entry.self, #Predicate { $0.deletedAt == nil })
        var history: [String: String] = [:]
        for e in entries.sorted(by: { $0.date < $1.date }) where !e.note.isEmpty { history[e.note.lowercased()] = e.categoryId }
        let note = p.counterparty ?? ""
        let category = CategoryGuesser.guess(note, kind: p.kind, history: history, valid: Set(store.categories(p.kind).map(\.id)))
        let paise = Money.paise(p.amount)
        let duplicate = entries.contains {
            $0.kind == p.kind && $0.amountPaise == paise && Calendar.current.isDate($0.date, inSameDayAs: p.date)
        }
        return Suggestion(kind: p.kind, amount: p.amount, date: p.date, accountId: account?.id, categoryId: category, note: note,
                          last4: p.last4, bank: p.bank, reference: p.reference, possibleDuplicate: duplicate, receivedAt: now)
    }

    func add(_ s: Suggestion) {
        markSeen(s.reference)
        items.insert(s, at: 0)
        persist()
    }

    /// Logs the (possibly edited) suggestion and remembers its account for those digits.
    @discardableResult
    func accept(_ s: Suggestion) -> Entry {
        markSeen(s.reference)
        BankAccountMatcher.remember(last4: s.last4, accountId: s.accountId)
        let e = DataStore.shared.addEntry(kind: s.kind, amount: s.amount, categoryId: s.categoryId, note: s.note, date: s.date,
                                          accountId: s.accountId)
        items.removeAll { $0.id == s.id }
        persist()
        return e
    }

    func acceptAll() {
        for s in items where !s.possibleDuplicate { accept(s) }
    }

    func dismiss(_ s: Suggestion) {
        items.removeAll { $0.id == s.id }
        persist()
    }

    private func markSeen(_ ref: String?) {
        guard let ref, !seenRefs.contains(ref) else { return }
        seenRefs = Array((seenRefs + [ref]).suffix(500))
    }

    private func persist() {
        guard let url else { return }
        do {
            try JSONEncoder().encode(Stored(items: items, seenRefs: seenRefs)).write(to: url, options: .atomic)
        } catch {
            Logger(subsystem: "com.varunthacker.expy", category: "inbox").error("Saving review inbox failed: \(error)")
        }
    }
}
