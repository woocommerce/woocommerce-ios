import XCTest
import Yosemite
@testable import WooCommerce

/// Tests for `Product`'s shipping helper.
final class Product_ShippingTests: XCTestCase {
    // MARK: - `isShippingEnabled`

    func testShippingIsEnabledForAPhysicalProduct() {
        let product = Product.fake().copy(virtual: false, downloadable: false)
        let model = EditableProductModel(product: product)
        XCTAssertTrue(model.isShippingEnabled())
    }

    func testShippingIsDisabledForADownloadableProduct() {
        let product = Product.fake().copy(virtual: false, downloadable: true)
        let model = EditableProductModel(product: product)
        XCTAssertFalse(model.isShippingEnabled())
    }

    func testShippingIsDisabledForAVirtualProduct() {
        let product = Product.fake().copy(virtual: true, downloadable: false)
        let model = EditableProductModel(product: product)
        XCTAssertFalse(model.isShippingEnabled())
    }
}
