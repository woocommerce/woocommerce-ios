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

    func test_mark_none_resolves_to_the_expected_path() {
        let mark = WooAPIVersion.none
        XCTAssertEqual(mark.rawValue, Expectations.none)
    }

    func test_mark_v1_resolves_to_the_expected_path() {
        let mark = WooAPIVersion.mark1
        XCTAssertEqual(mark.rawValue, Expectations.mark1)
    }

    func test_mark_v2_resolves_to_the_expected_path() {
        let mark = WooAPIVersion.mark2
        XCTAssertEqual(mark.rawValue, Expectations.mark2)
    }

    func test_mark_v3_resolves_to_the_expected_path() {
        let mark = WooAPIVersion.mark3
        XCTAssertEqual(mark.rawValue, Expectations.mark3)
    }

    func test_mark_v4_resolves_to_the_expected_path() {
        let mark = WooAPIVersion.mark4
        XCTAssertEqual(mark.rawValue, Expectations.mark4)
    }
}
