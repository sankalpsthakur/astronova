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
        XCTAssertTrue(app.buttons["timelineTab"].exists)
        XCTAssertTrue(app.buttons["matrixTab"].exists)
        XCTAssertTrue(app.buttons["selfTab"].exists)
    }

    @MainActor
    func testDiscoverDomainCardsAccessible() throws {
        launchSignedIn()

        let anyDomainCard = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] 'domain'")).firstMatch
        XCTAssertTrue(anyDomainCard.waitForExistence(timeout: 15), "Expected a domain card to be accessible")
    }

    @MainActor
    func testTimelineViewAccessibility() throws {
        launchSignedIn()

        tapTab("timelineTab")

        XCTAssertTrue(app.otherElements["timelineTabView"].waitForExistence(timeout: 15))
        XCTAssertTrue(app.otherElements["timeline.systemOverview"].exists)
        XCTAssertTrue(app.otherElements["timeline.dashaPulse"].exists)
        XCTAssertTrue(app.otherElements["predictionTimelineView"].exists)
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
