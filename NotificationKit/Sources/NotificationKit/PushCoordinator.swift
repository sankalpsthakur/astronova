import Foundation
import UserNotifications
import UIKit
import CloudKit
import CloudKitKit
import DataModels

/// Manages remote push registration and handling.
public final class PushCoordinator: NSObject {
    public override init() { super.init() }

    /// Called whenever a push or local notification is delivered to the app.
    public var onNotification: ((UNNotification) -> Void)?

    /// Reports registration success or failure for APNs.
    public var onRegistration: ((Result<Data, Error>) -> Void)?

    /// Request notification authorization and register for APNs.
    public func registerForPush() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            DispatchQueue.main.async {
                guard granted else {
                    self.onRegistration?(.failure(error ?? NSError(
                        domain: "NotificationKit",
                        code: 0,
                        userInfo: [NSLocalizedDescriptionKey: "Authorization denied"])))
                    return
                }

                UIApplication.shared.registerForRemoteNotifications()

                Task {
                    try? await self.createHoroscopeSubscription()
                }
            }
        }
    }

    /// Creates a silent push subscription for new Horoscope records in the public database.
    private func createHoroscopeSubscription() async throws {
        let predicate = NSPredicate(value: true)
        let subscription = CKQuerySubscription(
            recordType: Horoscope.recordType,
            predicate: predicate,
            subscriptionID: "horoscope_new_records",
            options: [.firesOnRecordCreation]
        )

        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info

        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            CKContainer.cosmic.publicCloudDatabase.save(subscription) { _, error in
                if let error = error as? CKError, error.code == .serverRejectedRequest {
                    // Subscription already exists
                    continuation.resume(returning: ())
                } else if let error = error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume(returning: ())
                }
            }
        }
    }

    /// Pass through to update registration callbacks from the AppDelegate.
    public func didRegisterForRemoteNotifications(token: Data) {
        onRegistration?(.success(token))
    }

    public func didFailToRegisterForRemoteNotifications(error: Error) {
        onRegistration?(.failure(error))
    }
}

extension PushCoordinator: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       willPresent notification: UNNotification,
                                       withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        onNotification?(notification)
        completionHandler([.badge, .sound, .banner])
    }

    public func userNotificationCenter(_ center: UNUserNotificationCenter,
                                       didReceive response: UNNotificationResponse,
                                       withCompletionHandler completionHandler: @escaping () -> Void) {
        onNotification?(response.notification)
        completionHandler()
    }
}