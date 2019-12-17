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

    func testDecimalInputIsValid() {
        let input = "9990,52"
        XCTAssertTrue(formatter.isValid(input: input))
    }
    
    func testPriceInputIsValid() {
        let input = "9990.52"
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

    // MARK: test cases for `format(input:)`

    func testFormattingEmptyInput() {
        let input = ""
        XCTAssertEqual(formatter.format(input: input), "0.00")
    }

    func testFormattingInputWithLeadingZeros() {
        let input = "00123.91"
        XCTAssertEqual(formatter.format(input: input), "123.91")
    }

    func testFormattingDecimalInput() {
        let input = "0.314"
        XCTAssertEqual(formatter.format(input: input), "0.314")
    }

    func testFormattingIntegerInput() {
        let input = "314200"
        XCTAssertEqual(formatter.format(input: input), "314200")
    }
}
