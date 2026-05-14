//
//  AstronovaAppApp.swift
//  AstronovaApp
//
//  Created by Sankalp Thakur on 6/6/25.
//

import SwiftUI
import AppIntents
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
                    Self.setupPortfolioAnalyticsOnce()

                    if !TestEnvironment.shared.isUITest {
                        Analytics.shared.track(.appLaunched, properties: nil)
                    }
                }
        }
    }

    // MARK: - Portfolio Analytics (Wave 13 closed-loop)

    @MainActor private static var hasStartedPortfolioAnalytics = false

    @MainActor
    private static func setupPortfolioAnalyticsOnce() {
        guard !hasStartedPortfolioAnalytics else { return }
        hasStartedPortfolioAnalytics = true

        #if DEBUG
        if TestEnvironment.shared.isUITest {
            print("🔍 [PortfolioAnalytics] skipped — UI test mode")
            return
        }
        #endif

        // Endpoint comes from the static remote-config (telemetry.iosapps.io
        // per ANALYTICS_DESIGN §7). Missing endpoint is non-fatal: events are
        // buffered locally and the package no-ops on send.
        let endpoint = (Bundle.main.infoDictionary?["IOSAPPS_TELEMETRY_ENDPOINT"] as? String)
            .flatMap(URL.init(string:))
        PortfolioAnalytics.shared.configure(appID: .astronova, endpoint: endpoint)

        // Feature flags — defaults are baked in; remote refresh is best-effort.
        let flagsEndpoint = (Bundle.main.infoDictionary?["IOSAPPS_FLAGS_ENDPOINT"] as? String)
            .flatMap(URL.init(string:))
        AstronovaFlags.shared.configure(endpoint: flagsEndpoint)

        // Begin emitting app_open / session_start / session_end.
        SessionTracker.shared.start()
    }
}

// MARK: - Notification Names

extension Notification.Name {
    static let switchToTab = Notification.Name("switchToTab")
    static let switchToProfileSection = Notification.Name("switchToProfileSection")
    static let openVideoSession = Notification.Name("openVideoSession")
}

enum AstronovaIntentRouteStore {
    static let pendingRouteKey = "astronova.intent.pendingRoute"

    enum Route: String {
        case today
        case timeTravel
        case temple
        case connect
        case profile
    }

    static func request(_ route: Route) {
        UserDefaults.standard.set(route.rawValue, forKey: pendingRouteKey)
    }

    static func consume() -> Route? {
        let defaults = UserDefaults.standard
        guard let rawValue = defaults.string(forKey: pendingRouteKey),
              let route = Route(rawValue: rawValue) else {
            return nil
        }
        defaults.removeObject(forKey: pendingRouteKey)
        return route
    }

    static func request(from url: URL) -> Bool {
        guard url.scheme == "astronova" else { return false }

        switch url.host {
        case "today", "guidance", "daily", "cosmic-weather":
            request(.today)
        case "time", "timeline", "time-travel", "muhurat":
            request(.timeTravel)
        case "temple", "ritual":
            request(.temple)
        case "connect", "oracle", "chat":
            request(.connect)
        case "profile", "blueprint", "pro", "paywall":
            request(.profile)
        default:
            return false
        }
        return true
    }
}

struct OpenTodaysGuidanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Today's Guidance"
    static let description = IntentDescription("Open Astronova to today's personal cosmic guidance.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        AstronovaIntentRouteStore.request(.today)
        return .result()
    }
}

struct OpenTimeTravelIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Time Travel"
    static let description = IntentDescription("Open Astronova's timeline view.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        AstronovaIntentRouteStore.request(.timeTravel)
        return .result()
    }
}

struct OpenTempleIntent: AppIntent {
    static let title: LocalizedStringResource = "Open Temple"
    static let description = IntentDescription("Open Astronova's temple and pooja flows.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        AstronovaIntentRouteStore.request(.temple)
        return .result()
    }
}

struct AstronovaShortcutsProvider: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: OpenTodaysGuidanceIntent(),
            phrases: [
                "Open today's guidance in \(.applicationName)",
                "Check \(.applicationName)"
            ],
            shortTitle: "Today",
            systemImageName: "sparkles"
        )

        AppShortcut(
            intent: OpenTimeTravelIntent(),
            phrases: [
                "Open time travel in \(.applicationName)",
                "Show my timeline in \(.applicationName)"
            ],
            shortTitle: "Timeline",
            systemImageName: "clock.arrow.circlepath"
        )

        AppShortcut(
            intent: OpenTempleIntent(),
            phrases: [
                "Open temple in \(.applicationName)",
                "Open pooja in \(.applicationName)"
            ],
            shortTitle: "Temple",
            systemImageName: "flame"
        )
    }
}
