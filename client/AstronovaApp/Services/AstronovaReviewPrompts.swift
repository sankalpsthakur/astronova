import Foundation
import StoreKit
import SwiftUI
import os

// MARK: - AstronovaReviewPrompts
//
// Peak-moment review-prompt service. Wraps `SKStoreReviewController` /
// `AppStore.requestReview()` with an app-level throttle layered on top of
// Apple's built-in once-per-365-days cap. We additionally throttle to a more
// conservative once-per-6-months and only fire after a documented peak
// experience (see Feedback Loops L3).
//
// Mirrors the planned `IOSAppsReviewPrompts` SPM package surface so callsites
// can be wired today and the implementation can be swapped later.

public enum AstronovaReviewPeak: String, Codable {
    case firstChartCompleted = "first_chart_completed"
    case oracleSessionFifth = "oracle_session_5"
    case templeBellStreak = "temple_bell_streak"
    case firstCosmicDiaryEntry = "first_cosmic_diary_entry"
}

@MainActor
public final class AstronovaReviewPrompts {
    public static let shared = AstronovaReviewPrompts()

    private let logger = Logger(subsystem: "com.astronova.app", category: "review-prompts")
    private let lastShownKey = "astronova_review_prompt_last_shown_at"
    private let peakKey = "astronova_review_prompt_peak"
    private let throttle: TimeInterval = 60 * 60 * 24 * 30 * 6 // 6 months

    private init() {}

    /// Request a review prompt — but only if (a) it has been at least 6 months
    /// since the last prompt and (b) we haven't already shown for this peak.
    /// Apple still enforces its own per-year cap underneath.
    public func requestIfPeak(_ peak: AstronovaReviewPeak) {
        #if DEBUG
        guard !TestEnvironment.shared.isUITest else {
            logger.debug("[review-prompt] suppressed during UI tests for peak=\(peak.rawValue, privacy: .public)")
            return
        }
        #endif

        guard shouldRequest(for: peak) else {
            logger.debug("[review-prompt] throttled for peak=\(peak.rawValue, privacy: .public)")
            return
        }

        recordRequest(for: peak)
        PortfolioAnalytics.shared.track(.reviewPromptShown, properties: ["peak": peak.rawValue])

        if #available(iOS 18.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive })
                as? UIWindowScene {
                AppStore.requestReview(in: scene)
            }
        } else if #available(iOS 16.0, *) {
            if let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive })
                as? UIWindowScene {
                SKStoreReviewController.requestReview(in: scene)
            }
        } else {
            SKStoreReviewController.requestReview()
        }
    }

    // MARK: - Throttle logic (extracted for unit testing)

    func shouldRequest(for peak: AstronovaReviewPeak, now: Date = Date()) -> Bool {
        let d = UserDefaults.standard

        // Per-peak one-shot.
        if let lastPeak = d.string(forKey: peakKey), lastPeak == peak.rawValue {
            return false
        }

        // Global throttle window.
        let lastShown = d.double(forKey: lastShownKey)
        guard lastShown > 0 else { return true }
        return now.timeIntervalSince1970 - lastShown >= throttle
    }

    private func recordRequest(for peak: AstronovaReviewPeak) {
        let d = UserDefaults.standard
        d.set(Date().timeIntervalSince1970, forKey: lastShownKey)
        d.set(peak.rawValue, forKey: peakKey)
    }

    // MARK: - Test seam

    func _resetForTests() {
        let d = UserDefaults.standard
        d.removeObject(forKey: lastShownKey)
        d.removeObject(forKey: peakKey)
    }
}
