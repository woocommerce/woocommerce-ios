import XCTest
import WooFoundation
@testable import WooCommerce

final class CouponAmountInputFormatterTests: XCTestCase {
    private var formatter = CouponAmountInputFormatter()

    // MARK: test cases for `isValid(input:)`

    func test_empty_input_is_not_valid() {
        let input = ""
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_alphanumeric_input_is_not_valid() {
        let input = "06two"
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_decimal_input_with_point_is_valid() {
        let input = "9990.52"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func test_decimal_input_with_comma_is_valid() {
        let input = "9990,52"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func test_trailing_point_input_is_valid() {
        let input = "9990."
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func test_leading_point_input_is_invalid() {
        let input = "."
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_leading_comma_input_is_invalid() {
        let input = ","
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func test_big_price_input_with_thousand_separators() {
        let input = "189,293,891,203.20"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    // MARK: test cases for `format(input:)`

    func test_formatting_empty_input() {
        let input = ""
        XCTAssertEqual(formatter.format(input: input), "0")
    }

    func test_formatting_zero_input() {
        let input = "0"
        XCTAssertEqual(formatter.format(input: input), "0")
    }

    func test_formatting_input_with_leading_zeros() {
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let formatter = CouponAmountInputFormatter(currencySettings: currencySettings)

        let input = "00123.91"
        XCTAssertEqual(formatter.format(input: input), "123.91")
    }

    func test_formatting_decimal_input_with_point() {
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let formatter = CouponAmountInputFormatter(currencySettings: currencySettings)

        let input = "0.314"
        XCTAssertEqual(formatter.format(input: input), "0.314")
    }

    func test_formatting_decimal_input_with_comma() {
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let formatter = CouponAmountInputFormatter(currencySettings: currencySettings)

        let input = "0,314"
        XCTAssertEqual(formatter.format(input: input), "0.314")
    }

    func test_formatting_integer_input() {
        let input = "314200"
        XCTAssertEqual(formatter.format(input: input), "314200")
    }

    func test_formatting_big_price_input() {
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let formatter = CouponAmountInputFormatter(currencySettings: currencySettings)

        let input = "189293891203.20"
        XCTAssertEqual(formatter.format(input: input), "189293891203.20")
    }

    func test_formatting_big_price_input_with_thousand_separators() {
        let currencySettings = CurrencySettings(currencyCode: .USD,
                                                currencyPosition: .leftSpace,
                                                thousandSeparator: "",
                                                decimalSeparator: ".",
                                                numberOfDecimals: 3)
        let formatter = CouponAmountInputFormatter(currencySettings: currencySettings)

        let input = "189,293,891,203.20"
        XCTAssertEqual(formatter.format(input: input), "189293891203.20")
    }

    func test_value_is_correct() {
        // When
        let pointValue = "0.00"

        // Then
        XCTAssertEqual(formatter.value(from: pointValue), NSNumber(value: 0))

        // When
        let commaValue = "0,00"

        // Then
        XCTAssertEqual(formatter.value(from: commaValue), NSNumber(value: 0))

        // When
        let noSeparatorValue = "000"

        // Then
        XCTAssertEqual(formatter.value(from: noSeparatorValue), NSNumber(value: 0))

        // When
        let emptyValue = ""

        // Then
        XCTAssertEqual(formatter.value(from: emptyValue), NSNumber(value: 0))
    }

    func test_percentage_input_higher_than_100_is_formatted_back_to_100() {
        formatter = CouponAmountInputFormatter(isPercentage: true)
        var input = "100.0000000000001"
        XCTAssertEqual(formatter.format(input: input), "100")

        input = "101"
        XCTAssertEqual(formatter.format(input: input), "100")
    }

    func test_non_percentage_input_higher_than_100_is_NOT_formatted_back_to_100() {
        formatter = CouponAmountInputFormatter(isPercentage: false)
        var input = "100.0000000000001"
        XCTAssertEqual(formatter.format(input: input), "100.0000000000001")

        input = "101"
        XCTAssertEqual(formatter.format(input: input), "101")
    }

    func test_percentage_input_lower_or_equal_than_100_is_NOT_formatted_to_100() {
        formatter = CouponAmountInputFormatter(isPercentage: true)
        var input = "0"
        XCTAssertEqual(formatter.format(input: input), "0")

        input = "99.9999999999999"
        XCTAssertEqual(formatter.format(input: input), "99.9999999999999")
    }
}
