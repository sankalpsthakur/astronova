import Foundation

struct PlanetaryPosition: Codable, Identifiable {
    let id: String
    let symbol: String
    let name: String
    let sign: String
    let degree: Double
    let retrograde: Bool
    let house: Int?
    let significance: String?
    
    enum CodingKeys: String, CodingKey {
        case id, symbol, name, sign, degree, retrograde, house, significance
    }
}

struct PlanetaryDataResponse: Codable {
    let planets: [PlanetaryPosition]
    let timestamp: String
    
    enum CodingKeys: String, CodingKey {
        case planets, timestamp
    }
}

struct BirthChartRequest: Codable {
    let birthDate: String
    let birthTime: String
    let latitude: Double
    let longitude: Double
    let timezone: String
    
    enum CodingKeys: String, CodingKey {
        case birthDate = "birth_date"
        case birthTime = "birth_time"
        case latitude, longitude, timezone
    }
}

class PlanetaryDataService {
    static let shared = PlanetaryDataService()
    
    private let networkClient = NetworkClient.shared
    private var cachedPlanets: [PlanetaryPosition] = []
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 3600 // 1 hour
    
    private init() {}
    
    func getCurrentPlanetaryPositions() async throws -> [PlanetaryPosition] {
        if shouldRefreshCache() {
            try await refreshCurrentPositions()
        }
        
        if cachedPlanets.isEmpty {
            return getDefaultPlanetaryPositions()
        }
        
        return cachedPlanets
    }
    
    func getBirthChartPositions(
        birthDate: String,
        birthTime: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) async throws -> [PlanetaryPosition] {
        let request = BirthChartRequest(
            birthDate: birthDate,
            birthTime: birthTime,
            latitude: latitude,
            longitude: longitude,
            timezone: timezone
        )
        
        do {
            let response = try await networkClient.request(
                endpoint: "/api/v1/chart/calculate",
                method: .POST,
                body: request,
                responseType: PlanetaryDataResponse.self
            )
            
            return response.planets
        } catch {
            print("Failed to fetch birth chart positions: \(error)")
            return getDefaultPlanetaryPositions()
        }
    }
    
    private func shouldRefreshCache() -> Bool {
        guard let lastFetch = lastFetchTime else { return true }
        return Date().timeIntervalSince(lastFetch) > cacheTimeout
    }
    
    private func refreshCurrentPositions() async throws {
        do {
            let response = try await networkClient.request(
                endpoint: "/api/v1/ephemeris/current",
                responseType: PlanetaryDataResponse.self
            )
            
            cachedPlanets = response.planets
            lastFetchTime = Date()
        } catch {
            print("Failed to fetch current planetary positions: \(error)")
            if cachedPlanets.isEmpty {
                throw error
            }
        }
    }
    
    private func getDefaultPlanetaryPositions() -> [PlanetaryPosition] {
        return [
            PlanetaryPosition(id: "sun", symbol: "☉", name: "Sun", sign: "Sagittarius", degree: 15.5, retrograde: false, house: 1, significance: "Core identity and vitality"),
            PlanetaryPosition(id: "moon", symbol: "☽", name: "Moon", sign: "Pisces", degree: 22.3, retrograde: false, house: 4, significance: "Emotions and intuition"),
            PlanetaryPosition(id: "mercury", symbol: "☿", name: "Mercury", sign: "Scorpio", degree: 8.7, retrograde: false, house: 12, significance: "Communication and thinking"),
            PlanetaryPosition(id: "venus", symbol: "♀", name: "Venus", sign: "Capricorn", degree: 2.1, retrograde: false, house: 2, significance: "Love and values"),
            PlanetaryPosition(id: "mars", symbol: "♂", name: "Mars", sign: "Leo", degree: 18.9, retrograde: false, house: 9, significance: "Energy and action"),
            PlanetaryPosition(id: "jupiter", symbol: "♃", name: "Jupiter", sign: "Gemini", degree: 12.4, retrograde: true, house: 7, significance: "Growth and wisdom"),
            PlanetaryPosition(id: "saturn", symbol: "♄", name: "Saturn", sign: "Aquarius", degree: 6.8, retrograde: false, house: 3, significance: "Structure and discipline"),
            PlanetaryPosition(id: "uranus", symbol: "♅", name: "Uranus", sign: "Taurus", degree: 25.2, retrograde: true, house: 6, significance: "Innovation and change"),
            PlanetaryPosition(id: "neptune", symbol: "♆", name: "Neptune", sign: "Pisces", degree: 29.7, retrograde: false, house: 4, significance: "Dreams and spirituality"),
            PlanetaryPosition(id: "pluto", symbol: "♇", name: "Pluto", sign: "Capricorn", degree: 28.1, retrograde: false, house: 2, significance: "Transformation and power")
        ]
    }
}