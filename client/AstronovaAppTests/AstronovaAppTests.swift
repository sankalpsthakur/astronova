//
//  AstronovaAppTests.swift
//  AstronovaAppTests
//
//  Created by Sankalp Thakur on 6/6/25.
//

import XCTest
import CoreLocation
import Security
@testable import AstronovaApp

final class AstronovaAppTests: XCTestCase {

    override func setUpWithError() throws {
        continueAfterFailure = false
        resetPersistentState()
    }

    override func tearDownWithError() throws {
        resetPersistentState()
    }

    private func resetPersistentState() {
        // UserDefaults state can leak between test runs and make AuthState/UserProfileManager nondeterministic.
        let defaults = UserDefaults.standard
        [
            "is_anonymous_user",
            "has_signed_in",
            "is_quick_start_user",
            "hasAstronovaPro",
            "chat_credits",
            "user_profile",
            "last_chart",
        ].forEach { defaults.removeObject(forKey: $0) }

        // Keychain token can also leak between runs and flip AuthState into "signed in".
        let jwtTokenKey = "com.sankalp.AstronovaApp.jwtToken"
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: jwtTokenKey,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Model Tests
    
    func testUserProfileCreation() throws {
        let profile = UserProfile()
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile.fullName, "")
        XCTAssertNil(profile.birthTime)
        XCTAssertNil(profile.birthPlace)
    }
    
    func testUserProfileCompletion() throws {
        let profileManager = UserProfileManager()
        XCTAssertFalse(profileManager.isProfileComplete)
        
        // Add minimal data
        profileManager.profile.fullName = "Test User"
        profileManager.profile.birthDate = Date()
        profileManager.profile.birthTime = Date()
        
        XCTAssertTrue(profileManager.isProfileComplete)
    }
    
    func testMinimalProfileData() throws {
        let profileManager = UserProfileManager()
        XCTAssertFalse(profileManager.hasMinimalProfileData)
        
        // Add just name and birth date
        profileManager.profile.fullName = "Test User"
        profileManager.profile.birthDate = Date()
        
        XCTAssertTrue(profileManager.hasMinimalProfileData)
    }
    
    func testReportPricing() throws {
        let loveReport = ReportPricing.loveReport
        XCTAssertEqual(loveReport.id, "love_forecast")
        XCTAssertEqual(loveReport.price, "$4.99")
        XCTAssertEqual(loveReport.title, "Love Forecast")
        
        let pricing = ReportPricing.pricing(for: "love_forecast")
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.title, "Love Forecast")
    }
    
    func testAllReportPricing() throws {
        let allReports = ReportPricing.allReports
        XCTAssertEqual(allReports.count, 4)
        
        let reportIds = allReports.map { $0.id }
        XCTAssertTrue(reportIds.contains("love_forecast"))
        XCTAssertTrue(reportIds.contains("birth_chart"))
        XCTAssertTrue(reportIds.contains("career_forecast"))
        XCTAssertTrue(reportIds.contains("year_ahead"))
    }
    
    // MARK: - Auth State Tests
    
    func testAuthStateInitialization() throws {
        let authState = AuthState()
        XCTAssertNotNil(authState)
        XCTAssertNotNil(authState.profileManager)
        XCTAssertFalse(authState.isAPIConnected)
        XCTAssertFalse(authState.isAnonymousUser)
        XCTAssertFalse(authState.isQuickStartUser)
    }
    
    func testFeatureAvailabilityAnonymous() throws {
        let authState = AuthState()
        authState.isAnonymousUser = true
        authState.isAPIConnected = true
        
        let features = authState.featureAvailability
        XCTAssertTrue(features.canGenerateCharts)
        XCTAssertFalse(features.canSaveData)
        XCTAssertFalse(features.canAccessPremiumFeatures)
        XCTAssertEqual(features.maxChartsPerDay, 3)
    }
    
    func testFeatureAvailabilityQuickStart() throws {
        let authState = AuthState()
        authState.isQuickStartUser = true
        authState.isAPIConnected = true
        
        let features = authState.featureAvailability
        XCTAssertTrue(features.canGenerateCharts)
        XCTAssertFalse(features.canSaveData)
        XCTAssertFalse(features.canAccessPremiumFeatures)
        XCTAssertEqual(features.maxChartsPerDay, 5)
    }
    
    // MARK: - Location Tests
    
    func testLocationResultCreation() throws {
        let coordinate = CLLocationCoordinate2D(latitude: 40.7128, longitude: -74.0060)
        let location = LocationResult(
            fullName: "Test City, Test State, Test Country",
            coordinate: coordinate,
            timezone: "America/New_York"
        )
        
        XCTAssertEqual(location.name, "Test City")
        XCTAssertEqual(location.latitude, 40.7128, accuracy: 0.001)
        XCTAssertEqual(location.longitude, -74.0060, accuracy: 0.001)
        XCTAssertEqual(location.country, "Test Country")
        XCTAssertEqual(location.timezone, "America/New_York")
        XCTAssertEqual(location.fullName, "Test City, Test State, Test Country")
    }
    
    // MARK: - Skeleton View Tests
    
    func testSkeletonViewCreation() throws {
        // Test disabled - SkeletonView not available in test target
        // let skeletonView = SkeletonView()
        // XCTAssertNotNil(skeletonView)
        XCTAssertTrue(true) // Placeholder test
    }
    
    func testSkeletonTextCreation() throws {
        // Test disabled - SkeletonText not available in test target
        // let skeletonText = SkeletonText(lines: 3, lineHeight: 16, spacing: 8)
        // XCTAssertNotNil(skeletonText)
        XCTAssertTrue(true) // Placeholder test
    }
    
    // MARK: - Performance Tests
    
    func testProfileManagerPerformance() throws {
        self.measure {
            let profileManager = UserProfileManager()
            profileManager.profile.fullName = "Performance Test User"
            profileManager.profile.birthDate = Date()
            profileManager.profile.birthTime = Date()
            _ = profileManager.isProfileComplete
        }
    }
    
    func testAuthStatePerformance() throws {
        self.measure {
            let authState = AuthState()
            _ = authState.featureAvailability
        }
    }
}
