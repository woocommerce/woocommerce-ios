import XCTest
@testable import WooCommerce

/// Tests for `Product`'s shipping helper.
final class Product_ShippingTests: XCTestCase {
    // MARK: - `isShippingEnabled`

    func testShippingIsEnabledForAPhysicalProduct() {
        let product = MockProduct().product(downloadable: false, virtual: false)
        let model = EditableProductModel(product: product)
        XCTAssertTrue(model.isShippingEnabled())
    }

    func testShippingIsDisabledForADownloadableProduct() {
        let product = MockProduct().product(downloadable: true, virtual: false)
        let model = EditableProductModel(product: product)
        XCTAssertFalse(model.isShippingEnabled())
    }

    func testShippingIsDisabledForAVirtualProduct() {
        let product = MockProduct().product(downloadable: false, virtual: true)
        let model = EditableProductModel(product: product)
        XCTAssertFalse(model.isShippingEnabled())
    }
}
