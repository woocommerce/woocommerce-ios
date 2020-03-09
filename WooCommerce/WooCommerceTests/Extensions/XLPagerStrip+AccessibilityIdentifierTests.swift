import XCTest
import XLPagerTabStrip
@testable import WooCommerce

final class XLPagerStripAccessibilityIdentifierTests: XCTestCase {
    func testThatAccessibilityIdentifierCanBeStoredAndRetrieved() {
        let title = "title"
        let id = "id"

        let info = IndicatorInfo(title: title, accessibilityIdentifier: id)
        XCTAssertEqual(title, info.title)
        XCTAssertEqual(id, info.accessibilityIdentifier)
    }
}
