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
        XCTAssertEqual(Double(1000).humanReadableString(), "1.0k") // "1.0k"
        XCTAssertEqual(Double(1000.00001).humanReadableString(), "1.0k") // "1.0k"
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
        XCTAssertEqual(Double(-1000).humanReadableString(), "-1.0k") // "-1.0k"
        XCTAssertEqual(Double(-1000.00001).humanReadableString(), "-1.0k") // "-1.0k"
    }

    func testHumanReadableStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(Double(1000).humanReadableString(), "1.0k") // "1.0k"
        XCTAssertEqual(Double(1000.00001).humanReadableString(), "1.0k") // "1.0k"
        XCTAssertEqual(Double(999_999).humanReadableString(), "1.0m") // "1.0m"
        XCTAssertEqual(Double(1_000_000).humanReadableString(), "1.0m") // "1.0m"
        XCTAssertEqual(Double(1_000_000.00001).humanReadableString(), "1.0m") // "1.0m"
        XCTAssertEqual(Double(999_999_999).humanReadableString(), "1.0b") // "1.0b"
        XCTAssertEqual(Double(1_000_000_000).humanReadableString(), "1.0b") // "1.0b"
        XCTAssertEqual(Double(1_000_000_000.00001).humanReadableString(), "1.0b") // "1.0b"
        XCTAssertEqual(Double(999_999_999_999).humanReadableString(), "1.0t") // "1.0t"
        XCTAssertEqual(Double(1_000_000_000_000).humanReadableString(), "1.0t") // "1.0t"
        XCTAssertEqual(Double(1_000_000_000_000.00001).humanReadableString(), "1.0t") // "1.0t"
        XCTAssertEqual(Double(999_000_000_000_000.00001).humanReadableString(), "999.0t") // "999.0t"
        XCTAssertEqual(Double(9_000_000_000_000_000.00001).humanReadableString(), "9000.0t") // "9000.0t"

        XCTAssertEqual(Double(9880).humanReadableString(), "9.9k") // "9.9k"
        XCTAssertEqual(Double(9999).humanReadableString(), "10.0k") // "10.0k"
        XCTAssertEqual(Double(44_999).humanReadableString(), "45.0k") // "45.0k"
        XCTAssertEqual(Double(77_164).humanReadableString(), "77.2k") // "77.2k"
        XCTAssertEqual(Double(100_101).humanReadableString(), "100.1k") // "100.1k"
        XCTAssertEqual(Double(110_099).humanReadableString(), "110.1k") // "110.1k"
        XCTAssertEqual(Double(9_899_999).humanReadableString(), "9.9m") // "9.9m"
        XCTAssertEqual(Double(5_800_199).humanReadableString(), "5.8m") // "5.8m"
        XCTAssertEqual(Double(998_999_999).humanReadableString(), "999.0m") // "999.0m"
        XCTAssertEqual(Double(999_999_999.9999).humanReadableString(), "1.0b") // "1.0b"
        XCTAssertEqual(Double(999_999_999).humanReadableString(), "1.0b") // "1.0b"
        XCTAssertEqual(Double(1_000_000_000).humanReadableString(), "1.0b") // "1.0b"
        XCTAssertEqual(Double(99_899_999_999).humanReadableString(), "99.9b") // "99.9b"
        XCTAssertEqual(Double(999_999_999_999).humanReadableString(), "1.0t") // "1.0t"
    }

    func testHumanReadableStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(Double(-1000).humanReadableString(), "-1.0k") // "-1.0k"
        XCTAssertEqual(Double(-1000.00001).humanReadableString(), "-1.0k") // "-1.0k"
        XCTAssertEqual(Double(-999_999).humanReadableString(), "-1.0m") // "-1.0m"
        XCTAssertEqual(Double(-1_000_000).humanReadableString(), "-1.0m") // "-1.0m"
        XCTAssertEqual(Double(-1_000_000.00001).humanReadableString(), "-1.0m") // "-1.0m"
        XCTAssertEqual(Double(-999_999_999).humanReadableString(), "-1.0b") // "-1.0b"
        XCTAssertEqual(Double(-1_000_000_000).humanReadableString(), "-1.0b") // "-1.0b"
        XCTAssertEqual(Double(-1_000_000_000.00001).humanReadableString(), "-1.0b") // "-1.0b"
        XCTAssertEqual(Double(-999_999_999_999).humanReadableString(), "-1.0t") // "-1.0t"
        XCTAssertEqual(Double(-1_000_000_000_000).humanReadableString(), "-1.0t") // "-1.0t"
        XCTAssertEqual(Double(-1_000_000_000_000.00001).humanReadableString(), "-1.0t") // "-1.0t"

        XCTAssertEqual(Double(-9_880).humanReadableString(), "-9.9k")// "-9.9k"
        XCTAssertEqual(Double(-9_999).humanReadableString(), "-10.0k") // "-10.0k"
        XCTAssertEqual(Double(-44_999).humanReadableString(), "-45.0k") // "-45.0k"
        XCTAssertEqual(Double(-77_164).humanReadableString(), "-77.2k") // "-77.2k"
        XCTAssertEqual(Double(-100_101).humanReadableString(), "-100.1k") // "-100.1k"
        XCTAssertEqual(Double(-110_099).humanReadableString(), "-110.1k") // "-110.1k"
        XCTAssertEqual(Double(-9_899_999).humanReadableString(), "-9.9m") // "-9.9m"
        XCTAssertEqual(Double(-5_800_199).humanReadableString(), "-5.8m") // "-5.8m"
        XCTAssertEqual(Double(-998_999_999).humanReadableString(), "-999.0m") // "-999.0m"
        XCTAssertEqual(Double(-999_999_999).humanReadableString(), "-1.0b") // "-1.0b"
        XCTAssertEqual(Double(-1_000_000_000).humanReadableString(), "-1.0b") // "-1.0b"
        XCTAssertEqual(Double(-99_899_999_999).humanReadableString(), "-99.9b") // "-99.9b"
        XCTAssertEqual(Double(-999_999_999_999).humanReadableString(), "-1.0t") // "-1.0t"
        XCTAssertEqual(Double(-999_000_000_000_000.00001).humanReadableString(), "-999.0t") // "-999.0t"
        XCTAssertEqual(Double(-9_000_000_000_000_000.00001).humanReadableString(), "-9000.0t") // "-9000.0t"
    }
}
