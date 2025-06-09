//
//  AstronovaAppTests.swift
//  AstronovaAppTests
//
//  Created by Sankalp Thakur on 6/6/25.
//

import XCTest
@testable import AstronovaApp

final class AstronovaAppTests: XCTestCase {
    
    var mockDependencies: DependencyContainer!
    var mockAPIServices: MockAPIServices!
    var mockStoreManager: MockStoreManager!
    
    override func setUpWithError() throws {
        mockDependencies = DependencyContainer.mock
        mockAPIServices = mockDependencies.apiServices as? MockAPIServices
        mockStoreManager = mockDependencies.storeManager as? MockStoreManager
    }
    
    override func tearDownWithError() throws {
        mockDependencies = nil
        mockAPIServices = nil
        mockStoreManager = nil
    }
    
    // MARK: - Dependency Injection Tests
    
    func testDependencyInjection() throws {
        XCTAssertNotNil(mockDependencies.apiServices)
        XCTAssertNotNil(mockDependencies.networkClient)
        XCTAssertNotNil(mockDependencies.storeManager)
    }
    
    // MARK: - API Services Tests
    
    func testHealthCheck() async throws {
        let response = try await mockAPIServices.healthCheck()
        XCTAssertEqual(response.status, "healthy")
        XCTAssertEqual(response.message, "Mock service is running")
    }
    
    func testHealthCheckFailure() async throws {
        mockAPIServices.shouldFailRequests = true
        
        do {
            _ = try await mockAPIServices.healthCheck()
            XCTFail("Expected network error")
        } catch {
            XCTAssertTrue(error is NetworkError)
        }
    }
    
    func testGenerateChart() async throws {
        let profile = UserProfile()
        profile.firstName = "Test"
        profile.lastName = "User"
        profile.birthDate = Date()
        profile.birthPlace = "New York, NY, USA"
        profile.birthCoordinates = "40.7128,-74.0060"
        profile.birthTimezone = "America/New_York"
        
        let chart = try await mockAPIServices.generateChart(from: profile)
        XCTAssertNotNil(chart.westernChart)
    }
    
    func testGetHoroscope() async throws {
        let horoscope = try await mockAPIServices.getHoroscope(sign: "Aries", period: "daily")
        XCTAssertEqual(horoscope.sign, "Aries")
        XCTAssertEqual(horoscope.period, "daily")
        XCTAssertFalse(horoscope.content.isEmpty)
    }
    
    // MARK: - Store Manager Tests
    
    func testStoreManagerInitialState() throws {
        XCTAssertFalse(mockStoreManager.hasProSubscription)
        XCTAssertFalse(mockStoreManager.products.isEmpty)
    }
    
    func testPurchaseProduct() async throws {
        let success = await mockStoreManager.purchaseProduct(productId: "astronova_pro_monthly")
        XCTAssertTrue(success)
        XCTAssertTrue(mockStoreManager.hasProSubscription)
    }
    
    func testPurchaseFailure() async throws {
        mockStoreManager.shouldFailPurchases = true
        let success = await mockStoreManager.purchaseProduct(productId: "astronova_pro_monthly")
        XCTAssertFalse(success)
        XCTAssertFalse(mockStoreManager.hasProSubscription)
    }
    
    // MARK: - View Model Tests
    
    @MainActor
    func testMainViewModel() throws {
        let viewModel = MainViewModel(dependencies: mockDependencies)
        
        XCTAssertEqual(viewModel.selectedTab, 0)
        XCTAssertEqual(viewModel.selectedSection, "overview")
        XCTAssertFalse(viewModel.isLoading)
        
        viewModel.switchToTab(2)
        XCTAssertEqual(viewModel.selectedTab, 2)
        
        viewModel.switchToProfileSection("settings")
        XCTAssertEqual(viewModel.selectedSection, "settings")
        XCTAssertEqual(viewModel.selectedTab, 2)
    }
    
    @MainActor
    func testChartViewModel() async throws {
        let viewModel = ChartViewModel(apiServices: mockAPIServices)
        
        XCTAssertNil(viewModel.currentChart)
        XCTAssertFalse(viewModel.isGeneratingChart)
        
        let profile = UserProfile()
        profile.firstName = "Test"
        profile.lastName = "User"
        profile.birthDate = Date()
        profile.birthPlace = "New York, NY, USA"
        profile.birthCoordinates = "40.7128,-74.0060"
        profile.birthTimezone = "America/New_York"
        
        await viewModel.generateChart(for: profile)
        
        XCTAssertNotNil(viewModel.currentChart)
        XCTAssertFalse(viewModel.isGeneratingChart)
    }
    
    @MainActor
    func testHoroscopeViewModel() async throws {
        let viewModel = HoroscopeViewModel(apiServices: mockAPIServices)
        
        XCTAssertNil(viewModel.currentHoroscope)
        XCTAssertEqual(viewModel.selectedPeriod, "daily")
        
        await viewModel.loadHoroscope(for: "Aries")
        
        XCTAssertNotNil(viewModel.currentHoroscope)
        XCTAssertEqual(viewModel.currentHoroscope?.sign, "Aries")
        XCTAssertEqual(viewModel.selectedPeriod, "daily")
    }
}
