import XCTest
@testable import AstronovaApp

@MainActor
final class NPSServiceTests: XCTestCase {

    override func setUpWithError() throws {
        NPSService.shared._resetForTests()
        PortfolioAnalytics.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        NPSService.shared._resetForTests()
        PortfolioAnalytics.shared._resetForTests()
    }

    func testOracleSessionFiveTriggersNPS() {
        var captured: PortfolioEvent?
        PortfolioAnalytics.shared.testEventSink = { event, _ in
            if event == .npsShown { captured = event }
        }

        for _ in 1..<5 {
            let surfaced = NPSService.shared.recordOracleSession()
            XCTAssertFalse(surfaced, "Only the 5th session must surface NPS")
        }
        let surfaced = NPSService.shared.recordOracleSession()
        XCTAssertTrue(surfaced)
        XCTAssertEqual(captured, .npsShown)
        XCTAssertEqual(NPSService.shared.pendingTrigger, .oracleSession5)
    }

    func testFirstCosmicDiaryEntryTriggersNPS() {
        let surfaced = NPSService.shared.recordCosmicDiaryEntry()
        XCTAssertTrue(surfaced)
        XCTAssertEqual(NPSService.shared.pendingTrigger, .firstCosmicDiaryEntry)
    }

    func testSecondCosmicDiaryEntryDoesNotResurfaceNPS() {
        _ = NPSService.shared.recordCosmicDiaryEntry()
        NPSService.shared.dismiss()

        let resurfaced = NPSService.shared.recordCosmicDiaryEntry()
        XCTAssertFalse(resurfaced, "Same trigger key must not re-fire within throttle")
    }

    func testThrottleBlocksWithinSixMonths() {
        _ = NPSService.shared.recordOracleSession() // 1
        _ = NPSService.shared.recordOracleSession()
        _ = NPSService.shared.recordOracleSession()
        _ = NPSService.shared.recordOracleSession()
        _ = NPSService.shared.recordOracleSession() // 5 — fires

        // Different trigger but within throttle window
        let surfaced = NPSService.shared.recordCosmicDiaryEntry()
        XCTAssertFalse(surfaced, "Throttle window must apply across triggers")
    }

    func testSubmitEmitsCorrectBucket() {
        let exp = expectation(description: "submit")
        var props: [String: String]?
        PortfolioAnalytics.shared.testEventSink = { event, properties in
            if event == .npsSubmitted {
                props = properties
                exp.fulfill()
            }
        }

        NPSService.shared.submit(score: 10, comment: "Love it", trigger: .oracleSession5)
        wait(for: [exp], timeout: 1.0)

        XCTAssertEqual(props?["score"], "10")
        XCTAssertEqual(props?["bucket"], "promoter")
        XCTAssertEqual(props?["has_comment"], "true")
        XCTAssertNil(props?["comment"], "Raw comment text must never appear in analytics props")
    }

    func testDetractorBucketing() {
        var props: [String: String]?
        PortfolioAnalytics.shared.testEventSink = { event, properties in
            if event == .npsSubmitted { props = properties }
        }
        NPSService.shared.submit(score: 3, comment: "", trigger: .oracleSession5)
        XCTAssertEqual(props?["bucket"], "detractor")
        XCTAssertEqual(props?["has_comment"], "false")
    }

    func testPassiveBucketing() {
        var props: [String: String]?
        PortfolioAnalytics.shared.testEventSink = { event, properties in
            if event == .npsSubmitted { props = properties }
        }
        NPSService.shared.submit(score: 7, comment: "", trigger: .oracleSession5)
        XCTAssertEqual(props?["bucket"], "passive")
    }
}
