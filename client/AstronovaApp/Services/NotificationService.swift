import Foundation
import UserNotifications

/// Push registrations for Astronova.
///
/// Wave 10 — notification redesign. The Wave 8/9 copy spoiled the daily
/// reveal ("Tap to see today's Focus, Relationships, and Energy"); the
/// Temple Bell push used loss-aversion guilt ("Maintain your streak!"). Both
/// patterns violate the redesign brief. This file replaces:
///   - The daily reminder with an anti-spoiler anticipation prompt that
///     contains zero astrological content.
///   - The Temple Bell daily streak push with a once-per-week "saved your
///     seat" reminder. Method names stay stable so the Wave 9 callsites in
///     TempleBellView don't need to rebuild — they get a weekly cadence
///     under the hood.
final class NotificationService: ObservableObject {
    static let shared = NotificationService()
    private init() {}

    // Notification identifiers — kept stable so re-scheduling overwrites the
    // previous request rather than stacking duplicates.
    private static let dailyReminderID = "daily_reminder"
    private static let templeBellWeeklyID = "temple_bell_weekly_reminder"

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

    // MARK: - Daily morning anticipation push

    /// Schedule the morning "today is here" push. Honors the wake-time hour
    /// the user has chosen (or 8am local default). Body contains *no*
    /// astrological content — it only invites the user back to the app.
    ///
    /// Wave 10 anti-spoiler rule: nothing about Focus / Relationships /
    /// Energy / streaks / depth tiers in the push body.
    func scheduleDailyReminder(at hour: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.dailyReminderID,
            // Defensive cleanup: remove any legacy Wave 9 IDs that may still
            // be installed on returning users' devices.
            "daily_reminder_v1",
            "temple_bell_daily_reminder"
        ])

        var date = DateComponents()
        date.hour = max(0, min(23, hour))

        let content = UNMutableNotificationContent()
        content.title = "Today is here."
        content.body = "Open Astronova to see what the cosmos has prepared."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(identifier: Self.dailyReminderID, content: content, trigger: trigger)
        try? await center.add(request)
    }

    /// Schedule a one-shot anticipation push tied to a specific named transit
    /// happening today. The transit name is shown but **no reading content**
    /// is included — the user still has to open the app for the body.
    ///
    /// Currently unused — wired so a future server-pushed transit calendar
    /// can call into a uniform local-fallback path.
    func scheduleTransitTeaser(transitTitle: String, fireAt date: Date) async {
        let center = UNUserNotificationCenter.current()
        let identifier = "transit_teaser_\(Int(date.timeIntervalSince1970))"

        let content = UNMutableNotificationContent()
        content.title = "\(transitTitle) today."
        content.body = "Your reading awaits."
        content.sound = .default

        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
        try? await center.add(request)
    }

    // MARK: - Temple Bell — weekly, not daily

    /// Schedule the Temple Bell reminder. Wave 10: weekly cadence (Sunday at
    /// the user's chosen hour) framed as a "saved your seat" invitation, not
    /// a streak threat. The signature is preserved so existing callsites in
    /// `TempleBellView` continue to work without modification.
    func scheduleTempleBellReminder(at hour: Int) async {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.templeBellWeeklyID,
            // Defensive cleanup: drop the old daily streak push if present.
            "temple_bell_daily_reminder"
        ])

        var date = DateComponents()
        date.hour = max(0, min(23, hour))
        date.weekday = 1 // Sunday

        let content = UNMutableNotificationContent()
        content.title = "The temple bell rests this week."
        content.body = "We've saved your seat. Come ring it when you can."
        content.sound = .default

        let trigger = UNCalendarNotificationTrigger(dateMatching: date, repeats: true)
        let request = UNNotificationRequest(
            identifier: Self.templeBellWeeklyID,
            content: content,
            trigger: trigger
        )
        try? await center.add(request)
    }

    func cancelTempleBellReminder() {
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: [
            Self.templeBellWeeklyID,
            "temple_bell_daily_reminder" // legacy id, cleared on cancel too
        ])
    }
}
