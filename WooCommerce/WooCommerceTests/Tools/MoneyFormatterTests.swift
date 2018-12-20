import XCTest
@testable import WooCommerce

/// Money Formatter Tests
///
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

    /// Testing large value string
    ///
    private let negativeLargeValueString = "-32758.90"

    /// Testing large value decimal
    ///
    private let largeValueDecimal = Decimal(string: "237256980.31")

    /// Test bad data string
    ///
    private let badDataString = "ack"

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
    private let frLocale = Locale(identifier: "fr_CA")

    // MARK: - Test zero amounts return as formatted strings


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

    // MARK: - Test non-zero amounts return as formatted strings


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

        // Fun fact: the currency formatter grouping separator is a unicode non-breaking space character.
        // https://stackoverflow.com/a/39954700/4150507
        XCTAssertEqual(formattedString, "618,72\u{00a0}€")
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

        XCTAssertEqual(formattedString, "618,72\u{00a0}€")
    }

    /// Test large number value as string yields properly formatted dollar string
    ///
    func testLargeStringValueReturnsFormattedNonZeroDollar() {
        let formattedString = MoneyFormatter().format(value: negativeLargeValueString,
                                                      currencyCode: currencyCodeUSD,
                                                      locale: usLocale)

        XCTAssertEqual(formattedString, "-$32,758.90")
    }

    /// Test large number value as string yields properly formatted euro string
    ///
    func testLargeStringValueReturnsFormattedNonZeroEuroForUSLocale() {
        let formattedString = MoneyFormatter().format(value: negativeLargeValueString,
                                                      currencyCode: currencyCodeEUR,
                                                      locale: usLocale)

        XCTAssertEqual(formattedString, "-€32,758.90")
    }

    /// Test large number as string yields properly formatted euro string
    ///
    func testLargeStringValueReturnsFormattedNonZeroEuroForFRLocale() {
        let formattedString = MoneyFormatter().format(value: negativeLargeValueString,
                                                      currencyCode: currencyCodeEUR,
                                                      locale: frLocale)

        XCTAssertEqual(formattedString, "-32\u{00a0}758,90\u{00a0}€")
    }

    /// Test large number as string yields properly formatted yen string
    ///
    func testLargeStringValueReturnsFormattedNonZeroYenForFRLocale() {
        let formattedString = MoneyFormatter().format(value: negativeLargeValueString,
                                                      currencyCode: currencyCodeJPY,
                                                      locale: frLocale)

        XCTAssertEqual(formattedString, "-32\u{00a0}759\u{00a0}¥")
    }

    /// Test large number as decimal yields properly formatted dollar string
    ///
    func testLargeDecimalValueReturnsFormattedNonZeroDollarForUSLocale() {
        guard let decimalValue = largeValueDecimal else {
            XCTFail()
            return
        }

        let formattedString = MoneyFormatter().format(value: decimalValue,
                                                      currencyCode: currencyCodeUSD,
                                                      locale: usLocale)

        XCTAssertEqual(formattedString, "$237,256,980.31")
    }

    /// Test large number as decimal yields properly formatted euro string
    ///
    func testLargeDecimalValueReturnsFormattedNonZeroEuroForFRLocale() {
        guard let decimalValue = largeValueDecimal else {
            XCTFail()
            return
        }

        let formattedString = MoneyFormatter().format(value: decimalValue,
                                                      currencyCode: currencyCodeEUR,
                                                      locale: frLocale)

        XCTAssertEqual(formattedString, "237\u{00a0}256\u{00a0}980,31\u{00a0}€")
    }

    /// Test large number as decimal yields properly formatted yen string
    ///
    func testLargeDecimalValueReturnsFormattedNonZeroYenForFRLocale() {
        guard let decimalValue = largeValueDecimal else {
            XCTFail()
            return
        }

        let formattedString = MoneyFormatter().format(value: decimalValue,
                                                      currencyCode: currencyCodeJPY,
                                                      locale: frLocale)

        XCTAssertEqual(formattedString, "237\u{00a0}256\u{00a0}980\u{00a0}¥")
    }

    // MARK: - Test bad data string received returns empty string

    /// Test bad data string returns nil
    ///
    func testBadDataStringValueReturnsEmptyString() {
        let formattedString = MoneyFormatter().format(value: badDataString,
                                                      currencyCode: currencyCodeUSD,
                                                      locale: usLocale)

        XCTAssertNil(formattedString)
    }

    // MARK: - Test IfNonZero methods

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

    ///  Test currency formatting returns expected strings
    ///
    func testStringValueIsNonZeroAndReturnsFormattedNonZeroEuroForFRLocale() {
        let formattedString = MoneyFormatter().formatIfNonZero(value: nonZeroString,
                                                               currencyCode: currencyCodeEUR,
                                                               locale: frLocale)

        XCTAssertEqual(formattedString, "618,72\u{00a0}€")
    }

    func testDecimalValueIsNonZeroAndReturnsFormattedNonZeroYenForFRLocale() {
        guard let decimalValue = nonZeroDecimal else {
            XCTFail()
            return
        }

        let formattedDecimal = MoneyFormatter().formatIfNonZero(value: decimalValue,
                                                                currencyCode: currencyCodeJPY,
                                                                locale: frLocale)

        // Fun fact: A Japanese Yen is the lowest value possible in Japanese currency.
        // Therefore, there are no decimal values for this currency.
        XCTAssertEqual(formattedDecimal, "619\u{00a0}¥")
    }
}


