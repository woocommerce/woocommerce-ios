import XCTest
@testable import WooCommerce

/// Tests for `Product`'s shipping helper.
final class Product_ShippingTests: XCTestCase {
    // MARK: - `isShippingEnabled`

    func testShippingIsEnabledForAPhysicalProduct() {
        let product = MockProduct().product(downloadable: false, virtual: false)
        XCTAssertTrue(product.isShippingEnabled)
    }

    func testShippingIsDisabledForADownloadableProduct() {
        let product = MockProduct().product(downloadable: true, virtual: false)
        XCTAssertFalse(product.isShippingEnabled)
    }

    func testShippingIsDisabledForAVirtualProduct() {
        let product = MockProduct().product(downloadable: false, virtual: true)
        XCTAssertFalse(product.isShippingEnabled)
    }
}
