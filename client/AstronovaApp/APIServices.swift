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
    func getPlanetaryPositions(for date: Date, latitude: Double?, longitude: Double?, system: String) async throws -> [DetailedPlanetaryPosition]
    func getChatResponse(messages: [ProtocolChatMessage]) async throws -> ProtocolChatResponse
    func fetchCompleteDasha(request: DashaCompleteRequest) async throws -> DashaCompleteResponse
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
        // Use NetworkClient's healthCheck to match server route
        return try await networkClient.healthCheck()
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

    // MARK: - Dashas

    /// Fetches the comprehensive dasha response from the backend
    func fetchCompleteDasha(request: DashaCompleteRequest) async throws -> DashaCompleteResponse {
        try await networkClient.request(
            endpoint: "/api/v1/astrology/dashas/complete",
            method: HTTPMethod.POST,
            body: request,
            responseType: DashaCompleteResponse.self
        )
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

    // MARK: - Discover Snapshot

    /// Get unified Discover snapshot for daily check-in (GET version)
    func getDiscoverSnapshot(sign: String, date: Date? = nil) async throws -> DiscoverSnapshot {
        var queryString = "?sign=\(sign.lowercased())"
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryString += "&date=\(formatter.string(from: date))"
        }

        return try await networkClient.request(
            endpoint: "/api/v1/discover/snapshot\(queryString)",
            method: HTTPMethod.GET,
            body: nil,
            responseType: DiscoverSnapshot.self
        )
    }

    /// Get personalized Discover snapshot with birth data (POST version)
    func getPersonalizedDiscoverSnapshot(birthData: BirthData, targetDate: Date? = nil) async throws -> DiscoverSnapshot {
        struct DiscoverRequest: Codable {
            let birthData: BirthDataPayload
            let targetDate: String?

            struct BirthDataPayload: Codable {
                let date: String
                let time: String
                let timezone: String
                let latitude: Double
                let longitude: Double
            }
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"

        let request = DiscoverRequest(
            birthData: DiscoverRequest.BirthDataPayload(
                date: birthData.date,
                time: birthData.time,
                timezone: birthData.timezone,
                latitude: birthData.latitude,
                longitude: birthData.longitude
            ),
            targetDate: targetDate.map { formatter.string(from: $0) }
        )

        return try await networkClient.request(
            endpoint: "/api/v1/discover/snapshot",
            method: HTTPMethod.POST,
            body: request,
            responseType: DiscoverSnapshot.self
        )
    }

    // MARK: - Domain Insights

    /// Response structure for domain insights endpoint
    struct DomainInsightsResponse: Codable {
        let date: String
        let domains: [DomainInsightResponse]
        let cosmicWeather: CosmicWeatherResponse?
        let dailyHoroscope: String?

        struct DomainInsightResponse: Codable {
            let id: String
            let domain: String
            let shortInsight: String
            let fullInsight: String
            let drivers: [PlanetaryDriverResponse]
            let intensity: Double
        }

        struct PlanetaryDriverResponse: Codable {
            let id: String
            let planet: String
            let aspect: String?
            let sign: String?
            let explanation: String
        }

        struct CosmicWeatherResponse: Codable {
            let date: String
            let summary: String
            let mood: String
            let dominantPlanet: String?
            let moonPhase: String?
        }
    }

    /// Get life domain insights with planetary drivers
    func getDomainInsights(date: Date? = nil) async throws -> ([DomainInsight], String?) {
        var queryString = ""
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            queryString = "?date=\(formatter.string(from: date))"
        }

        let response: DomainInsightsResponse = try await networkClient.request(
            endpoint: "/api/v1/discover/domains\(queryString)",
            method: HTTPMethod.GET,
            body: nil,
            responseType: DomainInsightsResponse.self
        )

        // Convert response to app models
        let insights = response.domains.compactMap { domainResp -> DomainInsight? in
            guard let domain = LifeDomain(rawValue: domainResp.domain) else {
                return nil
            }

            let drivers = domainResp.drivers.map { driverResp in
                PlanetaryDriver(
                    id: driverResp.id,
                    planet: driverResp.planet,
                    aspect: driverResp.aspect,
                    sign: driverResp.sign,
                    explanation: driverResp.explanation
                )
            }

            return DomainInsight(
                id: domainResp.id,
                domain: domain,
                shortInsight: domainResp.shortInsight,
                fullInsight: domainResp.fullInsight,
                drivers: drivers,
                intensity: domainResp.intensity
            )
        }

        return (insights, response.dailyHoroscope)
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
    /// Primary attempt: legacy endpoint returning a dictionary of basic positions.
    /// Fallbacks: new ephemeris endpoint (array) mapped to dictionary, then on-device calculation.
    func getCurrentPlanetaryPositions() async throws -> [String: PlanetaryPosition] {
        // 1) Try legacy dictionary endpoint
        do {
            return try await networkClient.request(
                endpoint: "/api/v1/astrology/positions",
                method: HTTPMethod.GET,
                body: nil,
                responseType: [String: PlanetaryPosition].self
            )
        } catch {
            // 2) Try ephemeris endpoint and map to expected type
            do {
                struct EphemerisResponse: Codable { let planets: [DetailedPlanetaryPosition] }
                let ephemeris: EphemerisResponse = try await networkClient.request(
                    endpoint: "/api/v1/ephemeris/current",
                    responseType: EphemerisResponse.self
                )
                var mapped: [String: PlanetaryPosition] = [:]
                for p in ephemeris.planets {
                    mapped[p.name] = PlanetaryPosition(degree: p.degree, sign: p.sign)
                }
                if !mapped.isEmpty { return mapped }
            } catch { /* continue to fallback */ }

            // 3) No local calculation; propagate error to caller
            throw error
        }
    }

    /// Get planetary positions for a specific date.
    /// - Parameters:
    ///   - date: Date to compute positions for (interpreted in UTC day).
    ///   - latitude: Optional latitude (enables rising sign / houses if supported server-side).
    ///   - longitude: Optional longitude (enables rising sign / houses if supported server-side).
    ///   - system: "western" or "vedic".
    func getPlanetaryPositions(
        for date: Date,
        latitude: Double? = nil,
        longitude: Double? = nil,
        system: String = "western"
    ) async throws -> [DetailedPlanetaryPosition] {
        struct EphemerisResponse: Codable {
            let planets: [DetailedPlanetaryPosition]
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        var components = URLComponents()
        components.path = "/api/v1/ephemeris/at"
        var queryItems: [URLQueryItem] = [
            .init(name: "date", value: formatter.string(from: date)),
            .init(name: "system", value: system),
        ]
        if let latitude { queryItems.append(.init(name: "lat", value: String(latitude))) }
        if let longitude { queryItems.append(.init(name: "lon", value: String(longitude))) }
        components.queryItems = queryItems

        let response: EphemerisResponse = try await networkClient.request(
            endpoint: components.path + "?" + (components.query ?? ""),
            responseType: EphemerisResponse.self
        )
        return response.planets
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

        // Get the actual CompatibilityResponse and convert to Data for backward compatibility
        let response = try await networkClient.request(
            endpoint: "/api/v1/compatibility",
            method: HTTPMethod.POST,
            body: request,
            responseType: CompatibilityResponse.self
        )

        // Encode back to Data for callers expecting Data
        let encoder = JSONEncoder()
        return try encoder.encode(response)
    }
    
    /// Generate detailed report
    /// - Parameters:
    ///   - birthData: User's birth data for the report
    ///   - type: Type of report to generate
    ///   - userId: Optional user ID to associate the report with (for library storage)
    func generateDetailedReport(birthData: BirthData, type: String, userId: String? = nil) async throws -> DetailedReportResponse {
        struct ReportRequest: Codable {
            let birthData: BirthData
            let reportType: String
            let userId: String?
        }

        let request = ReportRequest(birthData: birthData, reportType: type, userId: userId)

        return try await networkClient.request(
            endpoint: "/api/v1/reports/generate",
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
            endpoint: "/api/v1/reports/generate",
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
        return try await networkClient.requestData(
            endpoint: "/api/v1/reports/\(reportId)/pdf",
            method: HTTPMethod.GET,
            body: nil
        )
    }
    
    /// Check subscription status
    func checkSubscriptionStatus() async throws -> Bool {
        let response = try await networkClient.request(
            endpoint: "/api/v1/subscription/status",
            method: HTTPMethod.GET,
            body: nil,
            responseType: SubscriptionStatusResponse.self
        )

        return response.isActive
    }
    
    /// Generate report (alias for generateDetailedReport)
    /// - Parameters:
    ///   - birthData: User's birth data for the report
    ///   - type: Type of report to generate
    ///   - userId: Optional user ID to associate the report with (for library storage)
    func generateReport(birthData: BirthData, type: String, userId: String? = nil) async throws -> DetailedReportResponse {
        return try await generateDetailedReport(birthData: birthData, type: type, userId: userId)
    }
    
    /// Get detailed planetary positions
    func getDetailedPlanetaryPositions() async throws -> [DetailedPlanetaryPosition] {
        // Prefer detailed ephemeris endpoint
        do {
            struct EphemerisResponse: Codable { let planets: [DetailedPlanetaryPosition] }
            let res: EphemerisResponse = try await networkClient.request(
                endpoint: "/api/v1/ephemeris/current",
                responseType: EphemerisResponse.self
            )
            return res.planets
        } catch {
            // Fallback to legacy positions endpoint and map to detailed
            let basicPositions = try await getCurrentPlanetaryPositions()
            return basicPositions.map { (planetName, position) in
                DetailedPlanetaryPosition(
                    id: planetName.lowercased(),
                    symbol: planetSymbol(for: planetName),
                    name: planetName,
                    sign: position.sign,
                    degree: position.degree,
                    retrograde: false,
                    house: nil,
                    significance: planetSignificance(for: planetName)
                )
            }
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

    // MARK: - Lightweight helpers
    /// Direct GET helper for ad-hoc endpoints
    func directGET<T: Codable>(endpoint: String, responseType: T.Type) async throws -> T {
        return try await networkClient.request(
            endpoint: endpoint,
            method: HTTPMethod.GET,
            body: nil,
            responseType: responseType
        )
    }

    // MARK: - Birth Data Sync

    /// Sync birth data to server for personalized features
    func syncBirthData(userId: String, profile: UserProfile) async throws {
        guard let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude,
              let timezone = profile.timezone else {
            // Location data not complete, skip sync
            return
        }

        struct BirthDataRequest: Codable {
            let userId: String
            let birthData: BirthDataPayload

            struct BirthDataPayload: Codable {
                let date: String
                let time: String?
                let timezone: String
                let latitude: Double
                let longitude: Double
                let locationName: String?
            }
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: profile.birthDate)

        var timeString: String? = nil
        if let birthTime = profile.birthTime {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            timeString = timeFormatter.string(from: birthTime)
        }

        let request = BirthDataRequest(
            userId: userId,
            birthData: BirthDataRequest.BirthDataPayload(
                date: dateString,
                time: timeString,
                timezone: timezone,
                latitude: latitude,
                longitude: longitude,
                locationName: profile.birthPlace
            )
        )

        let _: [String: String] = try await networkClient.request(
            endpoint: "/api/v1/chat/birth-data",
            method: HTTPMethod.POST,
            body: request,
            responseType: [String: String].self
        )
    }

    /// Fetch birth data from server
    func fetchBirthData(userId: String) async throws -> [String: Any]? {
        struct BirthDataResponse: Codable {
            let hasBirthData: Bool
            let birthData: BirthData?

            struct BirthData: Codable {
                let birth_date: String?
                let birth_time: String?
                let timezone: String?
                let latitude: Double?
                let longitude: Double?
                let location_name: String?
            }
        }

        let response: BirthDataResponse = try await networkClient.request(
            endpoint: "/api/v1/chat/birth-data?userId=\(userId)",
            method: HTTPMethod.GET,
            body: nil,
            responseType: BirthDataResponse.self
        )

        guard response.hasBirthData, let data = response.birthData else {
            return nil
        }

        return [
            "birth_date": data.birth_date as Any,
            "birth_time": data.birth_time as Any,
            "timezone": data.timezone as Any,
            "latitude": data.latitude as Any,
            "longitude": data.longitude as Any,
            "location_name": data.location_name as Any
        ]
    }

    // MARK: - Relationships (Compatibility)

    /// List all relationships for the current user
    /// Note: X-User-Id header is automatically set by NetworkClient
    func listRelationships() async throws -> [RelationshipProfile] {
        struct RelationshipsResponse: Codable {
            let relationships: [RelationshipAPIProfile]
        }

        struct RelationshipAPIProfile: Codable {
            let id: String
            let name: String
            let avatarUrl: String?
            let sunSign: String
            let moonSign: String
            let risingSign: String?
            let birthDate: String
            let sharedSignature: String?
            let lastPulse: RelationshipPulse?
            let lastViewed: String?
            let isFavorite: Bool?
        }

        let response: RelationshipsResponse = try await networkClient.request(
            endpoint: "/api/v1/compatibility/relationships",
            method: HTTPMethod.GET,
            body: nil,
            responseType: RelationshipsResponse.self
        )

        // Convert API response to RelationshipProfile models
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"

        return response.relationships.compactMap { apiProfile -> RelationshipProfile? in
            guard let birthDate = dateFormatter.date(from: apiProfile.birthDate) else {
                return nil
            }

            var lastViewed: Date? = nil
            if let lastViewedStr = apiProfile.lastViewed {
                let isoFormatter = ISO8601DateFormatter()
                lastViewed = isoFormatter.date(from: lastViewedStr)
            }

            return RelationshipProfile(
                id: apiProfile.id,
                name: apiProfile.name,
                avatarUrl: apiProfile.avatarUrl,
                sunSign: apiProfile.sunSign,
                moonSign: apiProfile.moonSign,
                risingSign: apiProfile.risingSign,
                birthDate: birthDate,
                sharedSignature: apiProfile.sharedSignature,
                lastPulse: apiProfile.lastPulse,
                lastViewed: lastViewed
            )
        }
    }

    /// Create a new relationship
    /// Note: X-User-Id header is automatically set by NetworkClient
    func createRelationship(
        name: String,
        birthDate: Date,
        birthTime: Date? = nil,
        timezone: String? = nil,
        latitude: Double? = nil,
        longitude: Double? = nil,
        locationName: String? = nil
    ) async throws -> RelationshipProfile {
        struct CreateRelationshipRequest: Codable {
            let partnerName: String
            let partnerBirthDate: String
            let partnerBirthTime: String?
            let partnerTimezone: String?
            let partnerLatitude: Double?
            let partnerLongitude: Double?
            let partnerLocationName: String?
        }

        struct CreateRelationshipResponse: Codable {
            let id: String
            let name: String
            let avatarUrl: String?
            let sunSign: String
            let moonSign: String
            let risingSign: String?
            let birthDate: String
            let sharedSignature: String?
            let lastPulse: RelationshipPulse?
            let lastViewed: String?
            let isFavorite: Bool?
        }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let birthDateString = dateFormatter.string(from: birthDate)

        var birthTimeString: String? = nil
        if let birthTime = birthTime {
            let timeFormatter = DateFormatter()
            timeFormatter.dateFormat = "HH:mm"
            birthTimeString = timeFormatter.string(from: birthTime)
        }

        let request = CreateRelationshipRequest(
            partnerName: name,
            partnerBirthDate: birthDateString,
            partnerBirthTime: birthTimeString,
            partnerTimezone: timezone,
            partnerLatitude: latitude,
            partnerLongitude: longitude,
            partnerLocationName: locationName
        )

        let response: CreateRelationshipResponse = try await networkClient.request(
            endpoint: "/api/v1/compatibility/relationships",
            method: HTTPMethod.POST,
            body: request,
            responseType: CreateRelationshipResponse.self
        )

        return RelationshipProfile(
            id: response.id,
            name: response.name,
            avatarUrl: response.avatarUrl,
            sunSign: response.sunSign,
            moonSign: response.moonSign,
            risingSign: response.risingSign,
            birthDate: birthDate,
            sharedSignature: response.sharedSignature,
            lastPulse: response.lastPulse,
            lastViewed: nil
        )
    }

    /// Delete a relationship
    /// Note: X-User-Id header is automatically set by NetworkClient
    func deleteRelationship(relationshipId: String) async throws {
        let _: [String: Bool] = try await networkClient.request(
            endpoint: "/api/v1/compatibility/relationships/\(relationshipId)",
            method: HTTPMethod.DELETE,
            body: nil,
            responseType: [String: Bool].self
        )
    }

    /// Get full compatibility snapshot for a relationship
    /// Note: X-User-Id header is automatically set by NetworkClient
    func getCompatibilitySnapshot(relationshipId: String, date: Date? = nil) async throws -> CompatibilitySnapshot {
        var endpoint = "/api/v1/compatibility/relationships/\(relationshipId)/snapshot"
        if let date = date {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            endpoint += "?date=\(formatter.string(from: date))"
        }

        return try await networkClient.request(
            endpoint: endpoint,
            method: HTTPMethod.GET,
            body: nil,
            responseType: CompatibilitySnapshot.self
        )
    }
}
