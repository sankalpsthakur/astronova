import Foundation
import os

// MARK: - PortfolioAnalytics
//
// In-app shim that mirrors the surface of the `IOSAppsAnalytics` Swift package
// (umbrella/analytics/IOSAppsAnalytics). Wave 13 lands the package as a real
// SPM dependency across the portfolio; until that integration lands, this
// file is the locally-vendored equivalent so events can be wired now.
//
// When the package becomes a real dependency, this file can be replaced with
// `import IOSAppsAnalytics` + `typealias PortfolioAnalytics = IOSAppsAnalytics`.
//
// Schema is defined in `umbrella/analytics/ANALYTICS_DESIGN.md`.

/// Standardized event names. New events must be added to ANALYTICS_DESIGN.md
/// first per the design's update rule.
public enum PortfolioEvent: String, CaseIterable, Codable {
    // Lifecycle
    case appOpen = "app_open"
    case sessionStart = "session_start"
    case sessionEnd = "session_end"

    // App-specific core actions
    case chartViewed = "chart_viewed"

    // Oracle (Astronova-specific premium loop)
    case oracleSessionStarted = "oracle_session_started"
    case oracleMessageSent = "oracle_message_sent"

    // Cosmic Diary / Future Letter (deferred features, events declared so
    // wiring exists when the surfaces land — see follow-ups in progress doc)
    case cosmicDiaryEntryCreated = "cosmic_diary_entry_created"
    case futureLetterScheduled = "future_letter_scheduled"

    // Monetization
    case paywallShown = "paywall_shown"
    case paywallDismissed = "paywall_dismissed"
    case paywallConverted = "paywall_converted"
    case subscriptionStarted = "subscription_started"
    case subscriptionCancelled = "subscription_cancelled"
    case subscriptionPaused = "subscription_paused"
    case iapPurchased = "iap_purchased"

    // Growth
    case referralSent = "referral_sent"
    case referralRedeemed = "referral_redeemed"
    case featureUsed = "feature_used"

    // In-app feedback (Wave 13)
    case npsShown = "nps_shown"
    case npsSubmitted = "nps_submitted"

    // Reviews
    case reviewPromptShown = "review_prompt_shown"

    // Re-engagement
    case lapsedReengagementScheduled = "lapsed_reengagement_scheduled"
    case lapsedReengagementOpened = "lapsed_reengagement_opened"

    // FTUE funnel (Wave 13 — UX_FRAMEWORK G7)
    case ftueStep = "ftue_step"
}

public enum PortfolioAppID: String, Codable {
    case astronova
    case cram
    case flash
    case sadhana
    case variant
    case skin
}

/// JSON-serializable analytics envelope per ANALYTICS_DESIGN §3.
struct PortfolioAnalyticsEvent: Codable {
    let eventName: String
    let appID: String
    let userID: String
    let timestamp: String
    let sessionID: String
    let experimentBuckets: [String: String]
    let properties: [String: String] // forced string-coerce on dispatch

    enum CodingKeys: String, CodingKey {
        case eventName = "event_name"
        case appID = "app_id"
        case userID = "user_id"
        case timestamp
        case sessionID = "session_id"
        case experimentBuckets = "experiment_buckets"
        case properties
    }
}

/// Public SDK entry point. Singleton-scoped for the host app's lifetime.
/// Mirrors `IOSAppsAnalytics.shared` in `umbrella/analytics/IOSAppsAnalytics`.
public final class PortfolioAnalytics {
    public static let shared = PortfolioAnalytics()

    // MARK: - Configuration

    private(set) var appID: PortfolioAppID?
    private(set) var endpoint: URL?
    private(set) var sessionID = UUID().uuidString
    private var experimentBuckets: [String: String] = [:]
    private var buffer: [PortfolioAnalyticsEvent] = []
    private var flushTimer: Timer?
    private let queue = DispatchQueue(label: "com.astronova.portfolio-analytics", qos: .utility)
    private let logger = Logger(subsystem: "com.astronova.app", category: "portfolio-analytics")

    /// Flush interval (seconds) per ANALYTICS_DESIGN §7.
    public var flushInterval: TimeInterval = 30
    /// Max batch size that triggers an immediate flush regardless of timer.
    public var maxBatchSize: Int = 100

    /// Optional test hook — set in unit tests so we can assert without a server.
    var testEventSink: ((PortfolioEvent, [String: String]) -> Void)?

    // MARK: - Opt-out

    private let optOutKey = "portfolio_analytics_opted_out"
    private let userIDKey = "portfolio_analytics_user_id"
    private let firstLaunchKey = "portfolio_analytics_first_launch_at"
    private let acquisitionSourceKey = "portfolio_analytics_acquisition_source"

