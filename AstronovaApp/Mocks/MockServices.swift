import Foundation
import CoreLocation

// MARK: - Mock Network Client

class MockNetworkClient: NetworkClientProtocol {
    var shouldFailRequests = false
    var mockResponses: [String: Any] = [:]
    
    func healthCheck() async throws -> HealthResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        return HealthResponse(
            status: "healthy", 
            message: "Mock service is running"
        )
    }
    
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        responseType: T.Type
    ) async throws -> T {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        // Return mock response if available
        if let mockResponse = mockResponses[endpoint] as? T {
            return mockResponse
        }
        
        // Create default mock responses
        if responseType == ChartResponse.self {
            let mockChart = ChartResponse(
                westernChart: nil,
                vedicChart: nil,
                chineseChart: nil
            )
            return mockChart as! T
        }
        
        throw NetworkError.noData
    }
    
    func requestData(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> Data {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return Data()
    }
}

// MARK: - Mock API Services

class MockAPIServices: ObservableObject {
    private let mockNetworkClient = MockNetworkClient()
    
    var shouldFailRequests = false {
        didSet {
            mockNetworkClient.shouldFailRequests = shouldFailRequests
        }
    }
    
    func healthCheck() async throws -> HealthResponse {
        return try await mockNetworkClient.healthCheck()
    }
    
    func generateChart(birthData: BirthData, systems: [String]) async throws -> ChartResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return ChartResponse(
            westernChart: WesternChart(
                positions: [
                    "sun": Position(sign: "Aries", degree: 15.5, house: 1),
                    "moon": Position(sign: "Taurus", degree: 23.2, house: 2)
                ],
                houses: [:],
                aspects: []
            ),
            vedicChart: nil,
            chineseChart: nil
        )
    }
    
    func generateChart(from profile: UserProfile) async throws -> ChartResponse {
        let birthData = try BirthData(from: profile)
        return try await generateChart(birthData: birthData, systems: ["western"])
    }
    
    func getChartAspects(birthData: BirthData) async throws -> Data {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        return Data()
    }
    
    func getHoroscope(sign: String, period: String) async throws -> HoroscopeResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        return HoroscopeResponse(
            sign: sign,
            type: period,
            date: dateString,
            horoscope: "Mock horoscope content for \(sign)",
            keywords: ["mock", "test"],
            luckyNumbers: [1, 2, 3],
            compatibility: ["Aries", "Leo"]
        )
    }
    
    func getCompatibilityReport(person1: BirthData, person2: BirthData) async throws -> CompatibilityResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return CompatibilityResponse(
            compatibility_score: 0.75,
            summary: "Mock compatibility summary",
            detailed_analysis: "Mock detailed analysis",
            strengths: ["Communication", "Shared values"],
            challenges: ["Different life goals"]
        )
    }
    
    func getDetailedReport(birthData: BirthData, reportType: String) async throws -> DetailedReportResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return DetailedReportResponse(
            report_type: reportType,
            content: "Mock detailed report content",
            sections: [],
            generated_at: Date()
        )
    }
    
    func searchLocations(query: String) async throws -> [LocationResult] {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return [
            LocationResult(
                name: "Mock City",
                displayName: "Mock City, Mock State, Mock Country",
                latitude: 40.7128,
                longitude: -74.0060,
                country: "Mock Country",
                state: "Mock State",
                timezone: "America/New_York"
            )
        ]
    }
    
    func getCurrentTransits() async throws -> TransitsResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return TransitsResponse(
            date: Date(),
            transits: []
        )
    }
    
    func getChatResponse(messages: [ProtocolChatMessage]) async throws -> ProtocolChatResponse {
        if shouldFailRequests {
            throw NetworkError.serverError(500)
        }
        
        return ProtocolChatResponse(
            response: "Mock AI response",
            conversation_id: "mock-conversation-id"
        )
    }
}

// MARK: - Mock Store Manager

class MockStoreManager: ObservableObject, StoreManagerProtocol {
    @Published var hasProSubscription = false
    @Published var products: [String: String] = [
        "love_forecast": "$4.99",
        "birth_chart": "$7.99",
        "career_forecast": "$5.99",
        "year_ahead": "$9.99",
        "astronova_pro_monthly": "$9.99"
    ]
    
    var shouldFailPurchases = false
    
    func loadProducts() {
        // Mock implementation - products are already loaded
    }
    
    func purchaseProduct(productId: String) async -> Bool {
        if shouldFailPurchases {
            return false
        }
        
        if productId == "astronova_pro_monthly" {
            hasProSubscription = true
        }
        
        return true
    }
    
    func hasProduct(_ productId: String) -> Bool {
        if productId == "astronova_pro_monthly" {
            return hasProSubscription
        }
        return true // Mock: assume all products are available
    }
    
    func restorePurchases() async {
        // Mock implementation - do nothing
    }
}

// MARK: - Mock Dependency Container

extension DependencyContainer {
    static var mock: DependencyContainer {
        return DependencyContainer(
            networkClient: MockNetworkClient(),
            apiServices: MockAPIServices(),
            storeManager: MockStoreManager()
        )
    }
}