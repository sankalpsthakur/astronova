import Foundation

/// Minimal wrapper mimicking Swiss Ephemeris calculations.
public struct PlanetPosition {
    public let name: String
    public let longitude: Double

    public init(name: String, longitude: Double) {
        self.name = name
        self.longitude = longitude
    }
}

public final class Ephemeris {
    public init() {}

    /// Returns fake planetary positions for a given date.
    public func positions(for date: Date) -> [PlanetPosition] {
        let planets = ["Sun", "Moon", "Mars", "Mercury", "Jupiter", "Venus", "Saturn"]
        let base = date.timeIntervalSince1970.truncatingRemainder(dividingBy: 360)
        return planets.enumerated().map { index, name in
            PlanetPosition(name: name, longitude: fmod(base + Double(index) * 30.0, 360))
        }
    }
}