// MARK: - Decimal Unit Testing
extension MoneyFormatterTests {

    /// Verifies that the string value returns an accurate decimal value
    ///
    func testStringReturnsDecimal() {
        let stringValue = "9.99"
        let expectedResult = NSDecimalNumber(string: stringValue)

        let converted = MoneyFormatter().convertToDecimal(from: stringValue)

        // check the formatted decimal exists
        guard let actualResult = converted else {
            XCTFail()
            return
        }

        // check the decimal type
        XCTAssertTrue(actualResult.isKind(of: NSDecimalNumber.self))

        // check the decimal value
        XCTAssertEqual(expectedResult, actualResult)
    }


    /// This is where a float-to-decimal unit test would go.
    /// It's not here because we don't allow using floats for currency.
    /// Be Responsible. Friends don't let friends use `float` or `double` for currency.


    /// Verifies that the formatted decimal value is NOT rounded
    ///
    func testStringValueIsNotRoundedDecimal() {
        let stringValue = "9.9999"
        let expectedResult = NSDecimalNumber(string: stringValue)

        let actualResult = MoneyFormatter().convertToDecimal(from: stringValue)
        XCTAssertEqual(expectedResult, actualResult)
    }

    /// Verifies that the decimal separator is localized
    ///
    func testDecimalSeparatorIsLocalized() {
        let separator = ","
        let stringValue = "1.17"
        let expectedResult = "1,17"
        let converted = MoneyFormatter().convertToDecimal(from: stringValue)

        guard let convertedDecimal = converted else {
            XCTFail()
            return
        }

        let actualResult = MoneyFormatter().localizeAmount(decimal: convertedDecimal, decimalSeparator: separator)

        XCTAssertEqual(expectedResult, actualResult)
    }

    /// Verifies that bad data doesn't get converted into a decimal
    ///
    func testBadDataInStringDoesNotConvertToDecimal() {
        let badInput = "~HUKh*(&Y3HkJ8"
        let actualResult = MoneyFormatter().convertToDecimal(from: badInput)

        XCTAssertNil(actualResult)
    }

    /// Verifies that negative numbers are successfully converted into a decimal
    ///
    func testNegativeNumbersSuccessfullyConvertToDecimal() {
        let negativeNumber = "-81346.45"
        let expectedResult = NSDecimalNumber(string: negativeNumber)
        let actualResult = MoneyFormatter().convertToDecimal(from: negativeNumber)

        XCTAssertEqual(expectedResult, actualResult)
    }
}


