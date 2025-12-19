//
//  MonetizationJourneyTests.swift
//  AstronovaAppUITests
//
//  E2E UI Tests for Monetization User Journeys
//
//  Prerequisites:
//  - Backend server running (python server/app.py)
//  - Simulator selected (iPhone 15 recommended)
//  - Tests use BasicStoreManager for mock purchases
//

import XCTest

final class MonetizationJourneyTests: XCTestCase {

    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Helper Methods

    private func anyElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier == %@", identifier)).firstMatch
    }

    private func firstElement(withIdentifierPrefix prefix: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier BEGINSWITH %@", prefix)).firstMatch
    }

    private func launchSignedIn(arguments: [String], environment: [String: String] = [:]) {
        app.launchArguments = arguments
        app.launchEnvironment = environment
        app.launch()
        let homeTabButton = app.buttons["homeTab"]
        if homeTabButton.waitForExistence(timeout: 20) {
            return
        }
        // SwiftUI buttons can sometimes surface as `otherElements` in XCTest queries.
        if app.otherElements["homeTab"].waitForExistence(timeout: 5) {
            return
        }
        XCTFail("Home tab should be visible after launch.\n\nDebug:\n\(app.debugDescription)")
    }

    private func tapTab(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons[identifier]
        if button.waitForExistence(timeout: 10) {
            button.tap()
            return
        }
        let other = app.otherElements[identifier]
        XCTAssertTrue(other.waitForExistence(timeout: 10), "Tab '\(identifier)' should exist", file: file, line: line)
        other.tap()
    }

    private func waitForNotExists(_ element: XCUIElement, timeout: TimeInterval = 8) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        while Date() < deadline {
            if !element.exists { return true }
            RunLoop.current.run(until: Date().addingTimeInterval(0.1))
        }
        return !element.exists
    }

    private func chatInputElement() -> XCUIElement {
        if app.textFields["chatInputField"].exists { return app.textFields["chatInputField"] }
        if app.textViews["chatInputField"].exists { return app.textViews["chatInputField"] }
        return app.textFields.firstMatch
    }

    // MARK: - Journey A: Free -> Hits Limit -> Buys Credits -> Continues

    @MainActor
    func testJourneyA_FreeToCreditPurchase() throws {
        launchSignedIn(arguments: [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SET_FREE_LIMIT_REACHED",
            "UITEST_SET_CHAT_CREDITS",
            "UITEST_MOCK_PURCHASES",
            "UITEST_ENABLE_LOGGING"
        ], environment: [
            "UITEST_CHAT_CREDITS_VALUE": "0"
        ])

        tapTab("askTab")

        let getPackages = anyElement("getChatPackagesButton")
        XCTAssertTrue(getPackages.waitForExistence(timeout: 8), "Get Chat Packages CTA should be visible")
        getPackages.tap()

        let packagesSheet = anyElement("chatPackagesSheet")
        XCTAssertTrue(
            packagesSheet.waitForExistence(timeout: 8) || app.navigationBars["Chat Packages"].waitForExistence(timeout: 8),
            "Chat packages sheet should open"
        )

        let buyButton = firstElement(withIdentifierPrefix: "chatPackBuyButton_")
        XCTAssertTrue(buyButton.waitForExistence(timeout: 8), "A chat pack buy button should exist")
        buyButton.tap()
        sleep(1)

        let done = anyElement("doneButton")
        XCTAssertTrue(done.waitForExistence(timeout: 5), "Done button should exist to dismiss the sheet")
        done.tap()

        let input = chatInputElement()
        XCTAssertTrue(input.waitForExistence(timeout: 8), "Chat input should exist")
        input.tap()
        input.typeText("What is my horoscope today?")

        let send = anyElement("sendMessageButton")
        XCTAssertTrue(send.waitForExistence(timeout: 5), "Send button should exist")
        send.tap()

        XCTAssertFalse(app.staticTexts["DAILY LIMIT REACHED"].exists, "Should not be blocked once credits exist")
    }

    // MARK: - Journey B: Free -> Paywall -> Pro -> Unlimited Chat

    @MainActor
    func testJourneyB_FreeToProSubscription() throws {
        launchSignedIn(arguments: [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_SET_FREE_LIMIT_REACHED",
            "UITEST_SET_CHAT_CREDITS",
            "UITEST_MOCK_PURCHASES",
            "UITEST_ENABLE_LOGGING"
        ], environment: [
            "UITEST_CHAT_CREDITS_VALUE": "0"
        ])

        tapTab("askTab")

        let goUnlimited = anyElement("goUnlimitedButton")
        if !goUnlimited.waitForExistence(timeout: 8) {
            XCTFail("Go Unlimited CTA should exist on the banner.\n\nDebug:\n\(app.debugDescription)")
            return
        }
        goUnlimited.tap()

        let paywall = anyElement("paywallView")
        XCTAssertTrue(paywall.waitForExistence(timeout: 8), "Paywall should open")

        let startPro = anyElement("startProButton")
        XCTAssertTrue(startPro.waitForExistence(timeout: 8), "Start Pro button should exist")
        startPro.tap()

        XCTAssertTrue(waitForNotExists(paywall, timeout: 12), "Paywall should dismiss after Pro purchase")

        // Refresh Ask tab state (it reads subscription status onAppear)
        tapTab("homeTab")
        tapTab("askTab")

        XCTAssertFalse(anyElement("goUnlimitedButton").exists, "Free limit banner should not show for Pro users")
    }

    // MARK: - Journey C: Report Purchase -> Generation -> Library

    @MainActor
    func testJourneyC_ReportPurchaseAndLibrary() throws {
        launchSignedIn(arguments: [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_MOCK_PURCHASES",
            "UITEST_ENABLE_LOGGING"
        ])

        tapTab("manageTab")

        let reportsShopLink = app.staticTexts["Reports Shop"]
        XCTAssertTrue(reportsShopLink.waitForExistence(timeout: 10), "Reports Shop entry should exist in Manage")
        reportsShopLink.tap()

        XCTAssertTrue(
            anyElement("reportsStoreView").waitForExistence(timeout: 8) || app.navigationBars["Reports Shop"].waitForExistence(timeout: 8),
            "Reports shop should open"
        )

        let reportBuyButton = firstElement(withIdentifierPrefix: "reportBuyButton_")
        XCTAssertTrue(reportBuyButton.waitForExistence(timeout: 8), "A report buy button should exist")
        reportBuyButton.tap()

        // Allow backend generation to complete.
        sleep(2)

        let done = anyElement("doneButton")
        XCTAssertTrue(done.waitForExistence(timeout: 8), "Done button should exist to exit the shop")
        done.tap()

        // Back to Discover and open the library.
        tapTab("homeTab")

        let viewAll = app.buttons.matching(NSPredicate(format: "label BEGINSWITH 'View All'")).firstMatch
        XCTAssertTrue(viewAll.waitForExistence(timeout: 12), "View All should appear once at least one report exists")
        viewAll.tap()

        XCTAssertTrue(anyElement("myReportsView").waitForExistence(timeout: 10), "My Reports library should open")

        let anyReport = firstElement(withIdentifierPrefix: "reportRow_")
        XCTAssertTrue(anyReport.waitForExistence(timeout: 10), "At least one report should appear in the library")
    }

    // MARK: - Journey D: Time Travel Blocked → Complete Profile → Dashas Load

    @MainActor
    func testJourneyD_TimeTravelIncompleteProfile() throws {
        // Launch with minimal profile (missing birth time/location)
        launchSignedIn(arguments: [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_MINIMAL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_ENABLE_LOGGING"
        ])

        // Navigate to Time Travel tab
        tapTab("timeTravelTab")

        // Verify incomplete profile prompt is shown
        let incompletePrompt = anyElement("incompleteProfilePrompt")
        XCTAssertTrue(incompletePrompt.waitForExistence(timeout: 10), "Incomplete profile prompt should appear for users missing birth data")

        // Verify the CTA button exists
        let completeBirthDataButton = anyElement("completeBirthDataButton")
        XCTAssertTrue(completeBirthDataButton.waitForExistence(timeout: 5), "Complete Birth Data button should be visible")

        // Tap the CTA to go to profile editing
        completeBirthDataButton.tap()

        // Wait for profile edit view to appear (should have birth time picker)
        let birthTimePicker = anyElement("birthTimePicker")
        let profileEditAppeared = birthTimePicker.waitForExistence(timeout: 10) ||
            app.navigationBars["Edit Profile"].waitForExistence(timeout: 5)
        XCTAssertTrue(profileEditAppeared, "Profile edit view should open with birth time picker")
    }

    // MARK: - Smoke Test: App Launch and Basic Navigation

    @MainActor
    func testAppLaunchAndNavigation() throws {
        launchSignedIn(arguments: [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING"
        ])

        tapTab("homeTab")
        tapTab("connectTab")
        tapTab("timeTravelTab")
        tapTab("askTab")
        tapTab("manageTab")
    }
}
