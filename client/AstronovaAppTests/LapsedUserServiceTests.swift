import XCTest
@testable import AstronovaApp

@MainActor
final class LapsedUserServiceTests: XCTestCase {

    override func setUpWithError() throws {
        LapsedUserService.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        LapsedUserService.shared._resetForTests()
    }

    func testNoLastOpenIsNotLapsed() {
        XCTAssertFalse(LapsedUserService.shared.isLapsed())
    }

    func testRecentOpenIsNotLapsed() {
        LapsedUserService.shared.recordAppOpen(now: Date())
        XCTAssertFalse(LapsedUserService.shared.isLapsed())
    }

    func testOpenFifteenDaysAgoIsLapsed() {
        let fifteenDaysAgo = Date().addingTimeInterval(-15 * 24 * 3600)
        LapsedUserService.shared.recordAppOpen(now: fifteenDaysAgo)
        XCTAssertTrue(LapsedUserService.shared.isLapsed(now: Date()))
    }

    func testOpenAtThresholdIsLapsed() {
        let fourteenDaysAgo = Date().addingTimeInterval(-14 * 24 * 3600)
        LapsedUserService.shared.recordAppOpen(now: fourteenDaysAgo)
        XCTAssertTrue(LapsedUserService.shared.isLapsed(now: Date()))
    }

    func testAntiSpoilerBodyIsNonEmptyAndDeterministicForSameDay() {
        let now = Date()
        let body1 = LapsedUserService.antiSpoilerBody(now: now)
        let body2 = LapsedUserService.antiSpoilerBody(now: now)
        XCTAssertFalse(body1.isEmpty)
        XCTAssertEqual(body1, body2)
    }
}
