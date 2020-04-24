import XCTest

@testable import WooCommerce

final class PositiveIntegerInputFormatterTests: XCTestCase {
    private let formatter = PositiveIntegerInputFormatter()

    // MARK: test cases for `isValid(input:)`

    func testEmptyInputIsValid() {
        let input = ""
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func testAlphanumericInputIsNotValid() {
        let input = "06two"
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func testDecimalInputIsNotValid() {
        let input = "9990.52"
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func testTrailingPointInputIsValid() {
        let input = "9990."
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func testIntegerInputIsValid() {
        let input = "888888"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    // MARK: test cases for `format(input:)`

    func testFormattingEmptyInput() {
        let input = ""
        XCTAssertEqual(formatter.format(input: input), "0")
    }

    func testFormattingInputWithLeadingZeros() {
        let input = "0012391"
        XCTAssertEqual(formatter.format(input: input), "12391")
    }

    func testFormattingIntegerInput() {
        let input = "314200"
        XCTAssertEqual(formatter.format(input: input), "314200")
    }
}
