import XCTest

@testable import Networking

final class WooAPIVersionTests: XCTestCase {
    private struct Expectations {
        static let none = ""
        static let mark1 = "wc/v1"
        static let mark2 = "wc/v2"
        static let mark3 = "wc/v3"
        static let mark4 = "wc/v4"
    }

    func testMarkNoneResolvesToTheExpectedPath() {
        let mark = WooAPIVersion.none
        XCTAssertEqual(mark.rawValue, Expectations.none)
    }

    func testMarkV1ResolvesToTheExpectedPath() {
        let mark = WooAPIVersion.mark1
        XCTAssertEqual(mark.rawValue, Expectations.mark1)
    }

    func testMarkV2ResolvesToTheExpectedPath() {
        let mark = WooAPIVersion.mark2
        XCTAssertEqual(mark.rawValue, Expectations.mark2)
    }

    func testMarkV3ResolvesToTheExpectedPath() {
        let mark = WooAPIVersion.mark3
        XCTAssertEqual(mark.rawValue, Expectations.mark3)
    }

    func testMarkV4ResolvesToTheExpectedPath() {
        let mark = WooAPIVersion.mark4
        XCTAssertEqual(mark.rawValue, Expectations.mark4)
    }
}
