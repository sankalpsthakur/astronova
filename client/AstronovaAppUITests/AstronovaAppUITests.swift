//
//  AstronovaAppUITests.swift
//  AstronovaAppUITests
//
//  Created by Sankalp Thakur on 6/6/25.
//

import XCTest

final class AstronovaAppUITests: XCTestCase {

    private var evidenceDirectoryURL: URL {
        if let envPath = ProcessInfo.processInfo.environment["QA_EVIDENCE_DIR"] {
            return URL(fileURLWithPath: envPath, isDirectory: true)
        }
        return URL(fileURLWithPath: "/Users/sankalp/Projects/iosapps/astronova/qa-results/2026051816", isDirectory: true)
    }

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
        try? FileManager.default.createDirectory(at: evidenceDirectoryURL, withIntermediateDirectories: true)
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    private func captureEvidence(named name: String) {
        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        let pngURL = evidenceDirectoryURL.appendingPathComponent("\(name).png")
        try? screenshot.pngRepresentation.write(to: pngURL)
    }

    @MainActor
    func testFirstRunGuestOnboardingShowsCalibrationFlow() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET", "UITEST_ENABLE_LOGGING"]
        app.launch()

        let guestButtonByIdentifier = app.buttons["continueWithoutSigningInButton"]
        let guestButton = guestButtonByIdentifier.exists ? guestButtonByIdentifier : app.buttons["Preview calibration without signing in"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 12), "Guest CTA should be visible on first launch")
        guestButton.tap()

        let profileSetup = app.descendants(matching: .any)["profileSetupView"]
        XCTAssertTrue(profileSetup.waitForExistence(timeout: 12), "Guest flow should enter profile setup without hanging")
        XCTAssertTrue(app.descendants(matching: .any)["onboarding.calibrationSplash"].waitForExistence(timeout: 8), "First onboarding screen should be the new calibration splash")
        captureEvidence(named: "17-onboarding-calibration-splash")

        let primaryButtonByIdentifier = app.descendants(matching: .any)["saveProfileButton"]
        let primaryButton = primaryButtonByIdentifier.waitForExistence(timeout: 4)
            ? primaryButtonByIdentifier
            : app.buttons["Begin calibration"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 8), "Calibration primary CTA should be available")
        primaryButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["onboarding.birthCoordinates"].waitForExistence(timeout: 8), "Continue should advance to birth coordinates")
        XCTAssertTrue(app.datePickers["birthDatePicker"].waitForExistence(timeout: 8), "Birth-date picker should remain in the recalibrated flow")
        XCTAssertTrue(app.datePickers["birthTimePicker"].waitForExistence(timeout: 8), "Birth-time picker should remain in the recalibrated flow")
        let nameField = app.textFields["profileNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 8), "Name capture should remain in the recalibrated flow")
        nameField.tap()
        nameField.typeText("Arjun Rao")
        XCTAssertTrue(app.textFields["locationSearchField"].waitForExistence(timeout: 8), "Birth-place search should remain in the recalibrated flow")
        captureEvidence(named: "17-onboarding-birth-coordinates")

        let continueButtonByIdentifier = app.descendants(matching: .any)["saveProfileButton"]
        let continueButton = continueButtonByIdentifier.waitForExistence(timeout: 4)
            ? continueButtonByIdentifier
            : app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 8), "Continue CTA should be available after birth coordinates")
        continueButton.tap()

        XCTAssertTrue(app.descendants(matching: .any)["onboarding.phoneVector"].waitForExistence(timeout: 8), "Continue should advance to the phone Loshu vector screen")
        captureEvidence(named: "17-onboarding-phone-vector")
    }

    @MainActor
    func testOnboardingReachesContextPriorsAfterPhoneVector() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET", "UITEST_ENABLE_LOGGING"]
        app.launch()

        // Guest path → profile setup
        let guestButton = app.buttons["continueWithoutSigningInButton"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 12), "Guest CTA missing")
        guestButton.tap()

        let primaryButton = app.descendants(matching: .any)["saveProfileButton"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 8), "Begin calibration CTA missing")
        primaryButton.tap()

        let nameField = app.textFields["profileNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 8), "Name capture should remain in the recalibrated flow")
        nameField.tap()
        nameField.typeText("Arjun Rao")

        let continueButton = app.descendants(matching: .any)["saveProfileButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 4))
        continueButton.tap()

        XCTAssertTrue(continueButton.waitForExistence(timeout: 4))
        continueButton.tap()

        XCTAssertTrue(
            app.descendants(matching: .any)["onboarding.contextPriors"].waitForExistence(timeout: 8),
            "Continue should advance from phone vector to context priors"
        )
        captureEvidence(named: "17-onboarding-context-priors")
    }

    /// Regression test for the 2026-05-21 audit P2 fix: tapping
    /// "Continue without signing in" silently created an anonymous UUID and
    /// started analytics with no disclosure. The fix adds a caption under
    /// the button explaining what happens and pointing to the privacy
    /// toggle. This test pins that the caption is on-screen before the
    /// user makes a consent-shaped decision.
    @MainActor
    func testGuestModeDisclosureIsVisibleBeforeTap() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET", "UITEST_ENABLE_LOGGING"]
        app.launch()

        let guestButton = app.buttons["continueWithoutSigningInButton"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 12), "Guest CTA missing")

        // Caption ID guards against accidental removal of the disclosure.
        let disclosure = app.staticTexts["guestModeDisclosure"]
        XCTAssertTrue(
            disclosure.waitForExistence(timeout: 4),
            "Just-in-time disclosure caption must be visible on the auth gate"
        )
    }

    @MainActor
    func testLaunchPerformance() throws {
        if #available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 7.0, *) {
            // This measures how long it takes to launch your application.
            measure(metrics: [XCTApplicationLaunchMetric()]) {
                XCUIApplication().launch()
            }
        }
    }
}