    public var isOptedOut: Bool {
        get { UserDefaults.standard.bool(forKey: optOutKey) }
        set {
            UserDefaults.standard.set(newValue, forKey: optOutKey)
            if newValue {
                // Per privacy doctrine: drop buffered events and rotate UUID.
                queue.async { [weak self] in
                    self?.buffer.removeAll()
                }
                UserDefaults.standard.removeObject(forKey: userIDKey)
            }
        }
    }

    /// Stable per-device UUID v4 — regenerated whenever opt-out flips back on.
    public var userID: String {
        if let cached = UserDefaults.standard.string(forKey: userIDKey) {
            return cached
        }
        let new = UUID().uuidString
        UserDefaults.standard.set(new, forKey: userIDKey)
        return new
    }

    private init() {}

    /// Configure on app launch. Idempotent.
    public func configure(appID: PortfolioAppID, endpoint: URL? = nil) {
        self.appID = appID
        self.endpoint = endpoint
        startFlushTimer()
    }

    public func rotateSession() {
        sessionID = UUID().uuidString
    }

    public func setExperimentBucket(_ key: String, value: String) {
        experimentBuckets[key] = value
    }

    public func experimentBucket(for key: String) -> String? {
        experimentBuckets[key]
    }

    public func setAcquisitionSource(_ source: [String: String]) {
        // Only stamped on the very first launch — never overwritten.
        guard UserDefaults.standard.dictionary(forKey: acquisitionSourceKey) == nil else { return }
        UserDefaults.standard.set(source, forKey: acquisitionSourceKey)
        UserDefaults.standard.set(ISO8601DateFormatter().string(from: Date()), forKey: firstLaunchKey)
    }

    public var acquisitionSource: [String: String]? {
        UserDefaults.standard.dictionary(forKey: acquisitionSourceKey) as? [String: String]
    }

    // MARK: - Track

    /// Emit an event. Properties are coerced to `String` for transport per §3.
    public func track(_ event: PortfolioEvent, properties: [String: String] = [:]) {
        // Opt-out gate at every call.
        guard !isOptedOut else { return }

        if let sink = testEventSink {
            sink(event, properties)
            return
        }

        #if DEBUG
        logger.debug("[PortfolioAnalytics] \(event.rawValue, privacy: .public) \(properties.description, privacy: .public)")
        // Debug builds do not ship to the network per ANALYTICS_DESIGN §2 hardening.
        return
        #else
        guard let appID = appID else { return }
        let stamped = stamp(properties: properties)
        let env = PortfolioAnalyticsEvent(
            eventName: event.rawValue,
            appID: appID.rawValue,
            userID: userID,
            timestamp: Self.iso8601.string(from: Date()),
            sessionID: sessionID,
            experimentBuckets: experimentBuckets,
            properties: stamped
        )
        queue.async { [weak self] in
            guard let self = self else { return }
            self.buffer.append(env)
            if self.buffer.count >= self.maxBatchSize {
                self.flushLocked()
            }
        }
        #endif
    }

    private func stamp(properties: [String: String]) -> [String: String] {
        var out = properties
        // Stamp acquisition_source on monetization events so cohort LTV can
        // group on it forever — per ANALYTICS_DESIGN §5.2.
        if let source = acquisitionSource {
            for (k, v) in source {
                out["acquisition_source_\(k)"] = v
            }
        }
        return out
    }

    // MARK: - Flush

    private func startFlushTimer() {
        flushTimer?.invalidate()
        let timer = Timer(timeInterval: flushInterval, repeats: true) { [weak self] _ in
            self?.queue.async { self?.flushLocked() }
        }
        RunLoop.main.add(timer, forMode: .common)
        flushTimer = timer
    }

    /// Public manual flush (test or app-background hook).
    public func flush() {
        queue.async { [weak self] in self?.flushLocked() }
    }

    private func flushLocked() {
        guard let endpoint = endpoint, !buffer.isEmpty else { return }
        let batch = buffer
        buffer.removeAll()

        var req = URLRequest(url: endpoint)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try? JSONEncoder().encode(["events": batch])

        URLSession.shared.dataTask(with: req) { [weak self] _, response, error in
            // On any failure, re-append the batch so we retry next cycle.
            if error != nil || ((response as? HTTPURLResponse)?.statusCode ?? 0) >= 400 {
                self?.queue.async {
                    self?.buffer.append(contentsOf: batch)
                }
            }
        }.resume()
    }

    // MARK: - Test seam

    /// Reset persistent state. Called from unit tests only.
    func _resetForTests() {
        let d = UserDefaults.standard
        d.removeObject(forKey: optOutKey)
        d.removeObject(forKey: userIDKey)
        d.removeObject(forKey: firstLaunchKey)
        d.removeObject(forKey: acquisitionSourceKey)
        queue.sync {
            buffer.removeAll()
        }
        sessionID = UUID().uuidString
        experimentBuckets.removeAll()
        testEventSink = nil
    }

    // MARK: - Helpers

    private static let iso8601: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
}
