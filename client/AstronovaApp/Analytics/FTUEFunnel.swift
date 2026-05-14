import Foundation

// MARK: - FTUEFunnel (Astronova)
//
// Wave 13. Per UX_FRAMEWORK G7, FTUE is the single highest-leverage
// retention point. This file declares Astronova's canonical FTUE funnel
// and provides a single emission point so all FTUE call sites stamp the
// same shape of properties (compulsory for the dashboard to compute
// drop-off honestly).
//
// Funnel definition (matches `progress/wave13-ftue.md`):
//   1. app_open               — cold-launch reached
//   2. onboarding_step1       — first onboarding screen seen
//   3. birth_data_entered     — natal data captured
//   4. first_chart_generated  — chart rendered to screen
//   5. first_oracle_query     — Shastriji prompt sent (skippable)
//   6. first_session_complete — user exits cold without crash/error
//
// Each `record` call emits `PortfolioEvent.ftueStep` with the properties
// agreed across the portfolio:
//   step_index, step_name, total_steps, time_since_install_seconds,
//   ftue_label = "ftue_step_<n>_<name>".

public enum AstronovaFTUEStep: Int, CaseIterable {
    case appOpen = 1
    case onboardingStep1 = 2
    case birthDataEntered = 3
    case firstChartGenerated = 4
    case firstOracleQuery = 5
    case firstSessionComplete = 6

    public var slug: String {
        switch self {
        case .appOpen: return "app_open"
        case .onboardingStep1: return "onboarding_step1"
        case .birthDataEntered: return "birth_data_entered"
        case .firstChartGenerated: return "first_chart_generated"
        case .firstOracleQuery: return "first_oracle_query"
        case .firstSessionComplete: return "first_session_complete"
        }
    }

    public var isSkippable: Bool {
        // Oracle is the only optional gate in this funnel.
        self == .firstOracleQuery
    }

    public static var totalSteps: Int { allCases.count }
}

public final class AstronovaFTUEFunnel {
    public static let shared = AstronovaFTUEFunnel()

    private let defaults: UserDefaults
    private let analytics: PortfolioAnalytics
    private let firstLaunchKey = "astronova.ftue.firstLaunchAt"
    private let stepRecordedPrefix = "astronova.ftue.step."

    public init(
        defaults: UserDefaults = .standard,
        analytics: PortfolioAnalytics = .shared
    ) {
        self.defaults = defaults
        self.analytics = analytics
    }

    /// Marks the canonical install timestamp. Safe to call repeatedly —
    /// only the first invocation persists.
    public func markInstallIfNeeded() {
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date(), forKey: firstLaunchKey)
        }
    }

    /// Records a single funnel step. Idempotent per (step, install) so
    /// repeated entry into a screen does not inflate completion counts.
    public func record(_ step: AstronovaFTUEStep) {
        markInstallIfNeeded()
        let key = stepRecordedPrefix + step.slug
        guard !defaults.bool(forKey: key) else { return }
        defaults.set(true, forKey: key)

        let firstLaunch = (defaults.object(forKey: firstLaunchKey) as? Date) ?? Date()
        let dt = max(0, Int(Date().timeIntervalSince(firstLaunch)))

        analytics.track(.ftueStep, properties: [
            "step_index": String(step.rawValue),
            "step_name": step.slug,
            "total_steps": String(AstronovaFTUEStep.totalSteps),
            "time_since_install_seconds": String(dt),
            "ftue_label": "ftue_step_\(step.rawValue)_\(step.slug)",
            "skippable": step.isSkippable ? "true" : "false",
            "app": "astronova"
        ])
    }

    /// Inspection seam for tests / debug overlays.
    public func hasRecorded(_ step: AstronovaFTUEStep) -> Bool {
        defaults.bool(forKey: stepRecordedPrefix + step.slug)
    }

    /// Reset for tests + the "reset onboarding" debug switch.
    public func _resetForTests() {
        for step in AstronovaFTUEStep.allCases {
            defaults.removeObject(forKey: stepRecordedPrefix + step.slug)
        }
        defaults.removeObject(forKey: firstLaunchKey)
    }
}
