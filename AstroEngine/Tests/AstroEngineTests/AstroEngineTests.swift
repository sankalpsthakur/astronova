import XCTest
import CoreLocation
@testable import AstroEngine
@testable import DataModels

final class AstroEngineTests: XCTestCase {
    func testWesternPositions() throws {
        let calc = WesternCalc()
        let positions = calc.positions(for: Date(timeIntervalSince1970: 0))
        let longs = positions.map { Int($0.longitude) }
        XCTAssertEqual(longs, [0,30,60,90,120,150,180])
    }

    func testLoShuSquare() throws {
        let calc = LoShuCalc()
        let grid = calc.square(for: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(grid[0][0], 1) // digit 1 appears once
        XCTAssertEqual(grid[2][2], 0)
    }

    func testMatchService() throws {
        let now = Date()
        let me = UserProfile(fullName: "Me",
                              birthDate: now,
                              birthTime: nil,
                              birthPlace: CLLocation(latitude: 0, longitude: 0),
                              sunSign: "Aries",
                              moonSign: "Aries",
                              risingSign: "Aries",
                              plusExpiry: nil,
                              createdAt: now,
                              updatedAt: now)
        let them = UserProfile(fullName: "Them",
                                birthDate: now,
                                birthTime: nil,
                                birthPlace: CLLocation(latitude: 0, longitude: 0),
                                sunSign: "Aries",
                                moonSign: "Aries",
                                risingSign: "Aries",
                                plusExpiry: nil,
                                createdAt: now,
                                updatedAt: now)
        let match = MatchService().compare(me, with: them)
        XCTAssertEqual(match.scoreTotal, 7)
    }
}
