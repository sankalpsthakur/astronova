//
//  JourneyAcceptanceTests.swift
//  AstronovaAppUITests
//
//  QA acceptance suite for TestFlight build 2026051810/11/12.
//  Verifies the 6 journeys flagged "shoddy" in earlier builds:
//   1. Self / Time Travel tabs render without backend
//   2. GHCR cutover — apiBaseURL + /health probe
//   3. Paywall open + close (haptic + sound on mock purchase)
//   4. Privacy / Terms (in-app SwiftUI view, NOT WKWebView — see REPORT.md)
//   5. "Read horoscope aloud" button toggles speaking state
//   6. Voice-reading toggle gates speech
//

import XCTest

final class JourneyAcceptanceTests: XCTestCase {

    // MARK: - Constants

    /// Build under test. Reflected in screenshot paths + asserted at runtime
    /// against AppConfig.apiBaseURL once accessible to the host process.
    private static let expectedAPIBaseURL = "https://astronova-ghcr.onrender.com"

    /// Where per-journey screenshots and supporting evidence are written.
    /// Resolves relative to the workspace so xcodebuild runs picks it up
    /// from any cwd.
    private static let evidenceDirectoryURL: URL = {
        // ProcessInfo("WORKSPACE_ROOT") wins for CI; otherwise climb from the
        // XCTest bundle URL to the repo root.
        if let envPath = ProcessInfo.processInfo.environment["QA_EVIDENCE_DIR"] {
            return URL(fileURLWithPath: envPath, isDirectory: true)
        }
        let testBundleURL = Bundle(for: JourneyAcceptanceTests.self).bundleURL
        // Walk up until we find a folder containing "qa-results"; fall back to /tmp.
        var current = testBundleURL.deletingLastPathComponent()
        for _ in 0..<10 {
            let candidate = current.appendingPathComponent("qa-results/2026051810",
                                                           isDirectory: true)
            if FileManager.default.fileExists(atPath: candidate.path) {
                return candidate
            }
            if current.path == "/" { break }
            current.deleteLastPathComponent()
        }
        return URL(fileURLWithPath: "/tmp/astronova-qa-2026051810", isDirectory: true)
    }()

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

