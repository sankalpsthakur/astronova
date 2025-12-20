//
//  TestEnvironment.swift
//  AstronovaApp
//
//  UI Test Launch Harness for deterministic E2E testing
//

import Foundation
import SwiftUI
import Security

/// Launch arguments for UI testing
enum TestLaunchArgument: String {
    case reset = "UITEST_RESET"
    case seedProfileFull = "UITEST_SEED_PROFILE_FULL"
    case seedProfileMinimal = "UITEST_SEED_PROFILE_MINIMAL"
    case setFreeLimitReached = "UITEST_SET_FREE_LIMIT_REACHED"
    case setChatCredits = "UITEST_SET_CHAT_CREDITS"
    case setProSubscribed = "UITEST_SET_PRO_SUBSCRIBED"
    case skipOnboarding = "UITEST_SKIP_ONBOARDING"
    case mockPurchases = "UITEST_MOCK_PURCHASES"
    case enableLogging = "UITEST_ENABLE_LOGGING"
}

/// Environment keys for passing test values
enum TestEnvironmentKey: String {
    case chatCreditsValue = "UITEST_CHAT_CREDITS_VALUE"
    case dailyMessageCount = "UITEST_DAILY_MESSAGE_COUNT"
}

/// Handles UI test launch arguments for deterministic test state
final class TestEnvironment {
    static let shared = TestEnvironment()

    private let processInfo = ProcessInfo.processInfo

    /// Whether the app is running in UI test mode
    var isUITest: Bool {
        hasArgument(.reset) ||
        hasArgument(.seedProfileFull) ||
        hasArgument(.seedProfileMinimal) ||
        hasArgument(.setFreeLimitReached) ||
        hasArgument(.setChatCredits) ||
        hasArgument(.setProSubscribed) ||
        hasArgument(.skipOnboarding) ||
        hasArgument(.mockPurchases) ||
        hasArgument(.enableLogging)
    }

    /// Check if a launch argument is present
    func hasArgument(_ arg: TestLaunchArgument) -> Bool {
        processInfo.arguments.contains(arg.rawValue)
    }

    /// Get environment variable value
    func getValue(for key: TestEnvironmentKey) -> String? {
        processInfo.environment[key.rawValue]
    }

    /// Get integer value from environment
    func getIntValue(for key: TestEnvironmentKey, default defaultValue: Int = 0) -> Int {
        guard let stringValue = getValue(for: key),
              let intValue = Int(stringValue) else {
            return defaultValue
        }
        return intValue
    }

    /// Apply test configuration to the app state
    func applyTestConfiguration() {
        guard isUITest else { return }

        log("Applying UI test configuration...")

        // Reset all state if requested
        if hasArgument(.reset) {
            resetAllState()
        }

        // Seed profile data
        if hasArgument(.seedProfileFull) {
            seedFullProfile()
        } else if hasArgument(.seedProfileMinimal) {
            seedMinimalProfile()
        }

        // Set free limit reached state
        if hasArgument(.setFreeLimitReached) {
            setFreeLimitReached()
        }

        // Set chat credits
        if hasArgument(.setChatCredits) {
            let credits = getIntValue(for: .chatCreditsValue, default: 10)
            setChatCredits(credits)
        }

        // Set pro subscription
        if hasArgument(.setProSubscribed) {
            setProSubscribed()
        }

        // Skip onboarding
        if hasArgument(.skipOnboarding) {
            skipOnboarding()
        }

        // Enable mock purchases
        if hasArgument(.mockPurchases) {
            enableMockPurchases()
        }

        log("UI test configuration applied")
    }

    // MARK: - Private Configuration Methods

    private func resetAllState() {
        log("Resetting all app state...")

        // Clear Keychain-backed auth state (e.g., JWT)
        clearAuthKeychain()

        // Clear UserDefaults
        let domain = Bundle.main.bundleIdentifier ?? "com.sankalp.AstronovaApp"
        UserDefaults.standard.removePersistentDomain(forName: domain)
        UserDefaults.standard.synchronize()

        // Clear specific app storage keys
        let keysToReset = [
            "has_signed_in",
            "is_anonymous_user",
            "is_quick_start_user",
            "chat_credits",
            "daily_message_count",
            "last_message_date",
            "is_pro_subscriber",
            "onboarding_complete",
            "user_profile",
            "trigger_show_report_shop",
            "trigger_show_chat_packages"
        ]

        for key in keysToReset {
            UserDefaults.standard.removeObject(forKey: key)
        }

        UserDefaults.standard.synchronize()
        log("State reset complete")
    }

