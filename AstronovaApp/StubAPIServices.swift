#if DEBUG
import Foundation
import CoreLocation

/// Stub API service for testing - only available in DEBUG builds
class StubAPIServices: ObservableObject {
    static let shared = StubAPIServices()
    
    var jwtToken: String? = nil
    var onTokenExpired: (() async -> Void)? = nil
    
    init() {}
    
    func healthCheck() async throws -> HealthResponse {
        return HealthResponse(status: "ok")
    }
    
    func generateChart(birthData: BirthData, systems: [String]) async throws -> ChartResponse {
        throw APIError(error: "Stub implementation", details: nil, code: "STUB")
    }
    
    func generateChart(from profile: UserProfile) async throws -> ChartResponse {
        throw APIError(error: "Stub implementation", details: nil, code: "STUB")
    }
    
    func getChartAspects(birthData: BirthData) async throws -> Data {
        return Data()
    }
    
    func getHoroscope(sign: String, period: String) async throws -> HoroscopeResponse {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        return HoroscopeResponse(
            sign: sign,
            type: period,
            date: dateString,
            horoscope: "This is a stub horoscope for \(sign)",
            keywords: ["stub"],
            luckyNumbers: [1, 2, 3],
            compatibility: ["Aries"]
        )
    }
    
    func getCompatibilityReport(person1: BirthData, person2: BirthData) async throws -> CompatibilityResponse {
        return CompatibilityResponse(
            compatibility_score: 0.75,
            summary: "Stub compatibility report",
            detailed_analysis: "This is a stub analysis",
            strengths: ["Stub strength"],
            challenges: ["Stub challenge"]
        )
    }
    
    func getDetailedReport(birthData: BirthData, reportType: String) async throws -> DetailedReportResponse {
        throw APIError(error: "Stub implementation", details: nil, code: "STUB")
    }
    
    func searchLocations(query: String) async throws -> [LocationResult] {
        return [
            LocationResult(
                name: "Stub City",
                displayName: "Stub City, Stub State, Stub Country",
                latitude: 0.0,
                longitude: 0.0,
                country: "Stub Country",
                state: "Stub State",
                timezone: "UTC"
            )
        ]
    }
    
    func getCurrentTransits() async throws -> TransitsResponse {
        return TransitsResponse(date: Date(), transits: [])
    }
    
    func getChatResponse(messages: [ProtocolChatMessage]) async throws -> ProtocolChatResponse {
        return ProtocolChatResponse(
            response: "This is a stub chat response",
            conversation_id: "stub-conversation-id"
        )
    }
    
    func getDailyHoroscope(for sunSign: String) async throws -> HoroscopeResponse {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: Date())
        
        return HoroscopeResponse(
            sign: sunSign,
            type: "daily",
            date: dateString,
            horoscope: "Stub daily horoscope for \(sunSign)",
            keywords: ["daily", "stub"],
            luckyNumbers: [7, 14, 21],
            compatibility: ["Leo"]
        )
    }
    
    func sendChatMessage(_ message: String, context: String) async throws -> ChatResponse {
        return ChatResponse(
            reply: "Stub response to: \(message)",
            messageId: "stub-message-id"
        )
    }
    
    func getUserReports(userId: String) async throws -> [DetailedReport] {
        return []
    }
    
    func generateDetailedReport(userId: String, reportType: String, profileData: UserProfile) async throws -> DetailedReportResponse {
        throw APIError(error: "Stub implementation", details: nil, code: "STUB")
    }
    
    func authenticateWithApple(idToken: String, userIdentifier: String, email: String?, firstName: String?, lastName: String?) async throws -> AuthResponse {
        return AuthResponse(
            jwtToken: "stub-jwt-token",
            user: User(
                id: "stub-user-id",
                email: email ?? "stub@example.com",
                profile: nil
            )
        )
    }
    
    func logout() async throws {
        jwtToken = nil
    }
    
    func validateToken() async throws -> Bool {
        return jwtToken != nil
    }
    
    func refreshToken() async throws -> AuthResponse {
        return AuthResponse(
            jwtToken: "stub-refreshed-jwt-token",
            user: User(
                id: "stub-user-id",
                email: "stub@example.com",
                profile: nil
            )
        )
    }
}
#endif