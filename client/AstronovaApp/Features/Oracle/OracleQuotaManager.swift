import Foundation
import SwiftUI

// MARK: - Oracle Quota Manager
// Single source of truth for daily limit + credits + subscription status

@MainActor
final class OracleQuotaManager: ObservableObject {
    static let shared = OracleQuotaManager()

    // MARK: - Published State

    @Published private(set) var dailyUsed: Int = 0
    @Published private(set) var hasSubscription: Bool = false
    @AppStorage("chat_credits") var credits: Int = 0

    // MARK: - Constants

    let dailyFreeLimit = 1  // One sacred question per day

    // MARK: - Debug Mode (bypass limits for local testing)

    private var isDebugMode: Bool {
        #if DEBUG
        return true
        #else
        return false
        #endif
    }

    // MARK: - Computed Properties

    var canAsk: Bool {
        if isDebugMode { return true }
        return hasSubscription || dailyUsed < dailyFreeLimit || credits > 0
    }

    var remainingFree: Int {
        if isDebugMode { return 999 }
        return max(0, dailyFreeLimit - dailyUsed)
    }

    var isLimited: Bool {
        if isDebugMode { return false }
        return !hasSubscription && dailyUsed >= dailyFreeLimit && credits == 0
    }

    var resetTime: Date {
        Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date())
    }

    var resetCountdown: String {
        let remaining = max(0, Int(resetTime.timeIntervalSince(Date())))
        let hours = remaining / 3600
        let minutes = (remaining % 3600) / 60
        if hours > 0 { return "\(hours)h \(minutes)m" }
        return "\(minutes)m"
    }

    // MARK: - Initialization

    private init() {
        loadDailyUsage()
        checkSubscription()
    }

    // MARK: - Public Methods

    /// Call after a successful message send
    func recordUsage(depth: OracleDepth = .quick) {
        guard !hasSubscription else { return }

        let cost = depth.creditCost

        if dailyUsed < dailyFreeLimit {
            // Use free quota first
            dailyUsed += 1
            saveDailyUsage()
        } else if credits >= cost {
            // Then use credits
            credits -= cost
        }
    }

    /// Check if user can afford a specific depth
    func canAfford(depth: OracleDepth) -> Bool {
        if hasSubscription { return true }
        if dailyUsed < dailyFreeLimit { return true }
        return credits >= depth.creditCost
    }

    /// Refresh subscription status
    func checkSubscription() {
        hasSubscription = UserDefaults.standard.bool(forKey: "hasAstronovaPro")
    }

    /// Reload daily usage (call on app foreground)
    func refresh() {
        loadDailyUsage()
        checkSubscription()
    }

    // MARK: - Private Methods

    private var todayKey: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return "oracle_daily_\(formatter.string(from: Date()))"
    }

    private func loadDailyUsage() {
        dailyUsed = UserDefaults.standard.integer(forKey: todayKey)
    }

    private func saveDailyUsage() {
        UserDefaults.standard.set(dailyUsed, forKey: todayKey)
    }
}

// MARK: - Oracle Depth

enum OracleDepth: String, CaseIterable {
    case quick = "Quick"
    case deep = "Deep"

    var creditCost: Int {
        switch self {
        case .quick: return 1
        case .deep: return 2
        }
    }

    var description: String {
        switch self {
        case .quick: return "Direct insight"
        case .deep: return "Detailed analysis + timing"
        }
    }

    var icon: String {
        switch self {
        case .quick: return "sparkle"
        case .deep: return "sparkles"
        }
    }
}
