import Foundation
import SwiftUI
import CoreLocation

/// Represents a complete astrological chart with all planetary positions and houses.
public struct AstrologicalChart {
    public let birthData: BirthData
    public let planets: [ChartPlanet]
    public let houses: [ChartHouse]
    public let aspects: [ChartAspect]
    public let chartType: ChartType
    public let calculationDate: Date
    
    public init(
        birthData: BirthData,
        planets: [ChartPlanet],
        houses: [ChartHouse],
        aspects: [ChartAspect],
        chartType: ChartType,
        calculationDate: Date = Date()
    ) {
        self.birthData = birthData
        self.planets = planets
        self.houses = houses
        self.aspects = aspects
        self.chartType = chartType
        self.calculationDate = calculationDate
    }
}

/// Type of astrological chart calculation.
public enum ChartType: String, CaseIterable {
    case siderealBirth = "Sidereal Birth Chart"
    case tropicalBirth = "Tropical Birth Chart"
    case siderealTransit = "Current Sidereal Positions"
    case tropicalTransit = "Current Tropical Positions"
    case composite = "Composite Chart"
    
    public var isPremiumFeature: Bool {
        switch self {
        case .siderealBirth, .tropicalBirth:
            return false
        case .siderealTransit, .tropicalTransit, .composite:
            return true
        }
    }
}

/// Enhanced planet representation for chart visualization.
public struct ChartPlanet {
    public let name: String
    public let symbol: String
    public let longitude: Double
    public let latitude: Double
    public let speed: Double
    public let sign: ZodiacSign
    public let degree: Double
    public let minute: Double
    public let isRetrograde: Bool
    public let house: Int
    public let color: Color
    
    public init(
        name: String,
        symbol: String,
        longitude: Double,
        latitude: Double = 0,
        speed: Double = 0,
        isRetrograde: Bool = false,
        house: Int = 1
    ) {
        self.name = name
        self.symbol = symbol
        self.longitude = longitude
        self.latitude = latitude
        self.speed = speed
        self.isRetrograde = isRetrograde
        self.house = house
        
        // Calculate sign and degree
        let normalizedLongitude = longitude.truncatingRemainder(dividingBy: 360)
        var signIndex = Int(normalizedLongitude / 30)
        // Ensure signIndex is within valid range (0-11)
        signIndex = max(0, min(signIndex, ZodiacSign.allCases.count - 1))
        self.sign = ZodiacSign.allCases[signIndex]
        self.degree = normalizedLongitude.truncatingRemainder(dividingBy: 30)
        self.minute = (degree - floor(degree)) * 60
        
        // Assign colors based on planet
        self.color = Self.colorForPlanet(name)
    }
    
    private static func colorForPlanet(_ name: String) -> Color {
        switch name.lowercased() {
        case "sun": return .orange
        case "moon": return .blue
        case "mercury": return .green
        case "venus": return .pink
        case "mars": return .red
        case "jupiter": return .purple
        case "saturn": return .brown
        case "uranus": return .cyan
        case "neptune": return .indigo
        case "pluto": return .black
        case "north node", "rahu": return .gray
        case "south node", "ketu": return .gray
        default: return .primary
        }
    }
}

/// Zodiac sign enumeration with symbols and properties.
public enum ZodiacSign: String, CaseIterable {
    case aries = "Aries"
    case taurus = "Taurus"
    case gemini = "Gemini"
    case cancer = "Cancer"
    case leo = "Leo"
    case virgo = "Virgo"
    case libra = "Libra"
    case scorpio = "Scorpio"
    case sagittarius = "Sagittarius"
    case capricorn = "Capricorn"
    case aquarius = "Aquarius"
    case pisces = "Pisces"
    
    public var symbol: String {
        switch self {
        case .aries: return "♈"
        case .taurus: return "♉"
        case .gemini: return "♊"
        case .cancer: return "♋"
        case .leo: return "♌"
        case .virgo: return "♍"
        case .libra: return "♎"
        case .scorpio: return "♏"
        case .sagittarius: return "♐"
        case .capricorn: return "♑"
        case .aquarius: return "♒"
        case .pisces: return "♓"
        }
    }
    
    public var element: Element {
        switch self {
        case .aries, .leo, .sagittarius: return .fire
        case .taurus, .virgo, .capricorn: return .earth
        case .gemini, .libra, .aquarius: return .air
        case .cancer, .scorpio, .pisces: return .water
        }
    }
    
    public var modality: Modality {
        switch self {
        case .aries, .cancer, .libra, .capricorn: return .cardinal
        case .taurus, .leo, .scorpio, .aquarius: return .fixed
        case .gemini, .virgo, .sagittarius, .pisces: return .mutable
        }
    }
}

public enum Element: String, CaseIterable {
    case fire = "Fire"
    case earth = "Earth"
    case air = "Air"
    case water = "Water"
    
    public var color: Color {
        switch self {
        case .fire: return .red
        case .earth: return .brown
        case .air: return .yellow
        case .water: return .blue
        }
    }
}

