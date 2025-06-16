import XCTest
@testable import AstronovaNetworking

final class AstronovaNetworkingTests: XCTestCase {
    func testExample() throws {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        let networking = AstronovaNetworking()
        XCTAssertEqual(networking.text, "Hello, AstronovaNetworking!")
    }
}