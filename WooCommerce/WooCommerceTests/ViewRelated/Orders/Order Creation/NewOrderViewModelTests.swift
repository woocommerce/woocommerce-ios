import XCTest
@testable import WooCommerce
import Yosemite

class NewOrderViewModelTests: XCTestCase {

    let sampleSiteID: Int64 = 123
    let sampleProductID: Int64 = 5

    func test_view_model_inits_with_expected_values() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)

        // When
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .none)
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "pending")
        XCTAssertEqual(viewModel.productRows.count, 0)
    }

    func test_create_button_is_enabled_when_order_detail_changes_from_default_value() {
        // Given
        let viewModel = NewOrderViewModel(siteID: sampleSiteID)

        // When
        viewModel.orderDetails.status = .processing

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .create)
    }

    func test_loading_indicator_is_enabled_during_network_request() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let navigationItem: NewOrderViewModel.NavigationItem = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(viewModel.navigationTrailingItem)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createOrder()
        }

        // Then
        XCTAssertEqual(navigationItem, .loading)
    }

    func test_create_button_is_enabled_after_the_network_operation_completes() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.orderDetails.status = .processing
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createOrder(_, order, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.createOrder()

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .create)
    }

    func test_view_model_fires_error_notice_when_order_creation_fails() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createOrder(_, _, onCompletion):
                onCompletion(.failure(NSError(domain: "Error", code: 0)))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.createOrder()

        // Then
        XCTAssertEqual(viewModel.presentNotice, .error)
    }

    func test_view_model_loads_synced_pending_order_status() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        storageManager.insertOrderStatus(.init(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 0))

        // When
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "Pending payment")
    }

    func test_view_model_is_updated_when_order_status_updated() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let storageManager = MockStorageManager()
        storageManager.insertOrderStatus(.init(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 0))
        storageManager.insertOrderStatus(.init(name: "Processing", siteID: sampleSiteID, slug: "processing", total: 0))

        // When
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "Pending payment")

        // When
        viewModel.orderDetails.status = .processing

        // Then
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "Processing")
    }

    func test_view_model_is_updated_when_product_is_added_to_order() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, statusKey: "publish")
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.addProductViewModel.selectProduct(product.productID)

        // Then
        let expectedOrderItem = product.toOrderItem(quantity: 1)
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productID == sampleProductID }), "Product rows do not contain expected product")
        XCTAssertTrue(viewModel.orderDetails.items.contains(where: { $0.orderItem == expectedOrderItem }), "Order details do not contain expected order item")
    }

    func test_order_details_are_updated_when_product_quantity_changes() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, statusKey: "publish")
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.addProductViewModel.selectProduct(product.productID)
        viewModel.productRows[0].incrementQuantity()

        // And when another product is added to the order (to confirm the first product's quantity change is retained)
        viewModel.addProductViewModel.selectProduct(product.productID)

        // Then
        let expectedOrderItem = product.toOrderItem(quantity: 2)
        XCTAssertTrue(viewModel.orderDetails.items.contains(where: { $0.orderItem == expectedOrderItem }),
                      "Order details do not contain order item with updated quantity")
    }

    func test_selectOrderItem_selects_expected_order_item() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, statusKey: "publish")
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)
        viewModel.addProductViewModel.selectProduct(product.productID)

        // When
        let expectedOrderItem = viewModel.orderDetails.items[0]
        viewModel.selectOrderItem(expectedOrderItem.id)

        // Then
        XCTAssertEqual(viewModel.selectedOrderItem, expectedOrderItem)
    }

    func test_view_model_is_updated_when_product_is_removed_from_order() {
        // Given
        let product0 = Product.fake().copy(siteID: sampleSiteID, productID: 0, statusKey: "publish")
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, statusKey: "publish")
        let storageManager = MockStorageManager()
        storageManager.insertProducts([product0, product1])
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // Given products are added to order
        viewModel.addProductViewModel.selectProduct(product0.productID)
        viewModel.addProductViewModel.selectProduct(product1.productID)

        // When
        let expectedRemainingItem = viewModel.orderDetails.items[1]
        viewModel.removeItemFromOrder(viewModel.orderDetails.items[0])

        // Then
        let expectedProductRow = ProductRowViewModel(id: expectedRemainingItem.id, product: product1, canChangeQuantity: true)
        XCTAssertEqual(viewModel.productRows, [expectedProductRow])
        XCTAssertEqual(viewModel.orderDetails.items, [expectedRemainingItem])
    }
}

private extension MockStorageManager {

    func insertOrderStatus(_ readOnlyOrderStatus: OrderStatus) {
        let orderStatus = viewStorage.insertNewObject(ofType: StorageOrderStatus.self)
        orderStatus.update(with: readOnlyOrderStatus)
        viewStorage.saveIfNeeded()
    }

    func insertProducts(_ readOnlyProducts: [Product]) {
        for readOnlyProduct in readOnlyProducts {
            let product = viewStorage.insertNewObject(ofType: StorageProduct.self)
            product.update(with: readOnlyProduct)
            viewStorage.saveIfNeeded()
        }
    }
}
