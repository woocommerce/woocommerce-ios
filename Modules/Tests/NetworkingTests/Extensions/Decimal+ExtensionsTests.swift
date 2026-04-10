import XCTest

/// Decimal+Extensions: Unit Tests

class Decimal_ExtensionsTests: XCTestCase {

    func test_isInteger_check() {
        XCTAssertTrue(Decimal(12345678).isInteger)
        XCTAssertTrue(Decimal(10000000).isInteger)
        XCTAssertTrue(Decimal(12.0).isInteger)
        XCTAssertTrue(Decimal(0).isInteger)
        XCTAssertTrue(Decimal(-12.0).isInteger)
        XCTAssertTrue(Decimal(-10000000).isInteger)
        XCTAssertTrue(Decimal(-12345678).isInteger)

        XCTAssertFalse(Decimal(12.345678).isInteger)
        XCTAssertFalse(Decimal(0.0000000001).isInteger)
        XCTAssertFalse(Decimal(-0.0000000001).isInteger)
        XCTAssertFalse(Decimal(-12.345678).isInteger)
    }
}
