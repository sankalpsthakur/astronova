import XCTest
@testable import AstronovaApp

@MainActor
final class AstronovaReviewPromptsTests: XCTestCase {

    override func setUpWithError() throws {
        AstronovaReviewPrompts.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        AstronovaReviewPrompts.shared._resetForTests()
    }

    func testFirstRequestForPeakIsAllowed() {
        XCTAssertTrue(AstronovaReviewPrompts.shared.shouldRequest(for: .firstChartCompleted))
    }

    func testSamePeakIsNotRequestedTwice() {
        // Simulate first request landing.
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "astronova_review_prompt_last_shown_at")
        UserDefaults.standard.set("first_chart_completed", forKey: "astronova_review_prompt_peak")
        XCTAssertFalse(AstronovaReviewPrompts.shared.shouldRequest(for: .firstChartCompleted))
    }

    func testDifferentPeakWithinThrottleWindowIsBlocked() {
        UserDefaults.standard.set(Date().timeIntervalSince1970, forKey: "astronova_review_prompt_last_shown_at")
        UserDefaults.standard.set("first_chart_completed", forKey: "astronova_review_prompt_peak")
        XCTAssertFalse(AstronovaReviewPrompts.shared.shouldRequest(for: .oracleSessionFifth))
    }

    func testDifferentPeakAfterSixMonthsIsAllowed() {
        let sevenMonthsAgo = Date().addingTimeInterval(-(60 * 60 * 24 * 30 * 7))
        UserDefaults.standard.set(sevenMonthsAgo.timeIntervalSince1970, forKey: "astronova_review_prompt_last_shown_at")
        UserDefaults.standard.set("first_chart_completed", forKey: "astronova_review_prompt_peak")
        XCTAssertTrue(AstronovaReviewPrompts.shared.shouldRequest(for: .oracleSessionFifth))
    }
}
