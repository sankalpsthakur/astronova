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

    // MARK: - Dependency Injection Tests
    
    func testDependencyContainerCreation() throws {
        let container = DependencyContainer()
        XCTAssertNotNil(container.networkClient)
        XCTAssertNotNil(container.apiServices)
        XCTAssertNotNil(container.storeManager)
    }
    
    func testMockDependencyContainer() throws {
        let mockContainer = DependencyContainer.mock
        XCTAssertNotNil(mockContainer.networkClient)
        XCTAssertNotNil(mockContainer.apiServices)
        XCTAssertNotNil(mockContainer.storeManager)
        
        // Verify it's using mock services
        XCTAssertTrue(mockContainer.networkClient is MockNetworkClient)
        XCTAssertTrue(mockContainer.apiServices is MockAPIServices)
        XCTAssertTrue(mockContainer.storeManager is MockStoreManager)
    }
    
    func testNetworkClientProtocolConformance() throws {
        let networkClient: NetworkClientProtocol = NetworkClient()
        XCTAssertNotNil(networkClient)
    }
    
    func testAPIServicesProtocolConformance() throws {
        let mockNetworkClient = MockNetworkClient()
        let apiServices: APIServicesProtocol = APIServices(networkClient: mockNetworkClient)
        XCTAssertNotNil(apiServices)
    }
    
    func testStoreManagerProtocolConformance() throws {
        let storeManager: StoreManagerProtocol = StoreManager()
        XCTAssertNotNil(storeManager)
        XCTAssertFalse(storeManager.hasProSubscription)
    }
    
    // MARK: - ViewModel Tests
    
    func testMainViewModelCreation() throws {
        let mockContainer = DependencyContainer.mock
        let viewModel = MainViewModel(dependencies: mockContainer)
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.selectedTab, 0)
        XCTAssertEqual(viewModel.selectedSection, "overview")
    }
    
    func testChartViewModelCreation() throws {
        let mockContainer = DependencyContainer.mock
        let viewModel = ChartViewModel(apiServices: mockContainer.apiServices)
        XCTAssertNotNil(viewModel)
        XCTAssertNil(viewModel.currentChart)
        XCTAssertFalse(viewModel.isGeneratingChart)
    }
    
    func testHoroscopeViewModelCreation() throws {
        let mockContainer = DependencyContainer.mock
        let viewModel = HoroscopeViewModel(apiServices: mockContainer.apiServices)
        XCTAssertNotNil(viewModel)
        XCTAssertEqual(viewModel.selectedPeriod, "daily")
        XCTAssertFalse(viewModel.isLoadingHoroscope)
    }
    
    // MARK: - Model Tests
    
    func testUserProfileCreation() throws {
        let profile = UserProfile()
        XCTAssertNotNil(profile)
        XCTAssertEqual(profile.fullName, "")
    }
    
    func testReportPricing() throws {
        let loveReport = ReportPricing.loveReport
        XCTAssertEqual(loveReport.id, "love_forecast")
        XCTAssertEqual(loveReport.price, "$4.99")
        
        let pricing = ReportPricing.pricing(for: "love_forecast")
        XCTAssertNotNil(pricing)
        XCTAssertEqual(pricing?.title, "Love Forecast")
    }
    
    // MARK: - Mock Service Tests
    
    func testMockNetworkClientHealthCheck() async throws {
        let mockClient = MockNetworkClient()
        let response = try await mockClient.healthCheck()
        XCTAssertEqual(response.status, "healthy")
        XCTAssertEqual(response.message, "Mock service is running")
    }
    
    func testMockAPIServicesHoroscope() async throws {
        let mockServices = MockAPIServices()
        let horoscope = try await mockServices.getHoroscope(sign: "aries", period: "daily")
        XCTAssertEqual(horoscope.sign, "aries")
        XCTAssertEqual(horoscope.period, "daily")
        XCTAssertTrue(horoscope.content.contains("Mock horoscope content"))
    }
    
    func testMockStoreManagerPurchase() async throws {
        let mockStore = MockStoreManager()
        let success = await mockStore.purchaseProduct(productId: "astronova_pro_monthly")
        XCTAssertTrue(success)
        XCTAssertTrue(mockStore.hasProSubscription)
    }

    func testDependencyInjectionPerformance() throws {
        self.measure {
            let _ = DependencyContainer()
        }
    }
}
