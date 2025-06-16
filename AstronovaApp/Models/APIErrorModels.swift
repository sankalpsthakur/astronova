import Foundation

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

// MARK: - Additional Response Types for Protocol Conformance

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