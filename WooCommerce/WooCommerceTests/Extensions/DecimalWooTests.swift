import XCTest
@testable import WooCommerce
import Foundation


/// Decimal+Helpers: Unit Tests
///
final class DecimalWooTests: XCTestCase {

    func test_intValue_returns_the_expected_result() {

        // Positive numbers
        XCTAssertEqual(Decimal(string: "1234.0")?.intValue, 1234)
        XCTAssertEqual(Decimal(string: "100.123456789123")?.intValue, 100)
        XCTAssertEqual(Decimal(string: "200")?.intValue, 200)
        XCTAssertEqual(Decimal(string: "2")?.intValue, 2)
        XCTAssertEqual(Decimal(string: "0")?.intValue, 0)
        XCTAssertEqual(Decimal(string: "0.2323921301")?.intValue, 0)

        // Negative numbers
        XCTAssertEqual(Decimal(string: "-1234.0")?.intValue, -1234)
        XCTAssertEqual(Decimal(string: "-100.123456789123")?.intValue, -100)
        XCTAssertEqual(Decimal(string: "-200")?.intValue, -200)
        XCTAssertEqual(Decimal(string: "-2")?.intValue, -2)
        XCTAssertEqual(Decimal(string: "-0")?.intValue, 0)
        XCTAssertEqual(Decimal(string: "-0.2323921301")?.intValue, 0)
    }
}
