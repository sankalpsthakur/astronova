import XCTest
import SwiftUI

@testable import AstronovaApp

final class SnapshotTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--snapshot-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - Onboarding Flow Snapshots
    
    func testOnboardingWelcomeScreen() throws {
        // Wait for welcome screen to appear
        let welcomeTitle = app.staticTexts["Welcome to AstroNova"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
        
        // Take snapshot of welcome screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "OnboardingWelcomeScreen"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testOnboardingNameInput() throws {
        navigateToNameInput()
        
        // Take snapshot of name input screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "OnboardingNameInput"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testOnboardingBirthDateInput() throws {
        navigateToNameInput()
        fillNameAndContinue()
        
        let birthDateTitle = app.staticTexts["When were you born?"]
        XCTAssertTrue(birthDateTitle.waitForExistence(timeout: 3))
        
        // Take snapshot of birth date screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "OnboardingBirthDateInput"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testOnboardingBirthTimeInput() throws {
        navigateToNameInput()
        fillNameAndContinue()
        fillBirthDateAndContinue()
        
        let birthTimeTitle = app.staticTexts["What time were you born?"]
        XCTAssertTrue(birthTimeTitle.waitForExistence(timeout: 3))
        
        // Take snapshot of birth time screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "OnboardingBirthTimeInput"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testOnboardingLocationInput() throws {
        navigateToNameInput()
        fillNameAndContinue()
        fillBirthDateAndContinue()
        fillBirthTimeAndContinue()
        
        let locationTitle = app.staticTexts["Where were you born?"]
        XCTAssertTrue(locationTitle.waitForExistence(timeout: 3))
        
        // Take snapshot of location input screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "OnboardingLocationInput"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testOnboardingPersonalizedInsight() throws {
        completeOnboardingFlow()
        
        let insightTitle = app.staticTexts.matching(identifier: "PersonalizedInsightTitle").firstMatch
        XCTAssertTrue(insightTitle.waitForExistence(timeout: 10))
        
        // Take snapshot of personalized insight screen
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "OnboardingPersonalizedInsight"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Main App Snapshots
    
    func testMainTabBar() throws {
        completeOnboardingToMainApp()
        
        // Wait for tab bar to appear
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Take snapshot of main tab bar
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "MainTabBar"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testTodayTab() throws {
        completeOnboardingToMainApp()
        
        let todayTab = app.tabBars.buttons["Today"]
        todayTab.tap()
        
        // Wait for today content to load
        sleep(2)
        
        // Take snapshot of today tab
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "TodayTab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testFriendsTab() throws {
        completeOnboardingToMainApp()
        
        let friendsTab = app.tabBars.buttons["Friends"]
        friendsTab.tap()
        
        // Wait for friends content to load
        sleep(2)
        
        // Take snapshot of friends tab
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "FriendsTab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testNexusTab() throws {
        completeOnboardingToMainApp()
        
        let nexusTab = app.tabBars.buttons["Nexus"]
        nexusTab.tap()
        
        // Wait for nexus/chat content to load
        sleep(2)
        
        // Take snapshot of nexus tab
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "NexusTab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testProfileTab() throws {
        completeOnboardingToMainApp()
        
        let profileTab = app.tabBars.buttons["Profile"]
        profileTab.tap()
        
        // Wait for profile content to load
        sleep(2)
        
        // Take snapshot of profile tab
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ProfileTab"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Chat Interface Snapshots
    
    func testChatInterface() throws {
        completeOnboardingToMainApp()
        
        // Navigate to chat
        let nexusTab = app.tabBars.buttons["Nexus"]
        nexusTab.tap()
        
        // Wait for chat interface
        let messageInput = app.textFields["Ask about your cosmic journey..."]
        XCTAssertTrue(messageInput.waitForExistence(timeout: 3))
        
        // Type a message
        messageInput.tap()
        messageInput.typeText("What does my birth chart say about my personality?")
        
        // Take snapshot of chat with message
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "ChatInterface"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Compatibility Interface Snapshots
    
    func testCompatibilityInterface() throws {
        completeOnboardingToMainApp()
        
        // Navigate to friends/compatibility
        let friendsTab = app.tabBars.buttons["Friends"]
        friendsTab.tap()
        
        // Look for compatibility check button
        let compatibilityButton = app.buttons["Check Compatibility"]
        if compatibilityButton.exists {
            compatibilityButton.tap()
            
            // Wait for compatibility interface
            sleep(2)
            
            // Take snapshot of compatibility interface
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "CompatibilityInterface"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    // MARK: - Dark Mode Snapshots
    
    func testDarkModeOnboarding() throws {
        // Enable dark mode
        app.launchArguments.append("--dark-mode")
        app.terminate()
        app.launch()
        
        // Wait for welcome screen
        let welcomeTitle = app.staticTexts["Welcome to AstroNova"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
        
        // Take snapshot of dark mode onboarding
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "DarkModeOnboarding"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    func testDarkModeMainApp() throws {
        // Enable dark mode
        app.launchArguments.append("--dark-mode")
        app.terminate()
        app.launch()
        
        completeOnboardingToMainApp()
        
        // Take snapshot of dark mode main app
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "DarkModeMainApp"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Accessibility Snapshots
    
    func testAccessibilityLargeText() throws {
        // Enable large text
        app.launchArguments.append("--large-text")
        app.terminate()
        app.launch()
        
        completeOnboardingToMainApp()
        
        // Take snapshot with large text
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "AccessibilityLargeText"
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    
    // MARK: - Helper Methods
    
    private func navigateToNameInput() {
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
        }
    }
    
    private func fillNameAndContinue() {
        let nameField = app.textFields["Enter your name"]
        if nameField.waitForExistence(timeout: 3) {
            nameField.tap()
            nameField.typeText("John Doe")
            
            let continueButton = app.buttons["Continue"]
            continueButton.tap()
        }
    }
    
    private func fillBirthDateAndContinue() {
        // Interact with date picker
        let datePicker = app.datePickers.firstMatch
        if datePicker.waitForExistence(timeout: 3) {
            datePicker.tap()
            
            let continueButton = app.buttons["Continue"]
            continueButton.tap()
        }
    }
    
    private func fillBirthTimeAndContinue() {
        // Interact with time picker
        let timePicker = app.datePickers.firstMatch
        if timePicker.waitForExistence(timeout: 3) {
            timePicker.tap()
            
            let continueButton = app.buttons["Continue"]
            continueButton.tap()
        }
    }
    
    private func fillLocationAndContinue() {
        let locationField = app.textFields["Search for your birth location"]
        if locationField.waitForExistence(timeout: 3) {
            locationField.tap()
            locationField.typeText("New York, NY")
            
            // Wait for location suggestions and select first one
            sleep(2)
            let firstSuggestion = app.buttons.firstMatch
            if firstSuggestion.exists {
                firstSuggestion.tap()
            }
            
            let continueButton = app.buttons["Continue"]
            continueButton.tap()
        }
    }
    
    private func completeOnboardingFlow() {
        navigateToNameInput()
        fillNameAndContinue()
        fillBirthDateAndContinue()
        fillBirthTimeAndContinue()
        fillLocationAndContinue()
    }
    
    private func completeOnboardingToMainApp() {
        completeOnboardingFlow()
        
        // Wait for personalized insight and continue to main app
        let enterAppButton = app.buttons["Enter the Cosmic App"]
        if enterAppButton.waitForExistence(timeout: 10) {
            enterAppButton.tap()
        }
        
        // Wait for main app to load
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
    }
}

// MARK: - Snapshot Testing Extensions

extension SnapshotTests {
    
    func testAllTabsSequence() throws {
        // Test all tabs in sequence for comprehensive screenshots
        completeOnboardingToMainApp()
        
        let tabs = ["Today", "Friends", "Nexus", "Profile"]
        
        for (index, tabName) in tabs.enumerated() {
            let tab = app.tabBars.buttons[tabName]
            tab.tap()
            
            // Wait for content to load
            sleep(2)
            
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "Tab\(index + 1)_\(tabName)"
            attachment.lifetime = .keepAlways
            add(attachment)
        }
    }
    
    func testOrientationSnapshots() throws {
        completeOnboardingToMainApp()
        
        // Portrait
        let portraitScreenshot = app.screenshot()
        let portraitAttachment = XCTAttachment(screenshot: portraitScreenshot)
        portraitAttachment.name = "MainApp_Portrait"
        portraitAttachment.lifetime = .keepAlways
        add(portraitAttachment)
        
        // Rotate to landscape (if supported)
        XCUIDevice.shared.orientation = .landscapeLeft
        sleep(1)
        
        let landscapeScreenshot = app.screenshot()
        let landscapeAttachment = XCTAttachment(screenshot: landscapeScreenshot)
        landscapeAttachment.name = "MainApp_Landscape"
        landscapeAttachment.lifetime = .keepAlways
        add(landscapeAttachment)
        
        // Rotate back to portrait
        XCUIDevice.shared.orientation = .portrait
    }
}