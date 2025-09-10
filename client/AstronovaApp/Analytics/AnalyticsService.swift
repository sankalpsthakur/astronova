import Foundation
import os

/// Lightweight analytics abstraction with privacy-first defaults
protocol AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent, properties: [String: String]?)
}

enum AnalyticsEvent: String {
    case appLaunched = "app_launched"
    case onboardingViewed = "onboarding_viewed"
    case onboardingCompleted = "onboarding_completed"
    case homeViewed = "home_viewed"
    case paywallShown = "paywall_shown"
    case purchaseSuccess = "purchase_success"
    case notificationOptInPrompted = "notification_optin_prompted"
    case notificationOptedIn = "notification_opted_in"
}

final class Analytics: AnalyticsServiceProtocol {
    static let shared: AnalyticsServiceProtocol = Analytics()
    private let logger = Logger(subsystem: "com.astronova.app", category: "analytics")

    func track(_ event: AnalyticsEvent, properties: [String: String]? = nil) {
        #if DEBUG
        if let props = properties, !props.isEmpty {
            logger.debug("[ANALYTICS] \(event.rawValue, privacy: .public) props=\(String(describing: props), privacy: .public)")
        } else {
            logger.debug("[ANALYTICS] \(event.rawValue, privacy: .public)")
        }
        #else
        // In production, keep it minimal or forward to a provider if added later
        if let props = properties, !props.isEmpty {
            logger.log("\(event.rawValue, privacy: .public) props=\(String(describing: props), privacy: .private(mask: .hash))")
        } else {
            logger.log("\(event.rawValue, privacy: .public)")
        }
        #endif
    }
}

