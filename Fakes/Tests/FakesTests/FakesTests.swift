import XCTest
@testable import Fakes

final class FakesTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Fakes().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
