import XCTest

@testable import WooCommerce

final class IntegerInputFormatterTests: XCTestCase {
    private let formatter = IntegerInputFormatter(defaultValue: "1")

    // MARK: test cases for `isValid(input:)`

    func test_empty_input_is_valid() {
        let input = ""
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func test_alphanumeric_input_is_not_valid() {
        let input = "06two"
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_decimal_input_is_not_valid() {
        let input = "9990.52"
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_input_with_trailing_point_is_not_valid() {
        let input = "9990."
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_integer_input_is_valid() {
        let input = "888888"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func test_negative_input_is_valid() {
        let input = "-888888"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func test_only_minus_sign_input_is_valid() {
        let input = "-"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    // MARK: test cases for `format(input:)`

    func test_format_with_empty_input_returns_default_value() {
        let input = ""
        XCTAssertEqual(formatter.format(input: input), "1")
    }

    func test_format_with_leading_zeroes_input_returns_input_without_leading_zeroes() {
        let input = "0012391"
        XCTAssertEqual(formatter.format(input: input), "12391")
    }

    func test_format_with_integer_input_returns_same_input() {
        let input = "314200"
        XCTAssertEqual(formatter.format(input: input), "314200")
    }

    func test_format_with_negative_integer_input_returns_same_input() {
        let input = "-3412424214"
        XCTAssertEqual(formatter.format(input: input), "-3412424214")
    }

    func test_format_with_single_minus_sign_input_returns_same_input() {
        let input = "-"
        XCTAssertEqual(formatter.format(input: input), input)
    }

    func test_format_with_multiple_minus_sign_input_returns_default_value() {
        let input = "--"
        XCTAssertEqual(formatter.format(input: input), "-1")
    }
}
