import XCTest
@testable import WooCommerce


/// Bundle+Woo: Unit Tests
///
class BundleWooTests: XCTestCase {

    /// Verifies that the main Bundle's Version is not an empty string.
    ///
    func testMainBundleVersionIsNotAnemptyString() {
        XCTAssertFalse(Bundle.main.version.isEmpty)
    }
}
