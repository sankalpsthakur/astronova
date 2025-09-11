import Foundation
import UserNotifications

final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private init() {}

    func requestAuthorization() async -> Bool {
        do {
            let center = UNUserNotificationCenter.current()
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            return false
        }
    }

    func authorizationStatus() async -> UNAuthorizationStatus {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        return settings.authorizationStatus
    }

    func scheduleDailyReminder(at hour: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["daily_reminder"]) 

        var date = DateComponents()
        date.hour = hour

        let content = UNMutableNotificationContent()
        content.title = "Your daily guidance is ready"
        content.body = "Tap to see today's Focus, Relationships, and Energy insights."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: "daily_reminder", content: content, trigger: trigger)
        try? await center.add(request)
    }
}
