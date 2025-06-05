import Foundation
import UserNotifications

/// Schedules local daily notifications as a fallback when pushes fail.
public final class DailyScheduler {
    public init() {}

    /// Schedule a notification at the specified local date components.
    public func scheduleNotification(at dateComponents: DateComponents, body: String) {
        // TODO: implement scheduling logic
    }
}