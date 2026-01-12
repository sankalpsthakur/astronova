//
//  AccessibilityTests.swift
//  AstronovaAppUITests
//
//  Basic accessibility coverage for key flows
//

import XCTest

final class AccessibilityTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func launchSignedIn(extraArguments: [String] = []) {
        app.launchArguments = [
            "UITEST_RESET",
            "UITEST_SEED_PROFILE_FULL",
            "UITEST_SKIP_ONBOARDING",
            "UITEST_ENABLE_LOGGING"
        ] + extraArguments
        app.launch()
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

    private func chatInputElement() -> XCUIElement {
        if app.textFields["chatInputField"].exists { return app.textFields["chatInputField"] }
        if app.textViews["chatInputField"].exists { return app.textViews["chatInputField"] }
        return app.textFields.firstMatch
    }

    @MainActor
    func testMainTabsAccessible() throws {
        launchSignedIn()

        XCTAssertTrue(app.buttons["homeTab"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.buttons["timeTravelTab"].exists)
        XCTAssertTrue(app.buttons["templeTab"].exists)
        XCTAssertTrue(app.buttons["connectTab"].exists)
        XCTAssertTrue(app.buttons["selfTab"].exists)
    }

    @MainActor
    func testDiscoverDomainCardsAccessible() throws {
        launchSignedIn()

        let anyDomainCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'domain'")).firstMatch
        XCTAssertTrue(anyDomainCard.waitForExistence(timeout: 15), "Expected a domain card to be accessible")
    }

    @MainActor
    func testOracleViewAccessibility() throws {
        launchSignedIn()

        tapTab("templeTab")

        let askOracle = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'Ask the Oracle'")).firstMatch
        XCTAssertTrue(askOracle.waitForExistence(timeout: 10), "Ask the Oracle card should be visible")
        askOracle.tap()

        let scrollList = app.scrollViews["chatMessagesList"]
        if scrollList.waitForExistence(timeout: 10) {
            XCTAssertTrue(scrollList.exists)
        } else {
            let otherList = app.otherElements["chatMessagesList"]
            XCTAssertTrue(otherList.waitForExistence(timeout: 10), "Chat messages list should be accessible")
        }

        let input = chatInputElement()
        XCTAssertTrue(input.waitForExistence(timeout: 10), "Chat input field should be accessible")

        let sendButton = app.buttons["sendMessageButton"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 10), "Send button should be accessible")
    }

    @MainActor
    func testDynamicTypeAccessibilityXXXL() throws {
        launchSignedIn(extraArguments: [
            "-UIPreferredContentSizeCategoryName",
            "UICTContentSizeCategoryAccessibilityXXXL"
        ])

        XCTAssertTrue(app.buttons["homeTab"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.exists)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "DynamicType_XXXL"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testTouchTargetMinimumSize() throws {
        launchSignedIn()

        let buttons = app.buttons.allElementsBoundByIndex.filter { $0.exists && $0.isHittable }
        for button in buttons {
            let frame = button.frame
            XCTAssertGreaterThanOrEqual(min(frame.size.width, frame.size.height), 44, "Button '\(button.label)' is below 44pt minimum")
        }
    }
}