// MARK: - Thousand Separator Unit Testing
extension MoneyFormatterTests {
    /// Verifies that the thousand separator is localized to a comma
    ///
    func testThousandSeparatorIsLocalizedToComma() {
        let comma = ","
        let stringValue = "1204.67"
        let expectedResult = "1,204.67"

        let convertedDecimal = MoneyFormatter().convertToDecimal(from: stringValue)

        guard let decimal = convertedDecimal else {
            XCTFail()
            return
        }

        let formattedString = MoneyFormatter().localizeAmount(decimal: decimal, thousandSeparator: comma)
        guard let actualResult = formattedString else {
            XCTFail()
            return
        }

        XCTAssertEqual(expectedResult, actualResult)
    }

    /// Verifies that the result string is accurate when a blank string is entered for the thousand separator
    ///
    func testThousandSeparatorIsLocalizedToBlankString() {
        let decimalSeparator = "."
        let thousandSeparator = ""
        let stringValue = "1204.67"
        let expectedResult = "1204.67"

        let convertedDecimal = MoneyFormatter().convertToDecimal(from: stringValue)
        guard let decimal = convertedDecimal else {
            XCTFail()
            return
        }

        let localizedAmount = MoneyFormatter().localizeAmount(decimal: decimal,
                                                              decimalSeparator: decimalSeparator,
                                                              thousandSeparator: thousandSeparator)

        guard let actualResult = localizedAmount else {
            XCTFail()
            return
        }

        XCTAssertEqual(expectedResult, actualResult)
    }

    /// Verifies that the decimal separator is properly applied after thousands separator
    ///
    func testCommaDecimalSeparatorAfterCommaThousandSeparatorWasApplied() {
        let separator = ","
        let stringValue = "45958320.97"
        let expectedResult = "45,958,320,97"

        let converted = MoneyFormatter().convertToDecimal(from: stringValue)
        guard let convertedDecimal = converted else {
            XCTFail()
            return
        }

        let localizedAmount = MoneyFormatter().localizeAmount(decimal: convertedDecimal, decimalSeparator: separator, decimalPosition: 2, thousandSeparator: separator)
        guard let actualResult = localizedAmount else {
            XCTFail()
            return
        }

        XCTAssertEqual(expectedResult, actualResult)
    }

    /// Verifies decimal places are correct after localize methods have been applied
    ///
    func testDecimalPlacesAfterLocalizeThousandAndLocalizeDecimalFormattingWasApplied() {
        let decimalPosition = 3
        let separator = ","
        let stringValue = "45958320.97"
        let expectedResult = "45,958,320,970"

        let converted = MoneyFormatter().convertToDecimal(from: stringValue)
        guard let convertedDecimal = converted else {
            XCTFail()
            return
        }

        let formattedAmount = MoneyFormatter().localizeAmount(decimal: convertedDecimal,
                                                              decimalSeparator: separator,
                                                              decimalPosition: decimalPosition,
                                                              thousandSeparator: separator)

        guard let actualResult = formattedAmount else {
            XCTFail()
            return
        }

        XCTAssertEqual(expectedResult, actualResult)
    }
}


// MARK: - Currency Formatting Unit Tests
extension MoneyFormatter {
    /// Verifies that user's full currency preferences are applied
    ///
    func testCompleteCurrencyFormattingRespectsUserRules() {
        let decimalSeparator = ","
        let thousandSeparator = "."
        let decimalPosition = 3
        let currencyPosition = Currency.Position.rightSpace
        let currencyCode = Currency.Code.JOD
        let stringAmount = "-7867818684.64"
        let expectedResult = "-7.867.818.684,640 د.ا"

        let decimalAmount = MoneyFormatter().convertToDecimal(from: stringAmount)
        guard let decimal = decimalAmount else {
            DDLogError("Error: invalid string amount. Cannot convert to decimal.")
            XCTFail()
            return
        }

        let amount = MoneyFormatter().localizeAmount(decimal: decimal,
                                                             decimalSeparator: decimalSeparator,
                                                             decimalPosition: decimalPosition,
                                                             thousandSeparator: thousandSeparator)

        guard let localizedAmount = amount else {
            XCTFail()
            return
        }

        let formattedAmount = MoneyFormatter().formatCurrency(using: localizedAmount,
                                                              at: currencyPosition,
                                                              with: currencyCode)

        guard let actualResult = formattedAmount else {
            XCTFail()
            return
        }

        XCTAssertEqual(expectedResult, actualResult)
    }
}
