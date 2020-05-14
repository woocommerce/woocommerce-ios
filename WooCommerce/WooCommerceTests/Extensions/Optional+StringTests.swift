import XCTest
@testable import WooCommerce

final class Optional_StringTests: XCTestCase {
    // MARK: - `isNilOrEmpty`

    func testNilStringReturnsTrueForNilOrEmpty() {
        let string: String? = nil
        XCTAssertTrue(string.isNilOrEmpty)
    }

    func testEmptyStringReturnsTrueForNilOrEmpty() {
        let string: String? = ""
        XCTAssertTrue(string.isNilOrEmpty)
    }

    func testNonEmptyStringReturnsFalseForNilOrEmpty() {
        let string: String? = "🤓"
        XCTAssertFalse(string.isNilOrEmpty)
    }
}
