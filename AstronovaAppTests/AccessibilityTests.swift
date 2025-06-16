import XCTest
import SwiftUI
@testable import AstronovaApp

final class AccessibilityTests: XCTestCase {
    
    var app: XCUIApplication!
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--accessibility-testing"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }
    
    // MARK: - VoiceOver Accessibility Tests
    
    func testVoiceOverNavigationOnboarding() throws {
        // Test VoiceOver navigation through onboarding flow
        let welcomeTitle = app.staticTexts["Welcome to AstroNova"]
        XCTAssertTrue(welcomeTitle.waitForExistence(timeout: 5))
        
        // Check accessibility properties
        XCTAssertTrue(welcomeTitle.isAccessibilityElement)
        XCTAssertFalse(welcomeTitle.accessibilityLabel?.isEmpty ?? true)
        
        let getStartedButton = app.buttons["Get Started"]
        XCTAssertTrue(getStartedButton.exists)
        XCTAssertTrue(getStartedButton.isAccessibilityElement)
        XCTAssertEqual(getStartedButton.accessibilityTraits, .button)
        
        // Test button accessibility
        XCTAssertNotNil(getStartedButton.accessibilityLabel)
        XCTAssertNotNil(getStartedButton.accessibilityHint)
    }
    
    func testVoiceOverMainTabNavigation() throws {
        navigateToMainApp()
        
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test each tab button accessibility
        let tabNames = ["Today", "Friends", "Nexus", "Profile"]
        
        for tabName in tabNames {
            let tabButton = app.tabBars.buttons[tabName]
            XCTAssertTrue(tabButton.exists, "Tab button '\(tabName)' should exist")
            XCTAssertTrue(tabButton.isAccessibilityElement, "Tab button '\(tabName)' should be accessible")
            XCTAssertEqual(tabButton.accessibilityTraits, .button, "Tab button '\(tabName)' should have button trait")
            
            // Verify accessibility label is descriptive
            let accessibilityLabel = tabButton.accessibilityLabel ?? ""
            XCTAssertFalse(accessibilityLabel.isEmpty, "Tab button '\(tabName)' should have accessibility label")
            XCTAssertTrue(accessibilityLabel.contains(tabName), "Accessibility label should contain tab name")
        }
    }
    
    func testChatInterfaceAccessibility() throws {
        navigateToMainApp()
        
        // Navigate to chat
        let nexusTab = app.tabBars.buttons["Nexus"]
        nexusTab.tap()
        
        // Test message input accessibility
        let messageInput = app.textFields.firstMatch
        if messageInput.waitForExistence(timeout: 3) {
            XCTAssertTrue(messageInput.isAccessibilityElement)
            XCTAssertEqual(messageInput.accessibilityTraits, .searchField)
            XCTAssertNotNil(messageInput.accessibilityLabel)
            XCTAssertNotNil(messageInput.accessibilityHint)
        }
        
        // Test send button accessibility
        let sendButton = app.buttons["Send"]
        if sendButton.exists {
            XCTAssertTrue(sendButton.isAccessibilityElement)
            XCTAssertEqual(sendButton.accessibilityTraits, .button)
            XCTAssertNotNil(sendButton.accessibilityLabel)
        }
    }
    
    // MARK: - Dynamic Type Tests
    
    func testDynamicTypeSupport() throws {
        // Test different Dynamic Type sizes
        let contentSizes: [UIContentSizeCategory] = [
            .extraSmall,
            .medium,
            .large,
            .extraLarge,
            .extraExtraLarge,
            .extraExtraExtraLarge,
            .accessibilityMedium,
            .accessibilityLarge,
            .accessibilityExtraLarge,
            .accessibilityExtraExtraLarge,
            .accessibilityExtraExtraExtraLarge
        ]
        
        for contentSize in contentSizes {
            // Set content size category
            app.launchArguments = ["--content-size-\(contentSize.rawValue)"]
            app.terminate()
            app.launch()
            
            // Navigate to main content
            navigateToMainApp()
            
            // Verify text is still readable and buttons are still tappable
            let tabBar = app.tabBars.firstMatch
            XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
            
            // Test that buttons maintain minimum tap target size (44x44 points)
            let todayTab = app.tabBars.buttons["Today"]
            XCTAssertTrue(todayTab.exists)
            
            let frame = todayTab.frame
            XCTAssertGreaterThanOrEqual(frame.height, 44, "Tab button should maintain 44pt minimum height for \(contentSize)")
            XCTAssertGreaterThanOrEqual(frame.width, 44, "Tab button should maintain 44pt minimum width for \(contentSize)")
        }
    }
    
