import Foundation
import CoreLocation

// MARK: - Protocol Definitions

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

/// API Services Protocol
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
    
    // Token expiry callback
    var onTokenExpired: (() async -> Void)?
    
    // Dependency-injectable initializer
    init(networkClient: NetworkClientProtocol = NetworkClient()) {
        self.networkClient = networkClient
    }
    
    // Keep singleton for backward compatibility but prefer DI
    private init() {
        self.networkClient = NetworkClient()
    }
    
    // MARK: - Health Check
    
    /// Check if the backend service is healthy
    func healthCheck() async throws -> HealthResponse {
        return try await networkClient.request(
            endpoint: "/api/v1/health",
            method: HTTPMethod.GET,
            body: nil,
            responseType: HealthResponse.self
        )
    }
    
    // MARK: - Chart Generation
    
    /// Generate astrological chart
    func generateChart(birthData: BirthData, systems: [String]) async throws -> ChartResponse {
        struct ChartRequest: Codable {
            let birthData: BirthData
            let systems: [String]
        }
        
        let request = ChartRequest(birthData: birthData, systems: systems)
        
        return try await networkClient.request(
            endpoint: "/api/v1/chart/generate",
            method: HTTPMethod.POST,
            body: request,
            responseType: ChartResponse.self
        )
    }
    
    /// Generate chart from user profile
    func generateChart(from profile: UserProfile) async throws -> ChartResponse {
        guard let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude,
              let timezone = profile.timezone else {
            throw NetworkError.invalidRequest
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: profile.birthDate)
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        let timeString = profile.birthTime != nil ? timeFormatter.string(from: profile.birthTime!) : "12:00"
        
        let birthData = BirthData(
            name: profile.fullName,
            date: dateString,
            time: timeString,
            latitude: latitude,
            longitude: longitude,
            city: profile.birthPlace ?? "Unknown",
            state: nil,
            country: "Unknown",
            timezone: timezone
        )
        
        let systems = ["tropical"] // Default to tropical system
        
        return try await generateChart(birthData: birthData, systems: systems)
    }
    
    /// Get chart aspects
    func getChartAspects(birthData: BirthData) async throws -> Data {
        return try await networkClient.request(
            endpoint: "/api/v1/chart/aspects",
            method: HTTPMethod.POST,
            body: birthData,
            responseType: Data.self
        )
    }
    
    // MARK: - Protocol Required Methods
    
    /// Get horoscope for protocol conformance
    func getHoroscope(sign: String, period: String) async throws -> HoroscopeResponse {
        switch period.lowercased() {
        case "daily":
            return try await getDailyHoroscope(for: sign)
        case "weekly":
            return try await getWeeklyHoroscope(for: sign)
        case "monthly":
            return try await getMonthlyHoroscope(for: sign)
        default:
            return try await getDailyHoroscope(for: sign)
        }
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
        if query.isEmpty {
            return []
        }
        
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
        
        return try await networkClient.request(
            endpoint: components.path + "?" + (components.query ?? ""),
            method: HTTPMethod.GET,
            body: nil,
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Get weekly horoscope for a sign
    func getWeeklyHoroscope(for sign: String) async throws -> HoroscopeResponse {
        let queryString = "?sign=\(sign.lowercased())&type=weekly"
        
        return try await networkClient.request(
            endpoint: "/api/v1/horoscope\(queryString)",
            method: HTTPMethod.GET,
            body: nil,
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Get monthly horoscope for a sign
    func getMonthlyHoroscope(for sign: String) async throws -> HoroscopeResponse {
        let queryString = "?sign=\(sign.lowercased())&type=monthly"
        
        return try await networkClient.request(
            endpoint: "/api/v1/horoscope\(queryString)",
            method: HTTPMethod.GET,
            body: nil,
            responseType: HoroscopeResponse.self
        )
    }
    
    /// Search locations with details
    func searchLocationsDetailed(query: String, limit: Int = 10) async throws -> LocationSearchResponse {
        var components = URLComponents()
        components.path = "/api/v1/location/search"
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: String(limit))
        ]
        
        let response = try await networkClient.request(
            endpoint: components.path + "?" + (components.query ?? ""),
            method: HTTPMethod.GET,
            body: nil,
            responseType: LocationSearchResponse.self
        )
        
        return response
    }
    
    /// Get current planetary positions
    func getCurrentPlanetaryPositions() async throws -> [String: PlanetaryPosition] {
        return try await networkClient.request(
            endpoint: "/api/v1/astrology/positions",
            method: HTTPMethod.GET,
            body: nil,
            responseType: [String: PlanetaryPosition].self
        )
    }
    
    /// Send chat message
    func sendChatMessage(_ message: String, context: String = "") async throws -> ChatResponse {
        struct ChatRequest: Codable {
            let message: String
            let context: String
        }
        
        let request = ChatRequest(message: message, context: context)
        
        return try await networkClient.request(
            endpoint: "/api/v1/chat",
            method: HTTPMethod.POST,
            body: request,
            responseType: ChatResponse.self
        )
    }
    
    /// Calculate compatibility between two people
    func calculateCompatibility(person1: BirthData, person2: BirthData) async throws -> Data {
        struct CompatibilityRequest: Codable {
            let person1: BirthData
            let person2: BirthData
        }
        
        let request = CompatibilityRequest(person1: person1, person2: person2)
        
        return try await networkClient.request(
            endpoint: "/api/v1/compatibility",
            method: HTTPMethod.POST,
            body: request,
            responseType: Data.self
        )
    }
    
    /// Generate detailed report
    func generateDetailedReport(birthData: BirthData, type: String) async throws -> DetailedReportResponse {
        struct ReportRequest: Codable {
            let birthData: BirthData
            let reportType: String
        }
        
        let request = ReportRequest(birthData: birthData, reportType: type)
        
        return try await networkClient.request(
            endpoint: "/api/v1/report/generate",
            method: HTTPMethod.POST,
            body: request,
            responseType: DetailedReportResponse.self
        )
    }
    
    // MARK: - Report Services
    
    /// Get user reports
    func getUserReports(userId: String) async throws -> [DetailedReport] {
        return try await networkClient.request(
            endpoint: "/api/v1/reports/user/\(userId)",
            method: HTTPMethod.GET,
            body: nil,
            responseType: [DetailedReport].self
        )
    }
    
    /// Generate detailed report with user profile
    func generateDetailedReport(userId: String, reportType: String, profileData: UserProfile) async throws -> DetailedReportResponse {
        struct ReportRequest: Codable {
            let userId: String
            let reportType: String
            let profileData: UserProfile
        }
        
        let request = ReportRequest(
            userId: userId,
            reportType: reportType,
            profileData: profileData
        )
        
        return try await networkClient.request(
            endpoint: "/api/v1/report/generate",
            method: HTTPMethod.POST,
            body: request,
            responseType: DetailedReportResponse.self
        )
    }
    
    // MARK: - Authentication
    
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
        // Check if token exists locally first
        guard jwtToken != nil && !jwtToken!.isEmpty else {
            return false
        }
        
        // Then validate with backend
        do {
            let response = try await networkClient.request(
                endpoint: "/api/v1/auth/validate",
                method: HTTPMethod.GET,
                body: nil,
                responseType: [String: Bool].self
            )
            
            return response["valid"] ?? false
        } catch {
            // If validation fails, assume token is invalid
            return false
        }
    }
    
    /// Refresh JWT token
    func refreshToken() async throws -> AuthResponse {
        let response = try await networkClient.request(
            endpoint: "/api/v1/auth/refresh",
            method: HTTPMethod.POST,
            body: nil,
            responseType: AuthResponse.self
        )
        
        // Update stored token
        jwtToken = response.jwtToken
        
        return response
    }
    
    /// Logout user
    func logout() async throws {
        let _ = try await networkClient.request(
            endpoint: "/api/v1/auth/logout",
            method: HTTPMethod.POST,
            body: nil,
            responseType: [String: String].self
        )
        
        // Clear stored token
        jwtToken = nil
    }
    
    /// Delete user account
    func deleteAccount() async throws {
        let _ = try await networkClient.request(
            endpoint: "/api/v1/auth/delete-account",
            method: HTTPMethod.DELETE,
            body: nil,
            responseType: [String: String].self
        )
        
        // Clear stored token after successful deletion
        jwtToken = nil
    }
    
    /// Generate PDF for report
    func generateReportPDF(reportId: String) async throws -> Data {
        return try await networkClient.request(
            endpoint: "/api/v1/reports/\(reportId)/pdf",
            method: HTTPMethod.GET,
            body: nil,
            responseType: Data.self
        )
    }
    
    /// Check subscription status
    func checkSubscriptionStatus() async throws -> Bool {
        let response = try await networkClient.request(
            endpoint: "/api/v1/subscription/status",
            method: HTTPMethod.GET,
            body: nil,
            responseType: [String: Bool].self
        )
        
        return response["isActive"] ?? false
    }
    
    /// Generate report (alias for generateDetailedReport)
    func generateReport(birthData: BirthData, type: String) async throws -> DetailedReportResponse {
        return try await generateDetailedReport(birthData: birthData, type: type)
    }
    
    /// Get detailed planetary positions
    func getDetailedPlanetaryPositions() async throws -> [DetailedPlanetaryPosition] {
        // For now, convert from current basic positions to detailed format
        let basicPositions = try await getCurrentPlanetaryPositions()
        
        return basicPositions.map { (planetName, position) in
            DetailedPlanetaryPosition(
                id: planetName.lowercased(),
                symbol: planetSymbol(for: planetName),
                name: planetName,
                sign: position.sign,
                degree: position.degree,
                retrograde: false, // TODO: Get from API
                house: nil, // TODO: Calculate house position
                significance: planetSignificance(for: planetName)
            )
        }
    }
    
    private func planetSymbol(for planet: String) -> String {
        switch planet {
        case "Sun": return "☉"
        case "Moon": return "☽"
        case "Mercury": return "☿"
        case "Venus": return "♀"
        case "Mars": return "♂"
        case "Jupiter": return "♃"
        case "Saturn": return "♄"
        case "Uranus": return "♅"
        case "Neptune": return "♆"
        case "Pluto": return "♇"
        default: return "●"
        }
    }
    
    private func planetSignificance(for planet: String) -> String {
        switch planet {
        case "Sun": return "Core identity and vitality"
        case "Moon": return "Emotions and intuition"
        case "Mercury": return "Communication and thinking"
        case "Venus": return "Love and values"
        case "Mars": return "Energy and action"
        case "Jupiter": return "Growth and wisdom"
        case "Saturn": return "Structure and discipline"
        case "Uranus": return "Innovation and change"
        case "Neptune": return "Dreams and spirituality"
        case "Pluto": return "Transformation and power"
        default: return "Planetary influence"
        }
    }
}