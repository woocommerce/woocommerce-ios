import XCTest
@testable import Yosemite

/// Tests for `Product+Settings.swift`.
final class Product_SettingsTests: XCTestCase {
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
