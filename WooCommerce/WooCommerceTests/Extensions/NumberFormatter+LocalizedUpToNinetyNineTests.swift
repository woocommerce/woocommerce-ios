
import XCTest

@testable import WooCommerce

final class NumberFormatterLocalizedUpToNinetyNineTests: XCTestCase {

    func testItReturnsNinetyNinePlusIfTheNumberIsGreaterThanNinetyNine() {
        let localized = NumberFormatter.localizedUpToNinetyNine(100)

        XCTAssertEqual(localized, NSLocalizedString("99+", comment: ""))
    }

    func testItReturnsTheLocalizedNumberIfTheNumberIsLessThanNinetyNine() {
        let localized = NumberFormatter.localizedUpToNinetyNine(98)

        XCTAssertEqual(localized, NumberFormatter.localizedString(from: NSNumber(value: 98), number: .none))
    }

    func testItReturnsTheLocalizedNumberIfTheNumberIsNinetyNine() {
        let localized = NumberFormatter.localizedUpToNinetyNine(99)

        XCTAssertEqual(localized, NumberFormatter.localizedString(from: NSNumber(value: 99), number: .none))
    }
}
