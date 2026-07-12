//
//  AstronovaAppApp.swift
//  AstronovaApp
//
//  Created by Sankalp Thakur on 6/6/25.
//

import SwiftUI
import AppIntents
import Diagnostics
#if canImport(SmartlookAnalytics)
import SmartlookAnalytics
#endif

@main
struct AstronovaAppApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var authState: AuthState
    @StateObject private var gamification = GamificationManager()

    init() {
        // MARK: - Portfolio Analytics SDK (Wave 13)
        // The `IOSAppsAnalytics` Swift package is not yet a direct dependency
        // of the AstronovaApp Xcode target — the in-app `PortfolioAnalytics`
        // shim (Analytics/PortfolioAnalytics.swift) mirrors its public surface
        // and is configured below in `setupPortfolioAnalyticsOnce()`. Once the
        // SPM dep lands, replace the shim per ANALYTICS_INTEGRATION.md:
        //
        // import IOSAppsAnalytics
        // IOSAppsAnalytics.shared.configure(
        //     appID: .astronova,
        //     endpoint: URL(string: "https://telemetry.iosapps.io/v1/events")!
        // )
        //
        // PostHog session replay (D7) is wired by linking `posthog-ios` and
        // calling `SessionReplay.shared.bind(...)` per the example in
        // astronova/ANALYTICS_INTEGRATION.md. Deferred until the package
        // dependency is added.
        //
        // NetworkLogger: AstronovaAPI's URLSession is built in
        // `Services/Network/AstronovaAPIClient.swift`. Add
        // `NetworkLogger.instrument(config)` there once the SDK is linked.
        // (Out of scope here — task forbids touching non-@main files.)

        // Apply UI test configuration if running in test mode
        TestEnvironment.shared.applyTestConfiguration()

        // Pro bypass only when explicitly requested by UI tests
        #if DEBUG
        if TestEnvironment.shared.hasArgument(.setProSubscribed) {
            UserDefaults.standard.set(true, forKey: "hasAstronovaPro")
        }
        #endif

        _authState = StateObject(wrappedValue: AuthState())

        Task { await DiagnosticsSupportLog.shared.record("Application initialized") }

        // Warm the Today-screen ephemeris substitutions cache so the Today
        // tab renders real moon void-of-course / aspect / eclipse values on
        // first paint instead of falling back to the deterministic stub.
        // No-op when the cache is already current for this UTC day.
        TopoSubstitutionsService.shared.refreshIfStale()

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

        guard AnalyticsConsentController.startSmartlookIfAllowed(projectKey: projectKey) else {
            #if DEBUG
            print("ℹ️ [Smartlook] Skipped because anonymous analytics is turned off")
            #endif
            return
        }

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
                    if scenePhase == .active {
                        Self.startStoreKitObservationForForeground()
                    }

                    if !TestEnvironment.shared.isUITest {
                        Analytics.shared.track(.appLaunched, properties: nil)
                    }
                }
                .onChange(of: scenePhase) { _, newPhase in
                    switch newPhase {
                    case .active:
                        Self.startStoreKitObservationForForeground()
                    case .background:
                        StoreKitManager.shared.stopSubscriptionStatusObservation()
                    case .inactive:
                        // Keep observing through short interruptions such as
                        // StoreKit sheets and Control Center transitions.
                        break
                    @unknown default:
                        break
                    }
                }
        }
    }

    @MainActor
    private static func startStoreKitObservationForForeground() {
        guard !TestEnvironment.shared.isUITest else { return }
        let store = StoreKitManager.shared
        store.startSubscriptionStatusObservation()
        Task {
            await store.refreshEntitlements()
            await store.refreshSubscriptionStatusObservation()
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
}

enum AstronovaIntentRouteStore {
    static let pendingRouteKey = "astronova.intent.pendingRoute"

    enum Route: String {
        case today
        case timeTravel
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
        case "time", "timeline", "time-travel":
            request(.timeTravel)
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
    static let title: LocalizedStringResource = "Open Timeline"
    static let description = IntentDescription("Open Astronova's current timeline view.")
    static let openAppWhenRun = true

    func perform() async throws -> some IntentResult {
        AstronovaIntentRouteStore.request(.timeTravel)
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
                "Open timeline in \(.applicationName)",
                "Show my timeline in \(.applicationName)"
            ],
            shortTitle: "Timeline",
            systemImageName: "clock.arrow.circlepath"
        )
    }
}
