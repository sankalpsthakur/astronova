import Foundation
import SwissEphemeris
import DataModels

/// Performs Vedic Kundali (birth chart) calculations using Swiss Ephemeris.
public final class VedicKundaliCalc {
    private let eph: Ephemeris

    public init(ephemeris: Ephemeris = Ephemeris()) {
        self.eph = ephemeris
    }

    /// Sidereal planetary positions with a fixed ayanamsa of 24°.
    public func positions(for birth: BirthData) -> [PlanetPosition] {
        eph.positions(for: birth.date).map {
            PlanetPosition(name: $0.name,
                           longitude: fmod($0.longitude - 24 + 360, 360))
        }
    }

    public func aspects(for birth: BirthData) -> [Aspect] {
        WesternCalc(ephemeris: eph).aspects(for: birth)
    }
}