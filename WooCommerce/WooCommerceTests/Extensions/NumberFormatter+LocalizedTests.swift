import XCTest
@testable import WooCommerce

class NumberFormatter_LocalizedTests: XCTestCase {

    func test_double_from_string_returns_correctly_depending_on_locale() {
        // Given
        let usLocale = Locale(identifier: "en_US")
        let itLocale = Locale(identifier: "it_IT")

        // When
        let valueWithPeriod = "1.2"

        // Then
        XCTAssertEqual(NumberFormatter.double(from: valueWithPeriod, locale: usLocale), Double(1.2))
        XCTAssertNil(NumberFormatter.double(from: valueWithPeriod, locale: itLocale))

        // When
        let valueWithComma = "1,2"

        // Then
        XCTAssertNil(NumberFormatter.double(from: valueWithComma, locale: usLocale))
        XCTAssertEqual(NumberFormatter.double(from: valueWithComma, locale: itLocale), Double(1.2))

        // When
        let valueWithThousandSeparator = "1,000"

        // Then
        XCTAssertEqual(NumberFormatter.double(from: valueWithThousandSeparator, locale: usLocale), Double(1000))
        XCTAssertEqual(NumberFormatter.double(from: valueWithThousandSeparator, locale: itLocale), Double(1))
    }

    func test_string_from_number_returns_correctly_depending_on_locale() {
        // Given
        let usLocale = Locale(identifier: "en_US")
        let itLocale = Locale(identifier: "it_IT")
        let value: Double = 1.2
        let number = NSNumber(value: value)

        // Then
        XCTAssertEqual(NumberFormatter.localizedString(from: number, locale: usLocale), "1.2")
        XCTAssertEqual(NumberFormatter.localizedString(from: number, locale: itLocale), "1,2")
    }

    func test_localizedString_using_method_returns_correctly_based_on_from_and_to_locales() {
        // Given
        let usLocale = Locale(identifier: "en_US")
        let itLocale = Locale(identifier: "it_IT")

        // When
        let valueWithPeriod = "1.2"

        // Then

        // Valid output when converting to a different locale
        XCTAssertEqual(NumberFormatter.localizedString(using: valueWithPeriod,
                                                       from: usLocale,
                                                       to: itLocale),
                       "1,2")

        // Nil output when providing invalid `from` locale
        XCTAssertNil(NumberFormatter.localizedString(using: valueWithPeriod,
                                                       from: itLocale,
                                                       to: usLocale))

        // Same output as input when providing same locale values from `from` and `to` params
        XCTAssertEqual(NumberFormatter.localizedString(using: valueWithPeriod,
                                                       from: usLocale,
                                                       to: usLocale),
                       "1.2")

        // When
        let valueWithComma = "1,2"

        // Then

        // Valid output when converting to a different locale
        XCTAssertEqual(NumberFormatter.localizedString(using: valueWithComma,
                                                       from: itLocale,
                                                       to: usLocale),
                       "1.2")

        // Nil output when providing invalid `from` locale
        XCTAssertNil(NumberFormatter.localizedString(using: valueWithComma,
                                                       from: usLocale,
                                                       to: itLocale))

        // Same output as input when providing same locale values from `from` and `to` params
        XCTAssertEqual(NumberFormatter.localizedString(using: valueWithComma,
                                                       from: itLocale,
                                                       to: itLocale),
                       "1,2")

        // When
        let valueWithThousandSeparator = "1,000"

        // Then
        XCTAssertEqual(NumberFormatter.localizedString(using: valueWithThousandSeparator,
                                                       from: itLocale,
                                                       to: usLocale),
                       "1")
        XCTAssertNil(NumberFormatter.localizedString(using: valueWithThousandSeparator,
                                                       from: usLocale,
                                                       to: itLocale))
    }
}
