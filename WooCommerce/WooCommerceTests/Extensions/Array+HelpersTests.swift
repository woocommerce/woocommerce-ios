
import XCTest

@testable import WooCommerce

/// Tests cases for the array extensions in `Array+Helpers.swift`.
///
final class ArrayHelpersTests: XCTestCase {

    func testReverseMethodReversesTheArrayIfTheGivenConditionIsTrue() {
        let source = ["h", "e", "l", "l", "o"]

        let reversed = source.reversed(when: source.count == 5)

        XCTAssertEqual(reversed, ["o", "l", "l", "e", "h"])
    }

    func testReverseMethodDoesNotReverseTheArrayIfTheGivenConditionIsFalse() {
        let source = ["h", "e", "l", "l", "o"]

        let notReversed = source.reversed(when: source.count == 9_000)

        XCTAssertEqual(notReversed, source)
    }
}
