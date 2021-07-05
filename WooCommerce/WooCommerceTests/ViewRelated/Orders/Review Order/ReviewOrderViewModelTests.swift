import XCTest
import Yosemite

import protocol Storage.StorageManagerType

@testable import WooCommerce

class ReviewOrderViewModelTests: XCTestCase {

    private let productID: Int64 = 1_00
    private let siteID: Int64 = 123

    override func setUpWithError() throws {
        try super.setUpWithError()
    }

    override func tearDownWithError() throws {
        try super.tearDownWithError()
    }

    func test_productDetailsCellViewModel_returns_correct_item_details() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, items: [item])
        let product = Product().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)
        let productCellModel = viewModel.productDetailsCellViewModel(for: item)

        // Then
        XCTAssertEqual(productCellModel.name, item.name)
    }

    func test_productDetailsCellViewModel_returns_no_addOns_if_view_model_receives_showAddOns_as_false() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, items: [item])
        let product = Product().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)
        let productCellModel = viewModel.productDetailsCellViewModel(for: item)

        // Then
        XCTAssertEqual(productCellModel.hasAddOns, false)
    }
}
