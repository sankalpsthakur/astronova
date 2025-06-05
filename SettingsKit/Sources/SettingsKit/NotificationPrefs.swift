import Foundation

/// User notification preference flags persisted in settings.
public struct NotificationPrefs: Codable {
    public var dailyEnabled: Bool

    public init(dailyEnabled: Bool = true) {
        self.dailyEnabled = dailyEnabled
    }
}