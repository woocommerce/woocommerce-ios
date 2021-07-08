import XCTest
import Yosemite

import protocol Storage.StorageType
import protocol Storage.StorageManagerType

@testable import WooCommerce

class ReviewOrderViewModelTests: XCTestCase {

    private let orderID: Int64 = 543
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
        let item = OrderItem.fake().copy(productID: productID, quantity: 1)
        let order = Order.fake().copy(status: .processing, items: [item])
        let product = Product().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let aggregateItem = viewModel.aggregateOrderItems.first
        XCTAssertNotNil(aggregateItem)
        let productCellModel = viewModel.productDetailsCellViewModel(for: aggregateItem!)
        XCTAssertEqual(productCellModel.name, item.name)
    }

    func test_productDetailsCellViewModel_returns_no_addOns_if_view_model_receives_showAddOns_as_false() {
        // Given
        let item = OrderItem.fake().copy(productID: productID, quantity: 1)
        let order = Order.fake().copy(status: .processing, items: [item])
        let product = Product().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let aggregateItem = viewModel.aggregateOrderItems.first!
        let productCellModel = viewModel.productDetailsCellViewModel(for: aggregateItem)
        XCTAssertEqual(productCellModel.hasAddOns, false)
    }

    func test_productDetailsCellViewModel_returns_correct_hasAddOns_if_view_model_receives_showAddOns_as_true_and_there_are_valid_addons() {
        // Given
        let addOnName = "Test"
        let itemAttribute = OrderItemAttribute.fake().copy(name: addOnName)
        let item = OrderItem.fake().copy(productID: productID, quantity: 1, attributes: [itemAttribute])
        let order = Order.fake().copy(siteID: siteID, status: .processing, items: [item])
        let addOn = ProductAddOn.fake().copy(name: addOnName)
        let product = Product().copy(productID: productID, addOns: [addOn])

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: true, storageManager: storageManager)

        // Then
        let aggregateItem = viewModel.aggregateOrderItems.first!
        let productCellModel = viewModel.productDetailsCellViewModel(for: aggregateItem)
        XCTAssertEqual(productCellModel.hasAddOns, true)
    }

    func test_productSection_contains_only_non_refunded_items() {
        // Given
        let productID2: Int64 = 335
        let itemID1: Int64 = 134
        let itemID2: Int64 = 432

        let product1 = Product().copy(productID: productID)
        let product2 = Product().copy(productID: productID2)

        let item1 = OrderItem.fake().copy(itemID: itemID1, productID: product1.productID, quantity: 1)
        let item2 = OrderItem.fake().copy(itemID: itemID2, productID: product2.productID, quantity: -1)
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, status: .processing, items: [item1, item2])

        let itemRefund = OrderItemRefund.fake().copy(itemID: item2.itemID, productID: item2.productID)
        let refund = Refund.fake().copy(orderID: orderID, siteID: siteID, items: [itemRefund])
        insert(refund)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product1, product2], showAddOns: false, storageManager: storageManager)
        viewModel.configureResultsControllers {}

        // Then
        let productSection = viewModel.sections.first(where: { $0.category == .products })
        XCTAssertNotNil(productSection)
        let productRow = productSection?.rows.first(where: {
            if case .orderItem(let item) = $0,
               item.productID == productID {
                return true
            }
            return false
        })
        XCTAssertNotNil(productRow)
    }
}

private extension ReviewOrderViewModelTests {
    func insert(_ readOnlyRefund: Refund) {
        let storageRefund = storage.insertNewObject(ofType: StorageRefund.self)
        storageRefund.update(with: readOnlyRefund)
        storageRefund.items = Set(readOnlyRefund.items.map {
            let storageItem = storage.insertNewObject(ofType: StorageOrderItemRefund.self)
            storageItem.update(with: $0)
            return storageItem
        })
        storage.saveIfNeeded()
    }
}
