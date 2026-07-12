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
        // A subscribed status proves current access, not that a renewal just
        // happened. Renewal attribution requires a new transaction ID.
        if s == "subscribed" || s.hasSuffix(".subscribed") { return nil }
        if s == "expired" || s.hasSuffix(".expired") { return .lapsed }
        if s == "revoked" || s.hasSuffix(".revoked") { return .refunded }
        if s.contains("billingretry") || s.contains("billing_retry") { return .billingRetry }
        if s.contains("graceperiod") || s.contains("grace_period") { return .grace }
        if s == "cancelled" || s == "canceled"
            || s.hasSuffix(".cancelled") || s.hasSuffix(".canceled") { return .cancelled }
        return nil
    }
}

/// Persists the minimum state needed to avoid replaying lifecycle analytics.
/// Values contain only StoreKit product/transaction identifiers and phases;
/// no account, birth, or free-text data is stored.
struct SubscriptionLifecycleStateStore {
    private let defaults: UserDefaults
    private let keyPrefix: String
    private let transactionHistoryLimit = 50

    init(
        defaults: UserDefaults = .standard,
        keyPrefix: String = "astronova.subscription.lifecycle."
    ) {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    func shouldEmitTransaction(
        _ phase: SubscriptionLifecyclePhase,
        sku: String,
        transactionID: UInt64
    ) -> Bool {
        let key = keyPrefix + "transactions"
        let fingerprint = "\(phase.rawValue)|\(sku)|\(transactionID)"
        var history = defaults.stringArray(forKey: key) ?? []
        guard !history.contains(fingerprint) else { return false }

        history.append(fingerprint)
        if history.count > transactionHistoryLimit {
            history.removeFirst(history.count - transactionHistoryLimit)
        }
        defaults.set(history, forKey: key)
        return true
    }

    func shouldEmitStatus(
        _ phase: SubscriptionLifecyclePhase,
        sku: String,
        channel: String = "renewal_state"
    ) -> Bool {
        let key = statusKey(for: sku, channel: channel)
        guard defaults.string(forKey: key) != phase.rawValue else { return false }
        defaults.set(phase.rawValue, forKey: key)
        return true
    }

    func markSubscribed(sku: String) {
        defaults.set("subscribed", forKey: statusKey(for: sku, channel: "renewal_state"))
    }

    func markAutoRenewEnabled(sku: String) {
        defaults.set("enabled", forKey: statusKey(for: sku, channel: "auto_renew"))
    }

    private func statusKey(for sku: String, channel: String) -> String {
        keyPrefix + "status." + channel + "." + sku
    }
}
