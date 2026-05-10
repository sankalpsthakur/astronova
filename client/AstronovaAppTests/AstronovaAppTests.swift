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
        ["com.astronova.app.jwtToken", "com.sankalp.AstronovaApp.jwtToken"].forEach { jwtTokenKey in
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrAccount as String: jwtTokenKey,
            ]
            SecItemDelete(query as CFDictionary)
        }
    }

    private func makeDate(year: Int, month: Int, day: Int) -> Date {
        var components = DateComponents()
        components.year = year
        components.month = month
        components.day = day
        components.timeZone = TimeZone(secondsFromGMT: 0)
        return Calendar(identifier: .gregorian).date(from: components) ?? Date(timeIntervalSince1970: 0)
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

    func testShopCatalogHasSingleMonetizationTruth() throws {
        XCTAssertEqual(ShopCatalog.proMonthlyProductID, "astronova_pro_monthly")
        XCTAssertEqual(ShopCatalog.reportProductIDs.count, 7)
        XCTAssertEqual(ShopCatalog.chatCreditAmounts["chat_credits_5"], 50)
        XCTAssertEqual(ShopCatalog.chatCreditAmounts["chat_credits_15"], 150)
        XCTAssertEqual(ShopCatalog.chatCreditAmounts["chat_credits_50"], 500)
        XCTAssertEqual(ShopCatalog.allProductIDs.count, 11)
        XCTAssertTrue(ShopCatalog.allProductIDs.contains(ShopCatalog.proMonthlyProductID))
    }

    // MARK: - Copy Tests

    func testQuickStartInsightIncludesNameAndYear() throws {
        let date = makeDate(year: 1990, month: 1, day: 15)
        let insight = PersonalizationCopy.quickStartInsight(name: "Ava", birthDate: date)
        XCTAssertTrue(insight.contains("Ava"))
        XCTAssertTrue(insight.contains("1990"))
        XCTAssertTrue(insight.lowercased().contains("birth date"))
    }

    func testQuickStartInsightWithoutNameUsesGenericIntro() throws {
        let date = makeDate(year: 1992, month: 6, day: 10)
        let insight = PersonalizationCopy.quickStartInsight(name: " ", birthDate: date)
        XCTAssertTrue(insight.contains("Based on your birth date"))
        XCTAssertTrue(insight.contains("1992"))
    }

    func testCompatibilitySummaryUsesNameAndScore() throws {
        let summary = PersonalizationCopy.compatibilitySummary(score: 88, partnerName: "Taylor")
        XCTAssertTrue(summary.contains("Taylor"))
        XCTAssertTrue(summary.contains("88%"))
    }

    func testCompatibilitySummaryFallsBackForEmptyName() throws {
        let summary = PersonalizationCopy.compatibilitySummary(score: 50, partnerName: "")
        XCTAssertTrue(summary.contains("this person"))
        XCTAssertTrue(summary.contains("50%"))
    }

    func testRelationshipDateParserSupportsDateOnlyAndISO8601() throws {
        let dateOnly = try XCTUnwrap(APIServices.parseRelationshipBirthDate("1992-05-20"))
        let iso8601 = try XCTUnwrap(APIServices.parseRelationshipBirthDate("1992-05-20T00:00:00Z"))
        let fractionalISO8601 = try XCTUnwrap(APIServices.parseRelationshipBirthDate("1992-05-20T00:00:00.123Z"))

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        for parsed in [dateOnly, iso8601, fractionalISO8601] {
            let components = calendar.dateComponents([.year, .month, .day], from: parsed)
            XCTAssertEqual(components.year, 1992)
            XCTAssertEqual(components.month, 5)
            XCTAssertEqual(components.day, 20)
        }
    }

    func testClientSideHouseInsightReturnsReadableMeaning() throws {
        let planet = PlanetState(
            id: "sun",
            name: "Sun",
            symbol: "☉",
            longitude: 120.0,
            sign: "Leo",
            degree: 0.0,
            house: 10,
            significance: "Vitality and leadership.",
            isRetrograde: false,
            speed: 1.0
        )

        let insight = HouseInsight.clientSide(from: planet)
        XCTAssertEqual(insight.houseName, "10th House")
        XCTAssertEqual(insight.houseTheme, "Career & Status")
        XCTAssertEqual(insight.lifeArea, "Career")
    }

    func testScrubFeedbackHighlightsHouseShiftForPriorityPlanet() throws {
        let base = TimeTravelSnapshot.sample(targetDate: makeDate(year: 2026, month: 3, day: 15))

        var previousPlanets = base.planets
        let sunIndex = try XCTUnwrap(previousPlanets.firstIndex(where: { $0.id == "sun" }))
        let originalSun = previousPlanets[sunIndex]

        previousPlanets[sunIndex] = PlanetState(
            id: originalSun.id,
            name: originalSun.name,
            symbol: originalSun.symbol,
            longitude: originalSun.longitude,
            sign: originalSun.sign,
            degree: originalSun.degree,
            house: 9,
            significance: originalSun.significance,
            isRetrograde: originalSun.isRetrograde,
            speed: originalSun.speed,
            isDashaLord: originalSun.isDashaLord,
            isAntardashaLord: originalSun.isAntardashaLord
        )

        let previous = TimeTravelSnapshot(
            targetDate: base.targetDate,
            planets: previousPlanets,
            currentDasha: base.currentDasha,
            aspects: base.aspects,
            now: base.now,
            nextTransitions: base.nextTransitions,
            act: base.act
        )

        var currentPlanets = previousPlanets
        let shiftedSun = currentPlanets[sunIndex]
        currentPlanets[sunIndex] = PlanetState(
            id: shiftedSun.id,
            name: shiftedSun.name,
            symbol: shiftedSun.symbol,
            longitude: shiftedSun.longitude,
            sign: shiftedSun.sign,
            degree: shiftedSun.degree,
            house: 10,
            significance: shiftedSun.significance,
            isRetrograde: shiftedSun.isRetrograde,
            speed: shiftedSun.speed,
            isDashaLord: shiftedSun.isDashaLord,
            isAntardashaLord: shiftedSun.isAntardashaLord
        )

        let current = TimeTravelSnapshot(
            targetDate: base.targetDate.addingTimeInterval(86_400),
            planets: currentPlanets,
            currentDasha: base.currentDasha,
            aspects: base.aspects,
            now: base.now,
            nextTransitions: base.nextTransitions,
            act: base.act
        )

        let feedback = TimeTravelSnapshot.scrubFeedback(from: previous, to: current)

        XCTAssertTrue(feedback.insights.contains(where: { $0.id == "house-sun-9-10" && $0.text.contains("H9→H10") }))
        XCTAssertTrue(feedback.summary?.contains("10th house (career)") ?? false)
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
