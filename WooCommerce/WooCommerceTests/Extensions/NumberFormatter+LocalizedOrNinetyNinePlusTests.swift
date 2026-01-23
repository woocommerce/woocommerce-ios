
import XCTest

@testable import WooCommerce

final class NumberFormatterLocalizedOrNinetyNinePlusTests: XCTestCase {

    func testItReturnsNinetyNinePlusIfTheNumberIsGreaterThanNinetyNine() {
        let localized = NumberFormatter.localizedOrNinetyNinePlus(100)

        XCTAssertEqual(localized, NSLocalizedString("99+", comment: "This text appears as a label to indicate when a count or number exceeds 99, commonly used in badges, notifications, or counters to show '99+' instead of displaying the exact number."))
    }

    func testItReturnsTheLocalizedNumberIfTheNumberIsLessThanNinetyNine() {
        let localized = NumberFormatter.localizedOrNinetyNinePlus(98)

        XCTAssertEqual(localized, NumberFormatter.localizedString(from: NSNumber(value: 98), number: .none))
    }

    func testItReturnsTheLocalizedNumberIfTheNumberIsNinetyNine() {
        let localized = NumberFormatter.localizedOrNinetyNinePlus(99)

        XCTAssertEqual(localized, NumberFormatter.localizedString(from: NSNumber(value: 99), number: .none))
    }
}
