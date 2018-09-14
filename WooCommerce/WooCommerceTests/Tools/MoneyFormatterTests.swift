import XCTest
@testable import WooCommerce

class MoneyFormatterTests: XCTestCase {

    /// Test zero string values yield properly formatted dollar strings
    ///
    func testStringValueReturnsFormattedZeroDollarTotalForUSLocale() {
        let formatter = currencyFormatter(currencyCode: "USD")
        
    }

    /// Test zero decimal values yield properly formatted dollar strings
    ///
    func testDecimalValueReturnsFormattedZeroDollarTotalForUSLocale() {

    }

    /// Test non-zero string values yield properly formatted euro strings
    ///
    func testStringValueReturnsFormattedNonZeroEuroTotalForFRLocale() {

    }

    /// Test non-zero decimal values yield properly formatted yen strings
    ///
    func testDecimalValueReturnsFormattedNonZeroYenTotalForFRLocale() {

    }

    /// Test zero decimal values return nil
    ///
    func testNilReturnsForZeroValueInFormatIfNonZero() {

    }

    /// Test empty string returns nil
    ///
    func testNilReturnsForEmptyStringValueInFormatIfNonZero() {

    }

    // MARK: - test currency formatting returns expected strings
    func testFormatStringValueIsNonZeroAndReturnsString() {

    }

    func testFormatDecimalValueIsNonZeroAndReturnsString() {

    }
    
    override func setUp() {
        super.setUp()

        // things go here :)
    }
}
