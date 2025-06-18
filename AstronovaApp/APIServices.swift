import Foundation
import CoreLocation

// MARK: - Simple Response Types for Protocol Conformance

/// Simple horoscope response for protocol conformance
struct ProtocolHoroscopeResponse: Codable {
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

/// Simple chat response for protocol conformance
struct ProtocolChatResponse: Codable {
    let response: String
    let conversation_id: String
    
    init(response: String, conversation_id: String) {
        self.response = response
        self.conversation_id = conversation_id
    }
}

// MARK: - API Services Protocol

protocol APIServicesProtocol: ObservableObject {
    func healthCheck() async throws -> HealthResponse
    func generateChart(birthData: BirthData, systems: [String]) async throws -> ChartResponse
    func generateChart(from profile: UserProfile) async throws -> ChartResponse
    func getChartAspects(birthData: BirthData) async throws -> Data
    func getHoroscope(sign: String, period: String) async throws -> ProtocolHoroscopeResponse
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
}

// MARK: - Location Service Protocol

protocol LocationServiceProtocol: ObservableObject {
    var currentLocation: CLLocation? { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    
    func requestLocationPermission()
    func getCurrentLocation() async throws -> CLLocation
}

/// Main API service class that handles all backend communication
class APIServices: ObservableObject, APIServicesProtocol {
    static let shared = APIServices()
    
    private let networkClient: NetworkClientProtocol
    
    // JWT token for authenticated requests
    var jwtToken: String? {
        didSet {
            if let networkClient = networkClient as? NetworkClient {
                networkClient.setJWTToken(jwtToken)
            }
        }
    }
    
    // Callback for when token expires and needs refresh
    var onTokenExpired: (() async -> Void)?
    
    // Dependency-injectable initializer
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // Keep singleton for backward compatibility but prefer DI  
    private convenience init() {
        self.init(networkClient: NetworkClient())
    }
    
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
        
        return try await makeRequestWithTokenRefresh {
            try await networkClient.request(
                endpoint: "/api/v1/chart/generate",
                method: HTTPMethod.POST,
                body: request,
                responseType: ChartResponse.self
            )
        }
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
        return try await networkClient.requestData(
            endpoint: "/api/v1/chart/aspects",
            method: HTTPMethod.POST,
            body: request
        )
    }
    
    // MARK: - Location Services
    
