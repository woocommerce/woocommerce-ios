import XCTest
import Yosemite

import protocol Storage.StorageType
import protocol Storage.StorageManagerType

@testable import WooCommerce

class ReviewOrderViewModelTests: XCTestCase {

    private let productID: Int64 = 1_00
    private let siteID: Int64 = 123

    /// Mock Storage: InMemory
    ///
    private var storageManager: StorageManagerType!

    /// View storage for tests
    ///
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUpWithError() throws {
        try super.setUpWithError()
        storageManager = MockStorageManager()
    }

    override func tearDownWithError() throws {
        storageManager = nil
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

    func test_productDetailsCellViewModel_returns_correct_hasAddOns_if_view_model_receives_showAddOns_as_true_and_there_are_valid_addons() {
        // Given
        let addOnName = "Test"
        let itemAttribute = OrderItemAttribute.fake().copy(name: addOnName)
        let item = OrderItem.fake().copy(productID: productID, attributes: [itemAttribute])
        let order = Order.fake().copy(siteID: siteID, status: .processing, items: [item])
        let addOn = ProductAddOn.fake().copy(name: addOnName)
        let product = Product().copy(productID: productID, addOns: [addOn])

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: true, storageManager: storageManager)
        let productCellModel = viewModel.productDetailsCellViewModel(for: item)

        // Then
        XCTAssertEqual(productCellModel.hasAddOns, true)
    }
}
