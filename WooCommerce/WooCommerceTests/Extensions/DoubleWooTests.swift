import XCTest
@testable import WooCommerce


/// Double+Woo: Unit Tests
///
class DoubleWooTests: XCTestCase {

    func testHumanReadableStringWorksWithZeroValue() {
        XCTAssertEqual(Double(0).humanReadableString(), "0")
        XCTAssertEqual(Double(-0).humanReadableString(), "0")
        XCTAssertEqual(Double(0.01).humanReadableString(), "0")
        XCTAssertEqual(Double(-0.01).humanReadableString(), "0")
    }

    func testHumanReadableStringWorksWithPositiveValuesUnderOneThousand() {
        XCTAssertEqual(Double(1).humanReadableString(), "1")
        XCTAssertEqual(Double(10).humanReadableString(), "10")
        XCTAssertEqual(Double(198).humanReadableString(), "198")
        XCTAssertEqual(Double(198.44).humanReadableString(), "198")
        XCTAssertEqual(Double(199).humanReadableString(), "199")
        XCTAssertEqual(Double(199.99).humanReadableString(), "199")
        XCTAssertEqual(Double(999).humanReadableString(), "999")
        XCTAssertEqual(Double(999.99).humanReadableString(), "999")
        XCTAssertEqual(Double(999.99999).humanReadableString(), "999")
        XCTAssertEqual(Double(1000).humanReadableString(), expectedLocalizedAbbreviation(for: 1000)) // "1.0k"
        XCTAssertEqual(Double(1000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 1000)) // "1.0k"
    }

    func testHumanReadableStringWorksWithNegativeValuesUnderOneThousand() {
        XCTAssertEqual(Double(-1).humanReadableString(), "-1")
        XCTAssertEqual(Double(-10).humanReadableString(), "-10")
        XCTAssertEqual(Double(-198.44).humanReadableString(), "-198")
        XCTAssertEqual(Double(-199).humanReadableString(), "-199")
        XCTAssertEqual(Double(-199.99).humanReadableString(), "-199")
        XCTAssertEqual(Double(-999).humanReadableString(), "-999")
        XCTAssertEqual(Double(-999.99).humanReadableString(), "-999")
        XCTAssertEqual(Double(-999.99999).humanReadableString(), "-999")
        XCTAssertEqual(Double(-1000).humanReadableString(), expectedLocalizedAbbreviation(for: -1000)) // "-1.0k"
        XCTAssertEqual(Double(-1000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -1000)) // "-1.0k"
    }

    func testHumanReadableStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(Double(1000).humanReadableString(), expectedLocalizedAbbreviation(for: 1000)) // "1.0k"
        XCTAssertEqual(Double(1000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 1000)) // "1.0k"
        XCTAssertEqual(Double(999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000)) // "1.0m"
        XCTAssertEqual(Double(1_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000)) // "1.0m"
        XCTAssertEqual(Double(1_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000)) // "1.0m"
        XCTAssertEqual(Double(999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000)) // "1.0b"
        XCTAssertEqual(Double(1_000_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000)) // "1.0b"
        XCTAssertEqual(Double(1_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000)) //"1.0b"
        XCTAssertEqual(Double(999_999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000_000)) // "1.0t"
        XCTAssertEqual(Double(1_000_000_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000_000)) // "1.0t"
        XCTAssertEqual(Double(1_000_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000_000)) // "1.0t"
        XCTAssertEqual(Double(999_000_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 999_000_000_000_000)) // "999.0t"
        XCTAssertEqual(Double(9_000_000_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: 9_000_000_000_000_000)) // "9000.0t"

