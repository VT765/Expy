import Foundation
import UserNotifications

/// Local notifications only (no server, works with a free Apple ID):
/// recurring reminders on the due day, and budget alerts.
@MainActor
enum Notifier {
    private static var center: UNUserNotificationCenter { .current() }
    private static let reminderPrefix = "recurring-"

    /// Asks once; later calls return the saved answer.
    @discardableResult
    static func requestPermission() async -> Bool {
        (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
    }

    /// One pending reminder per active rule, at its next due date and time.
    static func rescheduleReminders(for rules: [RecurringRule]) {
        let pending = rules.filter { $0.remind && !$0.isPaused && !RecurrenceSchedule.hasEnded(next: $0.nextDate, end: $0.endDate) }
            .map { r in
                (id: reminderPrefix + r.id, date: r.nextDate, title: "\(r.note.isEmpty ? "Recurring entry" : r.note) is due today",
                 body: "\(Fmt.money(r.amount)) will be added to Expy. Open the app to see it in History.")
            }
        Task {
            let existing = await center.pendingNotificationRequests().map(\.identifier).filter { $0.hasPrefix(reminderPrefix) }
            center.removePendingNotificationRequests(withIdentifiers: existing)
            for p in pending where p.date > .now {
                let content = UNMutableNotificationContent()
                content.title = p.title
                content.body = p.body
                content.sound = .default
                let parts = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: p.date)
                try? await center.add(UNNotificationRequest(identifier: p.id, content: content,
                                                            trigger: UNCalendarNotificationTrigger(dateMatching: parts, repeats: false)))
            }
        }
    }

    /// Shown right away (as a banner even while Expy is open).
    static func post(id: String, title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        Task { try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: nil)) }
    }
}
