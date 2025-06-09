import Foundation
import CoreLocation

// MARK: - Simple Response Types for Protocol Conformance

/// Simple horoscope response for protocol conformance
struct HoroscopeResponse: Codable {
    let sign: String
    let period: String
    let content: String
    let date: Date
    
    init(sign: String, period: String, content: String, date: Date) {
        self.sign = sign
        self.period = period
        self.content = content
        self.date = date
    }
}

/// Simple chat message for protocol conformance
struct ChatMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date?
    
    init(role: String, content: String, timestamp: Date? = nil) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }
}

/// Simple chat request for protocol conformance
struct ChatRequest: Codable {
    let messages: [ChatMessage]
    
    init(messages: [ChatMessage]) {
        self.messages = messages
    }
}

/// Simple chat response for protocol conformance
struct ChatResponse: Codable {
    let response: String
    let conversation_id: String
    
    init(response: String, conversation_id: String) {
        self.response = response
        self.conversation_id = conversation_id
    }
}

// MARK: - Network Client Protocol

protocol NetworkClientProtocol {
    func healthCheck() async throws -> HealthResponse
    func request<T: Codable>(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?,
        responseType: T.Type
    ) async throws -> T
    func requestData(
        endpoint: String,
        method: HTTPMethod,
        body: Encodable?
    ) async throws -> Data
}

// MARK: - API Services Protocol

protocol APIServicesProtocol: ObservableObject {
    func healthCheck() async throws -> HealthResponse
    func generateChart(birthData: BirthData, systems: [String]) async throws -> ChartResponse
    func generateChart(from profile: UserProfile) async throws -> ChartResponse
    func getChartAspects(birthData: BirthData) async throws -> Data
    func getHoroscope(sign: String, period: String) async throws -> HoroscopeResponse
    func getCompatibilityReport(person1: BirthData, person2: BirthData) async throws -> CompatibilityResponse
    func getDetailedReport(birthData: BirthData, reportType: String) async throws -> DetailedReportResponse
    func searchLocations(query: String) async throws -> [LocationResult]
    func getCurrentTransits() async throws -> TransitsResponse
    func getChatResponse(messages: [ChatMessage]) async throws -> ChatResponse
}

// MARK: - Store Manager Protocol

protocol StoreManagerProtocol: ObservableObject {
    var hasProSubscription: Bool { get }
    var products: [String: String] { get }
    
    func loadProducts()
    func purchaseProduct(productId: String) async -> Bool
}

// MARK: - Location Service Protocol

protocol LocationServiceProtocol: ObservableObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission()
    func getCurrentLocation() async throws -> CLLocation
}