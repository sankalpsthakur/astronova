import XCTest
@testable import SwissEphemeris

final class SwissEphemerisTests: XCTestCase {
    func testPositionsCount() {
        let eph = Ephemeris()
        let positions = eph.positions(for: Date(timeIntervalSince1970: 0))
        XCTAssertEqual(positions.count, 7)
    }
}
