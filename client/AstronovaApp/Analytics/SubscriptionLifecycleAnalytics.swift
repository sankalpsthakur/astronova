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

/// StoreKit-free input consumed by the lifecycle decision/state layer. Keeping
/// this boundary free of `Product.SubscriptionInfo.Status` lets unit tests
/// exercise transitions without an App Store account or StoreKit session.
struct SubscriptionStatusSnapshot: Equatable {
    enum State: Equatable {
        case subscribed
        case expired
        case revoked
        case gracePeriod
        case billingRetry
        case unknown
    }

    let sku: String
    let state: State
    let willAutoRenew: Bool?
}

enum SubscriptionStatusDecisionEngine {
    /// Returns only lifecycle transitions supported by the allow-listed event
    /// vocabulary. In particular, `.subscribed` is current access and never
    /// evidence of a renewal; renewal attribution requires a transaction ID.
    static func phases(for snapshot: SubscriptionStatusSnapshot) -> [SubscriptionLifecyclePhase] {
        var phases: [SubscriptionLifecyclePhase] = []

        switch snapshot.state {
        case .subscribed, .unknown:
            break
        case .expired:
            phases.append(.lapsed)
        case .revoked:
            phases.append(.refunded)
        case .gracePeriod:
            phases.append(.grace)
        case .billingRetry:
            phases.append(.billingRetry)
        }

        if snapshot.willAutoRenew == false {
            phases.append(.cancelled)
        }
        return phases
    }
}

/// Owns exactly one long-lived async observation task. The injected operation
/// is StoreKit-backed in production and AsyncStream-backed in unit tests.
@MainActor
final class SubscriptionStatusObserver {
    typealias Handler = @MainActor (SubscriptionStatusSnapshot) async -> Void
    typealias Observe = (@escaping Handler) async -> Void

    private let observe: Observe
    private var task: Task<Void, Never>?
    private var observationID: UUID?

    init(observe: @escaping Observe) {
        self.observe = observe
    }

    var isRunning: Bool { task != nil }

    @discardableResult
    func start(handler: @escaping Handler) -> Bool {
        guard task == nil else { return false }

        let id = UUID()
        observationID = id
        task = Task { [weak self, observe] in
            await observe { snapshot in
                guard !Task.isCancelled else { return }
                await handler(snapshot)
            }

            guard let self, self.observationID == id else { return }
            self.task = nil
            self.observationID = nil
        }
        return true
    }

    @discardableResult
    func cancel() -> Bool {
        guard let task else { return false }
        observationID = nil
        self.task = nil
        task.cancel()
        return true
    }

    deinit {
        task?.cancel()
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

    /// Applies one verified status snapshot and returns only newly-observed,
    /// deduplicated phases. Persisted values contain no account or profile data.
    func phasesToEmit(for snapshot: SubscriptionStatusSnapshot) -> [SubscriptionLifecyclePhase] {
        let candidates = SubscriptionStatusDecisionEngine.phases(for: snapshot)
        var phases: [SubscriptionLifecyclePhase] = []

        for phase in candidates {
            let channel = phase == .cancelled ? "auto_renew" : "renewal_state"
            if shouldEmitStatus(phase, sku: snapshot.sku, channel: channel) {
                phases.append(phase)
            }
        }

        if snapshot.state == .subscribed {
            markSubscribed(sku: snapshot.sku)
        }
        if snapshot.willAutoRenew == true {
            markAutoRenewEnabled(sku: snapshot.sku)
        }
        return phases
    }

    private func statusKey(for sku: String, channel: String) -> String {
        keyPrefix + "status." + channel + "." + sku
    }
}
