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
        var components = URLComponents()
        components.path = "/api/v1/locations/search"
        components.queryItems = [
            URLQueryItem(name: "query", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return try await networkClient.request(
            endpoint: url.absoluteString,
            responseType: LocationSearchResponse.self
        )
    }
    
    /// Get timezone for coordinates
    func getTimezone(for coordinate: CLLocationCoordinate2D) async throws -> String {
        var components = URLComponents()
        components.path = "/api/v1/locations/timezone"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(coordinate.latitude)),
            URLQueryItem(name: "lng", value: String(coordinate.longitude))
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        let response = try await networkClient.request(
            endpoint: url.absoluteString,
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
        var components = URLComponents()
        components.path = "/api/v1/horoscope"
        
        var queryItems = [
            URLQueryItem(name: "sign", value: sign.lowercased()),
            URLQueryItem(name: "type", value: "daily")
        ]
        
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryItems.append(URLQueryItem(name: "date", value: formatter.string(from: date)))
        }
        
        components.queryItems = queryItems
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return try await networkClient.request(
            endpoint: url.absoluteString,
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Get weekly horoscope for a sign
    func getWeeklyHoroscope(for sign: String) async throws -> HoroscopeResponse {
        var components = URLComponents()
        components.path = "/api/v1/horoscope"
        components.queryItems = [
            URLQueryItem(name: "sign", value: sign.lowercased()),
            URLQueryItem(name: "type", value: "weekly")
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return try await networkClient.request(
            endpoint: url.absoluteString,
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Get monthly horoscope for a sign
    func getMonthlyHoroscope(for sign: String) async throws -> HoroscopeResponse {
        var components = URLComponents()
        components.path = "/api/v1/horoscope"
        components.queryItems = [
            URLQueryItem(name: "sign", value: sign.lowercased()),
            URLQueryItem(name: "type", value: "monthly")
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return try await networkClient.request(
            endpoint: url.absoluteString,
            responseType: HoroscopeResponse.self
        )
    }
    
    // MARK: - Chat Services
    
    /// Send a chat message to the AI astrologer
    func sendChatMessage(_ message: String, context: ChatContext? = nil) async throws -> ChatResponse {
        let request = ChatRequest(message: message, context: context)
        
        return try await networkClient.request(
            endpoint: "/api/v1/chat/send",
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
    
    /// Generate detailed premium report
    func generateDetailedReport(birthData: BirthData, type: String, userId: String? = nil, options: [String: String]? = nil) async throws -> DetailedReportResponse {
        let request = DetailedReportRequest(
            birthData: birthData,
            reportType: type,
            options: options,
            userId: userId
        )
        
        return try await networkClient.request(
            endpoint: "/api/v1/reports/full",
            method: .POST,
            body: request,
            responseType: DetailedReportResponse.self
        )
    }
    
    /// Get detailed report by ID
    func getDetailedReport(reportId: String) async throws -> DetailedReport {
        return try await networkClient.request(
            endpoint: "/api/v1/reports/\(reportId)",
            responseType: DetailedReport.self
        )
    }
    
    /// Get all reports for user
    func getUserReports(userId: String) async throws -> UserReportsResponse {
        return try await networkClient.request(
            endpoint: "/api/v1/reports/user/\(userId)",
            responseType: UserReportsResponse.self
        )
    }
    
    // MARK: - Ephemeris Services
    
    /// Get current planetary positions
    func getCurrentPlanetaryPositions() async throws -> [String: PlanetaryPosition] {
        return try await networkClient.request(
            endpoint: "/api/v1/ephemeris/positions",
            responseType: [String: PlanetaryPosition].self
        )
    }
    
    /// Get planetary positions for a specific date
    func getPlanetaryPositions(for date: Date) async throws -> [String: PlanetaryPosition] {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: date)
        
        var components = URLComponents()
        components.path = "/api/v1/ephemeris/positions"
        components.queryItems = [
            URLQueryItem(name: "date", value: dateString)
        ]
        
        guard let url = components.url else {
            throw NetworkError.invalidURL
        }
        
        return try await networkClient.request(
            endpoint: url.absoluteString,
            responseType: [String: PlanetaryPosition].self
        )
    }
    
    // MARK: - Compatibility Services
    
    /// Calculate compatibility between two people using modern match endpoint
    func calculateMatch(user: MatchUser, partner: MatchPartner, matchType: String = "romantic", systems: [String] = ["vedic", "chinese"]) async throws -> MatchResponse {
        let request = MatchRequest(
            user: user,
            partner: partner,
            matchType: matchType,
            systems: systems
        )
        
        return try await networkClient.request(
            endpoint: "/api/v1/match",
            method: .POST,
            body: request,
            responseType: MatchResponse.self
        )
    }
    
    /// Legacy compatibility calculation (for backward compatibility)
    func calculateCompatibility(person1: BirthData, person2: BirthData) async throws -> Data {
        // Convert BirthData to MatchUser format
        let user = MatchUser(
            birth_date: person1.date,
            birth_time: person1.time,
            timezone: person1.timezone,
            latitude: person1.latitude,
            longitude: person1.longitude
        )
        
        let partner = MatchPartner(
            name: person2.name,
            birth_date: person2.date,
            birth_time: person2.time,
            timezone: person2.timezone,
            latitude: person2.latitude,
            longitude: person2.longitude
        )
        
        let matchResponse = try await calculateMatch(user: user, partner: partner)
        return try JSONEncoder().encode(matchResponse)
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