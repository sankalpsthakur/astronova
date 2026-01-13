import Foundation
import os
#if canImport(SmartlookAnalytics)
import SmartlookAnalytics
#endif

/// Lightweight analytics abstraction with privacy-first defaults
protocol AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent, properties: [String: String]?)
}

enum AnalyticsEvent: String {
    // EXISTING EVENTS
    case appLaunched = "app_launched"
    case onboardingViewed = "onboarding_viewed"
    case onboardingCompleted = "onboarding_completed"
    case homeViewed = "home_viewed"
    case paywallShown = "paywall_shown"
    case purchaseSuccess = "purchase_success"
    case notificationOptInPrompted = "notification_optin_prompted"
    case notificationOptedIn = "notification_opted_in"

    // NEW AUTHENTICATION EVENTS
    case signInStarted = "sign_in_started"
    case signInSuccess = "sign_in_success"
    case signInFailed = "sign_in_failed"
    case signOut = "sign_out"
    case tokenExpired = "token_expired"
    case tokenRefreshSuccess = "token_refresh_success"
    case tokenRefreshFailed = "token_refresh_failed"
    case guestModeStarted = "guest_mode_started"
    case quickStartModeStarted = "quick_start_mode_started"

    // NEW FEATURE USAGE EVENTS
    case oracleChatSent = "oracle_chat_sent"
    case oracleChatReceived = "oracle_chat_received"
    case templeBookingStarted = "temple_booking_started"
    case templeBookingCompleted = "temple_booking_completed"
    case dashaTimelineViewed = "dasha_timeline_viewed"
    case compatibilityAnalyzed = "compatibility_analyzed"
    case chartGenerated = "chart_generated"

    // NEW ERROR TRACKING EVENTS
    case networkError = "network_error"
    case apiError = "api_error"
    case authenticationError = "authentication_error"
    case decodingError = "decoding_error"
}

final class Analytics: AnalyticsServiceProtocol {
    static let shared: AnalyticsServiceProtocol = Analytics()
    private let logger = Logger(subsystem: "com.astronova.app", category: "analytics")

    func track(_ event: AnalyticsEvent, properties: [String: String]? = nil) {
        // Skip tracking in UI test mode
        #if DEBUG
        if TestEnvironment.shared.isUITest {
            logger.debug("[ANALYTICS] Skipped (UI test mode): \(event.rawValue, privacy: .public)")
            return
        }
        #endif

        #if canImport(SmartlookAnalytics)
        // Track to Smartlook
        if let properties = properties, !properties.isEmpty {
            var smartlookProps = Properties()
            for (key, value) in properties {
                smartlookProps = smartlookProps.setProperty(key, to: value)
            }
            Smartlook.instance.track(event: event.rawValue, properties: smartlookProps)
            logger.debug("[ANALYTICS] ✅ Smartlook tracked: \(event.rawValue, privacy: .public) with \(properties.count) properties")
        } else {
            Smartlook.instance.track(event: event.rawValue)
            logger.debug("[ANALYTICS] ✅ Smartlook tracked: \(event.rawValue, privacy: .public)")
        }
        #else
        logger.warning("[ANALYTICS] ⚠️ Smartlook SDK not available - event logged locally only: \(event.rawValue, privacy: .public)")
        #endif

        // Keep debug logging
        #if DEBUG
        if let props = properties, !props.isEmpty {
            logger.debug("[ANALYTICS] \(event.rawValue, privacy: .public) props=\(String(describing: props), privacy: .public)")
        } else {
            logger.debug("[ANALYTICS] \(event.rawValue, privacy: .public)")
        }
        #endif
    }
}
