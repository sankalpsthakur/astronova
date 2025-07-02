import Foundation

struct DetailedPlanetaryPosition: Codable, Identifiable {
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
    let planets: [DetailedPlanetaryPosition]
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
    
    // MARK: - Static Data Storage
    private let userDefaults = UserDefaults.standard
    private let customPlanetsKey = "custom_planetary_positions"
    private let customPlanetsEnabledKey = "use_custom_planetary_positions"
    
    private init() {}
    
    func getCurrentPlanetaryPositions() async throws -> [DetailedPlanetaryPosition] {
        // Check if we should use custom static data
        if isUsingCustomPositions() {
            return getCustomPlanetaryPositions()
        }
        
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
    ) async throws -> [DetailedPlanetaryPosition] {
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
    
    private func getDefaultPlanetaryPositions() -> [DetailedPlanetaryPosition] {
        return [
            DetailedPlanetaryPosition(id: "sun", symbol: "☉", name: "Sun", sign: "Sagittarius", degree: 15.5, retrograde: false, house: 1, significance: "Core identity and vitality"),
            DetailedPlanetaryPosition(id: "moon", symbol: "☽", name: "Moon", sign: "Pisces", degree: 22.3, retrograde: false, house: 4, significance: "Emotions and intuition"),
            DetailedPlanetaryPosition(id: "mercury", symbol: "☿", name: "Mercury", sign: "Scorpio", degree: 8.7, retrograde: false, house: 12, significance: "Communication and thinking"),
            DetailedPlanetaryPosition(id: "venus", symbol: "♀", name: "Venus", sign: "Capricorn", degree: 2.1, retrograde: false, house: 2, significance: "Love and values"),
            DetailedPlanetaryPosition(id: "mars", symbol: "♂", name: "Mars", sign: "Leo", degree: 18.9, retrograde: false, house: 9, significance: "Energy and action"),
            DetailedPlanetaryPosition(id: "jupiter", symbol: "♃", name: "Jupiter", sign: "Gemini", degree: 12.4, retrograde: true, house: 7, significance: "Growth and wisdom"),
            DetailedPlanetaryPosition(id: "saturn", symbol: "♄", name: "Saturn", sign: "Aquarius", degree: 6.8, retrograde: false, house: 3, significance: "Structure and discipline"),
            DetailedPlanetaryPosition(id: "uranus", symbol: "♅", name: "Uranus", sign: "Taurus", degree: 25.2, retrograde: true, house: 6, significance: "Innovation and change"),
            DetailedPlanetaryPosition(id: "neptune", symbol: "♆", name: "Neptune", sign: "Pisces", degree: 29.7, retrograde: false, house: 4, significance: "Dreams and spirituality"),
            DetailedPlanetaryPosition(id: "pluto", symbol: "♇", name: "Pluto", sign: "Capricorn", degree: 28.1, retrograde: false, house: 2, significance: "Transformation and power")
        ]
    }
    
    // MARK: - Static Data CRUD Operations
    
    /// Check if custom planetary positions are enabled
    func isUsingCustomPositions() -> Bool {
        return userDefaults.bool(forKey: customPlanetsEnabledKey)
    }
    
    /// Enable or disable custom planetary positions
    func setUseCustomPositions(_ enabled: Bool) {
        userDefaults.set(enabled, forKey: customPlanetsEnabledKey)
    }
    
    /// Get custom planetary positions from storage
    func getCustomPlanetaryPositions() -> [DetailedPlanetaryPosition] {
        guard let data = userDefaults.data(forKey: customPlanetsKey),
              let positions = try? JSONDecoder().decode([DetailedPlanetaryPosition].self, from: data) else {
            return getDefaultPlanetaryPositions()
        }
        return positions
    }
    
    /// Save custom planetary positions to storage
    func setCustomPlanetaryPositions(_ positions: [DetailedPlanetaryPosition]) throws {
        let data = try JSONEncoder().encode(positions)
        userDefaults.set(data, forKey: customPlanetsKey)
    }
    
    /// Update a specific planet's position in custom data
    func updateCustomPlanetPosition(id: String, position: DetailedPlanetaryPosition) throws {
        var positions = getCustomPlanetaryPositions()
        
        if let index = positions.firstIndex(where: { $0.id == id }) {
            positions[index] = position
        } else {
            positions.append(position)
        }
        
        try setCustomPlanetaryPositions(positions)
    }
    
    /// Remove a planet from custom data
    func removeCustomPlanetPosition(id: String) throws {
        var positions = getCustomPlanetaryPositions()
        positions.removeAll { $0.id == id }
        try setCustomPlanetaryPositions(positions)
    }
    
    /// Reset custom positions to default values
    func resetToDefaultPositions() throws {
        let defaultPositions = getDefaultPlanetaryPositions()
        try setCustomPlanetaryPositions(defaultPositions)
    }
    
    /// Clear all custom data and disable custom mode
    func clearCustomPlanetaryData() {
        userDefaults.removeObject(forKey: customPlanetsKey)
        userDefaults.removeObject(forKey: customPlanetsEnabledKey)
    }
    
    /// Get a specific planet position by ID from current data source
    func getPlanetPosition(id: String) async throws -> DetailedPlanetaryPosition? {
        let positions = try await getCurrentPlanetaryPositions()
        return positions.first { $0.id == id }
    }
}