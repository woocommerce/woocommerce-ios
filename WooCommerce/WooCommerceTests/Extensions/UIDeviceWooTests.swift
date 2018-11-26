import XCTest
@testable import WooCommerce


/// UIDevice+Woo: Unit Tests
///
class UIDeviceWooTests: XCTestCase {

    /// Verifies that the modelIdentifier property does not return an empty string.
    ///
    func testModelIdentifierDoesNotReturnAnEmptyString() {
        XCTAssertFalse(UIDevice.current.modelIdentifier.isEmpty)
    }
}
