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
}

// MARK: - Location Models

/// Location search request
struct LocationSearchRequest: Codable {
    let query: String
    let limit: Int?
}

/// Location result from search
struct LocationResult: Codable {
    let name: String
    let displayName: String
    let latitude: Double
    let longitude: Double
    let country: String
    let state: String?
    let timezone: String
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
    let period: String
    let date: String
    let content: String
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
    let response: String
    let confidence: Double?
    let suggestions: [String]?
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

// MARK: - Compatibility Models

/// Compatibility calculation request
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
              let coordinates = profile.birthCoordinates,
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
        self.latitude = coordinates.latitude
        self.longitude = coordinates.longitude
        
        // Parse city, state, country from birthPlace
        let components = birthPlace.components(separatedBy: ", ")
        self.city = components.first ?? birthPlace
        self.state = components.count > 2 ? components[1] : nil
        self.country = components.last ?? "Unknown"
        self.timezone = timezone
    }
}

extension LocationResult {
    /// Convert to CLLocationCoordinate2D
    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    /// Full display name with country
    var fullName: String {
        if let state = state {
            return "\(name), \(state), \(country)"
        } else {
            return "\(name), \(country)"
        }
    }
}

extension ChartResponse {
    /// Get Western chart if available
    var westernChart: ChartSystem? {
        charts["western"]
    }
    
    /// Get Vedic chart if available
    var vedicChart: ChartSystem? {
        charts["vedic"]
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