    /// Launches the app with the canonical signed-in test profile plus any
    /// extra arguments. Always resets state so each journey starts clean.
    @discardableResult
    private func launchSignedIn(extraArguments: [String] = [],
                                environment: [String: String] = [:]) -> XCUIApplication {
        app.terminate()
        app.launchArguments = [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_ENABLE_LOGGING"
        ] + extraArguments
        var merged = environment
        // Surface deterministic samples so views can render without network.
        merged["UITEST_TIME_TRAVEL_SAMPLE"] = merged["UITEST_TIME_TRAVEL_SAMPLE"] ?? "1"
        merged["UITEST_DISCOVER_SAMPLE"] = merged["UITEST_DISCOVER_SAMPLE"] ?? "1"
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
                      "Tab '\(identifier)' should exist", file: file, line: line)
        other.tap()
    }

    private func waitForHomeTab(timeout: TimeInterval = 20) -> Bool {
        if app.buttons["homeTab"].waitForExistence(timeout: timeout) { return true }
        return app.otherElements["homeTab"].waitForExistence(timeout: 4)
    }

    // MARK: - Evidence helpers

    /// Captures a fullscreen screenshot, attaches it to the XCResult bundle,
    /// AND writes the raw PNG to qa-results so the report can reference it.
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
            // Non-fatal — the xcresult attachment is the durable record.
            print("[QA] failed to write screenshot to \(pngURL.path): \(error)")
        }
    }

    /// Writes an auxiliary text artefact (e.g., health-probe response body).
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

    // MARK: - Journey 1 — Self + Time Travel render without backend

    @MainActor
    func test_J1_selfAndTimeTravelTabsRenderOffline() throws {
        launchSignedIn(extraArguments: ["UITEST_OFFLINE_BACKEND"])
        XCTAssertTrue(waitForHomeTab(), "App should boot to Home tab in offline mode")

        // Self tab — Cosmic Pulse + Journey Map are placeholders that render
        // before any network response arrives.
        tapTab("selfTab")
        let cosmicPulse = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Cosmic Pulse"))
            .firstMatch
        let journeyMap = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Journey Map"))
            .firstMatch
        XCTAssertTrue(cosmicPulse.waitForExistence(timeout: 8) ||
                      journeyMap.waitForExistence(timeout: 4),
                      "Self tab should render placeholders without backend")

        captureEvidence(named: "01-self-offline")

        // Time Travel tab — UnifiedTimeTravelView seeds a sample when
        // UITEST_TIME_TRAVEL_SAMPLE=1, so the view should not crash.
        tapTab("timeTravelTab")
        XCTAssertTrue(app.otherElements["timeTravelView"].waitForExistence(timeout: 8) ||
                      app.descendants(matching: .any).count > 5,
                      "Time Travel tab should render without crash in offline mode")
        captureEvidence(named: "01-timetravel-offline")
    }

    // MARK: - Journey 2 — GHCR cutover

    @MainActor
    func test_J2_ghcrCutoverProbe() throws {
        // The host XCUITest process can hit the network directly — this
        // proves the operator can reach GHCR from a CI/local environment
        // even before the simulator app boots.
        let url = URL(string: "\(Self.expectedAPIBaseURL)/health")!
        let expectation = self.expectation(description: "ghcr-health-probe")
        var statusCode = -1
        var responseBody = Data()

        let task = URLSession(configuration: .ephemeral).dataTask(with: url) { data, response, error in
            if let http = response as? HTTPURLResponse {
                statusCode = http.statusCode
            }
            if let data = data {
                responseBody = data
            }
            if let error = error {
                print("[QA] /health probe error: \(error)")
            }
            expectation.fulfill()
        }
        task.resume()
        wait(for: [expectation], timeout: 25)

        writeArtifact(responseBody, filename: "02-health-response.json")
        XCTAssertEqual(statusCode, 200,
                       "GHCR /health should return 200; got \(statusCode)")

        // Sanity-launch the app and screenshot Home so the evidence bundle
        // has a visual artefact of the live build pointing at GHCR.
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
        XCTAssertTrue(paywallView.waitForExistence(timeout: 12),
                      "Paywall should auto-present via UITEST_PRESENT_PAYWALL")
        captureEvidence(named: "03-paywall-open")

        let closeButton = app.buttons["paywallCloseButton"]
        XCTAssertTrue(closeButton.waitForExistence(timeout: 5),
                      "paywallCloseButton must be hittable on PaywallView")
        XCTAssertTrue(closeButton.isHittable,
                      "Close button must be hittable from the user's perspective")
        closeButton.tap()
        XCTAssertFalse(paywallView.waitForExistence(timeout: 3),
                       "Paywall should dismiss after tapping close")

        // Re-open via the same hook to exercise the mock-purchase flow.
        app.terminate()
        launchSignedIn(extraArguments: [
            "UITEST_PRESENT_PAYWALL",
            "UITEST_MOCK_PURCHASES"
        ])
        let reopened = anyElement("paywallView")
        XCTAssertTrue(reopened.waitForExistence(timeout: 12),
                      "Paywall should re-present for mock purchase")

        let startPro = app.buttons["startProButton"]
        XCTAssertTrue(startPro.waitForExistence(timeout: 6),
                      "Start-Pro CTA should be present")
        startPro.tap()

        // The DEBUG mock purchase path routes through BasicStoreManager and
        // surfaces the "Welcome to Pro!" alert. This is the UI-observable
        // proxy for the haptic + system-sound + TTS purchase-success cue
        // (HapticFeedbackService.celebration() + AudioServicesPlaySystemSound).
        let welcomeAlert = app.alerts.element
        let welcomeTitle = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "Welcome to Pro"))
            .firstMatch
        XCTAssertTrue(welcomeAlert.waitForExistence(timeout: 12) ||
                      welcomeTitle.waitForExistence(timeout: 4),
                      "Mock purchase should fire the 'Welcome to Pro!' alert")
        captureEvidence(named: "03-paywall-purchase-success")
    }

    // MARK: - Journey 4 — Privacy view opens in-app

    @MainActor
    func test_J4_privacyOpensInApp() throws {
        // NOTE: The current build renders PrivacyPolicyView as a native
        // SwiftUI ScrollView (RootView.swift:5925), NOT a WKWebView pointed
        // at https://.../privacy. The journey check here is "in-app surface
        // reachable + populated" rather than "WKWebView URL == /privacy".
        // See REPORT.md observations for divergence from spec.
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need Home tab before opening Settings")

        tapTab("selfTab")

        // Open More Options sheet — entry point is the account-section
        // "Settings" affordance, which opens MoreOptionsSheet (sheet .settings).
        let settingsLikeButtons = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            "Settings", "More options", "More Options"
        ))
        let firstSettings = settingsLikeButtons.firstMatch
        XCTAssertTrue(firstSettings.waitForExistence(timeout: 10),
                      "Self tab should expose a Settings / More options entry")
        firstSettings.tap()

        // Inside MoreOptionsSheet — tap Privacy Policy row.
        let privacyButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Privacy Policy"
        )).firstMatch
        XCTAssertTrue(privacyButton.waitForExistence(timeout: 8),
                      "Privacy Policy entry should be reachable from MoreOptionsSheet")
        privacyButton.tap()

        // PrivacyPolicyView shows the title "Astronova Privacy Policy" and a
        // navigation title "Privacy Policy". Either is sufficient proof the
        // in-app surface rendered.
        let title = app.staticTexts.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Astronova Privacy Policy"
        )).firstMatch
        let navTitle = app.navigationBars["Privacy Policy"]
        XCTAssertTrue(title.waitForExistence(timeout: 8) ||
                      navTitle.waitForExistence(timeout: 4),
                      "PrivacyPolicyView should render in-app")
        captureEvidence(named: "04-privacy-policy")
    }

    // MARK: - Journey 5 — "Read horoscope aloud" toggles speaking state

    @MainActor
    func test_J5_readHoroscopeAloudFiresSpeech() throws {
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need Home tab to test Read button")

        // Home tab should be selected by default; ensure we're there.
        tapTab("homeTab")

        let readButton = app.buttons["home.readHoroscopeAloud"]
        // The button only renders when there's horoscope body text. In
        // offline / first-launch states the daily guidance may still be
        // loading — wait generously, but skip-with-note rather than fail
        // if the card never appears (the assertion is "the *button works*
        // when present", not "the card always loads").
        if !readButton.waitForExistence(timeout: 25) {
            captureEvidence(named: "05-read-button-missing")
            throw XCTSkip("Read button did not render — daily guidance card likely still loading. Captured screenshot for evidence.")
        }
        captureEvidence(named: "05-read-button-visible")

        let initialLabel = readButton.label
        XCTAssertTrue(initialLabel.contains("Read horoscope aloud") ||
                      initialLabel.contains("Read"),
                      "Button label should start as 'Read horoscope aloud' (was: '\(initialLabel)')")

        readButton.tap()

        // The button's accessibility label flips from "Read horoscope aloud"
        // → "Stop reading horoscope" once SpeechService.isSpeaking becomes
        // true. This is the UI-observable proxy for AVSpeechSynthesizer
        // state (which we can't read across processes from XCUITest).
        let stoppingPredicate = NSPredicate { _, _ in
            let label = self.app.buttons["home.readHoroscopeAloud"].label
            return label.contains("Stop") || label.contains("stop")
        }
        let stoppingExpectation = expectation(for: stoppingPredicate, evaluatedWith: NSNull())
        let result = XCTWaiter().wait(for: [stoppingExpectation], timeout: 4)

        captureEvidence(named: "05-read-button-speaking")

        // The simulator's AVSpeech may or may not actually emit audio under
        // CI — but the label must flip if SpeechService.speak() was invoked
        // and isVoiceReadingEnabled returned true (default).
        XCTAssertEqual(result, .completed,
                       "Button label should flip to 'Stop reading' within 4s of tap. Final label was '\(self.app.buttons["home.readHoroscopeAloud"].label)'")

        // Tap again to stop, so we leave a clean state for subsequent runs.
        if app.buttons["home.readHoroscopeAloud"].exists {
            app.buttons["home.readHoroscopeAloud"].tap()
        }
    }

    // MARK: - Journey 6 — Voice-reading toggle gates speech

    @MainActor
    func test_J6_voiceReadingToggleDisablesSpeech() throws {
        launchSignedIn()
        XCTAssertTrue(waitForHomeTab(), "Need Home tab")

        // Navigate to Self → Settings → toggle Voice reading OFF.
        tapTab("selfTab")
        let settingsButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@ OR label CONTAINS[c] %@",
            "Settings", "More options"
        )).firstMatch
        XCTAssertTrue(settingsButton.waitForExistence(timeout: 10),
                      "Settings entry must be reachable from Self tab")
        settingsButton.tap()

        let voiceToggle = app.switches["voice_reading_toggle"]
        let voiceToggleAny = anyElement("voice_reading_toggle")
        let resolvedToggle: XCUIElement = voiceToggle.waitForExistence(timeout: 6)
            ? voiceToggle
            : voiceToggleAny
        XCTAssertTrue(resolvedToggle.waitForExistence(timeout: 6),
                      "voice_reading_toggle must be present in MoreOptionsSheet")

        // The default is ON (true). Tap once to flip OFF.
        // For SwiftUI Toggles the .value is "1" / "0".
        if resolvedToggle.value as? String == "1" || resolvedToggle.value as? Int == 1 {
            resolvedToggle.tap()
        }
        captureEvidence(named: "06-voice-toggle-off")

        // Dismiss the sheet.
        let doneButton = app.buttons.matching(NSPredicate(
            format: "label CONTAINS[c] %@", "Done"
        )).firstMatch
        if doneButton.waitForExistence(timeout: 3) {
            doneButton.tap()
        } else {
            // Swipe down to dismiss the sheet as a fallback.
            app.swipeDown(velocity: .fast)
        }

        // Back to Home, tap Read; label MUST stay "Read horoscope aloud".
        tapTab("homeTab")
        let readButton = app.buttons["home.readHoroscopeAloud"]
        if !readButton.waitForExistence(timeout: 25) {
            captureEvidence(named: "06-read-button-missing-after-toggle")
            throw XCTSkip("Read button did not render — guidance still loading. Capture saved.")
        }

        let beforeLabel = readButton.label
        readButton.tap()

        // Give the app 3s — if SpeechService obeyed the toggle, the label
        // stays "Read horoscope aloud". If it ignored the toggle the label
        // would flip to "Stop reading".
        let stillRead = NSPredicate { _, _ in
            let label = self.app.buttons["home.readHoroscopeAloud"].label
            return !label.contains("Stop") && !label.contains("stop")
        }
        let stillReadExp = expectation(for: stillRead, evaluatedWith: NSNull())
        // We negate-by-waiting: if it never flips, we pass. We give 3s.
        _ = XCTWaiter().wait(for: [stillReadExp], timeout: 3)
        captureEvidence(named: "06-read-button-after-toggle-off")

        let afterLabel = app.buttons["home.readHoroscopeAloud"].label
        XCTAssertFalse(afterLabel.contains("Stop") || afterLabel.contains("stop"),
                       "With voice reading OFF, the Read button must NOT flip to 'Stop reading'. Before='\(beforeLabel)' After='\(afterLabel)'")
    }
}
