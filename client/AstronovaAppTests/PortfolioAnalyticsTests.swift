import XCTest
@testable import AstronovaApp

final class PortfolioAnalyticsTests: XCTestCase {

    override func setUpWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        PortfolioAnalytics.shared._resetForTests()
    }

    func testTrackRoutesThroughTestSink() {
        let exp = expectation(description: "event captured")
        var captured: (PortfolioEvent, [String: String])?
        PortfolioAnalytics.shared.testEventSink = { event, props in
            captured = (event, props)
            exp.fulfill()
        }

        PortfolioAnalytics.shared.track(.chartViewed, properties: [
            "chart_type": "natal",
            "is_paid": "false"
        ])

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(captured?.0, .chartViewed)
        XCTAssertEqual(captured?.1["chart_type"], "natal")
        XCTAssertEqual(captured?.1["is_paid"], "false")
    }

    func testOptOutDropsEventsAndRotatesUserID() {
        let originalUserID = PortfolioAnalytics.shared.userID
        XCTAssertFalse(PortfolioAnalytics.shared.isOptedOut)

        var emitted = 0
        PortfolioAnalytics.shared.testEventSink = { _, _ in emitted += 1 }

        PortfolioAnalytics.shared.track(.appOpen)
        XCTAssertEqual(emitted, 1)

        PortfolioAnalytics.shared.isOptedOut = true
        PortfolioAnalytics.shared.track(.appOpen)
        PortfolioAnalytics.shared.track(.sessionStart)
        XCTAssertEqual(emitted, 1, "Opt-out must short-circuit track()")

        let newUserID = PortfolioAnalytics.shared.userID
        XCTAssertNotEqual(originalUserID, newUserID, "Opt-out must rotate user UUID per privacy doctrine")
    }

    func testOptInDefaultsToTrue() {
        XCTAssertFalse(PortfolioAnalytics.shared.isOptedOut,
                       "Astronova default opt-out posture is OFF (analytics ON) per FEEDBACK_LOOPS_FRAMEWORK")
    }

    func testExperimentBucketIsRecorded() {
        PortfolioAnalytics.shared.setExperimentBucket("paywall_v3", value: "variant_b")
        XCTAssertEqual(PortfolioAnalytics.shared.experimentBucket(for: "paywall_v3"), "variant_b")
    }

    func testAcquisitionSourceIsStickyAndRecordsFirstLaunch() {
        let source1 = ["ref": "astronova_in_app", "utm_campaign": "first_chart_ceremony"]
        PortfolioAnalytics.shared.setAcquisitionSource(source1)

        // Subsequent calls must NOT overwrite (§5.2)
        PortfolioAnalytics.shared.setAcquisitionSource(["ref": "different"])

        XCTAssertEqual(PortfolioAnalytics.shared.acquisitionSource?["ref"], "astronova_in_app")
    }

    func testAnalyticsRouterFansOutToPortfolio() {
        // Verifies the AnalyticsService bridge in AnalyticsService.swift.
        let exp = expectation(description: "fanout fired")
        var captured: PortfolioEvent?
        PortfolioAnalytics.shared.testEventSink = { event, _ in
            captured = event
            exp.fulfill()
        }

        Analytics.shared.track(.chartViewed, properties: nil)

        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(captured, .chartViewed)
    }
}
