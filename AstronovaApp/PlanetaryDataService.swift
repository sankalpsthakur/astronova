import Foundation
import CoreLocation

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

public class PlanetaryDataService {
    public static let shared = PlanetaryDataService()
    
    private let networkClient = NetworkClient.shared
    private var cachedPlanets: [DetailedPlanetaryPosition] = []
    private var lastFetchTime: Date?
    private let cacheTimeout: TimeInterval = 3600 // 1 hour
    
    // MARK: - Static Data Storage
    private let userDefaults = UserDefaults.standard
    private let customPlanetsKey = "custom_planetary_positions"
    private let customPlanetsEnabledKey = "use_custom_planetary_positions"
    
    private init() {}
    
    public func getCurrentPlanetaryPositions() async throws -> [DetailedPlanetaryPosition] {
        // Check if we should use custom static data
        if isUsingCustomPositions() {
            return getCustomPlanetaryPositions()
        }
        
        // Calculate real-time positions using astronomical calculations
        let julianDay = AstronomicalCalculator.julianDay(from: Date())
        return calculatePlanetaryPositions(julianDay: julianDay, birthLocation: nil)
    }
    
    public func getBirthChartPositions(
        birthDate: String,
        birthTime: String,
        latitude: Double,
        longitude: Double,
        timezone: String
    ) async throws -> [DetailedPlanetaryPosition] {
        // Convert birth date and time to Date object
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd HH:mm"
        dateFormatter.timeZone = TimeZone(identifier: timezone) ?? TimeZone.current
        
        guard let date = dateFormatter.date(from: "\(birthDate) \(birthTime)") else {
            throw NSError(domain: "PlanetaryDataService", code: 1, userInfo: [NSLocalizedDescriptionKey: "Invalid date format"])
        }
        
        // Calculate positions using astronomical calculations
        let julianDay = AstronomicalCalculator.julianDay(from: date)
        let location = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        return calculatePlanetaryPositions(julianDay: julianDay, birthLocation: location)
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
    
    private func calculatePlanetaryPositions(julianDay: Double, birthLocation: CLLocationCoordinate2D?) -> [DetailedPlanetaryPosition] {
        var positions: [DetailedPlanetaryPosition] = []
        
        // Calculate house cusps if birth location is provided
        var houseCusps: [Double]?
        if let location = birthLocation {
            houseCusps = AstronomicalCalculator.calculateHouseCusps(
                julianDay: julianDay,
                latitude: location.latitude,
                longitude: location.longitude
            )
        }
        
        // Calculate Sun position
        let sunPos = AstronomicalCalculator.calculateSunPosition(julianDay: julianDay)
        let sunZodiac = AstronomicalCalculator.getExactZodiacPosition(longitude: sunPos.longitude)
        let sunHouse = houseCusps != nil ? AstronomicalCalculator.getHousePosition(planetLongitude: sunPos.longitude, houseCusps: houseCusps!) : nil
        
        positions.append(DetailedPlanetaryPosition(
            id: "sun",
            symbol: "☉",
            name: "Sun",
            sign: sunZodiac.sign,
            degree: sunPos.longitude,
            retrograde: false,
            house: sunHouse,
            significance: "Core identity and vitality"
        ))
        
        // Calculate Moon position
        let moonPos = AstronomicalCalculator.calculateMoonPosition(julianDay: julianDay)
        let moonZodiac = AstronomicalCalculator.getExactZodiacPosition(longitude: moonPos.longitude)
        let moonHouse = houseCusps != nil ? AstronomicalCalculator.getHousePosition(planetLongitude: moonPos.longitude, houseCusps: houseCusps!) : nil
        
        positions.append(DetailedPlanetaryPosition(
            id: "moon",
            symbol: "☽",
            name: "Moon",
            sign: moonZodiac.sign,
            degree: moonPos.longitude,
            retrograde: false,
            house: moonHouse,
            significance: "Emotions and intuition"
        ))
        
        // Calculate positions for other planets
        let planets = [
            ("Mercury", "mercury", "☿", "Communication and thinking"),
            ("Venus", "venus", "♀", "Love and values"),
            ("Mars", "mars", "♂", "Energy and action"),
            ("Jupiter", "jupiter", "♃", "Growth and wisdom"),
            ("Saturn", "saturn", "♄", "Structure and discipline"),
            ("Uranus", "uranus", "♅", "Innovation and change"),
            ("Neptune", "neptune", "♆", "Dreams and spirituality")
        ]
        
        for (planetName, id, symbol, significance) in planets {
            if let planetPos = AstronomicalCalculator.calculatePlanetPosition(planetName: planetName, julianDay: julianDay) {
                let zodiac = AstronomicalCalculator.getExactZodiacPosition(longitude: planetPos.longitude)
                let house = houseCusps != nil ? AstronomicalCalculator.getHousePosition(planetLongitude: planetPos.longitude, houseCusps: houseCusps!) : nil
                let isRetrograde = AstronomicalCalculator.isRetrograde(planetName: planetName, julianDay: julianDay)
                
                positions.append(DetailedPlanetaryPosition(
                    id: id,
                    symbol: symbol,
                    name: planetName,
                    sign: zodiac.sign,
                    degree: planetPos.longitude,
                    retrograde: isRetrograde,
                    house: house,
                    significance: significance
                ))
            }
        }
        
        return positions
    }
    
    private func getDefaultPlanetaryPositions() -> [DetailedPlanetaryPosition] {
        // This is now only used as a fallback
        let julianDay = AstronomicalCalculator.julianDay(from: Date())
        return calculatePlanetaryPositions(julianDay: julianDay, birthLocation: nil)
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