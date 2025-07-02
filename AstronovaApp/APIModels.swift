import Foundation
import CoreLocation

// MARK: - Birth Data Models

/// Birth data structure matching backend schema
struct BirthData: Codable {
    let name: String
    let date: String // YYYY-MM-DD format
    let time: String // HH:MM format
    let latitude: Double
    let longitude: Double
    let city: String
    let state: String?
    let country: String
    let timezone: String
}

/// Chart request matching backend schema
struct ChartRequest: Codable {
    let birthData: BirthData
    let chartType: String // "natal", "transit", etc.
    let systems: [String] // ["western", "vedic"]
}

/// Planetary position in a chart
struct PlanetaryPosition: Codable {
    let degree: Double
    let sign: String
}

/// Chart system (Western or Vedic) response
struct ChartSystem: Codable {
    let positions: [String: PlanetaryPosition]
    let svg: String // Base64 encoded SVG
}

/// Complete chart response from backend
struct ChartResponse: Codable {
    let chartId: String
    let charts: [String: ChartSystem] // "western", "vedic"
    let type: String
    let westernChart: WesternChart?
    let vedicChart: VedicChart?
    let chineseChart: ChineseChart?
}

/// Western chart structure
struct WesternChart: Codable {
    let positions: [String: Position]
    let houses: [String: House]
    let aspects: [Aspect]
}

/// Vedic chart structure  
struct VedicChart: Codable {
    let positions: [String: Position]
    let houses: [String: House]
    let dashas: [Dasha]
}

/// Chinese chart structure
struct ChineseChart: Codable {
    let year: String
    let month: String
    let day: String
    let hour: String
    let element: String
}

/// Position structure
struct Position: Codable {
    let sign: String
    let degree: Double
    let house: Int
}

/// House structure
struct House: Codable {
    let sign: String
    let degree: Double
}

/// Aspect structure
struct Aspect: Codable {
    let planet1: String
    let planet2: String
    let type: String
    let orb: Double
}

/// Dasha structure for Vedic astrology
struct Dasha: Codable {
    let planet: String
    let startDate: String
    let endDate: String
}

// MARK: - Location Models

/// Location search request
struct LocationSearchRequest: Codable {
    let query: String
    let limit: Int?
}

/// Location result from search
struct LocationResult: Codable, Hashable {
    let name: String
    let displayName: String
    let latitude: Double
    let longitude: Double
    let country: String
    let state: String?
    let timezone: String
    
    // Computed property for compatibility with UI
    var fullName: String {
        return displayName
    }
    
    // Computed property for coordinates
    var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Initializer for location service compatibility
    init(fullName: String, coordinate: CLLocationCoordinate2D, timezone: String) {
        // Parse the full name to extract city/state/country components
        let components = fullName.components(separatedBy: ", ").filter { !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
        
        self.displayName = fullName
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
        self.timezone = timezone
        
        // Extract city name (first component, or fallback to full name)
        self.name = components.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? fullName
        
        // Extract country (usually last component, with validation)
        if let lastComponent = components.last?.trimmingCharacters(in: .whitespacesAndNewlines), !lastComponent.isEmpty {
            self.country = lastComponent
        } else {
            self.country = "Unknown"
        }
        
        // Extract state (usually second to last if more than 2 components)
        if components.count > 2,
           let stateComponent = components.dropLast().last?.trimmingCharacters(in: .whitespacesAndNewlines),
           !stateComponent.isEmpty {
            self.state = stateComponent
        } else {
            self.state = nil
        }
    }
    
    // Hashable conformance
    func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(timezone)
    }
    
    // Equatable conformance
    static func == (lhs: LocationResult, rhs: LocationResult) -> Bool {
        return lhs.displayName == rhs.displayName &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.timezone == rhs.timezone
    }
}

/// Location search response
struct LocationSearchResponse: Codable {
    let locations: [LocationResult]
}

// MARK: - Horoscope Models

/// Horoscope request
struct HoroscopeRequest: Codable {
    let sign: String
    let period: String // "daily", "weekly", "monthly"
    let date: String? // Optional specific date
}

/// Horoscope response
struct HoroscopeResponse: Codable {
    let sign: String
    let type: String // "daily", "weekly", "monthly"
    let date: String
    let horoscope: String
    let keywords: [String]?
    let luckyNumbers: [Int]?
    let compatibility: [String]?
}

// MARK: - Chat Models

/// Chat message request
struct ChatRequest: Codable {
    let message: String
    let context: ChatContext?
}

/// Chat context for personalized responses
struct ChatContext: Codable {
    let userChart: ChartResponse?
    let currentTransits: [String: PlanetaryPosition]?
    let preferences: [String: String]?
}

/// Chat response
struct ChatResponse: Codable {
    let reply: String
    let messageId: String
    let suggestedFollowUps: [String]
}

/// Chat message for history
struct ChatMessage: Codable {
    let id: String
    let message: String
    let response: String
    let timestamp: String
    let userId: String?
}

// MARK: - Report Models

/// Report generation request
struct ReportRequest: Codable {
    let birthData: BirthData
    let reportType: String // "personality", "compatibility", "yearly"
    let options: ReportOptions?
}

/// Report generation options
struct ReportOptions: Codable {
    let includeTransits: Bool?
    let includeAspects: Bool?
    let language: String?
    let format: String? // "pdf", "text"
}

