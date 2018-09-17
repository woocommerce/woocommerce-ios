import XCTest
@testable import WooCommerce

class MoneyFormatterTests: XCTestCase {

    /// Testing zero value string
    ///
    private let zeroString = "0.00"

    /// Testing zero value decimal
    ///
    private let zeroDecimal = Decimal(0.00)

    /// Testing non-zero value string
    ///
    private let nonZeroString = "618.72"

    /// Testing non-zero value decimal
    ///
    private let nonZeroDecimal = Decimal(string: "618.72")

    /// Testing currency code in US Dollars
    ///
    private let currencyCodeUSD = "USD"

    /// Testing currency code in Euros
    ///
    private let currencyCodeEUR = "EUR"

    /// Testing currency code in Yen
    ///
    private let currencyCodeJPY = "JPY"

    /// Testing US locale
    ///
    private let usLocale = Locale(identifier: "en_US")

    /// Testing French-Canadian locale
    ///
    private let frLocale = Locale(identifier: "fr_FR")

    /// Test zero string values yield properly formatted dollar strings
    ///
    func testStringValueReturnsFormattedZeroDollarForUSLocale() {
        let formattedString = MoneyFormatter().format(value: zeroString,
                                                      currencyCode: currencyCodeUSD,
                                                      locale: usLocale)
        XCTAssertEqual(formattedString, "$0.00")
    }

    /// Test zero decimal values yield properly formatted dollar strings
    ///
    func testDecimalValueReturnsFormattedZeroDollarForUSLocale() {
        let formattedDecimal = MoneyFormatter().format(value: zeroDecimal,
                                                       currencyCode: currencyCodeUSD,
                                                       locale: usLocale)
        XCTAssertEqual(formattedDecimal, "$0.00")
    }

    /// Test non-zero string values yield properly formatted dollar strings
    ///
    func testStringValueReturnsFormattedNonZeroDollar() {
        let formattedString = MoneyFormatter().format(value: nonZeroString,
                                                      currencyCode: currencyCodeUSD,
                                                      locale: usLocale)
        XCTAssertEqual(formattedString, "$618.72")
    }

    /// Test non-zero decimal values yield properly formatted dollar strings
    ///
    func testDecimalValueReturnsFormattedNonZeroDollar() {
        guard let decimalValue = nonZeroDecimal else {
            XCTFail()
            return
        }
        let formattedDecimal = MoneyFormatter().format(value: decimalValue,
                                                       currencyCode: currencyCodeUSD,
                                                       locale: usLocale)
        XCTAssertEqual(formattedDecimal, "$618.72")
    }

    /// Test non-zero string values yield properly formatted euro strings
    ///
    func testStringValueReturnsFormattedNonZeroEuro() {
        let formattedString = MoneyFormatter().format(value: nonZeroString,
                                                      currencyCode: currencyCodeEUR,
                                                      locale: usLocale)
        XCTAssertEqual(formattedString, "€618.72")
    }

    /// Test non-zero string values yield properly formatted euro strings
    ///
    func testStringValueReturnsFormattedNonZeroEuroForFRLocale() {
        let formattedString = MoneyFormatter().format(value: nonZeroString,
                                                      currencyCode: currencyCodeEUR,
                                                      locale: frLocale)
        XCTAssertEqual(formattedString, "618,72 €")
    }

    /// Test non-zero decimal values yield properly formatted yen strings
    ///
    func testDecimalValueReturnsFormattedNonZeroYenForFRLocale() {
        guard let decimalValue = nonZeroDecimal else {
            XCTFail()
            return
        }
        let formattedString = MoneyFormatter().format(value: decimalValue,
                                                      currencyCode: currencyCodeEUR,
                                                      locale: frLocale)
        XCTAssertEqual(formattedString, "618,72 €")
    }

    /// Test zero decimal values return nil
    ///
    func testNilReturnsForZeroDecimalValueInFormatIfNonZero() {
        let formattedValue = MoneyFormatter().formatIfNonZero(value: zeroDecimal,
                                                              currencyCode: currencyCodeUSD,
                                                              locale: usLocale)
        XCTAssertNil(formattedValue)
    }

    /// Test empty string returns nil
    ///
    func testNilReturnsForEmptyStringValueInFormatIfNonZero() {
        let formattedValue = MoneyFormatter().formatIfNonZero(value: zeroString,
                                                              currencyCode: currencyCodeUSD,
                                                              locale: usLocale)
        XCTAssertNil(formattedValue)
    }

    // MARK: - test currency formatting returns expected strings
    func testStringValueIsNonZeroAndReturnsFormattedNonZeroEuroForFRLocale() {
        let formattedString = MoneyFormatter().formatIfNonZero(value: nonZeroString,
                                                               currencyCode: currencyCodeEUR,
                                                               locale: frLocale)
        XCTAssertEqual(formattedString, "618,72 €")
    }

    func testDecimalValueIsNonZeroAndReturnsFormattedNonZeroYenForFRLocale() {
        guard let decimalValue = nonZeroDecimal else {
            XCTFail()
            return
        }
        let formattedDecimal = MoneyFormatter().formatIfNonZero(value: decimalValue,
                                                                currencyCode: currencyCodeJPY,
                                                                locale: frLocale)
        XCTAssertEqual(formattedDecimal, "618.72 ¥")
    }
}
