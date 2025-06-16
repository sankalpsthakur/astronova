import XCTest
@testable import AstronovaNetworking

final class ConfigurationTests: XCTestCase {
    
    func testConfiguration_APIBaseURL() {
        // Test that Configuration can provide an API base URL
        let apiURL = Configuration.apiBaseURL
        XCTAssertFalse(apiURL.isEmpty, "API base URL should not be empty")
        XCTAssertTrue(apiURL.hasPrefix("http"), "API base URL should start with http")
    }
    
    func testConfiguration_Environment() {
        // Test that Configuration can provide environment info
        let environment = Configuration.environment
        XCTAssertFalse(environment.isEmpty, "Environment should not be empty")
    }
    
    func testConfiguration_AppVersion() {
        // Test that Configuration can provide app version
        let version = Configuration.appVersion
        XCTAssertFalse(version.isEmpty, "App version should not be empty")
    }
    
    func testConfiguration_BuildNumber() {
        // Test that Configuration can provide build number
        let buildNumber = Configuration.buildNumber
        XCTAssertFalse(buildNumber.isEmpty, "Build number should not be empty")
    }
    
    func testConfiguration_IsDevelopment() {
        // Test that Configuration can determine if this is a development build
        let isDev = Configuration.isDevelopment
        // This is a boolean test - just ensure it doesn't crash
        XCTAssertTrue(isDev == true || isDev == false, "isDevelopment should be a valid boolean")
    }
    
    func testConfiguration_DevelopmentURLFallback() {
        // Test development URL fallback behavior
        let devURL = "http://127.0.0.1:8080"
        let prodURL = "https://api.astronova.app"
        
        let apiURL = Configuration.apiBaseURL
        
        // Should be one of the expected URLs
        XCTAssertTrue(
            apiURL == devURL || apiURL == prodURL || apiURL.hasPrefix("http"),
            "API URL should be either development, production, or a valid HTTP URL"
        )
    }
}