import Foundation
import SwissEphemeris

/// Performs Vedic Kundali (birth chart) calculations using Swiss Ephemeris.
public final class VedicKundaliCalc {
    private let eph: Ephemeris

    public init(ephemeris: Ephemeris = Ephemeris()) {
        self.eph = ephemeris
    }

    /// Sidereal planetary positions with a fixed ayanamsa of 24°.
    public func positions(for date: Date) -> [PlanetPosition] {
        eph.positions(for: date).map {
            PlanetPosition(name: $0.name,
                           longitude: fmod($0.longitude - 24 + 360, 360))
        }
    }

    public func aspects(for date: Date) -> [Aspect] {
        WesternCalc(ephemeris: eph).aspects(for: date)
    }
}