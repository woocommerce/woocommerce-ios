import XCTest
@testable import WooCommerce


/// NSDecimalNumber+Helpers: Unit Tests
///
class NSDecimalNumberWooTests: XCTestCase {

    // MARK: - Zero tests

    func testZeroCheck() {
        XCTAssertTrue(NSDecimalNumber.zero.isZero())
        XCTAssertTrue(NSDecimalNumber(booleanLiteral: false).isZero())
        XCTAssertTrue(NSDecimalNumber(integerLiteral: 0).isZero())
        XCTAssertTrue(NSDecimalNumber(floatLiteral: 0.0).isZero())
        XCTAssertTrue(NSDecimalNumber(string: "0").isZero())

        XCTAssertFalse(NSDecimalNumber(booleanLiteral: true).isZero())
        XCTAssertFalse(NSDecimalNumber(integerLiteral: -11).isZero())
        XCTAssertFalse(NSDecimalNumber(integerLiteral: 11234234).isZero())
        XCTAssertFalse(NSDecimalNumber(floatLiteral: 0.0000000001).isZero())
        XCTAssertFalse(NSDecimalNumber(floatLiteral: 11.123).isZero())
        XCTAssertFalse(NSDecimalNumber(floatLiteral: -0.0000000001).isZero())
        XCTAssertFalse(NSDecimalNumber(floatLiteral: -11.123).isZero())
        XCTAssertFalse(NSDecimalNumber(string: "0.00000000001").isZero())
        XCTAssertFalse(NSDecimalNumber(string: "-0.00000000001").isZero())
        XCTAssertFalse(NSDecimalNumber(string: "-298374892374970").isZero())
        XCTAssertFalse(NSDecimalNumber(string: "298374892374970").isZero())
    }


    // MARK: - Human readable string tests (with rounding)

