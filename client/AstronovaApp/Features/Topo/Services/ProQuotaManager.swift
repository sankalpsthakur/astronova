import Foundation
import SwiftUI

/// Tracks usage counters for the Pro-gated TopoSelf surfaces.
///
/// Free quotas (resettable on calendar boundary):
/// - Decision Simulator: 3 runs per calendar month
/// - Pattern Detail: 1 detail view per ISO week
/// - Journal Insights: 2 sessions per calendar month
///
/// Pro users have no quotas. Reads `StoreKitManager.shared.hasProSubscription`
/// indirectly via `@AppStorage("hasAstronovaPro")` so this stays a value type.
@MainActor
final class ProQuotaManager: ObservableObject {
    static let shared = ProQuotaManager()

    @AppStorage("hasAstronovaPro") private var hasPro: Bool = false

    @AppStorage("topo.quota.decision.month") private var decisionMonthKey: String = ""
    @AppStorage("topo.quota.decision.count") private var decisionCount: Int = 0

    @AppStorage("topo.quota.pattern.week") private var patternWeekKey: String = ""
    @AppStorage("topo.quota.pattern.count") private var patternCount: Int = 0

    @AppStorage("topo.quota.insights.month") private var insightsMonthKey: String = ""
    @AppStorage("topo.quota.insights.count") private var insightsCount: Int = 0

    static let decisionMonthlyLimit = 3
    static let patternWeeklyLimit = 1
    static let insightsMonthlyLimit = 2

    // MARK: - Decisions

    var decisionsUsedThisMonth: Int {
        rollDecisionWindow()
        return decisionCount
    }

    var canRunDecision: Bool {
        hasPro || decisionsUsedThisMonth < Self.decisionMonthlyLimit
    }

    var decisionsRemaining: Int {
        max(0, Self.decisionMonthlyLimit - decisionsUsedThisMonth)
    }

    func recordDecisionRun() {
        rollDecisionWindow()
        decisionCount += 1
        objectWillChange.send()
    }

    private func rollDecisionWindow() {
        let key = Self.monthKey()
        if decisionMonthKey != key {
            decisionMonthKey = key
            decisionCount = 0
        }
    }

    // MARK: - Pattern Detail

    var patternViewsUsedThisWeek: Int {
        rollPatternWindow()
        return patternCount
    }

    var canViewPatternDetail: Bool {
        hasPro || patternViewsUsedThisWeek < Self.patternWeeklyLimit
    }

    func recordPatternView() {
        rollPatternWindow()
        patternCount += 1
        objectWillChange.send()
    }

    private func rollPatternWindow() {
        let key = Self.weekKey()
        if patternWeekKey != key {
            patternWeekKey = key
            patternCount = 0
        }
    }

    // MARK: - Insights

    var insightsViewsUsedThisMonth: Int {
        rollInsightsWindow()
        return insightsCount
    }

    var canViewInsights: Bool {
        hasPro || insightsViewsUsedThisMonth < Self.insightsMonthlyLimit
    }

    func recordInsightsView() {
        rollInsightsWindow()
        insightsCount += 1
        objectWillChange.send()
    }

    private func rollInsightsWindow() {
        let key = Self.monthKey()
        if insightsMonthKey != key {
            insightsMonthKey = key
            insightsCount = 0
        }
    }

    // MARK: - Helpers

    static func monthKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(c.year ?? 0)-\(c.month ?? 0)"
    }

    static func weekKey(_ date: Date = Date()) -> String {
        let c = Calendar.current.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return "\(c.yearForWeekOfYear ?? 0)-W\(c.weekOfYear ?? 0)"
    }
}
