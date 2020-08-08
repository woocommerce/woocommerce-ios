import XCTest
@testable import Testing

final class TestingTests: XCTestCase {
    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct
        // results.
        XCTAssertEqual(Testing().text, "Hello, World!")
    }

    static var allTests = [
        ("testExample", testExample),
    ]
}