public enum Modality: String, CaseIterable {
    case cardinal = "Cardinal"
    case fixed = "Fixed"
    case mutable = "Mutable"
}

/// Represents an astrological house in the chart.
public struct ChartHouse {
    public let number: Int
    public let cusp: Double
    public let sign: ZodiacSign
    public let ruler: String
    public let interpretation: String
    
    public init(number: Int, cusp: Double) {
        self.number = number
        self.cusp = cusp
        
        let normalizedCusp = cusp.truncatingRemainder(dividingBy: 360)
        let signIndex = Int(normalizedCusp / 30)
        self.sign = ZodiacSign.allCases[signIndex]
        self.ruler = Self.rulerForSign(sign)
        self.interpretation = Self.interpretationForHouse(number)
    }
    
    private static func rulerForSign(_ sign: ZodiacSign) -> String {
        switch sign {
        case .aries: return "Mars"
        case .taurus: return "Venus"
        case .gemini: return "Mercury"
        case .cancer: return "Moon"
        case .leo: return "Sun"
        case .virgo: return "Mercury"
        case .libra: return "Venus"
        case .scorpio: return "Mars"
        case .sagittarius: return "Jupiter"
        case .capricorn: return "Saturn"
        case .aquarius: return "Saturn"
        case .pisces: return "Jupiter"
        }
    }
    
    private static func interpretationForHouse(_ number: Int) -> String {
        switch number {
        case 1: return "Identity & Appearance"
        case 2: return "Resources & Values"
        case 3: return "Communication & Siblings"
        case 4: return "Home & Family"
        case 5: return "Creativity & Romance"
        case 6: return "Health & Service"
        case 7: return "Partnerships & Marriage"
        case 8: return "Transformation & Shared Resources"
        case 9: return "Philosophy & Higher Learning"
        case 10: return "Career & Reputation"
        case 11: return "Friendships & Hopes"
        case 12: return "Spirituality & Hidden Things"
        default: return "Unknown"
        }
    }
}

/// Represents planetary aspects in the chart.
public struct ChartAspect {
    public let planet1: ChartPlanet
    public let planet2: ChartPlanet
    public let type: AspectType
    public let orb: Double
    public let isApplying: Bool
    
    public init(planet1: ChartPlanet, planet2: ChartPlanet, type: AspectType, orb: Double, isApplying: Bool = true) {
        self.planet1 = planet1
        self.planet2 = planet2
        self.type = type
        self.orb = orb
        self.isApplying = isApplying
    }
}

/// Types of planetary aspects with their properties.
public enum AspectType: String, CaseIterable {
    case conjunction = "Conjunction"
    case sextile = "Sextile"
    case square = "Square"
    case trine = "Trine"
    case opposition = "Opposition"
    
    public var angle: Double {
        switch self {
        case .conjunction: return 0
        case .sextile: return 60
        case .square: return 90
        case .trine: return 120
        case .opposition: return 180
        }
    }
    
    public var orb: Double {
        switch self {
        case .conjunction: return 8
        case .sextile: return 6
        case .square: return 8
        case .trine: return 8
        case .opposition: return 8
        }
    }
    
    public var color: Color {
        switch self {
        case .conjunction: return .yellow
        case .sextile: return .green
        case .square: return .red
        case .trine: return .blue
        case .opposition: return .purple
        }
    }
    
    public var isHarmonious: Bool {
        switch self {
        case .sextile, .trine: return true
        case .square, .opposition: return false
        case .conjunction: return true // Generally considered neutral to positive
        }
    }
}

// MARK: - Birth Data Extension

public struct BirthData {
    public let date: Date
    public let time: DateComponents?
    public let location: CLLocation
    
    public init(date: Date, time: DateComponents?, location: CLLocation) {
        self.date = date
        self.time = time
        self.location = location
    }
}

extension BirthData {
    /// Converts to chart calculation format
    public var chartDate: Date {
        if let time = time {
            var components = Calendar.current.dateComponents([.year, .month, .day], from: date)
            components.hour = time.hour
            components.minute = time.minute
            components.second = time.second
            return Calendar.current.date(from: components) ?? date
        }
        return date
    }
    
    public var birthPlace: CLLocation { location }
    public var birthDate: Date { date }
    public var birthTime: DateComponents? { time }
}

// MARK: - User Profile for Chart Context

public struct UserProfile {
    public let fullName: String
    public let birthDate: Date
    public let birthTime: DateComponents?
    public let birthPlace: CLLocation
    public let sunSign: String
    public let moonSign: String
    public let risingSign: String
    public let plusExpiry: Date?
    public let createdAt: Date
    public let updatedAt: Date
    
    public init(
        fullName: String,
        birthDate: Date,
        birthTime: DateComponents?,
        birthPlace: CLLocation,
        sunSign: String,
        moonSign: String,
        risingSign: String,
        plusExpiry: Date? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.fullName = fullName
        self.birthDate = birthDate
        self.birthTime = birthTime
        self.birthPlace = birthPlace
        self.sunSign = sunSign
        self.moonSign = moonSign
        self.risingSign = risingSign
        self.plusExpiry = plusExpiry
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}