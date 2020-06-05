import XCTest
@testable import WooCommerce


// UITableViewCell+Helpers: Unit Tests
//
final class UITableViewCellHelpersTests: XCTestCase {

    /// Verifies that `reuseIdentifier` class method effectively returns a string that doesn't contain the class's module.
    ///
    func testReuseIdentifierEffectivelyReturnsClassnameWithNoNamespaces() {
        XCTAssertEqual(EmptyStoresTableViewCell.reuseIdentifier, "EmptyStoresTableViewCell")
    }
}
