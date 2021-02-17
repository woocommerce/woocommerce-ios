import XCTest
@testable import Hardware

final class HardwareTests: XCTestCase {
    func test_that_tests_run() {
        XCTAssertEqual(Hardware().text, "Hello, World!")
    }
}
