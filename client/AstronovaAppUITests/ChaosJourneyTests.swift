//
//  ChaosJourneyTests.swift
//  AstronovaAppUITests
//
//  Adversarial journey coverage with deterministic chaos.
//

import XCTest
import Foundation

final class ChaosJourneyTests: XCTestCase {

    private var app: XCUIApplication!
    private let homeTabs = ["homeTab", "templeTab", "connectTab", "selfTab", "timeTravelTab"]

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Deterministic RNG

    private struct LCGRandom {
        private var seed: UInt64

        init(seed: UInt64) {
            self.seed = seed
        }

        mutating func nextUInt32() -> UInt32 {
            seed = (seed &* 1_103_515_245 &+ 12_345) & 0x7fff_ffff_ffff
            return UInt32(seed >> 16)
        }

        mutating func nextStep(_ upperBound: Int) -> Int {
            guard upperBound > 0 else { return 0 }
            return Int(nextUInt32()) % upperBound
        }
    }

    private func launch(for profileMode: String, extraArguments: [String] = []) {
        app.terminate()
        app = XCUIApplication()
        app.launchEnvironment = ["UITEST_TIME_TRAVEL_SAMPLE": "1"]
        app.launchArguments = [
            "UITEST_RESET",
            profileMode,
            "UITEST_SKIP_ONBOARDING",
            "UITEST_MOCK_PURCHASES",
            "UITEST_ENABLE_LOGGING"
        ] + extraArguments
        app.launch()
        XCTAssertTrue(
            app.buttons["homeTab"].waitForExistence(timeout: 16) ||
                app.otherElements["homeTab"].waitForExistence(timeout: 5),
            "Home tab should be visible after launch"
        )
    }

    // MARK: - Element utilities

    private func tabCandidates(for identifier: String) -> [String] {
        switch identifier {
        case "askTab":
            return ["askTab", "templeTab"]
        case "manageTab":
            return ["manageTab", "selfTab"]
        default:
            return [identifier]
        }
    }

    private func anyElement(_ identifier: String) -> XCUIElement {
        app.descendants(matching: .any).matching(
            NSPredicate(format: "identifier == %@", identifier)
        ).firstMatch
    }

    private func elements(containing identifier: String) -> XCUIElementQuery {
        app.descendants(matching: .any).matching(NSPredicate(format: "identifier CONTAINS %@", identifier))
    }

    @discardableResult
    private func tap(_ element: XCUIElement, timeout: TimeInterval = 2.0) -> Bool {
        guard element.waitForExistence(timeout: timeout) else { return false }
        if element.isHittable {
            element.tap()
            return true
        }
        let fallbackCoordinate = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        fallbackCoordinate.tap()
        return true
    }

    private func tapButton(label text: String) -> Bool {
        let button = app.buttons.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
        return tap(button, timeout: 2.0)
    }

    private func tapText(label text: String) -> Bool {
        let element = app.staticTexts.matching(NSPredicate(format: "label CONTAINS[c] %@", text)).firstMatch
        return tap(element, timeout: 2.0)
    }

    @discardableResult
    private func tapTab(_ identifier: String, file: StaticString = #filePath, line: UInt = #line) -> Bool {
        let candidates = tabCandidates(for: identifier)
        for identifier in candidates {
            if tap(app.buttons[identifier], timeout: 2.0) { return true }
            if tap(app.otherElements[identifier], timeout: 2.0) { return true }
        }
        XCTFail("Failed to tap tab '\(candidates.joined(separator: ", "))'", file: file, line: line)
        return false
    }

    private func chatInputElement() -> XCUIElement {
        if app.textFields["chatInputField"].exists { return app.textFields["chatInputField"] }
        if app.textViews["chatInputField"].exists { return app.textViews["chatInputField"] }
        return app.textFields.firstMatch
    }