    private func clearAuthKeychain() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: "com.sankalp.AstronovaApp.jwtToken"
        ]

        SecItemDelete(query as CFDictionary)
    }

    private func seedFullProfile() {
        log("Seeding full profile...")

        let calendar = Calendar(identifier: .gregorian)

        let birthDate = calendar.date(from: DateComponents(year: 1990, month: 6, day: 15)) ?? Date()
        let birthTime = calendar.date(from: DateComponents(year: 1990, month: 6, day: 15, hour: 14, minute: 30))

        var profile = UserProfile(
            fullName: "Test User",
            birthDate: birthDate,
            birthTime: birthTime,
            birthPlace: "New York, NY, USA",
            birthLatitude: 40.7128,
            birthLongitude: -74.0060,
            timezone: "America/New_York"
        )

        // Optional niceties for realism
        profile.sunSign = "Gemini"

        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "user_profile")
        }

        // Force the app into the signed-in experience for UI tests
        UserDefaults.standard.set(true, forKey: "has_signed_in")
        UserDefaults.standard.set(true, forKey: "is_anonymous_user")
        UserDefaults.standard.set(true, forKey: "has_seen_tab_guide")
        UserDefaults.standard.synchronize()
    }

    private func seedMinimalProfile() {
        log("Seeding minimal profile...")

        let calendar = Calendar(identifier: .gregorian)
        let birthDate = calendar.date(from: DateComponents(year: 1990, month: 6, day: 15)) ?? Date()

        let profile = UserProfile(fullName: "Test User", birthDate: birthDate, birthTime: nil)
        if let data = try? JSONEncoder().encode(profile) {
            UserDefaults.standard.set(data, forKey: "user_profile")
        }

        // Signed-in, but intentionally incomplete profile
        UserDefaults.standard.set(true, forKey: "has_signed_in")
        UserDefaults.standard.set(true, forKey: "is_anonymous_user")
        UserDefaults.standard.set(true, forKey: "has_seen_tab_guide")
        UserDefaults.standard.synchronize()
    }

    private func setFreeLimitReached() {
        log("Setting free limit reached...")

        let maxFreeMessages = 5
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let key = "dailyMessageCount_\(today)"
        UserDefaults.standard.set(maxFreeMessages, forKey: key)

        UserDefaults.standard.synchronize()
    }

    private func setChatCredits(_ credits: Int) {
        log("Setting chat credits to \(credits)...")
        UserDefaults.standard.set(credits, forKey: "chat_credits")
        UserDefaults.standard.synchronize()
    }

    private func setProSubscribed() {
        log("Setting Pro subscription active...")
        UserDefaults.standard.set(true, forKey: "hasAstronovaPro")
        UserDefaults.standard.synchronize()
    }

    private func skipOnboarding() {
        log("Skipping onboarding...")
        UserDefaults.standard.set(true, forKey: "has_signed_in")
        UserDefaults.standard.set(true, forKey: "is_anonymous_user")
        UserDefaults.standard.set(true, forKey: "has_seen_tab_guide")
        UserDefaults.standard.synchronize()
    }

    private func enableMockPurchases() {
        log("Enabling mock purchases...")
        UserDefaults.standard.set(true, forKey: "mock_purchases_enabled")
        UserDefaults.standard.synchronize()
    }

    // MARK: - Logging

    private func log(_ message: String) {
        #if DEBUG
        if hasArgument(.enableLogging) || isUITest {
            print("[TestEnvironment] \(message)")
        }
        #endif
    }
}

// MARK: - Accessibility Identifiers

/// Centralized accessibility identifiers for UI testing
enum AccessibilityID {
    // Navigation
    static let tabBar = "tabBar"
    static let homeTab = "homeTab"
    static let templeTab = "templeTab"
    static let connectTab = "connectTab"
    static let askTab = "askTab"  // Legacy
    static let oracleTab = "oracleTab"
    static let timeTravelTab = "timeTravelTab"
    static let manageTab = "manageTab"
    static let selfTab = "selfTab"

    // Chat / Ask
    static let chatInputField = "chatInputField"
    static let sendMessageButton = "sendMessageButton"
    static let chatMessagesList = "chatMessagesList"
    static let freeLimitBanner = "freeLimitBanner"
    static let goUnlimitedButton = "goUnlimitedButton"
    static let getChatPackagesButton = "getChatPackagesButton"

    // Paywall
    static let paywallView = "paywallView"
    static let startProButton = "startProButton"
    static let restorePurchasesButton = "restorePurchasesButton"
    static let buyDetailedReportButton = "buyDetailedReportButton"
    static let buyChatPackagesButton = "buyChatPackagesButton"

    // Chat Packages
    static let chatPackagesSheet = "chatPackagesSheet"
    static let chatCreditsLabel = "chatCreditsLabel"
    static func chatPackBuyButton(_ productId: String) -> String {
        "chatPackBuyButton_\(productId)"
    }

    // Reports
    static let reportsStoreView = "reportsStoreView"
    static let myReportsView = "myReportsView"
    static func reportBuyButton(_ productId: String) -> String {
        "reportBuyButton_\(productId)"
    }
    static func reportRow(_ reportId: String) -> String {
        "reportRow_\(reportId)"
    }

    // Profile
    static let profileSetupView = "profileSetupView"
    static let birthDatePicker = "birthDatePicker"
    static let birthTimePicker = "birthTimePicker"
    static let locationSearchField = "locationSearchField"
    static let saveProfileButton = "saveProfileButton"

    // Time Travel
    static let timeTravelView = "timeTravelView"
    static let incompleteProfilePrompt = "incompleteProfilePrompt"
    static let completeBirthDataButton = "completeBirthDataButton"

    // Suggested Prompts
    static func suggestedPromptButton(_ index: Int) -> String {
        "suggestedPromptButton_\(index)"
    }

    // General
    static let loadingIndicator = "loadingIndicator"
    static let errorMessage = "errorMessage"
    static let dismissButton = "dismissButton"
    static let doneButton = "doneButton"
}
