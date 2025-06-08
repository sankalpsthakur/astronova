import Foundation
import CoreLocation

/// Main API service class that handles all backend communication
class APIServices: ObservableObject {
    static let shared = APIServices()
    
    private let networkClient = NetworkClient.shared
    
    private init() {}
    
    // MARK: - Health Check
    
    /// Check if the backend is healthy and accessible
    func healthCheck() async throws -> HealthResponse {
        return try await networkClient.healthCheck()
    }
    
    // MARK: - Chart Services
    
    /// Generate an astrological chart
    func generateChart(birthData: BirthData, systems: [String] = ["western", "vedic"]) async throws -> ChartResponse {
        let request = ChartRequest(
            birthData: birthData,
            chartType: "natal",
            systems: systems
        )
        
        return try await networkClient.request(
            endpoint: "/api/v1/chart/generate",
            method: .POST,
            body: request,
            responseType: ChartResponse.self
        )
    }
    
    /// Generate chart from UserProfile
    func generateChart(from profile: UserProfile) async throws -> ChartResponse {
        let birthData = try BirthData(from: profile)
        return try await generateChart(birthData: birthData)
    }
    
    /// Get chart aspects
    func getChartAspects(birthData: BirthData) async throws -> Data {
        let request = ChartRequest(
            birthData: birthData,
            chartType: "natal",
            systems: ["western"]
        )
        
        // Note: Return raw Data for flexible JSON handling
        // Can be decoded to specific types as needed
        return try await networkClient.requestRaw(
            endpoint: "/api/v1/chart/aspects",
            method: .POST,
            body: request
        )
    }
    
    // MARK: - Location Services
    
    /// Search for locations by name
    func searchLocations(query: String, limit: Int = 10) async throws -> LocationSearchResponse {
        let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? query
        
        return try await networkClient.request(
            endpoint: "/api/locations/search?query=\(encodedQuery)&limit=\(limit)",
            responseType: LocationSearchResponse.self
        )
    }
    
    /// Get timezone for coordinates
    func getTimezone(for coordinate: CLLocationCoordinate2D) async throws -> String {
        let response = try await networkClient.request(
            endpoint: "/api/locations/timezone?lat=\(coordinate.latitude)&lng=\(coordinate.longitude)",
            responseType: [String: String].self
        )
        
        guard let timezone = response["timezone"] else {
            throw NetworkError.decodingError
        }
        
        return timezone
    }
    
    // MARK: - Horoscope Services
    
    /// Get daily horoscope for a sign
    func getDailyHoroscope(for sign: String, date: Date? = nil) async throws -> HoroscopeResponse {
        var endpoint = "/api/horoscope/daily/\(sign.lowercased())"
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            endpoint += "?date=\(formatter.string(from: date))"
        }
        
        return try await networkClient.request(
            endpoint: endpoint,
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Get weekly horoscope for a sign
    func getWeeklyHoroscope(for sign: String) async throws -> HoroscopeResponse {
        return try await networkClient.request(
            endpoint: "/api/horoscope/weekly/\(sign.lowercased())",
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Get monthly horoscope for a sign
    func getMonthlyHoroscope(for sign: String) async throws -> HoroscopeResponse {
        return try await networkClient.request(
            endpoint: "/api/horoscope/monthly/\(sign.lowercased())",
            responseType: HoroscopeResponse.self
        )
    }
    
    // MARK: - Chat Services
    
    /// Send a chat message to the AI astrologer
    func sendChatMessage(_ message: String, context: ChatContext? = nil) async throws -> ChatResponse {
        let request = ChatRequest(message: message, context: context)
        
        return try await networkClient.request(
            endpoint: "/api/v1/chat",
            method: .POST,
            body: request,
            responseType: ChatResponse.self
        )
    }
    
    /// Retrieve chat history
    func getChatHistory() async throws -> [ChatMessage] {
        return try await networkClient.request(
            endpoint: "/api/v1/chat/history",
            responseType: [ChatMessage].self
        )
    }
    
    // MARK: - Report Services
    
    /// Generate a detailed astrological report
    func generateReport(birthData: BirthData, type: String, options: ReportOptions? = nil) async throws -> ReportResponse {
        let request = ReportRequest(
            birthData: birthData,
            reportType: type,
            options: options
        )
        
        return try await networkClient.request(
            endpoint: "/api/reports/generate",
            method: .POST,
            body: request,
            responseType: ReportResponse.self
        )
    }
    
    /// Get report status
    func getReportStatus(reportId: String) async throws -> ReportResponse {
        return try await networkClient.request(
            endpoint: "/api/reports/\(reportId)",
            responseType: ReportResponse.self
        )
    }
    
    // MARK: - Ephemeris Services
    
    /// Get current planetary positions
    func getCurrentPlanetaryPositions() async throws -> [String: PlanetaryPosition] {
        return try await networkClient.request(
            endpoint: "/api/ephemeris/current",
            responseType: [String: PlanetaryPosition].self
        )
    }
    
    /// Get planetary positions for a specific date
    func getPlanetaryPositions(for date: Date) async throws -> [String: PlanetaryPosition] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        return try await networkClient.request(
            endpoint: "/api/ephemeris/positions?date=\(dateString)",
            responseType: [String: PlanetaryPosition].self
        )
    }
    
    // MARK: - Compatibility Services
    
    /// Calculate compatibility between two birth charts
    func calculateCompatibility(person1: BirthData, person2: BirthData) async throws -> Data {
        let request = CompatibilityRequest(person1: person1, person2: person2)
        
        // Note: Return raw Data for flexible JSON handling
        // Can be decoded to specific types as needed
        return try await networkClient.requestRaw(
            endpoint: "/api/match/compatibility",
            method: .POST,
            body: request
        )
    }
}

// MARK: - Convenience Extensions

extension APIServices {
    /// Generate chart and update user profile with calculated signs
    func generateChartAndUpdateProfile(_ profile: inout UserProfile) async throws -> ChartResponse {
        let chartResponse = try await generateChart(from: profile)
        
        // Update profile with calculated signs from the chart
        if let westernChart = chartResponse.westernChart {
            profile.sunSign = westernChart.positions["sun"]?.sign
            profile.moonSign = westernChart.positions["moon"]?.sign
            // Rising sign would be the ascendant, which might need separate calculation
        }
        
        return chartResponse
    }
    
    /// Search for location and get timezone
    func findLocationWithTimezone(query: String) async throws -> LocationResult? {
        let searchResponse = try await searchLocations(query: query, limit: 1)
        return searchResponse.locations.first
    }
}