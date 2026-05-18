import Foundation
import Combine
import os

// MARK: - NPSService
//
// Peak-moment in-app NPS — 1 question, 0–10 slider, optional comment.
// Surface trigger rules per Wave 13 brief:
//   - After Oracle session #5
//   - After first Cosmic Diary entry created
// Cap once per 6 months globally (parallel to review prompt window).
// Emits `nps_shown` on present and `nps_submitted` on submit.

public enum NPSTrigger: String, Codable {
    case oracleSession5 = "oracle_session_5"
    case firstCosmicDiaryEntry = "first_cosmic_diary_entry"
}

@MainActor
public final class NPSService: ObservableObject {
    public static let shared = NPSService()

    private let oracleSessionsKey = "astronova_oracle_session_count"
    private let cosmicDiaryEntriesKey = "astronova_cosmic_diary_entry_count"
    private let lastNPSShownKey = "astronova_nps_last_shown_at"
    private let lastNPSTriggerKey = "astronova_nps_last_trigger"
    private let throttle: TimeInterval = 60 * 60 * 24 * 30 * 6 // 6 months
    private let logger = Logger(subsystem: "com.astronova.app", category: "nps")

    /// SwiftUI sheet driver. When non-nil, present the NPS sheet.
    @Published public var pendingTrigger: NPSTrigger?

    private init() {}

    // MARK: - Counters

    /// Call from OracleViewModel after a successful response is appended.
    @discardableResult
    public func recordOracleSession() -> Bool {
        let count = UserDefaults.standard.integer(forKey: oracleSessionsKey) + 1
        UserDefaults.standard.set(count, forKey: oracleSessionsKey)
        if count == 5 && shouldSurface(.oracleSession5) {
            surface(.oracleSession5)
            return true
        }
        return false
    }

    /// Call once when the user creates their first Cosmic Diary entry.
    @discardableResult
    public func recordCosmicDiaryEntry() -> Bool {
        let count = UserDefaults.standard.integer(forKey: cosmicDiaryEntriesKey) + 1
        UserDefaults.standard.set(count, forKey: cosmicDiaryEntriesKey)
        if count == 1 && shouldSurface(.firstCosmicDiaryEntry) {
            surface(.firstCosmicDiaryEntry)
            return true
        }
        return false
    }

    public var oracleSessionCount: Int {
        UserDefaults.standard.integer(forKey: oracleSessionsKey)
    }

    public var cosmicDiaryEntryCount: Int {
        UserDefaults.standard.integer(forKey: cosmicDiaryEntriesKey)
    }

    // MARK: - Gating

    func shouldSurface(_ trigger: NPSTrigger, now: Date = Date()) -> Bool {
        let d = UserDefaults.standard
        // Don't double-fire the same trigger.
        if d.string(forKey: lastNPSTriggerKey) == trigger.rawValue {
            return false
        }
        let lastShown = d.double(forKey: lastNPSShownKey)
        guard lastShown > 0 else { return true }
        return now.timeIntervalSince1970 - lastShown >= throttle
    }

    private func surface(_ trigger: NPSTrigger) {
        pendingTrigger = trigger
        PortfolioAnalytics.shared.track(.npsShown, properties: ["trigger": trigger.rawValue])
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: lastNPSShownKey)
        UserDefaults.standard.set(trigger.rawValue, forKey: lastNPSTriggerKey)
    }

    // MARK: - Submit

    public func submit(score: Int, comment: String, trigger: NPSTrigger) {
        var props: [String: String] = [
            "score": String(score),
            "trigger": trigger.rawValue,
            "has_comment": comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "false" : "true"
        ]
        // Bucket the score per ANALYTICS_DESIGN forbidden-rule on raw text —
        // comment text is NOT shipped; only its presence is logged.
        props["bucket"] = score >= 9 ? "promoter" : score >= 7 ? "passive" : "detractor"
        PortfolioAnalytics.shared.track(.npsSubmitted, properties: props)
        pendingTrigger = nil

        // Comment goes to local storage only; never to analytics.
        if !comment.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            var existing = UserDefaults.standard.array(forKey: "astronova_nps_comments") as? [[String: String]] ?? []
            existing.append([
                "score": String(score),
                "comment": comment,
                "trigger": trigger.rawValue,
                "at": ISO8601DateFormatter().string(from: Date())
            ])
            UserDefaults.standard.set(existing, forKey: "astronova_nps_comments")
        }
    }

    public func dismiss() {
        pendingTrigger = nil
    }

    // MARK: - Test seam

    func _resetForTests() {
        let d = UserDefaults.standard
        d.removeObject(forKey: oracleSessionsKey)
        d.removeObject(forKey: cosmicDiaryEntriesKey)
        d.removeObject(forKey: lastNPSShownKey)
        d.removeObject(forKey: lastNPSTriggerKey)
        d.removeObject(forKey: "astronova_nps_comments")
        pendingTrigger = nil
    }
}