    private func waitForNotExists(_ element: XCUIElement, timeout: TimeInterval = 7.0) -> Bool {
        let end = Date(timeIntervalSinceNow: timeout)
        while Date() < end {
            if !element.exists { return true }
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.15))
        }
        return !element.exists
    }

    private func addVisualCheckpoint(step: Int, seed: UInt64) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "Chaos(seed=\(seed)-step-\(step))"
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func safeScrollUp() {
        for _ in 0..<2 {
            app.swipeUp()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        }
    }

    private func safeScrollDown() {
        for _ in 0..<2 {
            app.swipeDown()
            RunLoop.current.run(until: Date(timeIntervalSinceNow: 0.25))
        }
    }

    // MARK: - Journeys

    private func openTimeTravelFlow(canRepairFromProfile: inout Bool, seed: UInt64) {
        tapTab("timeTravelTab")
        let prompt = anyElement("incompleteProfilePrompt")
        let view = anyElement("timeTravelView")

        if prompt.waitForExistence(timeout: 4) {
            canRepairFromProfile = true
            let completeButton = anyElement("completeBirthDataButton")
            if tap(completeButton, timeout: 2.0) {
                // Best-effort profile completion path for chaos recovery.
                let placeField = app.textFields.matching(
                    NSPredicate(format: "placeholderValue == %@", "City, State/Country")
                ).firstMatch
                if tap(placeField, timeout: 1.5) {
                    placeField.typeText("New York")
                    sleep(1)
                    let suggestion = app.staticTexts.matching(
                        NSPredicate(format: "label CONTAINS[c] 'New York'")
                    ).firstMatch
                    if suggestion.waitForExistence(timeout: 2.0) {
                        _ = tap(suggestion)
                    }
                }

                let saveButton = app.buttons["Save"]
                _ = tap(saveButton, timeout: 2.0)
                sleep(1)
                let done = app.buttons["Done"]
                if done.exists { _ = tap(done, timeout: 1.0) }

                tapTab("timeTravelTab")
                if view.waitForExistence(timeout: 4) || prompt.waitForExistence(timeout: 2.0) {
                    _ = addVisualCheckpoint(step: Int(seed % 1000), seed: seed)
                }
            }
            return
        }

        _ = view.waitForExistence(timeout: 6)
    }

    private func openOracleChatFlow() {
        tapTab("templeTab")
        let quickAccess = anyElement("oracleQuickAccessButton")
        if tap(quickAccess, timeout: 2.0) {
            let input = chatInputElement()
            if input.waitForExistence(timeout: 5) {
                input.tap()
                input.typeText("How is my alignment this cycle?")
                let send = anyElement("sendMessageButton")
                _ = tap(send, timeout: 2.0)
            }
            return
        }

        if !tapButton(label: "Ask the Oracle") {
            let oracleCard = anyElement("Ask the Oracle")
            _ = tap(oracleCard, timeout: 2.0)
        }

        let input = chatInputElement()
        guard input.waitForExistence(timeout: 8) else { return }
        input.tap()
        input.typeText("How is my alignment this cycle?")
        let send = anyElement("sendMessageButton")
        if tap(send, timeout: 2.0) {
            sleep(1)
        }
    }

    private func openPackagesFlow() {
        if !tapButton(label: "Get Chat Packages") {
            _ = tap(anyElement("getChatPackagesButton"), timeout: 2.0)
        }

        let sheet = anyElement("chatPackagesSheet")
        if sheet.waitForExistence(timeout: 5) {
            let buyButton = elements(containing: "chatPackBuyButton_").firstMatch
            if tap(buyButton, timeout: 3.0) {
                sleep(1)
            }
            let done = anyElement("doneButton")
            _ = tap(done, timeout: 2.0)
        }
    }

    private func openPaywallFlow() {
        let banner = anyElement("goUnlimitedButton")
        if tap(banner, timeout: 4.0) {
            let paywall = anyElement("paywallView")
            if paywall.waitForExistence(timeout: 4.0) {
                let proButton = anyElement("startProButton")
                if tap(proButton, timeout: 2.0) {
                    let close = anyElement("paywallCloseButton")
                    _ = tap(close, timeout: 2.0)
                    _ = waitForNotExists(paywall, timeout: 8)
                }
            }
            return
        }

        let close = anyElement("paywallCloseButton")
        _ = tap(close, timeout: 1.5)
    }

    private func openReportsFlow() {
        tapTab("manageTab")
        let storeButton = anyElement("reportsShopButton")
        if tap(storeButton, timeout: 5.0) {
            if app.navigationBars["Reports Shop"].waitForExistence(timeout: 3) {
                _ = true
            }
        } else {
            _ = tapText(label: "Reports Shop")
        }

        let store = anyElement("reportsStoreView")
        if store.waitForExistence(timeout: 4.0) {
            let buy = elements(containing: "reportBuyButton_").firstMatch
            if tap(buy, timeout: 2.0) {
                sleep(1)
            }

            let close = anyElement("doneButton")
            _ = tap(close, timeout: 1.5)
        } else {
            app.swipeUp()
        }

        tapTab("homeTab")
        _ = tapButton(label: "View all")
    }

    private func openConnectFlow() {
        tapTab("connectTab")
        _ = tapButton(label: "Add new relationship")
        _ = tapButton(label: "Import from Contacts")
    }

    private func openSelfFoundationFlow() {
        tapTab("selfTab")
        let foundation = anyElement("foundationToggle")
        _ = tap(foundation, timeout: 2.5)
        _ = tapButton(label: "Edit Details")
        if anyElement("birthDatePicker").waitForExistence(timeout: 2.0) || app.datePickers.firstMatch.waitForExistence(timeout: 1.0) {
            let save = app.buttons["Save"]
            _ = tap(save, timeout: 1.5)
        }
        let settingsButton = app.buttons["settingsButton"]
        if tap(settingsButton, timeout: 2.0) {
            _ = tapText(label: "Done")
            _ = tapText(label: "Close")
        }
    }

    private func randomHomeInteraction(_ selector: Int) {
        let actions = ["share", "swipe up", "explore", "sweep", "return"]
        let index = selector % actions.count
        switch index {
        case 0:
            _ = tapButton(label: "Share your daily insight")
        case 1:
            safeScrollUp()
        case 2:
            safeScrollDown()
        default:
            _ = tapButton(label: "Daily Insight")
        }
    }

    private func executeChaosStep(
        _ rng: inout LCGRandom,
        step: Int,
        seed: UInt64
    ) {
        let action = rng.nextStep(12)
        switch action {
        case 0:
            _ = tapTab(homeTabs[0])
        case 1:
            openOracleChatFlow()
        case 2:
            openPackagesFlow()
        case 3:
            openPaywallFlow()
        case 4:
            openConnectFlow()
        case 5:
            var repair = false
            openTimeTravelFlow(canRepairFromProfile: &repair, seed: seed)
        case 6:
            openSelfFoundationFlow()
        case 7:
            openReportsFlow()
        case 8:
            randomHomeInteraction(rng.nextStep(5))
        case 9:
            _ = tapTab(homeTabs[rng.nextStep(homeTabs.count)])
        case 10:
            safeScrollDown()
        default:
            safeScrollUp()
        }

        if step % 4 == 0 {
            addVisualCheckpoint(step: step, seed: seed)
        }
    }

    private func runChaos(seed: UInt64, profileMode: String, steps: Int) {
        launch(for: profileMode)

        var rng = LCGRandom(seed: seed)

        // Prime interaction.
        _ = tapTab("homeTab")

        for step in 1...steps {
            executeChaosStep(
                &rng,
                step: step,
                seed: seed
            )
        }

        if !app.windows.element(boundBy: 0).exists {
            XCTFail("App lost its main window during chaos run")
        }

        // A final safety pass to ensure no hard deadlock stuck on modal overlays.
        if anyElement("paywallView").exists {
            _ = tap(anyElement("paywallCloseButton"), timeout: 1.0)
        }
        if anyElement("chatPackagesSheet").exists {
            _ = tap(anyElement("doneButton"), timeout: 1.0)
        }
        _ = tapTab("homeTab")
    }

    // MARK: - Chaos Cases

    @MainActor
    func testChaosJourney_FullProfile_Seed20260213() throws {
        runChaos(seed: 20_260_213, profileMode: "UITEST_SEED_PROFILE_FULL", steps: 30)
    }

    @MainActor
    func testChaosJourney_MinimalProfile_Seed20260214() throws {
        runChaos(seed: 20_260_214, profileMode: "UITEST_SEED_PROFILE_MINIMAL", steps: 30)
    }

    @MainActor
    func testChaosJourney_FullProfile_HighIntensity_Seed314159() throws {
        runChaos(seed: 314_159, profileMode: "UITEST_SEED_PROFILE_FULL", steps: 42)
    }
}
