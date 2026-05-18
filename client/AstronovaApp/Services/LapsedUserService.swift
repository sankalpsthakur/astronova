import Foundation
import UserNotifications
import os

// MARK: - LapsedUserService
//
// Wave 13 brief task 6: re-engage users who haven't opened the app for 14
// days with an anti-spoiler local notification ("Mercury moves into Cancer
// this week. Will you watch?"). Wave 9 shipped the foundation (notification
// scheduling); this service formalises lapsed-detection + analytics emission
// at both schedule and open time so the win-back loop is measurable.

@MainActor
public final class LapsedUserService {
    public static let shared = LapsedUserService()

    private let lastOpenKey = "astronova_last_app_open_at"
    private let lapsedNotificationID = "astronova_lapsed_reengagement"
    private let lapsedScheduledKey = "astronova_lapsed_scheduled_at"
    private let logger = Logger(subsystem: "com.astronova.app", category: "lapsed-user")

    /// Days of no app_open before re-engagement fires.
    public let lapsedThresholdDays: Int = 14

    private init() {}

    /// Record an app_open. Call from RootView.onAppear.
    public func recordAppOpen(now: Date = Date()) {
        UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lastOpenKey)
        // If a lapsed notification was scheduled, cancel it — user is back.
        UNUserNotificationCenter.current()
            .removePendingNotificationRequests(withIdentifiers: [lapsedNotificationID])
        UserDefaults.standard.removeObject(forKey: lapsedScheduledKey)
    }

    /// True when last app_open was >= `lapsedThresholdDays` ago.
    public func isLapsed(now: Date = Date()) -> Bool {
        let last = UserDefaults.standard.double(forKey: lastOpenKey)
        guard last > 0 else { return false }
        let elapsed = now.timeIntervalSince1970 - last
        return elapsed >= TimeInterval(lapsedThresholdDays) * 24 * 3600
    }

    /// Schedule the anti-spoiler local notification to fire after the lapsed
    /// threshold passes from `now`. Notification body is anti-spoiler —
    /// hints at a transit without revealing the prediction.
    public func scheduleAntiSpoilerNotification(now: Date = Date()) async {
        let center = UNUserNotificationCenter.current()

        // Don't double-schedule.
        let pending = await center.pendingNotificationRequests()
        if pending.contains(where: { $0.identifier == lapsedNotificationID }) {
            return
        }

        let content = UNMutableNotificationContent()
        content.title = "A transit is coming"
        content.body = Self.antiSpoilerBody()
        content.sound = .default
        content.userInfo = ["source": "lapsed_reengagement"]

        let interval = TimeInterval(lapsedThresholdDays) * 24 * 3600
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
        let request = UNNotificationRequest(
            identifier: lapsedNotificationID,
            content: content,
            trigger: trigger
        )
        do {
            try await center.add(request)
            UserDefaults.standard.set(now.timeIntervalSince1970, forKey: lapsedScheduledKey)
            PortfolioAnalytics.shared.track(.lapsedReengagementScheduled, properties: [
                "threshold_days": String(lapsedThresholdDays)
            ])
        } catch {
            logger.error("Failed to schedule lapsed notification: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Hand-rolled bank of anti-spoiler hints. None should give away the
    /// actual transit's interpretation — only that one is approaching.
    public static func antiSpoilerBody(now: Date = Date()) -> String {
        let pool = [
            "Mercury moves into Cancer this week. Will you watch?",
            "A new moon arrives soon. Open Astronova to see what shifts.",
            "Your dasha sub-period is about to change.",
            "Venus is preparing to move. The chart waits.",
            "A retrograde station is on the horizon."
        ]
        let idx = Int(now.timeIntervalSince1970 / 86400) % pool.count
        return pool[idx]
    }

    // MARK: - Test seam

    func _resetForTests() {
        let d = UserDefaults.standard
        d.removeObject(forKey: lastOpenKey)
        d.removeObject(forKey: lapsedScheduledKey)
    }
}
