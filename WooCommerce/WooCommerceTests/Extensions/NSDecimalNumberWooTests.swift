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
        XCTAssertFalse(NSDecimalNumber(integerLiteral: 11_234_234).isZero())
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

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1000))  //"1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1000))  //"1.0k"
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

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1000))  //"-1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1000))  //"-1.0k"
    }

    func testRoundedHumanReadableStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1000))  //"1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1000))  //"1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000))  //"1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000))  // "1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000))  // "1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_000_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 999_000_000_000_000))  // "999.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9_000_000_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: 9000_000_000_000_000))  // "9000.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9880).humanReadableString(),
            expectedLocalizedAbbreviation(for: 9_900))  // "9.9k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 10_000))  // "10.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 44_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 45_000))  // "45.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 77_164).humanReadableString(),
            expectedLocalizedAbbreviation(for: 77_200))  // "77.2k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 100_101).humanReadableString(),
            expectedLocalizedAbbreviation(for: 100_100))  // "100.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 110_099).humanReadableString(),
            expectedLocalizedAbbreviation(for: 110_100))  // "110.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9_899_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 9_900_000))  // "9.9m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 5_800_199).humanReadableString(),
            expectedLocalizedAbbreviation(for: 5_800_000))  // "5.8m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 998_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 999_000_000))  // "999.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999.9999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 99_899_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 99_900_000_000))  // "99.9b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"
    }

    func testRoundedHumanReadableStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1000))  // "-1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1000))  // "-1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000))  // "-1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000))  // "-1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000))  // "-1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_880).humanReadableString(),
            expectedLocalizedAbbreviation(for: -9_900))  // "-9.9k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -10_000))  // "-10.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -44_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -45_000))  // "-45.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -77_164).humanReadableString(),
            expectedLocalizedAbbreviation(for: -77_200))  // "-77.2k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -100_101).humanReadableString(),
            expectedLocalizedAbbreviation(for: -100_100))  // "-100.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -110_099).humanReadableString(),
            expectedLocalizedAbbreviation(for: -110_100))  // "-110.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_899_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -9_900_000))  // "-9.9m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -5_800_199).humanReadableString(),
            expectedLocalizedAbbreviation(for: -5_800_000))  // "-5.8m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -998_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -999_000_000))  // "-999.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -99_899_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -99_900_000_000))  // "-99.9b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_000_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -999_000_000_000_000))  // "-999.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_000_000_000_000_000.00001).humanReadableString(),
            expectedLocalizedAbbreviation(for: -9_000_000_000_000_000))  // "-9000.0t"
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

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1000))  //"1.0k"
        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1000))  //"1.0k"
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

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1000))  // "-1.0k"
        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1000))  // "-1.0k"
    }

    func testHumanReadableStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1000))  // "1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1000))  // "1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000))  // "1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000))  // "1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000))  // "1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 999_000_000_000_000))  // "999.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9_000_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 9_000_000_000_000_000))  // "9000.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9880).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 9_900))  // "9.9k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 10_000))  // "10.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 44_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 45_000))  // "45.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 77_164).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 77_200))  // "77.2k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 100_101).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 100_100))  // "100.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 110_099).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 110_100))  // "110.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 9_899_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 9_900_000))  // "9.9m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 5_800_199).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 5_800_000))  // "5.8m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 998_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 999_000_000))  // "999.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999.9999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 1_000_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000))  // "1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 99_899_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 99_900_000_000))  // "99.9b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: 999_999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: 1_000_000_000_000))  // "1.0t"
    }

    func testHumanReadableStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1000))  // "-1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1000))  // "1.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000))  // "1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000))  // "-1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000))  // "-1.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_880).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -9_900))  // "-9.9k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -10_000))  // "-10.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -44_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -45_000))  // "-45.0k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -77_164).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -77_200))  // "-77.2k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -100_101).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -100_100))  // "-100.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -110_099).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -110_100))  // "-110.1k"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_899_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -9_900_000))  // "-9.9m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -5_800_199).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -5_800_000))  // "-5.8m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -998_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -999_000_000))  // "-999.0m"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -1_000_000_000).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000))  // "-1.0b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -99_899_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -99_900_000_000))  // "-99.9b"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_999_999_999).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -1_000_000_000_000))  // "-1.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -999_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -999_000_000_000_000))  // "-999.0t"

        XCTAssertEqual(
            NSDecimalNumber(floatLiteral: -9_000_000_000_000_000.00001).humanReadableString(roundSmallNumbers: false),
            expectedLocalizedAbbreviation(for: -9_000_000_000_000_000))  // "-9000.0t"
    }

    private func expectedLocalizedAbbreviation(for num: Double) -> String? {
        return Double(exactly: num)?.humanReadableString()
    }
}
