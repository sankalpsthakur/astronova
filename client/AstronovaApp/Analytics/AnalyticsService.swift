import Foundation
import os
#if canImport(SmartlookAnalytics)
import SmartlookAnalytics
#endif

/// Lightweight analytics abstraction with privacy-first defaults
protocol AnalyticsServiceProtocol {
    func track(_ event: AnalyticsEvent, properties: [String: String]?)
}

enum AnalyticsConsentController {
    static var isOptedOut: Bool {
        PortfolioAnalytics.shared.isOptedOut
    }

    @discardableResult
    static func startSmartlookIfAllowed(projectKey: String) -> Bool {
        guard !isOptedOut else {
            applySmartlookConsent()
            return false
        }

        #if canImport(SmartlookAnalytics)
        Smartlook.instance.preferences.projectKey = projectKey
        Smartlook.instance.start()
        return true
        #else
        return false
        #endif
    }

    static func applySmartlookConsent(projectKey: String? = nil) {
        #if canImport(SmartlookAnalytics)
        if isOptedOut {
            Smartlook.instance.stop()
        } else if let projectKey {
            Smartlook.instance.preferences.projectKey = projectKey
            Smartlook.instance.start()
        }
        #endif
    }
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

    // GAMIFICATION / PROGRESSION
    case streakCheckIn = "streak_check_in"
    case cardUnlocked = "card_unlocked"
    case insightShared = "insight_shared"
    case journeyMilestoneUnlocked = "journey_milestone_unlocked"
    case retentionDay7 = "retention_day_7"
    case oracleActionCompleted = "oracle_action_completed"
    case activationOracleAction = "activation_oracle_action"
    case timeTravelSnapshotViewed = "time_travel_snapshot_viewed"
    case templeEngagementCompleted = "temple_engagement_completed"
    case weeklyChapterCompleted = "weekly_chapter_completed"
    case templeBellRung = "temple_bell_rung"
    case templeBellStreakBonus = "temple_bell_streak_bonus"
    case diyPoojaStarted = "diy_pooja_started"
    case diyPoojaStepCompleted = "diy_pooja_step_completed"
    case diyPoojaCompleted = "diy_pooja_completed"
    case muhuratChecked = "muhurat_checked"
    case vedicEntryRead = "vedic_entry_read"
    case weeklyChallengeCompleted = "weekly_challenge_completed"
    case paywallConversion = "paywall_conversion"

    // NEW ERROR TRACKING EVENTS
    case networkError = "network_error"
    case apiError = "api_error"
    case authenticationError = "authentication_error"
    case decodingError = "decoding_error"

    // WAVE 13 FEEDBACK LOOPS — portfolio-standard names mirrored locally so
    // existing Smartlook callsites continue to work while the new
    // PortfolioAnalytics pipeline catches the same events.
    case appOpen = "app_open"
    case sessionStart = "session_start"
    case sessionEnd = "session_end"
    case chartViewed = "chart_viewed"
    case oracleSessionStarted = "oracle_session_started"
    case oracleMessageSent = "oracle_message_sent"
    case paywallDismissed = "paywall_dismissed"
    case paywallConverted = "paywall_converted"
    case subscriptionStarted = "subscription_started"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionPaused = "subscription_paused"
    case iapPurchased = "iap_purchased"
    case referralSent = "referral_sent"
    case referralRedeemed = "referral_redeemed"
    case cosmicDiaryEntryCreated = "cosmic_diary_entry_created"
    case futureLetterScheduled = "future_letter_scheduled"
    case npsShown = "nps_shown"
    case npsSubmitted = "nps_submitted"
}

extension AnalyticsEvent {
    /// Map a Smartlook-side event into its portfolio-standard counterpart.
    /// Events that don't have a portfolio peer return nil and stay
    /// Smartlook-only.
    var portfolioCounterpart: PortfolioEvent? {
        switch self {
        case .appLaunched, .appOpen: return .appOpen
        case .sessionStart: return .sessionStart
        case .sessionEnd: return .sessionEnd
        case .chartGenerated, .chartViewed: return .chartViewed
        case .oracleSessionStarted: return .oracleSessionStarted
        case .oracleChatSent, .oracleMessageSent: return .oracleMessageSent
        case .paywallShown: return .paywallShown
        case .paywallDismissed: return .paywallDismissed
        case .paywallConversion, .paywallConverted: return .paywallConverted
        case .subscriptionStarted: return .subscriptionStarted
        case .subscriptionCancelled: return .subscriptionCancelled
        case .subscriptionPaused: return .subscriptionPaused
        case .iapPurchased, .purchaseSuccess: return .iapPurchased
        case .referralSent: return .referralSent
        case .referralRedeemed: return .referralRedeemed
        case .cosmicDiaryEntryCreated: return .cosmicDiaryEntryCreated
        case .futureLetterScheduled: return .futureLetterScheduled
        case .npsShown: return .npsShown
        case .npsSubmitted: return .npsSubmitted
        default: return nil
        }
    }
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

        guard !AnalyticsConsentController.isOptedOut else {
            logger.debug("[ANALYTICS] Skipped (analytics opt-out): \(event.rawValue, privacy: .public)")
            return
        }

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

        // Fan out to portfolio analytics (Wave 13 closed-loop)
        if let portfolioEvent = event.portfolioCounterpart {
            PortfolioAnalytics.shared.track(portfolioEvent, properties: properties ?? [:])
        }

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
