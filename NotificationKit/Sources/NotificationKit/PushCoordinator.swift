import Foundation
import UserNotifications
import CloudKitKit

/// Manages remote push registration and handling.
public final class PushCoordinator: NSObject {
    public override init() { super.init() }

    /// Request notification authorization and register for APNs.
    public func registerForPush() {
        // TODO: implement UNUserNotificationCenter & CKSubscription logic
    }
}