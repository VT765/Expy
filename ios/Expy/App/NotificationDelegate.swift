import Foundation
import UserNotifications

/// Shows Expy's notifications as banners even while the app is open, and
/// opens the review list when a bank-message notification is tapped.
final class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()

    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        guard response.notification.request.identifier.hasPrefix("review-") else { return }
        await MainActor.run { NotificationCenter.default.post(name: .openReviewInbox, object: nil) }
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async
        -> UNNotificationPresentationOptions {
        [.banner, .list, .sound]
    }
}

extension Notification.Name {
    static let openReviewInbox = Notification.Name("expy.openReviewInbox")
}
