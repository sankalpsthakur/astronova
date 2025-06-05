import XCTest
import CoreLocation
@testable import AstroEngine
@testable import DataModels

final class AstroEngineTests: XCTestCase {
    func testWesternPositions() throws {
        let calc = WesternCalc()
        let data = BirthData(date: Date(timeIntervalSince1970: 0),
                             time: nil,
                             location: CLLocation(latitude: 0, longitude: 0))
        let positions = calc.positions(for: data)
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
        let me = BirthData(date: now,
                           time: nil,
                           location: CLLocation(latitude: 0, longitude: 0))
        let them = BirthData(date: now,
                             time: nil,
                             location: CLLocation(latitude: 0, longitude: 0))
        let match = MatchService().compare(myData: me,
                                           partnerData: them,
                                           partnerName: "Them")
        XCTAssertEqual(match.scoreTotal, 7)
    }
}