        XCTAssertEqual(Double(9880).humanReadableString(), expectedLocalizedAbbreviation(for: 9_900)) // "9.9k"
        XCTAssertEqual(Double(9999).humanReadableString(), expectedLocalizedAbbreviation(for: 10_000)) //"10.0k"
        XCTAssertEqual(Double(44_999).humanReadableString(), expectedLocalizedAbbreviation(for: 45_000)) // "45.0k"
        XCTAssertEqual(Double(77_164).humanReadableString(), expectedLocalizedAbbreviation(for: 77_200)) // "77.2k"
        XCTAssertEqual(Double(100_101).humanReadableString(), expectedLocalizedAbbreviation(for: 100_100)) // "100.1k"
        XCTAssertEqual(Double(110_099).humanReadableString(), expectedLocalizedAbbreviation(for: 110_100)) // "110.1k"
        XCTAssertEqual(Double(9_899_999).humanReadableString(), expectedLocalizedAbbreviation(for: 9_900_000)) // "9.9m"
        XCTAssertEqual(Double(5_800_199).humanReadableString(), expectedLocalizedAbbreviation(for: 5_800_000)) //"5.8m"
        XCTAssertEqual(Double(998_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 999_000_000)) // "999.0m"
        XCTAssertEqual(Double(999_999_999.9999).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000)) // "1.0b"
        XCTAssertEqual(Double(999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000)) // "1.0b"
        XCTAssertEqual(Double(1_000_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000)) // "1.0b"
        XCTAssertEqual(Double(99_899_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 99_900_000_000)) // "99.9b"
        XCTAssertEqual(Double(999_999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: 1_000_000_000_000)) // "1.0t"
    }

    func testHumanReadableStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(Double(-1000).humanReadableString(), expectedLocalizedAbbreviation(for: -1000)) // "-1.0k"
        XCTAssertEqual(Double(-1000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -1000)) // "-1.0k"
        XCTAssertEqual(Double(-999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000)) // "-1.0m"
        XCTAssertEqual(Double(-1_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000)) // "-1.0m"
        XCTAssertEqual(Double(-1_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000)) // "-1.0m"
        XCTAssertEqual(Double(-999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000)) // "-1.0b"
        XCTAssertEqual(Double(-1_000_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000)) // "-1.0b"
        XCTAssertEqual(Double(-1_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000)) // "-1.0b"
        XCTAssertEqual(Double(-999_999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000_000)) // "-1.0t"
        XCTAssertEqual(Double(-1_000_000_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000_000)) // "-1.0t"
        XCTAssertEqual(Double(-1_000_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000_000)) // "-1.0t"

        XCTAssertEqual(Double(-9_880).humanReadableString(), expectedLocalizedAbbreviation(for: -9_900))// "-9.9k"
        XCTAssertEqual(Double(-9_999).humanReadableString(), expectedLocalizedAbbreviation(for: -10_000)) // "-10.0k"
        XCTAssertEqual(Double(-44_999).humanReadableString(), expectedLocalizedAbbreviation(for: -45_000)) // "-45.0k"
        XCTAssertEqual(Double(-77_164).humanReadableString(), expectedLocalizedAbbreviation(for: -77_200)) // "-77.2k"
        XCTAssertEqual(Double(-100_101).humanReadableString(), expectedLocalizedAbbreviation(for: -100_100)) // "-100.1k"
        XCTAssertEqual(Double(-110_099).humanReadableString(), expectedLocalizedAbbreviation(for: -110_100)) // "-110.1k"
        XCTAssertEqual(Double(-9_899_999).humanReadableString(), expectedLocalizedAbbreviation(for: -9_900_000)) // "-9.9m"
        XCTAssertEqual(Double(-5_800_199).humanReadableString(), expectedLocalizedAbbreviation(for: -5_800_000)) // "-5.8m"
        XCTAssertEqual(Double(-998_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -999_000_000)) // "-999.0m"
        XCTAssertEqual(Double(-999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000)) // "-1.0b"
        XCTAssertEqual(Double(-1_000_000_000).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000)) // "-1.0b"
        XCTAssertEqual(Double(-99_899_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -99_900_000_000)) // "-99.9b"
        XCTAssertEqual(Double(-999_999_999_999).humanReadableString(), expectedLocalizedAbbreviation(for: -1_000_000_000_000)) // "-1.0t"
        XCTAssertEqual(Double(-999_000_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -999_000_000_000_000)) // "-999.0t"
        XCTAssertEqual(Double(-9_000_000_000_000_000.00001).humanReadableString(), expectedLocalizedAbbreviation(for: -9_000_000_000_000_000)) // "-9000.0t"
    }

    private func expectedLocalizedAbbreviation(for num: Double) -> String? {
        return Double(exactly: num)?.humanReadableString()
    }
}
