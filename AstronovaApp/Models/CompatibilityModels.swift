import Foundation

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

/// Compatibility response structure
struct CompatibilityResponse: Codable {
    let compatibility_score: Double
    let summary: String
    let detailed_analysis: String
    let strengths: [String]
    let challenges: [String]
}