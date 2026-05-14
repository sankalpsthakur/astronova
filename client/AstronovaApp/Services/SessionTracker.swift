import Foundation
import UIKit
import Combine
import os

// MARK: - SessionTracker
//
// Lifecycle event router. Listens to UIApplication notifications and emits
// `app_open` / `session_start` / `session_end` events through both the
// existing Smartlook `Analytics` shim and the new `PortfolioAnalytics`
// pipeline.
//
// Session boundaries: per ANALYTICS_DESIGN §4, a new session starts after
// >30 minutes of background idle.

@MainActor
public final class SessionTracker {
    public static let shared = SessionTracker()

    private let logger = Logger(subsystem: "com.astronova.app", category: "session")
    private var bag = Set<AnyCancellable>()
    private var sessionStartedAt: Date?
    private var backgroundedAt: Date?
    private let sessionRolloverInterval: TimeInterval = 30 * 60 // 30 minutes

    public func start() {
        // Foreground → app_open (+ session_start if rolled over)
        NotificationCenter.default
            .publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in self?.handleForeground() }
            .store(in: &bag)

        // Background → session_end (lazy, paired with the actual rollover)
        NotificationCenter.default
            .publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in self?.handleBackground() }
            .store(in: &bag)

        // Manual first-launch trigger so the first app_open fires before
        // didBecomeActive notifications have a subscriber.
        handleForeground(coldStart: true)
    }

    private func handleForeground(coldStart: Bool = false) {
        let now = Date()
        let isColdStart = coldStart || sessionStartedAt == nil

        // app_open every time the app becomes active
        PortfolioAnalytics.shared.track(.appOpen, properties: [
            "cold_start": isColdStart ? "true" : "false"
        ])

        let didRollover: Bool = {
            guard let bg = backgroundedAt else { return false }
            return now.timeIntervalSince(bg) >= sessionRolloverInterval
        }()

        if isColdStart || didRollover {
            PortfolioAnalytics.shared.rotateSession()
            sessionStartedAt = now
            var props: [String: String] = [:]
            if let source = PortfolioAnalytics.shared.acquisitionSource,
               let ref = source["ref"] {
                props["acquisition_source_ref"] = ref
            }
            PortfolioAnalytics.shared.track(.sessionStart, properties: props)
        }

        // Cancel any lapsed notification — user is here.
        LapsedUserService.shared.recordAppOpen(now: now)
    }

    private func handleBackground() {
        let now = Date()
        backgroundedAt = now
        if let started = sessionStartedAt {
            let duration = Int(now.timeIntervalSince(started))
            PortfolioAnalytics.shared.track(.sessionEnd, properties: [
                "duration_s": String(duration)
            ])
        }
        // Schedule the anti-spoiler notification so it fires if the user
        // doesn't come back within the threshold.
        Task {
            await LapsedUserService.shared.scheduleAntiSpoilerNotification(now: now)
        }
        PortfolioAnalytics.shared.flush()
    }

    // MARK: - Test seam
    func _resetForTests() {
        sessionStartedAt = nil
        backgroundedAt = nil
        bag.removeAll()
    }
}
