import Foundation

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