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
