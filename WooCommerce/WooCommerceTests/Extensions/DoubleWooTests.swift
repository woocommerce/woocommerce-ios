import XCTest
@testable import WooCommerce


/// Double+Woo: Unit Tests
///
class DoubleWooTests: XCTestCase {

    func testFriendlyStringWorksWithZeroValue() {
        XCTAssertEqual(Double(0).friendlyString(), "0")
        XCTAssertEqual(Double(-0).friendlyString(), "0")
        XCTAssertEqual(Double(0.01).friendlyString(), "0")
        XCTAssertEqual(Double(-0.01).friendlyString(), "0")
    }

    func testFriendlyStringWorksWithPositiveValuesUnderOneThousand() {
        XCTAssertEqual(Double(1).friendlyString(), "1")
        XCTAssertEqual(Double(10).friendlyString(), "10")
        XCTAssertEqual(Double(199).friendlyString(), "199")
        XCTAssertEqual(Double(199.99).friendlyString(), "199")
        XCTAssertEqual(Double(999).friendlyString(), "999")
        XCTAssertEqual(Double(999.99).friendlyString(), "999")
        XCTAssertEqual(Double(999.99999).friendlyString(), "999")
        XCTAssertEqual(Double(1000).friendlyString(), "1.0k")
        XCTAssertEqual(Double(1000.00001).friendlyString(), "1.0k")
    }

    func testFriendlyStringWorksWithNegativeValuesUnderOneThousand() {
        XCTAssertEqual(Double(-1).friendlyString(), "-1")
        XCTAssertEqual(Double(-10).friendlyString(), "-10")
        XCTAssertEqual(Double(-199).friendlyString(), "-199")
        XCTAssertEqual(Double(-199.99).friendlyString(), "-199")
        XCTAssertEqual(Double(-999).friendlyString(), "-999")
        XCTAssertEqual(Double(-999.99).friendlyString(), "-999")
        XCTAssertEqual(Double(-999.99999).friendlyString(), "-999")
        XCTAssertEqual(Double(-1000).friendlyString(), "-1.0k")
        XCTAssertEqual(Double(-1000.00001).friendlyString(), "-1.0k")
    }

    func testFriendlyStringWorksWithPositiveValuesAboveOneThousand() {
        XCTAssertEqual(Double(1000).friendlyString(), "1.0k")
        XCTAssertEqual(Double(1000.00001).friendlyString(), "1.0k")
        XCTAssertEqual(Double(999999).friendlyString(), "1.0m")
        XCTAssertEqual(Double(1000000).friendlyString(), "1.0m")
        XCTAssertEqual(Double(1000000.00001).friendlyString(), "1.0m")
        XCTAssertEqual(Double(999999999).friendlyString(), "1.0b")
        XCTAssertEqual(Double(1000000000).friendlyString(), "1.0b")
        XCTAssertEqual(Double(1000000000.00001).friendlyString(), "1.0b")
        XCTAssertEqual(Double(999999999999).friendlyString(), "1.0t")
        XCTAssertEqual(Double(1000000000000).friendlyString(), "1.0t")
        XCTAssertEqual(Double(1000000000000.00001).friendlyString(), "1.0t")

        XCTAssertEqual(Double(9880).friendlyString(), "9.9k")
        XCTAssertEqual(Double(9999).friendlyString(), "10.0k")
        XCTAssertEqual(Double(100101).friendlyString(), "100.1k")
        XCTAssertEqual(Double(110099).friendlyString(), "110.1k")
        XCTAssertEqual(Double(9899999).friendlyString(), "9.9m")
        XCTAssertEqual(Double(5800199).friendlyString(), "5.8m")
        XCTAssertEqual(Double(998999999).friendlyString(), "999.0m")
    }

    func testFriendlyStringWorksWithNegativeValuesAboveOneThousand() {
        XCTAssertEqual(Double(-1000).friendlyString(), "-1.0k")
        XCTAssertEqual(Double(-1000.00001).friendlyString(), "-1.0k")
        XCTAssertEqual(Double(-999999).friendlyString(), "-1.0m")
        XCTAssertEqual(Double(-1000000).friendlyString(), "-1.0m")
        XCTAssertEqual(Double(-1000000.00001).friendlyString(), "-1.0m")
        XCTAssertEqual(Double(-999999999).friendlyString(), "-1.0b")
        XCTAssertEqual(Double(-1000000000).friendlyString(), "-1.0b")
        XCTAssertEqual(Double(-1000000000.00001).friendlyString(), "-1.0b")
        XCTAssertEqual(Double(-999999999999).friendlyString(), "-1.0t")
        XCTAssertEqual(Double(-1000000000000).friendlyString(), "-1.0t")
        XCTAssertEqual(Double(-1000000000000.00001).friendlyString(), "-1.0t")

        XCTAssertEqual(Double(-9880).friendlyString(), "-9.9k")
        XCTAssertEqual(Double(-9999).friendlyString(), "-10.0k")
        XCTAssertEqual(Double(-100101).friendlyString(), "-100.1k")
        XCTAssertEqual(Double(-110099).friendlyString(), "-110.1k")
        XCTAssertEqual(Double(-9899999).friendlyString(), "-9.9m")
        XCTAssertEqual(Double(-5800199).friendlyString(), "-5.8m")
        XCTAssertEqual(Double(-998999999).friendlyString(), "-999.0m")
    }
}
