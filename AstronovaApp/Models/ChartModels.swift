import Foundation

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