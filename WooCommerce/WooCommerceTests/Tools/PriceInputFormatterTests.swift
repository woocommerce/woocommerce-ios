import XCTest

@testable import WooCommerce

final class PriceInputFormatterTests: XCTestCase {
    private let formatter = PriceInputFormatter()

    // MARK: test cases for `isValid(input:)`

    func testEmptyInputIsValid() {
        let input = ""
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func testAlphanumericInputIsNotValid() {
        let input = "06two"
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func testDecimalInputWithPointIsValid() {
        let input = "9990.52"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func testDecimalInputWithCommaIsValid() {
        let input = "9990,52"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func testTrailingPointInputIsValid() {
        let input = "9990."
        XCTAssertTrue(formatter.isValid(input: input))
    }

    func testLeadingPointInputIsInvalid() {
        let input = "."
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func testLeadingCommaInputIsInvalid() {
        let input = ","
        XCTAssertFalse(formatter.isValid(input: input))
    }

    func testBigPriceInputWithThousandSeparators() {
        let input = "189,293,891,203.20"
        XCTAssertTrue(formatter.isValid(input: input))
    }

    // MARK: test cases for `format(input:)`

    func testFormattingEmptyInput() {
        let input = ""
        XCTAssertEqual(formatter.format(input: input), "")
    }

    func testFormattingZeroInput() {
        let input = "0"
        XCTAssertEqual(formatter.format(input: input), "0")
    }

    func testFormattingInputWithLeadingZeros() {
        let currencySettings = CurrencySettings(currencyCode: .USD, currencyPosition: .leftSpace, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 3)
        let formatter = PriceInputFormatter(currencySettings: currencySettings)

        let input = "00123.91"
        XCTAssertEqual(formatter.format(input: input), "123.91")
    }

    func testFormattingDecimalInputWithPoint() {
        let currencySettings = CurrencySettings(currencyCode: .USD, currencyPosition: .leftSpace, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 3)
        let formatter = PriceInputFormatter(currencySettings: currencySettings)

        let input = "0.314"
        XCTAssertEqual(formatter.format(input: input), "0.314")
    }

    func testFormattingDecimalInputWithComma() {
        let currencySettings = CurrencySettings(currencyCode: .USD, currencyPosition: .leftSpace, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 3)
        let formatter = PriceInputFormatter(currencySettings: currencySettings)

        let input = "0,314"
        XCTAssertEqual(formatter.format(input: input), "0.314")
    }

    func testFormattingIntegerInput() {
        let input = "314200"
        XCTAssertEqual(formatter.format(input: input), "314200")
    }

    func testFormattingBigPriceInput() {
        let currencySettings = CurrencySettings(currencyCode: .USD, currencyPosition: .leftSpace, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 3)
        let formatter = PriceInputFormatter(currencySettings: currencySettings)

        let input = "189293891203.20"
        XCTAssertEqual(formatter.format(input: input), "189293891203.20")
    }

    func testFormattingBigPriceInputWithThousandSeparators() {
        let currencySettings = CurrencySettings(currencyCode: .USD, currencyPosition: .leftSpace, thousandSeparator: ",", decimalSeparator: ".", numberOfDecimals: 3)
        let formatter = PriceInputFormatter(currencySettings: currencySettings)

        let input = "189,293,891,203.20"
        XCTAssertEqual(formatter.format(input: input), "189293891203.20")
    }
}
