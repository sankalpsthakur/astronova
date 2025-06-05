import Foundation
import UserNotifications

/// Schedules local daily notifications as a fallback when pushes fail.
public final class DailyScheduler {
    public init() {}

    /// Schedule a local notification after the provided time interval. Used when push registration fails.
    public func scheduleNotification(after interval: TimeInterval, body: String) {
        let content = UNMutableNotificationContent()
        content.body = body
        content.sound = .default

        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString,
                                            content: content,
                                            trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }
}