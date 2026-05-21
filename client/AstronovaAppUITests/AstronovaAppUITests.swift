//
//  AstronovaAppUITests.swift
//  AstronovaAppUITests
//
//  Created by Sankalp Thakur on 6/6/25.
//

import XCTest

final class AstronovaAppUITests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.

        // In UI tests it is usually best to stop immediately when a failure occurs.
        continueAfterFailure = false

        // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    @MainActor
    func testExample() throws {
        // UI tests must launch the application that they test.
        let app = XCUIApplication()
        app.launch()

        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    @MainActor
    func testFirstRunGuestOnboardingAcceptsNameEntry() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET", "UITEST_ENABLE_LOGGING"]
        app.launch()

        let guestButtonByIdentifier = app.buttons["continueWithoutSigningInButton"]
        let guestButton = guestButtonByIdentifier.exists ? guestButtonByIdentifier : app.buttons["Continue without signing in"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 12), "Guest CTA should be visible on first launch")
        guestButton.tap()

        let profileSetup = app.descendants(matching: .any)["profileSetupView"]
        XCTAssertTrue(profileSetup.waitForExistence(timeout: 12), "Guest flow should enter profile setup without hanging")

        let primaryButtonByIdentifier = app.descendants(matching: .any)["saveProfileButton"]
        let primaryButton = primaryButtonByIdentifier.waitForExistence(timeout: 4)
            ? primaryButtonByIdentifier
            : app.buttons["Begin Journey"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 8), "Profile setup primary CTA should be available")
        primaryButton.tap()

        let nameFieldByIdentifier = app.descendants(matching: .any)["profileNameField"]
        let nameField = nameFieldByIdentifier.exists ? nameFieldByIdentifier : app.textFields["Profile name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 8), "Name field should expose a stable UI-test identifier")
        nameField.tap()
        nameField.typeText("Ava")

        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", "Ava")).firstMatch.waitForExistence(timeout: 5), "Typed name should populate validation copy")
        let continueButtonByIdentifier = app.descendants(matching: .any)["saveProfileButton"]
        let continueButton = continueButtonByIdentifier.waitForExistence(timeout: 4)
            ? continueButtonByIdentifier
            : app.buttons["Continue"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 8), "Continue CTA should be available after valid name entry")
        continueButton.tap()

        XCTAssertTrue(app.datePickers["birthDatePicker"].waitForExistence(timeout: 8), "Continue should advance to birth-date step after a valid name")
    }

    /// Regression test for the 2026-05-21 audit P1 fix: the onboarding
    /// name regex used to be `[a-zA-Z\s\-']` which rejected every non-ASCII
    /// script (José, Müller, María, أحمد, राज, கார்த்திக், 田中). The fix
    /// switches to `CharacterSet.letters` (Unicode general category L*).
    /// This test pins the contract so a regression won't slip back in.
    @MainActor
    func testOnboardingAcceptsUnicodeName() throws {
        let app = XCUIApplication()
        app.launchArguments = ["UITEST_RESET", "UITEST_ENABLE_LOGGING"]
        app.launch()

        // Guest path → profile setup
        let guestButton = app.buttons["continueWithoutSigningInButton"]
        XCTAssertTrue(guestButton.waitForExistence(timeout: 12), "Guest CTA missing")
        guestButton.tap()

        let primaryButton = app.descendants(matching: .any)["saveProfileButton"]
        XCTAssertTrue(primaryButton.waitForExistence(timeout: 8), "Begin Journey CTA missing")
        primaryButton.tap()

        let nameField = app.descendants(matching: .any)["profileNameField"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 8), "Name field missing")
        nameField.tap()
        // A name with a Latin extended grapheme — should validate as a letter
        // under the Unicode-aware regex but fail under the legacy ASCII regex.
        nameField.typeText("José")

        // Continue must enable + advance to birth-date step. The regression
        // shape would be: Continue stays disabled (button never advances) and
        // the date picker is never reached.
        let continueButton = app.descendants(matching: .any)["saveProfileButton"]
        XCTAssertTrue(continueButton.waitForExistence(timeout: 4))
        continueButton.tap()

        XCTAssertTrue(
            app.datePickers["birthDatePicker"].waitForExistence(timeout: 8),
            "Continue should advance to birth-date step for a Unicode name"
        )
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
