//
//  AstronovaAppTests.swift
//  AstronovaAppTests
//
//  Created by Sankalp Thakur on 6/6/25.
//

import XCTest
@testable import AstronovaApp

final class AstronovaAppTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    // MARK: - Basic Service Tests
    
    func testAPIServicesExists() throws {
        let apiServices = APIServices.shared
        XCTAssertNotNil(apiServices)
    }
    
    func testNetworkClientExists() throws {
        let networkClient = NetworkClient.shared
        XCTAssertNotNil(networkClient)
    }
    
    func testStoreManagerExists() throws {
        let storeManager = StoreManager.shared
        XCTAssertNotNil(storeManager)
        XCTAssertFalse(storeManager.hasProSubscription)
        XCTAssertTrue(storeManager.products.isEmpty) // Initially empty
    }
    
    func testUserProfileCreation() throws {
        let profile = UserProfile()
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile.fullName, "User")
    }
    
    func testReportPricing() throws {
        let loveReport = ReportPricing.loveReport
        XCTAssertEqual(loveReport.id, "love_forecast")
        XCTAssertEqual(loveReport.price, "$4.99")
        
        let pricing = ReportPricing.pricing(for: "love_forecast")
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.title, "Love Forecast")
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
            let _ = APIServices.shared
        }
    }
}