    /// Search for locations by name (detailed response)
    func searchLocationsDetailed(query: String, limit: Int = 10) async throws -> LocationSearchResponse {
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
    
    // MARK: - Protocol Required Methods
    
    /// Get horoscope for protocol conformance
    func getHoroscope(sign: String, period: String) async throws -> ProtocolHoroscopeResponse {
        let horoscope: AstronovaApp.HoroscopeResponse
        switch period.lowercased() {
        case "daily":
            horoscope = try await getDailyHoroscope(for: sign)
        case "weekly":
            horoscope = try await getWeeklyHoroscope(for: sign)
        case "monthly":
            horoscope = try await getMonthlyHoroscope(for: sign)
        default:
            horoscope = try await getDailyHoroscope(for: sign)
        }
        
        // Convert to protocol format
        return ProtocolHoroscopeResponse(
            sign: sign,
            period: period,
            content: horoscope.horoscope,
            date: Date()
        )
    }
    
    /// Get compatibility report for protocol conformance
    func getCompatibilityReport(person1: BirthData, person2: BirthData) async throws -> CompatibilityResponse {
        // Convert legacy method to return structured data
        let data = try await calculateCompatibility(person1: person1, person2: person2)
        let matchResponse = try JSONDecoder().decode(MatchResponse.self, from: data)
        
        return CompatibilityResponse(
            compatibility_score: Double(matchResponse.overallScore) / 100.0,
            summary: "Compatibility analysis based on astrological factors",
            detailed_analysis: "Detailed analysis of planetary aspects and compatibility",
            strengths: ["Communication", "Emotional connection"],
            challenges: ["Different life approaches"]
        )
    }
    
    /// Get detailed report for protocol conformance
    func getDetailedReport(birthData: BirthData, reportType: String) async throws -> DetailedReportResponse {
        return try await generateDetailedReport(birthData: birthData, type: reportType)
    }
    
    /// Search locations for protocol conformance
    func searchLocations(query: String) async throws -> [LocationResult] {
        let response = try await searchLocationsDetailed(query: query, limit: 10)
        return response.locations
    }
    
    /// Get current transits for protocol conformance
    func getCurrentTransits() async throws -> TransitsResponse {
        let positions = try await getCurrentPlanetaryPositions()
        let transits = positions.map { key, position in
            Transit(
                planet: key,
                aspect: "conjunction",
                target: "natal_position",
                orb: 0.0,
                isExact: true
            )
        }
        
        return TransitsResponse(date: Date(), transits: transits)
    }
    
    /// Get chat response for protocol conformance
    func getChatResponse(messages: [ProtocolChatMessage]) async throws -> ProtocolChatResponse {
        // Convert to simple message format
        guard let lastMessage = messages.last else {
            throw NetworkError.invalidRequest
        }
        
        let response = try await sendChatMessage(lastMessage.content)
        return ProtocolChatResponse(
            response: response.reply,
            conversation_id: response.messageId
        )
    }
    
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
    func getWeeklyHoroscope(for sign: String) async throws -> AstronovaApp.HoroscopeResponse {
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
    func getMonthlyHoroscope(for sign: String) async throws -> AstronovaApp.HoroscopeResponse {
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
    func sendChatMessage(_ message: String, context: ChatContext? = nil) async throws -> AstronovaApp.ChatResponse {
        let request = ChatRequest(message: message, context: context)
        
        return try await networkClient.request(
            endpoint: "/api/v1/chat/send",
            method: HTTPMethod.POST,
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
            method: HTTPMethod.POST,
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
            method: HTTPMethod.POST,
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
            method: HTTPMethod.POST,
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
        if let westernChart = chartResponse.charts["western"] {
            profile.sunSign = westernChart.positions["sun"]?.sign
            profile.moonSign = westernChart.positions["moon"]?.sign
            // Rising sign would be the ascendant, which might need separate calculation
        }
        
        return chartResponse
    }
    
    /// Search for location and get timezone
    func findLocationWithTimezone(query: String) async throws -> LocationResult? {
        let searchResponse = try await searchLocationsDetailed(query: query, limit: 1)
        return searchResponse.locations.first
    }
    
    // MARK: - Authentication Services
    
    /// Authenticate with Apple Sign-In
    func authenticateWithApple(
        idToken: String,
        userIdentifier: String,
        email: String?,
        firstName: String?,
        lastName: String?
    ) async throws -> AuthResponse {
        let request = AppleAuthRequest(
            idToken: idToken,
            userIdentifier: userIdentifier,
            email: email,
            firstName: firstName,
            lastName: lastName
        )
        
        let response = try await networkClient.request(
            endpoint: "/api/v1/auth/apple",
            method: HTTPMethod.POST,
            body: request,
            responseType: AuthResponse.self
        )
        
        // Store the JWT token for future requests
        jwtToken = response.jwtToken
        
        return response
    }
    
    /// Validate stored JWT token
    func validateToken() async throws -> Bool {
        let response = try await networkClient.request(
            endpoint: "/api/v1/auth/validate",
            method: HTTPMethod.GET,
            body: nil,
            responseType: [String: Bool].self
        )
        
        return response["valid"] ?? false
    }
    
    /// Refresh JWT token
    func refreshToken() async throws -> AuthResponse {
        return try await networkClient.request(
            endpoint: "/api/v1/auth/refresh",
            method: HTTPMethod.POST,
            body: nil,
            responseType: AuthResponse.self
        )
    }
    
    /// Logout user
    func logout() async throws {
        try await networkClient.request(
            endpoint: "/api/v1/auth/logout",
            method: HTTPMethod.POST,
            body: nil,
            responseType: [String: String].self
        )
        
        // Clear stored token
        jwtToken = nil
    }
    
    // MARK: - Token Management Helper
    
    /// Make a request with automatic token refresh on expiry
    private func makeRequestWithTokenRefresh<T>(_ request: () async throws -> T) async throws -> T {
        do {
            return try await request()
        } catch {
            // Check if error is token expiry
            if let networkError = error as? NetworkError,
               networkError.requiresReauthentication {
                // Trigger token refresh callback
                await onTokenExpired?()
                // Retry the request once after token refresh
                return try await request()
            } else {
                throw error
            }
        }
    }
}