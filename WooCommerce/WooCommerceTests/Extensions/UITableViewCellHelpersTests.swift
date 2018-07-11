import XCTest
@testable import WooCommerce


// UITableViewCell+Helpers: Unit Tests
//
class UITableViewCellHelpersTests: XCTestCase {
    
    func testReuseIdentifierEffectivelyReturnsClassnameWithNoNamespaces() {
        XCTAssertEqual(EmptyStoresTableViewCell.reuseIdentifier, "EmptyStoresTableViewCell")
    }
}
