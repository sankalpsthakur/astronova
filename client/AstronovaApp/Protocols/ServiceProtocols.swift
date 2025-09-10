import Foundation
import CoreLocation

// MARK: - Simple Response Types for Protocol Conformance

/// Simple chat message for protocol conformance
struct ProtocolChatMessage: Codable {
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
struct ProtocolChatRequest: Codable {
    let messages: [ProtocolChatMessage]
    
    init(messages: [ProtocolChatMessage]) {
        self.messages = messages
    }
}

/// Simple chat response for protocol conformance
struct ProtocolChatResponse: Codable {
    let response: String
    let conversation_id: String
    
    init(response: String, conversation_id: String) {
        self.response = response
        self.conversation_id = conversation_id
    }
}

// NetworkClientProtocol is now defined in NetworkClient.swift to avoid circular dependencies

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
    func getChatResponse(messages: [ProtocolChatMessage]) async throws -> ProtocolChatResponse
}

// MARK: - Store Manager Protocol

protocol StoreManagerProtocol: ObservableObject {
    var hasProSubscription: Bool { get }
    var products: [String: String] { get }
    
    func loadProducts()
    func purchaseProduct(productId: String) async -> Bool
    func hasProduct(_ productId: String) -> Bool
    func restorePurchases() async
}

// MARK: - Location Service Protocol

protocol LocationServiceProtocol: ObservableObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission()
    func getCurrentLocation() async throws -> CLLocation
}