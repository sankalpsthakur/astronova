import Foundation
import CoreLocation

// MARK: - Birth Data Models

/// Birth data structure matching backend schema
public struct BirthData: Codable {
    public let name: String
    public let date: String // YYYY-MM-DD format
    public let time: String // HH:MM format
    public let latitude: Double
    public let longitude: Double
    public let city: String
    public let state: String?
    public let country: String
    public let timezone: String
    
    public init(name: String, date: String, time: String, latitude: Double, longitude: Double, city: String, state: String?, country: String, timezone: String) {
        self.name = name
        self.date = date
        self.time = time
        self.latitude = latitude
        self.longitude = longitude
        self.city = city
        self.state = state
        self.country = country
        self.timezone = timezone
    }
}

/// Chart request matching backend schema
public struct ChartRequest: Codable {
    public let birthData: BirthData
    public let chartType: String // "natal", "transit", etc.
    public let systems: [String] // ["western", "vedic"]
    
    public init(birthData: BirthData, chartType: String, systems: [String]) {
        self.birthData = birthData
        self.chartType = chartType
        self.systems = systems
    }
}

/// Planetary position in a chart
public struct PlanetaryPosition: Codable {
    public let degree: Double
    public let sign: String
    
    public init(degree: Double, sign: String) {
        self.degree = degree
        self.sign = sign
    }
}

/// Chart system (Western or Vedic) response
public struct ChartSystem: Codable {
    public let positions: [String: PlanetaryPosition]
    public let svg: String // Base64 encoded SVG
    
    public init(positions: [String: PlanetaryPosition], svg: String) {
        self.positions = positions
        self.svg = svg
    }
}

/// Complete chart response from backend
public struct ChartResponse: Codable {
    public let chartId: String
    public let charts: [String: ChartSystem] // "western", "vedic"
    public let type: String
    public let westernChart: WesternChart?
    public let vedicChart: VedicChart?
    public let chineseChart: ChineseChart?
    
    public init(chartId: String, charts: [String: ChartSystem], type: String, westernChart: WesternChart?, vedicChart: VedicChart?, chineseChart: ChineseChart?) {
        self.chartId = chartId
        self.charts = charts
        self.type = type
        self.westernChart = westernChart
        self.vedicChart = vedicChart
        self.chineseChart = chineseChart
    }
}

/// Western chart structure
public struct WesternChart: Codable {
    public let positions: [String: Position]
    public let houses: [String: House]
    public let aspects: [Aspect]
    
    public init(positions: [String: Position], houses: [String: House], aspects: [Aspect]) {
        self.positions = positions
        self.houses = houses
        self.aspects = aspects
    }
}

/// Vedic chart structure  
public struct VedicChart: Codable {
    public let positions: [String: Position]
    public let houses: [String: House]
    public let dashas: [Dasha]
    
    public init(positions: [String: Position], houses: [String: House], dashas: [Dasha]) {
        self.positions = positions
        self.houses = houses
        self.dashas = dashas
    }
}

/// Chinese chart structure
public struct ChineseChart: Codable {
    public let year: String
    public let month: String
    public let day: String
    public let hour: String
    public let element: String
    
    public init(year: String, month: String, day: String, hour: String, element: String) {
        self.year = year
        self.month = month
        self.day = day
        self.hour = hour
        self.element = element
    }
}

/// Position structure
public struct Position: Codable {
    public let sign: String
    public let degree: Double
    public let house: Int
    
    public init(sign: String, degree: Double, house: Int) {
        self.sign = sign
        self.degree = degree
        self.house = house
    }
}

/// House structure
public struct House: Codable {
    public let sign: String
    public let degree: Double
    
    public init(sign: String, degree: Double) {
        self.sign = sign
        self.degree = degree
    }
}

/// Aspect structure
public struct Aspect: Codable {
    public let planet1: String
    public let planet2: String
    public let type: String
    public let orb: Double
    
    public init(planet1: String, planet2: String, type: String, orb: Double) {
        self.planet1 = planet1
        self.planet2 = planet2
        self.type = type
        self.orb = orb
    }
}

