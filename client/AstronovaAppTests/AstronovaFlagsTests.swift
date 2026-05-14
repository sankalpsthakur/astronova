import XCTest
@testable import AstronovaApp

final class AstronovaFlagsTests: XCTestCase {

    override func setUpWithError() throws {
        AstronovaFlags.shared._resetForTests()
    }

    override func tearDownWithError() throws {
        AstronovaFlags.shared._resetForTests()
    }

    func testDefaultsAreSafeForOfflineFirstLaunch() {
        // Fresh app launch with no network = baked-in defaults.
        let flags = AstronovaFlags.shared
        XCTAssertEqual(flags.paywallVariant, .default)
        XCTAssertEqual(flags.oracleModel, .sonnet)
        XCTAssertFalse(flags.cosmicDiaryEnabled)
        XCTAssertFalse(flags.giftAReadingEnabled)
    }

    func testOverridesAppliedForTests() {
        AstronovaFlags.shared._overrideForTests(
            paywallVariant: .tieredV1,
            oracleModel: .sonnetThinking,
            cosmicDiaryEnabled: true,
            giftAReadingEnabled: true
        )
        XCTAssertEqual(AstronovaFlags.shared.paywallVariant, .tieredV1)
        XCTAssertEqual(AstronovaFlags.shared.oracleModel, .sonnetThinking)
        XCTAssertTrue(AstronovaFlags.shared.cosmicDiaryEnabled)
        XCTAssertTrue(AstronovaFlags.shared.giftAReadingEnabled)
    }

    func testConfigureWithNilEndpointDoesNotCrashAndKeepsDefaults() {
        AstronovaFlags.shared.configure(endpoint: nil)
        XCTAssertEqual(AstronovaFlags.shared.paywallVariant, .default,
                       "nil endpoint must not corrupt baked-in defaults")
    }
}