    // MARK: - Color and Contrast Tests
    
    func testHighContrastSupport() throws {
        // Test high contrast mode
        app.launchArguments = ["--high-contrast"]
        app.terminate()
        app.launch()
        
        navigateToMainApp()
        
        // Verify elements are still visible and accessible
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test that text maintains readability
        let todayTab = app.tabBars.buttons["Today"]
        XCTAssertTrue(todayTab.exists)
        XCTAssertTrue(todayTab.isAccessibilityElement)
    }
    
    func testReduceMotionSupport() throws {
        // Test reduce motion accessibility setting
        app.launchArguments = ["--reduce-motion"]
        app.terminate()
        app.launch()
        
        // Complete onboarding with reduced motion
        navigateToMainApp()
        
        // Verify app still functions correctly without animations
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test tab switching without animations
        let friendsTab = app.tabBars.buttons["Friends"]
        friendsTab.tap()
        
        // Should switch immediately without animation delays
        sleep(1) // Brief pause to allow for any immediate UI updates
        
        let nexusTab = app.tabBars.buttons["Nexus"]
        nexusTab.tap()
        
        // Verify navigation works
        XCTAssertTrue(nexusTab.isSelected)
    }
    
    // MARK: - Switch Control Tests
    
    func testSwitchControlNavigation() throws {
        // Test Switch Control accessibility
        navigateToMainApp()
        
        // Verify all interactive elements are properly accessible for Switch Control
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 5))
        
        // Test sequential navigation through tab buttons
        let tabButtons = app.tabBars.buttons.allElementsBoundByIndex
        
        for (index, button) in tabButtons.enumerated() {
            XCTAssertTrue(button.isAccessibilityElement, "Tab button \(index) should be accessible for Switch Control")
            XCTAssertEqual(button.accessibilityTraits, .button, "Tab button \(index) should have button trait")
            
            // Verify button can be activated
            if button.isHittable {
                button.tap()
                // Brief pause to allow for UI updates
                sleep(0.5)
            }
        }
    }
    
    // MARK: - Assistive Touch Tests
    
    func testAssistiveTouchCompatibility() throws {
        navigateToMainApp()
        
        // Test that all buttons meet minimum size requirements for Assistive Touch
        let allButtons = app.buttons.allElementsBoundByIndex
        
        for (index, button) in allButtons.enumerated() {
            if button.exists && button.isHittable {
                let frame = button.frame
                
                // Verify minimum 44x44 point touch target
                XCTAssertGreaterThanOrEqual(frame.height, 44, "Button \(index) should have minimum 44pt height for Assistive Touch")
                XCTAssertGreaterThanOrEqual(frame.width, 44, "Button \(index) should have minimum 44pt width for Assistive Touch")
            }
        }
    }
    
    // MARK: - Keyboard Navigation Tests
    
    func testKeyboardNavigation() throws {
        navigateToMainApp()
        
        // Navigate to chat interface for text input testing
        let nexusTab = app.tabBars.buttons["Nexus"]
        nexusTab.tap()
        
        // Test keyboard navigation in text fields
        let messageInput = app.textFields.firstMatch
        if messageInput.waitForExistence(timeout: 3) {
            messageInput.tap()
            
            // Verify keyboard appears and input is focused
            XCTAssertTrue(messageInput.hasKeyboardFocus)
            
            // Test text input
            messageInput.typeText("Testing keyboard accessibility")
            
            // Verify text was entered
            XCTAssertEqual(messageInput.value as? String, "Testing keyboard accessibility")
        }
    }
    
    // MARK: - Semantic Labels Tests
    
    func testAccessibilityLabelsAndHints() throws {
        navigateToMainApp()
        
        // Test Today tab accessibility
        let todayTab = app.tabBars.buttons["Today"]
        todayTab.tap()
        
        // Check for meaningful accessibility labels on key elements
        let elements = app.descendants(matching: .any).allElementsBoundByIndex
        
        for element in elements {
            if element.isAccessibilityElement && element.exists {
                let label = element.accessibilityLabel ?? ""
                let hint = element.accessibilityHint ?? ""
                
                // Verify accessibility labels are meaningful (not just technical IDs)
                if !label.isEmpty {
                    XCTAssertFalse(label.hasPrefix("_"), "Accessibility label should not be a technical identifier: \(label)")
                    XCTAssertFalse(label.contains("UIKit"), "Accessibility label should not contain UIKit references: \(label)")
                    XCTAssertFalse(label.contains("SwiftUI"), "Accessibility label should not contain SwiftUI references: \(label)")
                }
                
                // Verify hints provide additional context when present
                if !hint.isEmpty {
                    XCTAssertNotEqual(label, hint, "Accessibility hint should be different from label")
                }
            }
        }
    }
    
    // MARK: - Error State Accessibility Tests
    
    func testErrorStateAccessibility() throws {
        navigateToMainApp()
        
        // Navigate to chat to test error states
        let nexusTab = app.tabBars.buttons["Nexus"]
        nexusTab.tap()
        
        // Try to trigger an error state (e.g., network error)
        let messageInput = app.textFields.firstMatch
        if messageInput.waitForExistence(timeout: 3) {
            messageInput.tap()
            messageInput.typeText("Test message that might trigger error")
            
            let sendButton = app.buttons["Send"]
            if sendButton.exists {
                sendButton.tap()
                
                // Wait for potential error message
                sleep(2)
                
                // Check if error alerts are accessible
                let alerts = app.alerts.allElementsBoundByIndex
                for alert in alerts {
                    if alert.exists {
                        XCTAssertTrue(alert.isAccessibilityElement)
                        XCTAssertNotNil(alert.accessibilityLabel)
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    
    private func navigateToMainApp() {
        // Skip onboarding for accessibility tests
        let skipOnboardingButton = app.buttons["Skip Onboarding"]
        if skipOnboardingButton.waitForExistence(timeout: 2) {
            skipOnboardingButton.tap()
        } else {
            // If no skip button, complete minimal onboarding
            completeMinimalOnboarding()
        }
        
        // Wait for main app
        let tabBar = app.tabBars.firstMatch
        XCTAssertTrue(tabBar.waitForExistence(timeout: 10))
    }
    
    private func completeMinimalOnboarding() {
        let getStartedButton = app.buttons["Get Started"]
        if getStartedButton.waitForExistence(timeout: 5) {
            getStartedButton.tap()
            
            // Fill minimal required information
            let nameField = app.textFields.firstMatch
            if nameField.waitForExistence(timeout: 3) {
                nameField.tap()
                nameField.typeText("Test User")
                
                let continueButton = app.buttons["Continue"]
                if continueButton.exists {
                    continueButton.tap()
                }
            }
        }
    }
}

// MARK: - Accessibility Testing Extensions

extension AccessibilityTests {
    
    func testAccessibilityAuditFullApp() throws {
        // Comprehensive accessibility audit
        navigateToMainApp()
        
        var accessibilityIssues: [String] = []
        
        // Test all tabs for accessibility compliance
        let tabs = ["Today", "Friends", "Nexus", "Profile"]
        
        for tabName in tabs {
            let tab = app.tabBars.buttons[tabName]
            tab.tap()
            
            // Wait for content to load
            sleep(1)
            
            // Audit current screen
            let issues = auditCurrentScreen(screenName: tabName)
            accessibilityIssues.append(contentsOf: issues)
        }
        
        // Report any accessibility issues found
        if !accessibilityIssues.isEmpty {
            let issueReport = accessibilityIssues.joined(separator: "\n")
            XCTFail("Accessibility issues found:\n\(issueReport)")
        }
    }
    
    private func auditCurrentScreen(screenName: String) -> [String] {
        var issues: [String] = []
        
        // Get all elements on current screen
        let allElements = app.descendants(matching: .any).allElementsBoundByIndex
        
        for (index, element) in allElements.enumerated() {
            if element.exists && element.isHittable {
                // Check touch target size for interactive elements
                let frame = element.frame
                if frame.height < 44 || frame.width < 44 {
                    if element.elementType == .button || element.elementType == .textField {
                        issues.append("\(screenName) - Element \(index): Interactive element too small (\(frame.width)x\(frame.height))")
                    }
                }
                
                // Check accessibility labels for interactive elements
                if element.isAccessibilityElement {
                    let label = element.accessibilityLabel ?? ""
                    if label.isEmpty && (element.elementType == .button || element.elementType == .textField) {
                        issues.append("\(screenName) - Element \(index): Interactive element missing accessibility label")
                    }
                }
            }
        }
        
        return issues
    }
}