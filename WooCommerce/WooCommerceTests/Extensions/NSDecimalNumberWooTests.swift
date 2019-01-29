import XCTest
@testable import WooCommerce


/// NSDecimalNumber+Helpers: Unit Tests
///
class NSDecimalNumberWooTests: XCTestCase {

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
}
