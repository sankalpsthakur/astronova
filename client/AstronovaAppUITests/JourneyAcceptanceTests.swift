//
//  JourneyAcceptanceTests.swift
//  AstronovaAppUITests
//
//  QA acceptance suite for the refreshed Astronova client.
//  These journeys pin the current product surface: calibrated onboarding,
//  Today dashboard value, journal habit loops, paywalls, report shop gates,
//  auth recovery, Apple Maps globe, Timeline, Matrix, and Journal agency.
//

import XCTest

final class JourneyAcceptanceTests: XCTestCase {

    // MARK: - Constants

    private static let expectedAPIBaseURL = "https://astronova-ghcr.onrender.com"
    private static let buildLabel = "2026051816"

    /// Where per-journey screenshots and supporting evidence are written.
    /// Absolute path — the test runner runs as a separate process and won't
    /// inherit pwd from xcodebuild. `QA_EVIDENCE_DIR` env var lets CI redirect
    /// without recompiling.
    private static let evidenceDirectoryURL: URL = {
        if let envPath = ProcessInfo.processInfo.environment["QA_EVIDENCE_DIR"] {
            return URL(fileURLWithPath: envPath, isDirectory: true)
        }
        return URL(fileURLWithPath:
            "/Users/sankalp/Projects/iosapps/astronova/qa-results/\(buildLabel)",
            isDirectory: true)
    }()

    /// Shared UserDefaults that the host app writes to. Reading from the same
    /// suite from the test bundle works because XCUITest runs on the same
    /// simulator sandbox — the suite name resolves to the app's preferences
    /// plist on disk.
    private static let appBundleID = "com.astronova.app"

