import XCTest
@testable import WooCommerce
import Foundation


/// Decimal+Helpers: Unit Tests
///
final class DecimalWooTests: XCTestCase {

    func test_intValue_returns_the_expected_result() {
        XCTAssertEqual(Decimal(string: "1234.0"), 1234)
        XCTAssertEqual(Decimal(string: "100.123456789123"), 100)
        XCTAssertEqual(Decimal(string: "200"), 200)
        XCTAssertEqual(Decimal(string: "2"), 2)
        XCTAssertEqual(Decimal(string: "0"), 0)
        XCTAssertEqual(Decimal(string: "0.2323921301"), 0)
    }
}
