//
//  AstronovaAppApp.swift
//  AstronovaApp
//
//  Created by Sankalp Thakur on 6/6/25.
//

import SwiftUI
import AppTrackingTransparency
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

        // NOTE: Smartlook initialization is deferred to RootView.onAppear
        // to request App Tracking Transparency (ATT) permission first
        #if DEBUG
        print("🔍 [INIT] Smartlook initialization deferred - will request ATT on app load")
        #endif
    }

    // MARK: - App Tracking Transparency (ATT)

    /// Request App Tracking Transparency permission from the user and initialize Smartlook
    /// if permission is granted. This follows Apple's guidelines by requesting ATT after
    /// the app's first screen loads (not immediately on launch).
    private func requestTrackingAuthorizationAndInitializeAnalytics() async {
        #if DEBUG
        if TestEnvironment.shared.isUITest {
            print("🔍 [DEBUG] ATT request SKIPPED - Running in UI test mode")
            return
        }
        #endif

        // Request tracking authorization from the user
        let status = await ATTrackingManager.requestTrackingAuthorization()

        switch status {
        case .authorized:
            #if DEBUG
            print("✅ [ATT] User granted tracking authorization")
            #endif
            Self.setupSmartlook()

        case .denied:
            #if DEBUG
            print("⚠️ [ATT] User denied tracking authorization - Smartlook will not be initialized")
            #endif

        case .notDetermined:
            #if DEBUG
            print("⚠️ [ATT] Tracking authorization not determined - requesting again")
            #endif
            let retryStatus = await ATTrackingManager.requestTrackingAuthorization()
            if retryStatus == .authorized {
                Self.setupSmartlook()
            }

        case .restricted:
            #if DEBUG
            print("⚠️ [ATT] Tracking is restricted on this device - Smartlook will not be initialized")
            #endif

        @unknown default:
            #if DEBUG
            print("⚠️ [ATT] Unknown tracking authorization status")
            #endif
        }
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
        print("❌ [Smartlook] SDK NOT available - SmartlookAnalytics cannot be imported")
        print("❌ [Smartlook] Check if package is properly linked to target")
        #endif
    }
    #endif

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(authState)
                .environmentObject(gamification)
                .onAppear {
                    // Request App Tracking Transparency permission and initialize analytics
                    Task {
                        await requestTrackingAuthorizationAndInitializeAnalytics()
                    }

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