    func testRoundedHumanReadableStringWorksWithZeroValue() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 0).humanReadableString(), "0")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -0).humanReadableString(), "0")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 0.01).humanReadableString(), "0")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -0.01).humanReadableString(), "0")
    }

    func testRoundedHumanReadableStringWorksWithPositiveValuesUnderOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1).humanReadableString(), "1")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 10).humanReadableString(), "10")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 198).humanReadableString(), "198")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 198.44).humanReadableString(), "198")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 199).humanReadableString(), "199")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 199.99).humanReadableString(), "199")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999).humanReadableString(), "999")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999.99).humanReadableString(), "999")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999.99999).humanReadableString(), "999")

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000).humanReadableString(), "1.0k") // "1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(), "1.0k") // "1.0k"
    }

    func testRoundedHumanReadableStringWorksWithNegativeValuesUnderOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1).humanReadableString(), "-1")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -10).humanReadableString(), "-10")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -198.44).humanReadableString(), "-198")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -199).humanReadableString(), "-199")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -199.99).humanReadableString(), "-199")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999).humanReadableString(), "-999")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999.99).humanReadableString(), "-999")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999.99999).humanReadableString(), "-999")

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000).humanReadableString(), "-1.0k") // "-1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(), "-1.0k") // "-1.0k"
    }

    func testRoundedHumanReadableStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000).humanReadableString(), "1.0k") // "1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(), "1.0k") // "1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999).humanReadableString(), "1.0m") // "1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000).humanReadableString(), "1.0m") // "1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000.00001).humanReadableString(), "1.0m") // "1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000.00001).humanReadableString(), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(), "1.0t") // "1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000_000).humanReadableString(), "1.0t") // "1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000_000.00001).humanReadableString(), "1.0t") // "1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_000_000_000_000.00001).humanReadableString(), "999.0t") // "999.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9_000_000_000_000_000.00001).humanReadableString(), "9000.0t") // "9000.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9880).humanReadableString(), "9.9k") // "9.9k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9999).humanReadableString(), "10.0k") // "10.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 44_999).humanReadableString(), "45.0k") // "45.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 77_164).humanReadableString(), "77.2k") // "77.2k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 100_101).humanReadableString(), "100.1k") // "100.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 110_099).humanReadableString(), "110.1k") // "110.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9_899_999).humanReadableString(), "9.9m") // "9.9m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 5_800_199).humanReadableString(), "5.8m") // "5.8m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 998_999_999).humanReadableString(), "999.0m") // "999.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999.9999).humanReadableString(), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 99_899_999_999).humanReadableString(), "99.9b") // "99.9b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(), "1.0t") // "1.0t"
    }

    func testRoundedHumanReadableStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000).humanReadableString(), "-1.0k") // "-1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(), "-1.0k") // "-1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999).humanReadableString(), "-1.0m") // "-1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000).humanReadableString(), "-1.0m") // "-1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000.00001).humanReadableString(), "-1.0m") // "-1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000.00001).humanReadableString(), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000_000).humanReadableString(), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000_000.00001).humanReadableString(), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_880).humanReadableString(), "-9.9k") // "-9.9k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_999).humanReadableString(), "-10.0k") // "-10.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -44_999).humanReadableString(), "-45.0k") // "-45.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -77_164).humanReadableString(), "-77.2k") // "-77.2k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -100_101).humanReadableString(), "-100.1k") // "-100.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -110_099).humanReadableString(), "-110.1k") // "-110.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_899_999).humanReadableString(), "-9.9m") // "-9.9m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -5_800_199).humanReadableString(), "-5.8m") // "-5.8m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -998_999_999).humanReadableString(), "-999.0m") // "-999.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(), "-1.0b")// "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -99_899_999_999).humanReadableString(), "-99.9b") // "-99.9b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_000_000_000_000.00001).humanReadableString(), "-999.0t") // "-999.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_000_000_000_000_000.00001).humanReadableString(), "-9000.0t") // "-9000.0t"
    }


    // MARK: - Human readable string tests (without rounding)

    func testHumanReadableStringWorksWithZeroValue() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 0).humanReadableString(roundSmallNumbers: false), "0")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -0).humanReadableString(roundSmallNumbers: false), "0")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 0.01).humanReadableString(roundSmallNumbers: false), "0.01")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -0.01).humanReadableString(roundSmallNumbers: false), "-0.01")
    }

    func testHumanReadableStringWorksWithPositiveValuesUnderOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1).humanReadableString(roundSmallNumbers: false), "1")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 10).humanReadableString(roundSmallNumbers: false), "10")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 198).humanReadableString(roundSmallNumbers: false), "198")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 198.44).humanReadableString(roundSmallNumbers: false), "198.44")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 199).humanReadableString(roundSmallNumbers: false), "199")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 199.99).humanReadableString(roundSmallNumbers: false), "199.99")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999).humanReadableString(roundSmallNumbers: false), "999")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999.99).humanReadableString(roundSmallNumbers: false), "999.99")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999.99999).humanReadableString(roundSmallNumbers: false), "999.99999")

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000).humanReadableString(roundSmallNumbers: false), "1.0k") // "1.0k"
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(roundSmallNumbers: false), "1.0k") // "1.0k"
    }

    func testHumanReadableStringWorksWithNegativeValuesUnderOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1).humanReadableString(roundSmallNumbers: false), "-1")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -10).humanReadableString(roundSmallNumbers: false), "-10")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -198.44).humanReadableString(roundSmallNumbers: false), "-198.44")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -199).humanReadableString(roundSmallNumbers: false), "-199")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -199.99).humanReadableString(roundSmallNumbers: false), "-199.99")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999).humanReadableString(roundSmallNumbers: false), "-999")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999.99).humanReadableString(roundSmallNumbers: false), "-999.99")
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999.99999).humanReadableString(roundSmallNumbers: false), "-999.99999")

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000).humanReadableString(roundSmallNumbers: false), "-1.0k") // "-1.0k"
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(roundSmallNumbers: false), "-1.0k") // "-1.0k"
    }

    func testHumanReadableStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000).humanReadableString(roundSmallNumbers: false), "1.0k") // "1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(roundSmallNumbers: false), "1.0k") // "1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999).humanReadableString(roundSmallNumbers: false), "1.0m") // "1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000).humanReadableString(roundSmallNumbers: false), "1.0m") // "1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000.00001).humanReadableString(roundSmallNumbers: false), "1.0m") // "1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(roundSmallNumbers: false), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(roundSmallNumbers: false), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(roundSmallNumbers: false), "1.0t") // "1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000_000).humanReadableString(roundSmallNumbers: false), "1.0t") // "1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "1.0t") // "1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "999.0t") // "999.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9_000_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "9000.0t") // "9000.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9880).humanReadableString(roundSmallNumbers: false), "9.9k") // "9.9k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9999).humanReadableString(roundSmallNumbers: false), "10.0k") // "10.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 44_999).humanReadableString(roundSmallNumbers: false), "45.0k") // "45.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 77_164).humanReadableString(roundSmallNumbers: false), "77.2k") // "77.2k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 100_101).humanReadableString(roundSmallNumbers: false), "100.1k") // "100.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 110_099).humanReadableString(roundSmallNumbers: false), "110.1k") // "110.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 9_899_999).humanReadableString(roundSmallNumbers: false), "9.9m") // "9.9m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 5_800_199).humanReadableString(roundSmallNumbers: false), "5.8m") // "5.8m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 998_999_999).humanReadableString(roundSmallNumbers: false), "999.0m") // "999.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999.9999).humanReadableString(roundSmallNumbers: false), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(roundSmallNumbers: false), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(roundSmallNumbers: false), "1.0b") // "1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 99_899_999_999).humanReadableString(roundSmallNumbers: false), "99.9b") // "99.9b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(roundSmallNumbers: false), "1.0t") // "1.0t"
    }

    func testHumanReadableStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000).humanReadableString(roundSmallNumbers: false), "-1.0k") // "-1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(roundSmallNumbers: false), "-1.0k") // "-1.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999).humanReadableString(roundSmallNumbers: false), "-1.0m") // "-1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000).humanReadableString(roundSmallNumbers: false), "-1.0m") // "-1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000.00001).humanReadableString(roundSmallNumbers: false), "-1.0m") // "-1.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(roundSmallNumbers: false), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(roundSmallNumbers: false), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(roundSmallNumbers: false), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000_000).humanReadableString(roundSmallNumbers: false), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_880).humanReadableString(roundSmallNumbers: false), "-9.9k") // "-9.9k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_999).humanReadableString(roundSmallNumbers: false), "-10.0k") // "-10.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -44_999).humanReadableString(roundSmallNumbers: false), "-45.0k") // "-45.0k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -77_164).humanReadableString(roundSmallNumbers: false), "-77.2k") // "-77.2k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -100_101).humanReadableString(roundSmallNumbers: false), "-100.1k") // "-100.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -110_099).humanReadableString(roundSmallNumbers: false), "-110.1k") // "-110.1k"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_899_999).humanReadableString(roundSmallNumbers: false), "-9.9m") // "-9.9m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -5_800_199).humanReadableString(roundSmallNumbers: false), "-5.8m") // "-5.8m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -998_999_999).humanReadableString(roundSmallNumbers: false), "-999.0m") // "-999.0m"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(roundSmallNumbers: false), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(roundSmallNumbers: false), "-1.0b") // "-1.0b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -99_899_999_999).humanReadableString(roundSmallNumbers: false), "-99.9b") // "-99.9b"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(roundSmallNumbers: false), "-1.0t") // "-1.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -999_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "-999.0t") // "-999.0t"

        XCTAssertEqual(NSDecimalNumber(floatLiteral: -9_000_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false), "-9000.0t") // "-9000.0t"
    }
}
