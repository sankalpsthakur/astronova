//
//  AstronovaAppApp.swift
//  AstronovaApp
//
//  Created by Sankalp Thakur on 6/6/25.
//

import SwiftUI
#if canImport(SmartlookAnalytics)
import SmartlookAnalytics
#endif

@main
struct AstronovaAppApp: App {
    @StateObject private var authState: AuthState

    init() {
        // Initialize Smartlook BEFORE any UI state
        // Disable in UI test mode to avoid polluting recordings
        #if DEBUG
        if !TestEnvironment.shared.isUITest {
            Self.setupSmartlook()
            print("🔍 [DEBUG] Smartlook initialization attempted (non-UI-test mode)")
        } else {
            print("🔍 [DEBUG] Smartlook SKIPPED - Running in UI test mode")
        }
        #else
        Self.setupSmartlook()
        print("🔍 [RELEASE] Smartlook initialization attempted")
        #endif

        // Apply UI test configuration if running in test mode
        TestEnvironment.shared.applyTestConfiguration()

        // Pro bypass only when explicitly requested by UI tests
        #if DEBUG
        if TestEnvironment.shared.hasArgument(.setProSubscribed) {
            UserDefaults.standard.set(true, forKey: "hasAstronovaPro")
        }
        #endif

        _authState = StateObject(wrappedValue: AuthState())
    }

    #if canImport(SmartlookAnalytics)
    private static func setupSmartlook() {
        print("✅ [Smartlook] SDK is available - starting setup")
        Smartlook.instance.preferences.projectKey = "3ea51a8cc18ecd6b6b43eec84450f694a65569ed"
        Smartlook.instance.start()
        print("✅ [Smartlook] Session recording started with project key: 3ea51a8...9ed")
        print("✅ [Smartlook] Check dashboard at: https://app.smartlook.com/")
    }
    #else
    private static func setupSmartlook() {
        print("❌ [Smartlook] SDK NOT available - SmartlookAnalytics cannot be imported")
        print("❌ [Smartlook] Check if package is properly linked to target")
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .onAppear {
                    if !TestEnvironment.shared.isUITest {
                        Analytics.shared.track(.appLaunched, properties: nil)
                    }
                }
        }
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
    static let openVideoSession = Notification.Name("openVideoSession")
}