/// Report response
struct ReportResponse: Codable {
    let reportId: String
    let type: String
    let content: String
    let downloadUrl: String?
    let generatedAt: String
}

/// Detailed report request for premium insights
struct DetailedReportRequest: Codable {
    let birthData: BirthData
    let reportType: String // "love_forecast", "birth_chart", "career_forecast", "year_ahead"
    let options: [String: String]?
    let userId: String?
}

/// Detailed report response
struct DetailedReportResponse: Codable {
    let reportId: String
    let type: String
    let title: String
    let summary: String
    let keyInsights: [String]
    let downloadUrl: String
    let generatedAt: String
    let status: String
}

/// Complete detailed report data
struct DetailedReport: Codable {
    let reportId: String
    let type: String
    let title: String
    let content: String
    let summary: String
    let keyInsights: [String]
    let downloadUrl: String
    let generatedAt: String
    let userId: String?
    let status: String
}

/// User reports response
struct UserReportsResponse: Codable {
    let reports: [DetailedReport]
}

// MARK: - Compatibility Models

/// Match user for compatibility calculation
struct MatchUser: Codable {
    let birth_date: String // YYYY-MM-DD format
    let birth_time: String // HH:MM format
    let timezone: String
    let latitude: Double
    let longitude: Double
}

/// Match partner (extends MatchUser with name)
struct MatchPartner: Codable {
    let name: String
    let birth_date: String // YYYY-MM-DD format
    let birth_time: String // HH:MM format
    let timezone: String
    let latitude: Double
    let longitude: Double
}

/// Match/compatibility calculation request
struct MatchRequest: Codable {
    let user: MatchUser
    let partner: MatchPartner
    let matchType: String
    let systems: [String]
}

/// Match/compatibility response
struct MatchResponse: Codable {
    let overallScore: Int
    let vedicScore: Int
    let chineseScore: Int
    let synastryAspects: [String]
    let userChart: [String: [String: Double]]?
    let partnerChart: [String: [String: Double]]?
}

/// Legacy compatibility calculation request (for backward compatibility)
struct CompatibilityRequest: Codable {
    let person1: BirthData
    let person2: BirthData
}

// MARK: - Error Models

/// API error response
struct APIError: Codable, Error {
    let error: String
    let details: [ValidationError]?
    let code: String?
}

/// Validation error details
struct ValidationError: Codable {
    let field: String?
    let message: String
    let code: String?
}

// MARK: - Extensions for convenience

extension BirthData {
    /// Create BirthData from UserProfile
    init(from profile: UserProfile) throws {
        guard let birthTime = profile.birthTime,
              let birthPlace = profile.birthPlace,
              let latitude = profile.birthLatitude,
              let longitude = profile.birthLongitude,
              let timezone = profile.timezone else {
            throw APIError(error: "Incomplete birth data", details: nil, code: "INCOMPLETE_DATA")
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        let timeFormatter = DateFormatter()
        timeFormatter.dateFormat = "HH:mm"
        
        self.name = profile.fullName
        self.date = dateFormatter.string(from: profile.birthDate)
        self.time = timeFormatter.string(from: birthTime)
        self.latitude = latitude
        self.longitude = longitude
        
        // Parse city, state, country from birthPlace
        let components = birthPlace.components(separatedBy: ", ")
        self.city = components.first ?? birthPlace
        self.state = components.count > 2 ? components[1] : nil
        self.country = components.last ?? "Unknown"
        self.timezone = timezone
    }
}



extension PlanetaryPosition {
    /// Format degree as readable string
    var formattedDegree: String {
        String(format: "%.2f°", degree)
    }
    
    /// Full position description
    var description: String {
        "\(sign) \(formattedDegree)"
    }
}

// MARK: - Additional Response Types for Protocol Conformance

/// Compatibility response structure
struct CompatibilityResponse: Codable {
    let compatibility_score: Double
    let summary: String
    let detailed_analysis: String
    let strengths: [String]
    let challenges: [String]
}


/// Report section structure
struct ReportSection: Codable {
    let title: String
    let content: String
    let category: String
}

/// Transits response structure
struct TransitsResponse: Codable {
    let date: Date
    let transits: [Transit]
}

/// Transit structure
struct Transit: Codable {
    let planet: String
    let aspect: String
    let target: String
    let orb: Double
    let isExact: Bool
}

// MARK: - Authentication Models

/// Authenticated user information
struct AuthenticatedUser: Codable {
    let id: String
    let email: String?
    let firstName: String?
    let lastName: String?
    let fullName: String
    let createdAt: String
    let updatedAt: String
    
    var displayName: String {
        if !fullName.isEmpty {
            return fullName
        } else if let email = email {
            return email
        } else {
            return "User"
        }
    }
    
    var initials: String {
        let components = fullName.components(separatedBy: " ")
        let initials = components.compactMap { $0.first }.map { String($0) }
        return initials.joined().uppercased()
    }
}

/// Apple authentication request
struct AppleAuthRequest: Codable {
    let idToken: String
    let userIdentifier: String
    let email: String?
    let firstName: String?
    let lastName: String?
}

/// Authentication response
struct AuthResponse: Codable {
    let jwtToken: String
    let user: AuthenticatedUser
    let expiresAt: String
}