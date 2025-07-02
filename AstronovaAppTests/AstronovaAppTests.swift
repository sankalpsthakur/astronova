//
//  AstronovaAppTests.swift
//  AstronovaAppTests
//
//  Created by Sankalp Thakur on 6/6/25.
//

import XCTest
import CoreLocation
@testable import AstronovaApp

final class AstronovaAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
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
        let skeletonView = SkeletonView()
        XCTAssertNotNil(skeletonView)
    }
    
    func testSkeletonTextCreation() throws {
        let skeletonText = SkeletonText(lines: 3, lineHeight: 16, spacing: 8)
        XCTAssertNotNil(skeletonText)
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
