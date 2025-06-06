import Foundation
import SwissEphemeris
import AstroEngine
import DataModels

/// Advanced chart calculator for both sidereal and tropical systems.
public final class ChartCalculator {
    private let ephemeris: Ephemeris
    private let vedicCalc: VedicKundaliCalc
    private let westernCalc: WesternCalc
    
    // Ayanamsa values for sidereal calculations
    private static let lahiriAyanamsa: Double = 24.0 // Simplified fixed value
    
    public init() {
        self.ephemeris = Ephemeris()
        self.vedicCalc = VedicKundaliCalc(ephemeris: ephemeris)
        self.westernCalc = WesternCalc(ephemeris: ephemeris)
    }
    
    /// Calculates a complete birth chart for the given birth data and chart type.
    public func calculateChart(for birthData: BirthData, type: ChartType) -> AstrologicalChart {
        let calculationDate = type.isTransitChart ? Date() : birthData.chartDate
        
        let positions = type.isSidereal ? 
            calculateSiderealPositions(for: calculationDate) :
            calculateTropicalPositions(for: calculationDate)
        
        let planets = positions.map { position in
            createChartPlanet(from: position, birthData: birthData)
        }
        
        let houses = calculateHouses(for: birthData, type: type)
        let aspects = calculateAspects(between: planets)
        
        return AstrologicalChart(
            birthData: birthData,
            planets: planets,
            houses: houses,
            aspects: aspects,
            chartType: type,
            calculationDate: calculationDate
        )
    }
    
    /// Calculates planetary positions for current transits over birth chart.
    public func calculateTransits(for birthChart: AstrologicalChart) -> [ChartPlanet] {
        let currentPositions = birthChart.chartType.isSidereal ?
            calculateSiderealPositions(for: Date()) :
            calculateTropicalPositions(for: Date())
        
        return currentPositions.map { position in
            createChartPlanet(from: position, birthData: birthChart.birthData, isTransit: true)
        }
    }
    
    // MARK: - Private Calculation Methods
    
    private func calculateSiderealPositions(for date: Date) -> [PlanetPosition] {
        return ephemeris.positions(for: date).map { position in
            let siderealLongitude = fmod(position.longitude - Self.lahiriAyanamsa + 360, 360)
            return PlanetPosition(name: position.name, longitude: siderealLongitude)
        }
    }
    
    private func calculateTropicalPositions(for date: Date) -> [PlanetPosition] {
        return ephemeris.positions(for: date)
    }
    
    private func createChartPlanet(from position: PlanetPosition, birthData: BirthData, isTransit: Bool = false) -> ChartPlanet {
        // Enhanced planet calculation with additional data
        let speed = calculatePlanetarySpeed(for: position.name)
        let isRetrograde = speed < 0
        let house = calculateHousePosition(longitude: position.longitude, birthData: birthData)
        
        return ChartPlanet(
            name: position.name,
            symbol: planetSymbol(for: position.name),
            longitude: position.longitude,
            speed: speed,
            isRetrograde: isRetrograde,
            house: house
        )
    }
    
    private func calculateHouses(for birthData: BirthData, type: ChartType) -> [ChartHouse] {
        // Simplified house calculation using Placidus system
        let ascendant = calculateAscendant(for: birthData)
        
        return (1...12).map { houseNumber in
            let houseCusp = fmod(ascendant + Double(houseNumber - 1) * 30, 360)
            return ChartHouse(number: houseNumber, cusp: houseCusp)
        }
    }
    
    private func calculateAscendant(for birthData: BirthData) -> Double {
        // Simplified ascendant calculation based on birth time and location
        let timeOfDay = Calendar.current.component(.hour, from: birthData.chartDate)
        let longitude = birthData.birthPlace.coordinate.longitude
        
        // Simplified formula - in real implementation would use proper sidereal time calculation
        let localSiderealTime = Double(timeOfDay) * 15 + longitude
        return fmod(localSiderealTime, 360)
    }
    
    private func calculateHousePosition(longitude: Double, birthData: BirthData) -> Int {
        let ascendant = calculateAscendant(for: birthData)
        let adjustedLongitude = fmod(longitude - ascendant + 360, 360)
        return Int(adjustedLongitude / 30) + 1
    }
    
    private func calculatePlanetarySpeed(for planetName: String) -> Double {
        // Simplified speed calculation - in reality would use ephemeris data
        switch planetName.lowercased() {
        case "sun": return 0.9856
        case "moon": return 13.1764
        case "mercury": return 1.3833
        case "venus": return 1.6022
        case "mars": return 0.5240
        case "jupiter": return 0.0831
        case "saturn": return 0.0335
        default: return 0.5
        }
    }
    
    private func calculateAspects(between planets: [ChartPlanet]) -> [ChartAspect] {
        var aspects: [ChartAspect] = []
        
        for i in 0..<planets.count {
            for j in i+1..<planets.count {
                let planet1 = planets[i]
                let planet2 = planets[j]
                
                if let aspect = findAspect(between: planet1, and: planet2) {
                    aspects.append(aspect)
                }
            }
        }
        
        return aspects
    }
    
    private func findAspect(between planet1: ChartPlanet, and planet2: ChartPlanet) -> ChartAspect? {
        let angle = abs(planet1.longitude - planet2.longitude)
        let normalizedAngle = min(angle, 360 - angle)
        
        for aspectType in AspectType.allCases {
            let orb = abs(normalizedAngle - aspectType.angle)
            if orb <= aspectType.orb {
                let isApplying = planet1.speed > planet2.speed
                return ChartAspect(
                    planet1: planet1,
                    planet2: planet2,
                    type: aspectType,
                    orb: orb,
                    isApplying: isApplying
                )
            }
        }
        
        return nil
    }
    
    private func planetSymbol(for name: String) -> String {
        switch name.lowercased() {
        case "sun": return "☉"
        case "moon": return "☽"
        case "mercury": return "☿"
        case "venus": return "♀"
        case "mars": return "♂"
        case "jupiter": return "♃"
        case "saturn": return "♄"
        case "uranus": return "♅"
        case "neptune": return "♆"
        case "pluto": return "♇"
        case "north node", "rahu": return "☊"
        case "south node", "ketu": return "☋"
        default: return "⚹"
        }
    }
}

// MARK: - Chart Type Extensions

extension ChartType {
    public var isSidereal: Bool {
        switch self {
        case .siderealBirth, .siderealTransit:
            return true
        case .tropicalBirth, .tropicalTransit, .composite:
            return false
        }
    }
    
    public var isTransitChart: Bool {
        switch self {
        case .siderealTransit, .tropicalTransit:
            return true
        case .siderealBirth, .tropicalBirth, .composite:
            return false
        }
    }
}