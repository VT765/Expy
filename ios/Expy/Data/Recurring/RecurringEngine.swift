import Foundation
import SwiftData

/// Creates the entries recurring rules owe, and keeps their reminders in
/// sync. Runs at launch and whenever the app comes to the foreground; iOS
/// doesn't let a free-provisioned app run on a schedule in the background,
/// so a rule due while Expy is closed is logged (with its due date) the next
/// time it opens.
@MainActor
enum RecurringEngine {
    static var activeRules: [RecurringRule] {
        DataStore.shared.fetch(RecurringRule.self, #Predicate { $0.deletedAt == nil }).sorted { $0.nextDate < $1.nextDate }
    }

    /// Logs every due occurrence; returns how many entries were created.
    @discardableResult
    static func processDue(now: Date = .now) -> Int {
        let store = DataStore.shared
        var created = 0
        for r in activeRules where !r.isPaused {
            let due = RecurrenceSchedule.due(next: r.nextDate, start: r.startDate, end: r.endDate, frequency: r.frequency, now: now)
            guard !due.dates.isEmpty else { continue }
            for d in due.dates {
                store.addEntry(kind: r.kind, amount: r.amount, categoryId: r.categoryId, note: r.note, date: d,
                               accountId: r.accountId, toAccountId: r.toAccountId, recurringRuleId: r.id)
            }
            r.nextDate = due.next
            r.updatedAt = now
            created += due.dates.count
        }
        store.save()
        Notifier.rescheduleReminders(for: activeRules)
        if created > 0 { ToastCenter.shared.show("Added \(created) recurring \(created == 1 ? "entry" : "entries")") }
        return created
    }

    struct Draft {
        var kind = TransactionKind.expense
        var amount = 0.0
        var categoryId = Defaults.otherCategoryId
        var accountId: String?
        var toAccountId: String?
        var note = ""
        var frequency = RecurrenceFrequency.monthly
        var startDate = Date.now
        var endDate: Date?
        var remind = true
    }

    /// New rules starting in the past are backfilled right away. Edits never
    /// re-log occurrences that already have entries.
    static func save(_ d: Draft, rule: RecurringRule?) {
        let store = DataStore.shared
        let start = atNine(d.startDate)
        let category = d.kind == .transfer ? Defaults.transferCategoryId : d.categoryId
        if let r = rule {
            r.kind = d.kind; r.amount = d.amount; r.categoryId = category
            r.accountId = d.accountId; r.toAccountId = d.kind == .transfer ? d.toAccountId : nil
            r.note = d.note; r.frequency = d.frequency; r.startDate = start; r.endDate = d.endDate; r.remind = d.remind
            let rid = r.id
            let last = store.fetch(Entry.self, #Predicate { $0.recurringRuleId == rid && $0.deletedAt == nil }).map(\.date).max()
            r.nextDate = RecurrenceSchedule.first(onOrAfter: last.map { $0.addingTimeInterval(1) } ?? start, start: start, frequency: d.frequency)
            r.updatedAt = .now
        } else {
            store.context.insert(RecurringRule(kind: d.kind, amountPaise: Money.paise(d.amount), categoryId: category, accountId: d.accountId,
                                               toAccountId: d.kind == .transfer ? d.toAccountId : nil, note: d.note,
                                               frequency: d.frequency, startDate: start, endDate: d.endDate, remind: d.remind))
        }
        store.save()
        processDue()
    }

    /// Resuming skips what was missed while paused.
    static func setPaused(_ r: RecurringRule, _ paused: Bool, now: Date = .now) {
        r.isPaused = paused
        if !paused {
            r.nextDate = RecurrenceSchedule.first(onOrAfter: max(r.nextDate, Calendar.current.startOfDay(for: now)),
                                                  start: r.startDate, frequency: r.frequency)
        }
        r.updatedAt = now
        DataStore.shared.save()
        Notifier.rescheduleReminders(for: activeRules)
    }

    /// Stops the rule; entries it already created stay.
    static func delete(_ r: RecurringRule) {
        r.deletedAt = .now
        r.updatedAt = .now
        DataStore.shared.save()
        Notifier.rescheduleReminders(for: activeRules)
    }

    /// Recurring entries are logged at 9 AM on their day.
    static func atNine(_ date: Date) -> Date {
        Calendar.current.date(bySettingHour: 9, minute: 0, second: 0, of: date) ?? date
    }
}
