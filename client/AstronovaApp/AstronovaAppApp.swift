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
    @StateObject private var gamification = GamificationManager()

    init() {
        // Apply UI test configuration if running in test mode
        TestEnvironment.shared.applyTestConfiguration()

        // Pro bypass only when explicitly requested by UI tests
        #if DEBUG
        if TestEnvironment.shared.hasArgument(.setProSubscribed) {
            UserDefaults.standard.set(true, forKey: "hasAstronovaPro")
        }
        #endif

        _authState = StateObject(wrappedValue: AuthState())

        // NOTE: Smartlook initialization is deferred to RootView.onAppear so
        // the first screen is visible before analytics starts.
        #if DEBUG
        print("🔍 [INIT] Smartlook initialization deferred until app load")
        #endif
    }

    // MARK: - Analytics

    @MainActor private static var hasStartedAnalytics = false

    @MainActor
    private static func setupAnalyticsOnce() {
        #if DEBUG
        if TestEnvironment.shared.isUITest {
            print("🔍 [DEBUG] Smartlook skipped - Running in UI test mode")
            return
        }
        #endif

        guard !hasStartedAnalytics else { return }
        hasStartedAnalytics = true
        Self.setupSmartlook()
    }

    #if canImport(SmartlookAnalytics)
    private static func setupSmartlook() {
        #if DEBUG
        print("✅ [Smartlook] SDK is available - starting setup")
        #endif

        guard let projectKey = Bundle.main.infoDictionary?["SMARTLOOK_PROJECT_KEY"] as? String else {
            #if DEBUG
            print("❌ [Smartlook] Failed to read SMARTLOOK_PROJECT_KEY from Info.plist")
            #endif
            return
        }

        Smartlook.instance.preferences.projectKey = projectKey
        Smartlook.instance.start()

        #if DEBUG
        print("✅ [Smartlook] Session recording started")
        #endif
    }
    #else
    private static func setupSmartlook() {
        #if DEBUG
        print("ℹ️ [Smartlook] SDK not linked in this build; analytics will remain local-only")
        #endif
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .environmentObject(gamification)
                .preferredColorScheme(.dark)
                .onAppear {
                    Self.setupAnalyticsOnce()

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