/// Dasha structure for Vedic astrology
public struct Dasha: Codable {
    public let planet: String
    public let startDate: String
    public let endDate: String
    
    public init(planet: String, startDate: String, endDate: String) {
        self.planet = planet
        self.startDate = startDate
        self.endDate = endDate
    }
}

// MARK: - Location Models

/// Location search request
public struct LocationSearchRequest: Codable {
    public let query: String
    public let limit: Int?
    
    public init(query: String, limit: Int? = nil) {
        self.query = query
        self.limit = limit
    }
}

/// Location result from search
public struct LocationResult: Codable, Hashable {
    public let name: String
    public let displayName: String
    public let latitude: Double
    public let longitude: Double
    public let country: String
    public let state: String?
    public let timezone: String
    
    // Computed property for compatibility with UI
    public var fullName: String {
        return displayName
    }
    
    // Computed property for coordinates
    public var coordinate: CLLocationCoordinate2D {
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
    
    // Initializer for location service compatibility
    public init(fullName: String, coordinate: CLLocationCoordinate2D, timezone: String) {
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
    
    public init(name: String, displayName: String, latitude: Double, longitude: Double, country: String, state: String?, timezone: String) {
        self.name = name
        self.displayName = displayName
        self.latitude = latitude
        self.longitude = longitude
        self.country = country
        self.state = state
        self.timezone = timezone
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        hasher.combine(displayName)
        hasher.combine(latitude)
        hasher.combine(longitude)
        hasher.combine(timezone)
    }
    
    // Equatable conformance
    public static func == (lhs: LocationResult, rhs: LocationResult) -> Bool {
        return lhs.displayName == rhs.displayName &&
               lhs.latitude == rhs.latitude &&
               lhs.longitude == rhs.longitude &&
               lhs.timezone == rhs.timezone
    }
}

/// Location search response
public struct LocationSearchResponse: Codable {
    public let locations: [LocationResult]
    
    public init(locations: [LocationResult]) {
        self.locations = locations
    }
}

// MARK: - Horoscope Models

/// Horoscope request
public struct HoroscopeRequest: Codable {
    public let sign: String
    public let period: String // "daily", "weekly", "monthly"
    public let date: String? // Optional specific date
    
    public init(sign: String, period: String, date: String? = nil) {
        self.sign = sign
        self.period = period
        self.date = date
    }
}

/// Horoscope response
public struct HoroscopeResponse: Codable {
    public let sign: String
    public let type: String // "daily", "weekly", "monthly"
    public let date: String
    public let horoscope: String
    public let keywords: [String]?
    public let luckyNumbers: [Int]?
    public let compatibility: [String]?
    
    public init(sign: String, type: String, date: String, horoscope: String, keywords: [String]?, luckyNumbers: [Int]?, compatibility: [String]?) {
        self.sign = sign
        self.type = type
        self.date = date
        self.horoscope = horoscope
        self.keywords = keywords
        self.luckyNumbers = luckyNumbers
        self.compatibility = compatibility
    }
}

// MARK: - Chat Models

/// Chat message request
public struct ChatRequest: Codable {
    public let message: String
    public let context: ChatContext?
    
    public init(message: String, context: ChatContext? = nil) {
        self.message = message
        self.context = context
    }
}

/// Chat context for personalized responses
public struct ChatContext: Codable {
    public let userChart: ChartResponse?
    public let currentTransits: [String: PlanetaryPosition]?
    public let preferences: [String: String]?
    
    public init(userChart: ChartResponse?, currentTransits: [String: PlanetaryPosition]?, preferences: [String: String]?) {
        self.userChart = userChart
        self.currentTransits = currentTransits
        self.preferences = preferences
    }
}

/// Chat response
public struct ChatResponse: Codable {
    public let reply: String
    public let messageId: String
    public let suggestedFollowUps: [String]
    
    public init(reply: String, messageId: String, suggestedFollowUps: [String]) {
        self.reply = reply
        self.messageId = messageId
        self.suggestedFollowUps = suggestedFollowUps
    }
}

/// Chat message for history
public struct ChatMessage: Codable {
    public let id: String
    public let message: String
    public let response: String
    public let timestamp: String
    public let userId: String?
    
    public init(id: String, message: String, response: String, timestamp: String, userId: String?) {
        self.id = id
        self.message = message
        self.response = response
        self.timestamp = timestamp
        self.userId = userId
    }
}

// MARK: - Report Models

/// Report generation request
public struct ReportRequest: Codable {
    public let birthData: BirthData
    public let reportType: String // "personality", "compatibility", "yearly"
    public let options: ReportOptions?
    
    public init(birthData: BirthData, reportType: String, options: ReportOptions? = nil) {
        self.birthData = birthData
        self.reportType = reportType
        self.options = options
    }
}

/// Report generation options
public struct ReportOptions: Codable {
    public let includeTransits: Bool?
    public let includeAspects: Bool?
    public let language: String?
    public let format: String? // "pdf", "text"
    
    public init(includeTransits: Bool?, includeAspects: Bool?, language: String?, format: String?) {
        self.includeTransits = includeTransits
        self.includeAspects = includeAspects
        self.language = language
        self.format = format
    }
}

/// Report response
public struct ReportResponse: Codable {
    public let reportId: String
    public let type: String
    public let content: String
    public let downloadUrl: String?
    public let generatedAt: String
    
    public init(reportId: String, type: String, content: String, downloadUrl: String?, generatedAt: String) {
        self.reportId = reportId
        self.type = type
        self.content = content
        self.downloadUrl = downloadUrl
        self.generatedAt = generatedAt
    }
}

/// Detailed report request for premium insights
public struct DetailedReportRequest: Codable {
    public let birthData: BirthData
    public let reportType: String // "love_forecast", "birth_chart", "career_forecast", "year_ahead"
    public let options: [String: String]?
    public let userId: String?
    
    public init(birthData: BirthData, reportType: String, options: [String: String]?, userId: String?) {
        self.birthData = birthData
        self.reportType = reportType
        self.options = options
        self.userId = userId
    }
}

/// Detailed report response
public struct DetailedReportResponse: Codable {
    public let reportId: String
    public let type: String
    public let title: String
    public let summary: String
    public let keyInsights: [String]
    public let downloadUrl: String
    public let generatedAt: String
    public let status: String
    
    public init(reportId: String, type: String, title: String, summary: String, keyInsights: [String], downloadUrl: String, generatedAt: String, status: String) {
        self.reportId = reportId
        self.type = type
        self.title = title
        self.summary = summary
        self.keyInsights = keyInsights
        self.downloadUrl = downloadUrl
        self.generatedAt = generatedAt
        self.status = status
    }
}

/// Complete detailed report data
public struct DetailedReport: Codable {
    public let reportId: String
    public let type: String
    public let title: String
    public let content: String
    public let summary: String
    public let keyInsights: [String]
    public let downloadUrl: String
    public let generatedAt: String
    public let userId: String?
    public let status: String
    
    public init(reportId: String, type: String, title: String, content: String, summary: String, keyInsights: [String], downloadUrl: String, generatedAt: String, userId: String?, status: String) {
        self.reportId = reportId
        self.type = type
        self.title = title
        self.content = content
        self.summary = summary
        self.keyInsights = keyInsights
        self.downloadUrl = downloadUrl
        self.generatedAt = generatedAt
        self.userId = userId
        self.status = status
    }
}

/// User reports response
public struct UserReportsResponse: Codable {
    public let reports: [DetailedReport]
    
    public init(reports: [DetailedReport]) {
        self.reports = reports
    }
}

// MARK: - Compatibility Models

/// Match user for compatibility calculation
public struct MatchUser: Codable {
    public let birth_date: String // YYYY-MM-DD format
    public let birth_time: String // HH:MM format
    public let timezone: String
    public let latitude: Double
    public let longitude: Double
    
    public init(birth_date: String, birth_time: String, timezone: String, latitude: Double, longitude: Double) {
        self.birth_date = birth_date
        self.birth_time = birth_time
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Match partner (extends MatchUser with name)
public struct MatchPartner: Codable {
    public let name: String
    public let birth_date: String // YYYY-MM-DD format
    public let birth_time: String // HH:MM format
    public let timezone: String
    public let latitude: Double
    public let longitude: Double
    
    public init(name: String, birth_date: String, birth_time: String, timezone: String, latitude: Double, longitude: Double) {
        self.name = name
        self.birth_date = birth_date
        self.birth_time = birth_time
        self.timezone = timezone
        self.latitude = latitude
        self.longitude = longitude
    }
}

/// Match/compatibility calculation request
public struct MatchRequest: Codable {
    public let user: MatchUser
    public let partner: MatchPartner
    public let matchType: String
    public let systems: [String]
    
    public init(user: MatchUser, partner: MatchPartner, matchType: String, systems: [String]) {
        self.user = user
        self.partner = partner
        self.matchType = matchType
        self.systems = systems
    }
}

/// Match/compatibility response
public struct MatchResponse: Codable {
    public let overallScore: Int
    public let vedicScore: Int
    public let chineseScore: Int
    public let synastryAspects: [String]
    public let userChart: [String: [String: Double]]?
    public let partnerChart: [String: [String: Double]]?
    
    public init(overallScore: Int, vedicScore: Int, chineseScore: Int, synastryAspects: [String], userChart: [String: [String: Double]]?, partnerChart: [String: [String: Double]]?) {
        self.overallScore = overallScore
        self.vedicScore = vedicScore
        self.chineseScore = chineseScore
        self.synastryAspects = synastryAspects
        self.userChart = userChart
        self.partnerChart = partnerChart
    }
}

/// Legacy compatibility calculation request (for backward compatibility)
public struct CompatibilityRequest: Codable {
    public let person1: BirthData
    public let person2: BirthData
    
    public init(person1: BirthData, person2: BirthData) {
        self.person1 = person1
        self.person2 = person2
    }
}

// MARK: - Error Models

/// API error response
public struct APIError: Codable, Error {
    public let error: String
    public let details: [ValidationError]?
    public let code: String?
    
    public init(error: String, details: [ValidationError]?, code: String?) {
        self.error = error
        self.details = details
        self.code = code
    }
}

/// Validation error details
public struct ValidationError: Codable, Sendable {
    public let field: String?
    public let message: String
    public let code: String?
    
    public init(field: String?, message: String, code: String?) {
        self.field = field
        self.message = message
        self.code = code
    }
}

// MARK: - Extensions for convenience

public extension PlanetaryPosition {
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
public struct CompatibilityResponse: Codable {
    public let compatibility_score: Double
    public let summary: String
    public let detailed_analysis: String
    public let strengths: [String]
    public let challenges: [String]
    
    public init(compatibility_score: Double, summary: String, detailed_analysis: String, strengths: [String], challenges: [String]) {
        self.compatibility_score = compatibility_score
        self.summary = summary
        self.detailed_analysis = detailed_analysis
        self.strengths = strengths
        self.challenges = challenges
    }
}

/// Report section structure
public struct ReportSection: Codable {
    public let title: String
    public let content: String
    public let category: String
    
    public init(title: String, content: String, category: String) {
        self.title = title
        self.content = content
        self.category = category
    }
}

/// Transits response structure
public struct TransitsResponse: Codable {
    public let date: Date
    public let transits: [Transit]
    
    public init(date: Date, transits: [Transit]) {
        self.date = date
        self.transits = transits
    }
}

/// Transit structure
public struct Transit: Codable {
    public let planet: String
    public let aspect: String
    public let target: String
    public let orb: Double
    public let isExact: Bool
    
    public init(planet: String, aspect: String, target: String, orb: Double, isExact: Bool) {
        self.planet = planet
        self.aspect = aspect
        self.target = target
        self.orb = orb
        self.isExact = isExact
    }
}