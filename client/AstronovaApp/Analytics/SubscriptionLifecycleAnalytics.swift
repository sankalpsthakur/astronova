import Foundation
import StoreKit

/// Maps StoreKit subscription phases onto allow-listed PortfolioAnalytics events.
/// Used for renew/cancel/grace/lapse/refund observability (story 41).
enum SubscriptionLifecyclePhase: String, CaseIterable {
    case trialStarted = "trial_started"
    case paidStarted = "paid_started"
    case renewed = "renewed"
    case cancelled = "cancelled"
    case grace = "grace"
    case billingRetry = "billing_retry"
    case lapsed = "lapsed"
    case refunded = "refunded"
}

enum SubscriptionLifecycleAnalytics {
    /// Convert a lifecycle phase to PortfolioEvent + properties (no PII).
    static func event(for phase: SubscriptionLifecyclePhase, sku: String? = nil) -> (PortfolioEvent, [String: String]) {
        var props: [String: String] = ["phase": phase.rawValue]
        if let sku, !sku.isEmpty {
            props["sku"] = sku
        }
        let event: PortfolioEvent
        switch phase {
        case .trialStarted:
            event = .trialStarted
        case .paidStarted:
            event = .subscriptionStarted
        case .renewed:
            event = .subscriptionRenewed
        case .cancelled:
            event = .subscriptionCancelled
        case .grace:
            event = .subscriptionGrace
        case .billingRetry:
            event = .subscriptionBillingRetry
        case .lapsed:
            event = .subscriptionLapsed
        case .refunded:
            event = .subscriptionRefunded
        }
        return (event, props)
    }

    static func emit(_ phase: SubscriptionLifecyclePhase, sku: String? = nil) {
        let (event, props) = event(for: phase, sku: sku)
        PortfolioAnalytics.shared.track(event, properties: props)
    }

    /// Best-effort mapping from Product.SubscriptionInfo.Status-like renewal states.
    /// Accepts both bare cases (`subscribed`) and `String(describing:)` forms.
    static func phase(fromRenewalState raw: String) -> SubscriptionLifecyclePhase? {
        let s = raw.lowercased()
        if s == "subscribed" || s.hasSuffix(".subscribed") { return .renewed }
        if s == "expired" || s.hasSuffix(".expired")
            || s == "revoked" || s.hasSuffix(".revoked") { return .lapsed }
        if s.contains("billingretry") || s.contains("billing_retry") { return .billingRetry }
        if s.contains("graceperiod") || s.contains("grace_period") { return .grace }
        if s == "cancelled" || s == "canceled"
            || s.hasSuffix(".cancelled") || s.hasSuffix(".canceled") { return .cancelled }
        return nil
    }
}
