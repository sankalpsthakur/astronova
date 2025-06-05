import Foundation
import SwissEphemeris
import DataModels

/// Simple representation of a planetary aspect.
public struct Aspect: Codable {
    public let planet1: String
    public let planet2: String
    public let angle: Double
}

/// Performs Western astrology chart calculations using Swiss Ephemeris.
public final class WesternCalc {
    private let eph: Ephemeris

    public init(ephemeris: Ephemeris = Ephemeris()) {
        self.eph = ephemeris
    }

    /// Planetary positions for a birth date in the tropical zodiac.
    public func positions(for birth: BirthData) -> [PlanetPosition] {
        eph.positions(for: birth.date)
    }

    /// Detect simple Ptolemaic aspects between planets.
    public func aspects(for birth: BirthData) -> [Aspect] {
        let positions = eph.positions(for: birth.date)
        var result: [Aspect] = []
        for i in 0..<positions.count {
            for j in i+1..<positions.count {
                let diff = abs(positions[i].longitude - positions[j].longitude).truncatingRemainder(dividingBy: 360)
                let angles: [Double] = [0, 60, 90, 120, 180]
                if let match = angles.first(where: { abs(diff - $0) < 5 }) {
                    result.append(Aspect(planet1: positions[i].name,
                                        planet2: positions[j].name,
                                        angle: match))
                }
            }
        }
        return result
    }
}