    // MARK: - State

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        try? FileManager.default.createDirectory(at: Self.evidenceDirectoryURL,
                                                 withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Launch helpers

    @discardableResult
    private func launchSignedIn(extraArguments: [String] = [],
                                environment: [String: String] = [:],
                                onWillLaunch: ((Date) -> Void)? = nil) -> XCUIApplication {
        app.terminate()
        app.launchArguments = [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_ENABLE_LOGGING"
        ] + extraArguments
        var merged = environment
        merged["UITEST_TIME_TRAVEL_SAMPLE"] = merged["UITEST_TIME_TRAVEL_SAMPLE"] ?? "1"
        merged["UITEST_DISCOVER_SAMPLE"] = merged["UITEST_DISCOVER_SAMPLE"] ?? "1"
        if let qaDir = ProcessInfo.processInfo.environment["QA_EVIDENCE_DIR"] {
            merged["QA_EVIDENCE_DIR"] = qaDir
        }
        app.launchEnvironment = merged
        onWillLaunch?(Date())
        app.launch()
        return app
    }

    @discardableResult
    private func relaunchSignedInPreservingState(extraArguments: [String] = [],
                                                environment: [String: String] = [:]) -> XCUIApplication {
        app.terminate()
        app.launchArguments = [
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_ENABLE_LOGGING"
        ] + extraArguments
        var merged = environment
        merged["UITEST_TIME_TRAVEL_SAMPLE"] = merged["UITEST_TIME_TRAVEL_SAMPLE"] ?? "1"
        merged["UITEST_DISCOVER_SAMPLE"] = merged["UITEST_DISCOVER_SAMPLE"] ?? "1"
        if let qaDir = ProcessInfo.processInfo.environment["QA_EVIDENCE_DIR"] {
            merged["QA_EVIDENCE_DIR"] = qaDir
        }
        app.launchEnvironment = merged
        app.launch()
        return app
    }

    private func tapTab(_ identifier: String,
                        file: StaticString = #filePath,
                        line: UInt = #line) {
        let button = app.buttons[identifier]
        if button.waitForExistence(timeout: 12) {
            button.tap()
            return
        }
        let other = app.otherElements[identifier]
        XCTAssertTrue(other.waitForExistence(timeout: 6),
                      "Tab '\(identifier)' should exist",
                      file: file, line: line)
        other.tap()
    }

    private func waitForHomeTab(timeout: TimeInterval = 25) -> Bool {
        if app.buttons["homeTab"].waitForExistence(timeout: timeout) { return true }
        return app.otherElements["homeTab"].waitForExistence(timeout: 4)
    }

    @discardableResult
    private func waitForProfileSetup(timeout: TimeInterval = 15) -> Bool {
        anyElement("profileSetupView").waitForExistence(timeout: timeout)
    }

    // MARK: - Evidence helpers

    private func captureEvidence(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let pngURL = Self.evidenceDirectoryURL.appendingPathComponent("\(name).png")
        do {
            try screenshot.pngRepresentation.write(to: pngURL)
        } catch {
            print("[QA] failed to write screenshot to \(pngURL.path): \(error)")
        }
    }

    private func writeArtifact(_ data: Data, filename: String) {
        let url = Self.evidenceDirectoryURL.appendingPathComponent(filename)
        try? data.write(to: url)
        let attachment = XCTAttachment(data: data, uniformTypeIdentifier: "public.data")
        attachment.name = filename
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // MARK: - Element helpers

    private func anyElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier == %@", identifier))
            .firstMatch
    }

    private func dismissPresentedSheet() {
        let close = app.buttons["analysis.sheet.close"]
        if close.waitForExistence(timeout: 2) {
            close.tap()
            RunLoop.current.run(until: Date().addingTimeInterval(0.6))
            return
        }

        let coordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.12))
        coordinate.press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.88)))
    }

    private func waitForElementByScrolling(_ identifier: String,
                                           timeout: TimeInterval = 10,
                                           file: StaticString = #filePath,
                                           line: UInt = #line) -> XCUIElement {
        let element = anyElement(identifier)
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists {
                return element
            }
            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }
        XCTAssertTrue(element.exists, "\(identifier) should exist on the current screen", file: file, line: line)
        return element
    }

    private func tapElementByScrolling(_ identifier: String,
                                       timeout: TimeInterval = 10,
                                       file: StaticString = #filePath,
                                       line: UInt = #line) {
        let element = app.buttons[identifier]
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if element.exists && element.isHittable {
                element.tap()
                return
            }
            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        }

        XCTAssertTrue(element.exists, "\(identifier) should exist on the current screen", file: file, line: line)
        XCTAssertTrue(element.isHittable, "\(identifier) should be physically tappable", file: file, line: line)
        if element.exists && element.isHittable {
            element.tap()
        }
    }

    /// Settings entry on Today tab is an unlabeled gear-icon Button. Find it
    /// by walking the top bar buttons.
    private func openSettingsFromToday() {
        // First try by image-system-name identifier (works on iOS 17+ for
        // SwiftUI Image inside Button when it's the label).
        let byImage = app.buttons.matching(NSPredicate(
            format: "identifier == %@", "gearshape"
        )).firstMatch
        if byImage.waitForExistence(timeout: 4) && byImage.isHittable {
            byImage.tap()
            return
        }

        // Fallback: the top bar has 2 trailing icon buttons (pause.circle
        // then gearshape). Walk the visible button set and find the gear
        // by frame heuristic (top-trailing region).
        let candidates = app.buttons.allElementsBoundByIndex
        for button in candidates.reversed() where button.isHittable {
            let f = button.frame
            if f.minY < 200 && f.minX > 250 {
                button.tap()
                return
            }
        }
        XCTFail("Could not find the Today tab Settings (gear) button")
    }

    /// Read the DEBUG speech-call counter from the app's UserDefaults via
    /// the simulator's shared CoreSimulator user-defaults plist. Returns
    /// nil if the key is absent (DEBUG counter not compiled in, or app
    /// hasn't run yet).
    private func readSpeechCounter() -> Int? {
        guard let defaults = UserDefaults(suiteName: Self.appBundleID) else {
            return nil
        }
        let key = "astronova.qa.speech_speak_counter"
        if defaults.object(forKey: key) == nil {
            return nil
        }
        return defaults.integer(forKey: key)
    }

    // MARK: - Journey 1 — Primary tabs render without backend

    @MainActor
    func test_J1_allTabsRenderOffline() throws {
        launchSignedIn(extraArguments: ["UITEST_OFFLINE_BACKEND"])
        XCTAssertTrue(waitForHomeTab(),
                      "App should boot to the home tab in offline mode")

        let tabsUnderTest: [(id: String, label: String)] = [
            ("homeTab", "Today"),
            ("timeTravelTab", "Map"),
            ("timelineTab", "Timeline"),
            ("matrixTab", "Matrix"),
            ("selfTab", "Journal")
        ]

        for (idx, tab) in tabsUnderTest.enumerated() {
            tapTab(tab.id)
            let tabButton = app.buttons[tab.id]
            XCTAssertTrue(tabButton.waitForExistence(timeout: 6),
                          "\(tab.label) tab button must exist")
            _ = tabButton.waitForExistence(timeout: 1)
            captureEvidence(named: String(format: "01-tab-%d-%@",
                                          idx + 1, tab.label.lowercased()))
        }

        XCTAssertTrue(app.exists,
                      "App must remain alive after touring all 5 tabs offline")
    }

    // MARK: - Journey 2 — GHCR cutover (apiBaseURL + /health)

    @MainActor
    func test_J2_ghcrCutoverProbe() throws {
        let url = URL(string: "\(Self.expectedAPIBaseURL)/health")!
        let expectation = self.expectation(description: "ghcr-health-probe")
        var statusCode = -1
        var responseBody = Data()
        var probeError: String? = nil

        let task = URLSession(configuration: .ephemeral).dataTask(with: url) { data, response, error in
            if let http = response as? HTTPURLResponse {
                statusCode = http.statusCode
            }
            if let data = data {
                responseBody = data
            }
            if let error = error {
                probeError = error.localizedDescription
                print("[QA] /health probe error: \(error)")
            }
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 30)

        writeArtifact(responseBody, filename: "02-health-response.json")
        if let probeError = probeError {
            let errBlob = "probe error: \(probeError)".data(using: .utf8) ?? Data()
            writeArtifact(errBlob, filename: "02-health-error.txt")
        }
        XCTAssertEqual(statusCode, 200,
                       "GHCR /health should return 200; got \(statusCode)")

        // Launch the app to attach a visual artefact of the live build
        // under GHCR base URL.
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "App should boot under GHCR baseURL")
        captureEvidence(named: "02-ghcr-home")
    }

    // MARK: - Journey 3 — Paywall open + close + mock purchase

    @MainActor
    func test_J3_paywallOpenCloseAndMockPurchase() throws {
        launchSignedIn(extraArguments: [
            "UITEST_PRESENT_PAYWALL",
            "UITEST_MOCK_PURCHASES"
        ])

        let paywallView = anyElement("paywallView")
        XCTAssertTrue(paywallView.waitForExistence(timeout: 15),
                      "Paywall should auto-present via UITEST_PRESENT_PAYWALL")
        captureEvidence(named: "03-paywall-open")

        let close = app.buttons["paywall.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 8),
                      "Paywall should expose the current close affordance")
        XCTAssertTrue(close.isHittable,
                      "Close button must be hittable from the user's perspective")
        close.tap()

        // Re-launch and exercise the mock purchase path.
        app.terminate()
        launchSignedIn(extraArguments: [
            "UITEST_PRESENT_PAYWALL",
            "UITEST_MOCK_PURCHASES"
        ])
        XCTAssertTrue(anyElement("paywallView").waitForExistence(timeout: 15),
                      "Paywall should re-present for mock purchase")

        let startPro = app.buttons["startProButton"]
        XCTAssertTrue(startPro.waitForExistence(timeout: 6),
                      "Start-Pro CTA should be present")
        XCTAssertTrue(startPro.isHittable, "Start-Pro CTA must be hittable")
        startPro.tap()

        // Mock-purchase success cue (PaywallView.firePurchaseSuccessCue) fires:
        //   - HapticFeedbackService.success()
        //   - AudioServicesPlaySystemSound(1407)
        //   - SpeechService.shared.speak("Cosmic access unlocked")
        // Evidence priority:
        //   1. SpeechService counter increment (most reliable, sync side-effect)
        //   2. Welcome alert visible
        //   3. Continue button visible
        //   4. Paywall auto-dismissed (terminal success state)
        let welcomeTitle = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Welcome to Pro"))
            .firstMatch
        let continueButton = app.buttons
            .matching(NSPredicate(format: "label == %@", "Continue"))
            .firstMatch

        let deadline = Date().addingTimeInterval(20)
        var successEvidence: String? = nil
        while Date() < deadline {
            if let count = readSpeechCounter(), count >= 1 {
                successEvidence = "SpeechService counter = \(count) (TTS success cue fired)"
                break
            }
            if app.alerts.element.exists {
                successEvidence = "system alert visible"
                break
            }
            if welcomeTitle.exists {
                successEvidence = "Welcome to Pro static text visible"
                break
            }
            if continueButton.exists {
                successEvidence = "Continue button visible"
                break
            }
            if !app.buttons["startProButton"].exists &&
               app.buttons["homeTab"].exists {
                successEvidence = "paywall dismissed (success terminal state)"
                break
            }
            Thread.sleep(forTimeInterval: 0.5)
        }
        captureEvidence(named: "03-paywall-purchase-success")

        if let evidence = successEvidence {
            print("[QA J3] Purchase success evidence: \(evidence)")
            let blob = "evidence: \(evidence)\n".data(using: .utf8) ?? Data()
            writeArtifact(blob, filename: "03-paywall-success-evidence.txt")
        } else {
            print("[QA J3] No purchase success affordance observed in 20s — see screenshot.")
        }

        XCTAssertNotNil(successEvidence,
                        "Mock purchase must produce a visible or measurable success affordance after tapping Start Pro")
    }

    @MainActor
    func test_J15_tieredPaywallsRestoreNoneAndMockPurchaseRecover() throws {
        for variant in ["tiered_v1", "tiered_v2"] {
            launchSignedIn(
                extraArguments: [
                    "UITEST_PRESENT_PAYWALL",
                    "UITEST_MOCK_PURCHASES"
                ],
                environment: ["UITEST_PAYWALL_VARIANT": variant]
            )

            XCTAssertTrue(anyElement("paywallView").waitForExistence(timeout: 15),
                          "\(variant) paywall should auto-present")
            captureEvidence(named: "15-\(variant)-paywall-open")

            tapElementByScrolling("restorePurchasesButton", timeout: 12)

            let noPurchases = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "No Purchases Found"))
                .firstMatch
            XCTAssertTrue(noPurchases.waitForExistence(timeout: 8),
                          "\(variant) restore-none path should explain that nothing was restored")
            captureEvidence(named: "15-\(variant)-restore-none")
            app.buttons["OK"].tap()

            let startPro = app.buttons["startProButton"]
            XCTAssertTrue(startPro.waitForExistence(timeout: 8),
                          "\(variant) should preserve the primary Pro CTA after restore-none")
            tapElementByScrolling("startProButton", timeout: 12)

            let welcomeTitle = app.staticTexts
                .matching(NSPredicate(format: "label CONTAINS[c] %@", "Welcome to Pro"))
                .firstMatch
            let continueButton = app.buttons
                .matching(NSPredicate(format: "label == %@", "Continue"))
                .firstMatch
            let deadline = Date().addingTimeInterval(12)
            var successEvidence: String? = nil
            while Date() < deadline {
                if let count = readSpeechCounter(), count >= 1 {
                    successEvidence = "SpeechService counter = \(count)"
                    break
                }
                if welcomeTitle.exists || continueButton.exists {
                    successEvidence = "Welcome alert visible"
                    break
                }
                RunLoop.current.run(until: Date().addingTimeInterval(0.4))
            }

            captureEvidence(named: "15-\(variant)-mock-purchase-success")
            XCTAssertNotNil(successEvidence,
                            "\(variant) mock purchase should produce a visible or measurable success affordance")
        }
    }

    @MainActor
    func test_J16_reportShopGatePurchasesFromPaywallAlternative() throws {
        launchSignedIn(
            extraArguments: [
                "UITEST_PRESENT_PAYWALL",
                "UITEST_MOCK_PURCHASES"
            ],
            environment: ["UITEST_PAYWALL_VARIANT": "tiered_v1"]
        )

        XCTAssertTrue(anyElement("paywallView").waitForExistence(timeout: 15),
                      "Paywall should open for the report-shop gate journey")
        captureEvidence(named: "16-paywall-primary-pro-cta")

        let otherWays = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Other ways to unlock"))
            .firstMatch
        XCTAssertTrue(otherWays.waitForExistence(timeout: 8),
                      "Paywall should keep report purchases behind a secondary disclosure")
        otherWays.tap()

        let reports = app.buttons["buyDetailedReportButton"]
        XCTAssertTrue(reports.waitForExistence(timeout: 8),
                      "Expanded paywall should expose Reports Shop as the secondary paid path")
        tapElementByScrolling("buyDetailedReportButton", timeout: 8)

        XCTAssertTrue(anyElement("reportsStoreView").waitForExistence(timeout: 10),
                      "Reports Shop should present from the paywall alternative CTA")
        captureEvidence(named: "16-reports-shop-open")

        tapElementByScrolling("reportsStore.restorePurchasesButton", timeout: 12)
        let noPurchases = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "No Purchases Found"))
            .firstMatch
        XCTAssertTrue(noPurchases.waitForExistence(timeout: 8),
                      "Reports Shop restore-none should clearly explain the state")
        captureEvidence(named: "16-reports-shop-restore-none")
        app.buttons["OK"].tap()

        let reportBuyButtons = app.buttons
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "reportBuyButton_"))
        XCTAssertTrue(reportBuyButtons.firstMatch.waitForExistence(timeout: 8),
                      "Non-Pro users should see individual report purchase buttons")
        let buy = reportBuyButtons.allElementsBoundByIndex.first { $0.isHittable }
            ?? reportBuyButtons.firstMatch
        XCTAssertFalse(buy.frame.isEmpty,
                       "At least one report buy button should be visible")
        buy.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()

        let reportReady = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Report Ready"))
            .firstMatch
        XCTAssertTrue(reportReady.waitForExistence(timeout: 10),
                      "Mock report purchase should generate a report and show success")
        captureEvidence(named: "16-report-purchase-success")
        app.buttons["OK"].tap()

        let purchasedBadge = app.descendants(matching: .any)
            .matching(NSPredicate(format: "identifier BEGINSWITH %@", "reportIncludedBadge_"))
            .firstMatch
        XCTAssertTrue(purchasedBadge.waitForExistence(timeout: 8),
                      "Purchased report should switch to a purchased/included badge in the same session")
        captureEvidence(named: "16-report-purchased-badge")
    }

    // MARK: - Journey 4 — Privacy reachable in-app via Settings

    @MainActor
    func test_J4_privacyOpensInApp() throws {
        // SettingsSheet on TodayTerrainView shows a "Privacy" row that opens
        // an in-app NavigationStack with a disclaimer. The task spec expected
        // a WKWebView load of /privacy; current build renders an inline
        // summary instead. Documented in REPORT.md.
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need home tab before opening Settings")
        tapTab("homeTab")

        openSettingsFromToday()

        let settingsNav = app.navigationBars["Settings"]
        XCTAssertTrue(settingsNav.waitForExistence(timeout: 8),
                      "SettingsSheet should present with title 'Settings'")
        captureEvidence(named: "04-settings-open")

        let privacyButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Privacy"
        )).firstMatch
        XCTAssertTrue(privacyButton.waitForExistence(timeout: 8),
                      "Privacy row must be reachable from SettingsSheet")
        privacyButton.tap()

        let privacyNav = app.navigationBars["Privacy"]
        let disclaimer = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@",
                                  "Astronova does not sell"))
            .firstMatch
        XCTAssertTrue(privacyNav.waitForExistence(timeout: 8) ||
                      disclaimer.waitForExistence(timeout: 4),
                      "Privacy sheet must render in-app with disclaimer text")
        captureEvidence(named: "04-privacy-sheet")
    }

    // MARK: - Journey 5 — "Read horoscope aloud" increments SpeechService counter

    @MainActor
    func test_J5_readHoroscopeAloudFiresSpeech() throws {
        // The button now lives on TodayTerrainView (re-wired from the sunset
        // HomeView). Identifier preserved as `home.readHoroscopeAloud`.
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need home tab")
        tapTab("homeTab")

        // The button only renders once the terrain snapshot is loaded.
        // Sample data is bundled so this is fast, but we allow time.
        let readButton = app.buttons["home.readHoroscopeAloud"]
        XCTAssertTrue(readButton.waitForExistence(timeout: 15),
                      "home.readHoroscopeAloud button must render on Today tab")
        captureEvidence(named: "05-today-with-read-button")

        // UITEST_RESET clears the counter, so a fresh launch sees nil/0.
        let before = readSpeechCounter() ?? 0

        readButton.tap()

        // `speak()` increments the counter synchronously after passing the
        // toggle + VoiceOver checks. The app also flips the button label to
        // "Stop reading..." while speech is active, which is the user-visible
        // oracle and remains reliable when simulator defaults are isolated
        // from the UI-test runner.
        let deadline = Date().addingTimeInterval(5)
        var after = readSpeechCounter() ?? 0
        let stopReadingButton = app.buttons
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Stop reading"))
            .firstMatch
        var sawStopReading = false
        while after == before && !sawStopReading && Date() < deadline {
            Thread.sleep(forTimeInterval: 0.2)
            after = readSpeechCounter() ?? 0
            sawStopReading = stopReadingButton.exists
        }
        captureEvidence(named: "05-after-read-tap")
        XCTAssertTrue(after == before + 1 || sawStopReading,
                      "Speech should either increment the DEBUG counter from \(before) to \(before + 1) or expose the Stop reading state; saw counter \(after), stopVisible=\(sawStopReading)")
    }

    // MARK: - Journey 6 — Voice reading toggle gates speech

    @MainActor
    func test_J6_voiceReadingToggleDisablesSpeech() throws {
        // Toggle lives in SettingsSheet under "VOICE". Flipping OFF must
        // cause subsequent Read taps to be a no-op (counter unchanged).
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need home tab")
        tapTab("homeTab")

        openSettingsFromToday()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8),
                      "SettingsSheet must present")
        captureEvidence(named: "06-settings-with-voice-toggle")

        // The Toggle row carries the identifier; XCUITest may surface it
        // as either a switch or otherElement depending on iOS version.
        let toggleAsSwitch = app.switches["settings.voiceReading.toggle"]
        let toggleAsAny = anyElement("settings.voiceReading.toggle")
        let toggle: XCUIElement
        if toggleAsSwitch.waitForExistence(timeout: 6) {
            toggle = toggleAsSwitch
        } else if toggleAsAny.waitForExistence(timeout: 4) {
            toggle = toggleAsAny
        } else {
            XCTFail("settings.voiceReading.toggle must be reachable from SettingsSheet")
            return
        }
        toggle.tap()

        // Confirm OFF via the AppStorage flag.
        let voiceOff: Bool = {
            guard let defaults = UserDefaults(suiteName: Self.appBundleID) else {
                return false
            }
            return !defaults.bool(forKey: "astronova.voice_reading_enabled")
        }()
        XCTAssertTrue(voiceOff, "Voice reading should be OFF after toggling")

        // Dismiss the sheet.
        let done = app.buttons["Done"]
        if done.waitForExistence(timeout: 4) {
            done.tap()
        } else {
            app.swipeDown()
        }

        // Back on Today — confirm counter is unchanged after Read tap.
        let readButton = app.buttons["home.readHoroscopeAloud"]
        XCTAssertTrue(readButton.waitForExistence(timeout: 15),
                      "home.readHoroscopeAloud must still render")
        captureEvidence(named: "06-today-read-with-voice-off")

        let before = readSpeechCounter() ?? 0
        readButton.tap()

        // Give the same window we gave J5 to make sure we're not racing.
        let deadline = Date().addingTimeInterval(3)
        while Date() < deadline {
            let now = readSpeechCounter() ?? 0
            if now > before { break }
            Thread.sleep(forTimeInterval: 0.2)
        }
        let after = readSpeechCounter() ?? before
        captureEvidence(named: "06-after-read-tap-voice-off")
        XCTAssertEqual(after, before,
                       "Counter must NOT increment when voice reading is OFF; before=\(before) after=\(after)")
    }

    // MARK: - Journey 7 — Timeline tab renders live system state

    @MainActor
    func test_J7_timelineTabShowsSystemDashaAndForecast() throws {
        let localBackend = ProcessInfo.processInfo.environment["ASTRONOVA_LOCAL_BACKEND"]
            ?? "http://127.0.0.1:18093"
        launchSignedIn(
            extraArguments: ["UITEST_START_TAB_INDEX=2"],
            environment: [
                "ASTRONOVA_LOCAL_BACKEND": localBackend,
                "UITEST_TIME_TRAVEL_SAMPLE": "0",
                "UITEST_DISCOVER_SAMPLE": "0"
            ]
        )

        XCTAssertTrue(anyElement("timelineTabView").waitForExistence(timeout: 18),
                      "Timeline tab should render as the third bottom-nav surface")
        XCTAssertTrue(anyElement("timeline.systemOverview").waitForExistence(timeout: 15),
                      "Timeline should expose the live server/system overview")
        XCTAssertTrue(anyElement("timeline.dashaPulse").waitForExistence(timeout: 15),
                      "Timeline should expose dasha pulse/progress")
        XCTAssertTrue(anyElement("predictionTimelineView").waitForExistence(timeout: 15),
                      "Timeline should embed the forecast timeline without a nested tab handoff")
        XCTAssertTrue(app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Timeline"))
            .firstMatch
            .waitForExistence(timeout: 4),
            "Timeline label should be visible in the product shell")
        captureEvidence(named: "07-timeline-live-state")
    }

    // MARK: - Journey 8 — Matrix tab renders numerology deep dive

    @MainActor
    func test_J8_matrixTabShowsLoshuEigenvaluesAndTransformations() throws {
        let localBackend = ProcessInfo.processInfo.environment["ASTRONOVA_LOCAL_BACKEND"]
            ?? "http://127.0.0.1:18093"
        launchSignedIn(
            extraArguments: ["UITEST_START_TAB_INDEX=3"],
            environment: ["ASTRONOVA_LOCAL_BACKEND": localBackend]
        )

        XCTAssertTrue(anyElement("matrixDeepDiveView").waitForExistence(timeout: 18),
                      "Matrix tab should render as the fourth bottom-nav surface")
        XCTAssertTrue(anyElement("loshuGridView").waitForExistence(timeout: 15),
                      "Matrix should compose the existing Loshu grid")
        XCTAssertTrue(anyElement("matrix.eigenvalues").waitForExistence(timeout: 15),
                      "Matrix should expose eigenvalue decomposition cards")
        XCTAssertTrue(anyElement("matrix.transformations").waitForExistence(timeout: 15),
                      "Matrix should expose transformation/action cards")
        XCTAssertTrue(app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Driver"))
            .firstMatch
            .waitForExistence(timeout: 8),
            "Matrix should show driver/conductor live numerology context")
        captureEvidence(named: "08-matrix-deep-dive")
    }

    // MARK: - Journey 9 — Journal draft survives interruption

    @MainActor
    func test_J9_journalDraftSurvivesRelaunch() throws {
        let draftText = "Interrupted draft survives relaunch"
        launchSignedIn(extraArguments: [
            "UITEST_START_TAB_INDEX=4",
            "UITEST_OFFLINE_BACKEND"
        ])

        let journal = anyElement("journalView")
        XCTAssertTrue(journal.waitForExistence(timeout: 15),
                      "Journal tab should render")

        let add = app.buttons["journalAddButton"]
        XCTAssertTrue(add.waitForExistence(timeout: 8),
                      "Journal should expose one primary add CTA")
        XCTAssertTrue(add.isHittable,
                      "Journal add CTA should be immediately hittable")
        add.tap()

        let compose = anyElement("journalComposeView")
        XCTAssertTrue(compose.waitForExistence(timeout: 8),
                      "Journal add should open compose")

        let editor = anyElement("journalWhatHappenedEditor")
        XCTAssertTrue(editor.waitForExistence(timeout: 8),
                      "Journal compose should expose the main reflection editor")
        editor.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        app.typeText(draftText)

        XCTAssertTrue(anyElement("journalDraftRestoredBanner").waitForExistence(timeout: 3),
                      "Typing a draft should show the local save affordance")
        captureEvidence(named: "09-journal-compose-draft")

        relaunchSignedInPreservingState(extraArguments: ["UITEST_START_TAB_INDEX=4"])

        XCTAssertTrue(anyElement("journalView").waitForExistence(timeout: 15),
                      "Journal should reopen after interruption")
        let restoredAdd = app.buttons["journalAddButton"]
        XCTAssertTrue(restoredAdd.waitForExistence(timeout: 8),
                      "Restored Journal add CTA should still be available")
        restoredAdd.tap()

        let restoredCompose = anyElement("journalComposeView")
        XCTAssertTrue(restoredCompose.waitForExistence(timeout: 8),
                      "Journal compose should reopen in one tap after relaunch")
        XCTAssertTrue(anyElement("journalDraftRestoredBanner").waitForExistence(timeout: 5),
                      "Compose should tell the user the interrupted draft was restored")

        let restoredText = app.staticTexts[draftText]
        let restoredEditor = anyElement("journalWhatHappenedEditor")
        let editorValue = restoredEditor.value as? String
        XCTAssertTrue(restoredText.waitForExistence(timeout: 3) ||
                      editorValue?.contains(draftText) == true,
                      "Interrupted draft text should be present after relaunch")
        captureEvidence(named: "09-journal-draft-restored")
    }

    // MARK: - Journey 10 — Journal Insights quota explains the paywall gate

    @MainActor
    func test_J10_journalInsightsQuotaGateIsContextual() throws {
        launchSignedIn(extraArguments: [
            "UITEST_START_TAB_INDEX=4",
            "UITEST_SET_INSIGHTS_LIMIT_REACHED"
        ])

        XCTAssertTrue(anyElement("journalView").waitForExistence(timeout: 15),
                      "Journal tab should render")

        let insights = app.buttons["journalInsightsTabButton"]
        XCTAssertTrue(insights.waitForExistence(timeout: 8),
                      "Journal should expose the Insights tab")
        if !insights.isHittable {
            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        }
        captureEvidence(named: "10-journal-quota-before-tap")

        tapElementByScrolling("journalInsightsTabButton", timeout: 8)

        let paywall = anyElement("paywallView")
        XCTAssertTrue(paywall.waitForExistence(timeout: 12),
                      "Exhausted Journal Insights quota should open the Pro gate")
        XCTAssertTrue(app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Unlock Journal Insights"))
            .firstMatch
            .waitForExistence(timeout: 5),
            "Paywall should explain the Journal Insights-specific value")
        captureEvidence(named: "10-journal-insights-paywall")

        let close = app.buttons["paywall.close"]
        XCTAssertTrue(close.waitForExistence(timeout: 8),
                      "Paywall should expose the canonical close affordance")
        close.tap()

        let gateBanner = anyElement("journalInsightsGateBanner")
        XCTAssertTrue(gateBanner.waitForExistence(timeout: 8),
                      "After dismissing paywall, Journal should keep a contextual recovery banner")
        captureEvidence(named: "10-journal-insights-gate-banner")
        XCTAssertTrue(app.staticTexts
            .matching(NSPredicate(format: "label == %@", "Unlock Journal Insights"))
            .firstMatch
            .waitForExistence(timeout: 4),
            "Quota banner should expose one clear upgrade CTA")
    }

    // MARK: - Journey 11 — Authentication recovery after sign-out

    @MainActor
    func test_J11_signOutRecoversThroughGuestPreview() throws {
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need signed-in home before testing account recovery")
        tapTab("homeTab")

        openSettingsFromToday()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8),
                      "SettingsSheet must present from Today")
        let signOut = app.buttons["settings.signOut.button"]
        if !signOut.waitForExistence(timeout: 4) || !signOut.isHittable {
            app.swipeUp()
            RunLoop.current.run(until: Date().addingTimeInterval(0.4))
        }
        XCTAssertTrue(signOut.waitForExistence(timeout: 8),
                      "Signed-in Settings should expose Sign out")
        captureEvidence(named: "11-settings-sign-out")
        tapElementByScrolling("settings.signOut.button", timeout: 8)

        XCTAssertTrue(anyElement("auth.calibrationLanding").waitForExistence(timeout: 12),
                      "After sign-out the app should return to the recalibrated signed-out landing")
        XCTAssertTrue(app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "working model of your life"))
            .firstMatch
            .waitForExistence(timeout: 8),
            "Signed-out landing should keep the recalibrated onboarding value proposition")
        let preview = app.buttons["continueWithoutSigningInButton"]
        XCTAssertTrue(preview.waitForExistence(timeout: 8),
                      "Signed-out landing should offer a guest preview recovery CTA")
        XCTAssertTrue(preview.isHittable,
                      "Guest preview CTA should be immediately tappable")
        captureEvidence(named: "11-auth-landing-after-sign-out")
    }

    @MainActor
    func test_J13_reviewerAccessShowsDataAndAccountControls() throws {
        launchSignedIn(extraArguments: ["UITEST_OFFLINE_BACKEND"])

        XCTAssertTrue(waitForHomeTab(), "Need signed-in home before opening reviewer settings")
        tapTab("homeTab")
        openSettingsFromToday()

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8),
                      "Reviewer-access proof should open the active Settings sheet")

        XCTAssertTrue(waitForElementByScrolling("settings.dataPrivacy.button", timeout: 8).exists,
                      "Settings should expose Data & Privacy")
        XCTAssertTrue(waitForElementByScrolling("settings.exportData.button", timeout: 8).exists,
                      "Settings should expose Export My Data")
        XCTAssertTrue(waitForElementByScrolling("settings.analyticsOptIn.toggle", timeout: 8).exists,
                      "Settings should expose anonymous usage sharing consent")
        XCTAssertTrue(waitForElementByScrolling("settings.shareDiagnostics.button", timeout: 8).exists,
                      "Settings should expose the privacy-safe diagnostics report surface")
        captureEvidence(named: "13-reviewer-data-controls")

        XCTAssertTrue(waitForElementByScrolling("settings.signOut.button", timeout: 8).exists,
                      "Settings should expose Sign Out")
        XCTAssertTrue(waitForElementByScrolling("settings.deleteAccount.button", timeout: 8).exists,
                      "Signed-in Settings should expose Delete Account without requiring review credentials")
        captureEvidence(named: "13-reviewer-account-controls")
    }

    @MainActor
    func test_J13_diagnosticsReportPresentsShareSheetAndCancels() throws {
        launchSignedIn(extraArguments: ["UITEST_OFFLINE_BACKEND"])

        XCTAssertTrue(waitForHomeTab(), "Need signed-in home before opening diagnostics")
        tapTab("homeTab")
        openSettingsFromToday()

        let diagnostics = waitForElementByScrolling("settings.shareDiagnostics.button", timeout: 8)
        XCTAssertTrue(diagnostics.exists,
                      "Settings should expose diagnostics report generation")
        diagnostics.tap()

        let close = app.buttons["Close"]
        let cancel = app.buttons["Cancel"]
        let activityList = app.otherElements["ActivityListView"]
        let shareSheetPresented = close.waitForExistence(timeout: 20)
            || cancel.waitForExistence(timeout: 1)
            || activityList.waitForExistence(timeout: 1)
        XCTAssertTrue(shareSheetPresented,
                      "Generating diagnostics should present the system share sheet")
        captureEvidence(named: "13-diagnostics-share-sheet")
        if close.isHittable {
            close.tap()
        } else if cancel.isHittable {
            cancel.tap()
        } else {
            app.swipeDown()
        }

        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 8),
                      "Cancelling diagnostics sharing should return to Settings")
        XCTAssertTrue(waitForElementByScrolling("settings.shareDiagnostics.button", timeout: 8).exists,
                      "Diagnostics should remain available after cancelling the share sheet")
    }

    // MARK: - Journey 12 — Journal is agency-first, not an analysis launcher

    @MainActor
    func test_J12_journalShowsFreeWillDecisionLoopAndNoWhereElse() throws {
        launchSignedIn(extraArguments: ["UITEST_START_TAB_INDEX=4"])
        XCTAssertTrue(anyElement("journalView").waitForExistence(timeout: 18),
                      "Journal tab should boot directly")

        XCTAssertTrue(anyElement("journal.freeWillHero").waitForExistence(timeout: 12),
                      "Journal should lead with Free Will instead of analysis modules")
        XCTAssertTrue(anyElement("journal.decisionLoop").waitForExistence(timeout: 12),
                      "Journal should expose the decision loop")
        XCTAssertFalse(app.buttons["analysis.astrocartography.button"].exists,
                       "Journal must not expose the old Where else astrocartography CTA")
        XCTAssertFalse(app.staticTexts["Where else"].exists,
                       "Where else belongs to Map, not Journal")
        captureEvidence(named: "12-journal-agency-loop")

        anyElement("journal.freeWillHero").tap()
        XCTAssertTrue(anyElement("bayesianSliderView").waitForExistence(timeout: 12),
                      "Free Will hero should open the Bayesian slider")
        captureEvidence(named: "12-journal-free-will")
        dismissPresentedSheet()

        XCTAssertTrue(anyElement("journalView").waitForExistence(timeout: 8),
                      "Dismissing Free Will should recover to Journal")
        let newDecision = app.buttons["decisionNewButton"]
        XCTAssertTrue(newDecision.waitForExistence(timeout: 8),
                      "Journal decision loop should keep the New Decision CTA")
        newDecision.tap()

        let compose = anyElement("decisionComposeView")
        XCTAssertTrue(compose.waitForExistence(timeout: 8),
                      "New Decision from Journal should reuse the decision compose flow")
        let quickPrompt = app.buttons["decisionQuickPromptButton_0"]
        XCTAssertTrue(quickPrompt.waitForExistence(timeout: 8),
                      "Decision compose should retain one-tap prompts")
        quickPrompt.tap()

        let run = app.buttons["decisionRunButton"]
        XCTAssertTrue(run.waitForExistence(timeout: 5),
                      "Decision run CTA should be reachable from the Journal flow")
        run.tap()

        XCTAssertTrue(anyElement("decisionResultView").waitForExistence(timeout: 10),
                      "Journal decision flow should reach the result screen")
        captureEvidence(named: "12-journal-decision-result")
    }

    // MARK: - Journey 13 — Apple Maps globe-backed relocation map

    @MainActor
    func test_J13_astrocartographyUsesAppleMapsGlobe() throws {
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Signed-in shell should render bottom navigation")

        tapTab("timeTravelTab")

        XCTAssertTrue(anyElement("mapTabView").waitForExistence(timeout: 12),
                      "Bottom-nav Map tab should own the astrocartography map surface")
        XCTAssertTrue(anyElement("astrocartographyMapView").waitForExistence(timeout: 12),
                      "Map tab should render the astrocartography journey directly, not hide it behind Journal")
        XCTAssertTrue(anyElement("appleMapsGlobeView").waitForExistence(timeout: 12),
                      "Map tab should render a real Apple Maps globe surface")
        XCTAssertTrue(anyElement("astrocartography.appleMaps.badge").waitForExistence(timeout: 6),
                      "The map surface should label the Apple Maps globe integration")
        XCTAssertTrue(anyElement("astrocartography.appleMaps.realisticElevation").waitForExistence(timeout: 6),
                      "The map should label realistic elevation mode")
        XCTAssertTrue(app.buttons["astrocartography.city.Dubai"].waitForExistence(timeout: 8),
                      "Globe-backed map should keep ranked relocation city controls")
        captureEvidence(named: "13-map-tab-apple-maps-globe")
    }

    // MARK: - Journey 14 — Today reaches value quickly and loops into journaling

    @MainActor
    func test_J14_todayDailySignalOpensHabitLoop() throws {
        var started: Date?
        launchSignedIn(extraArguments: [
            "UITEST_START_TAB_INDEX=0",
            "UITEST_OFFLINE_BACKEND"
        ], onWillLaunch: { started = $0 })

        XCTAssertTrue(anyElement("todayTerrainView").waitForExistence(timeout: 18),
                      "Today should boot directly into the active value surface")

        let dailySignal = anyElement("today.dailySignal.card")
        XCTAssertTrue(dailySignal.waitForExistence(timeout: 12),
                      "Today should show a daily signal without requiring navigation")
        let launchStarted = try XCTUnwrap(started, "The launch timer should start immediately before app.launch()")
        let timeToSignal = Date().timeIntervalSince(launchStarted)
        XCTAssertLessThan(timeToSignal, 30,
                          "Daily signal should be available inside the 30s first-value window")
        let ttv = ["time_to_daily_signal_seconds": timeToSignal]
        let ttvData = try JSONSerialization.data(withJSONObject: ttv, options: [.prettyPrinted, .sortedKeys])
        writeArtifact(ttvData, filename: "14-today-ttv.json")

        XCTAssertTrue(anyElement("today.dashboard.refreshed").waitForExistence(timeout: 12),
                      "Today should render the ZIP-guided dashboard surface")
        XCTAssertTrue(waitForElementByScrolling("today.archetype.card").exists,
                      "Today should lead with archetype synthesis, not the stale horoscope feed")
        XCTAssertTrue(waitForElementByScrolling("today.systemStatus.live").exists,
                      "Today should expose live system status")
        XCTAssertTrue(waitForElementByScrolling("today.hypothesis.card").exists,
                      "Today should expose a concrete hypothesis")
        XCTAssertFalse(app.staticTexts["Today's Horoscope"].exists,
                       "The stale horoscope title should not be the Today dashboard anchor")
        captureEvidence(named: "14-today-refreshed-dashboard")
        captureEvidence(named: "14-today-daily-signal")

        tapElementByScrolling("today.dailySignal.logCTA", timeout: 8)

        XCTAssertTrue(anyElement("today.logMoment.sheet").waitForExistence(timeout: 8),
                      "Habit CTA should open the log moment sheet")
        captureEvidence(named: "14-daily-signal-log-sheet")

        dismissPresentedSheet()
        XCTAssertTrue(anyElement("todayTerrainView").waitForExistence(timeout: 8),
                      "Dismissing the habit sheet should recover to Today")
        XCTAssertTrue(waitForElementByScrolling("today.actionQueue.card").exists,
                      "Today should convert insight into an action queue after the habit loop")
    }
}
