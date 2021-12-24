import XCTest
import Yosemite

import protocol Storage.StorageType
import protocol Storage.StorageManagerType

@testable import WooCommerce

class ReviewOrderViewModelTests: XCTestCase {

    private let orderID: Int64 = 396
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
        let product = Product.fake().copy(productID: productID)

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
        let product = Product.fake().copy(productID: productID)

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
        let product = Product.fake().copy(productID: productID, addOns: [addOn])

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: true, storageManager: storageManager)

        // Then
        let aggregateItem = viewModel.aggregateOrderItems.first!
        let productCellModel = viewModel.productDetailsCellViewModel(for: aggregateItem)
        XCTAssertEqual(productCellModel.hasAddOns, true)
    }

    func test_product_section_does_not_contain_refunded_items() {
        // Given
        let productID2: Int64 = 335
        let itemID1: Int64 = 134
        let itemID2: Int64 = 432

        let product1 = Product.fake().copy(productID: productID)
        let product2 = Product.fake().copy(productID: productID2)

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
        let refundedProductRow = productSection?.rows.first(where: {
            if case .orderItem(let item) = $0,
               item.productID == productID2 {
                return true
            }
            return false
        })
        XCTAssertNil(refundedProductRow)
    }

    func test_customerSection_does_not_contain_customer_note_cell_if_there_is_no_note() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, customerNote: nil, items: [item])
        let product = Product.fake().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let customerSection = viewModel.sections.first(where: { $0.category == .customerInformation })
        XCTAssertNotNil(customerSection)

        let customerNoteRow = customerSection?.rows.first(where: {
            if case .customerNote = $0 {
                return true
            }
            return false
        })
        XCTAssertNil(customerNoteRow)
    }

    func test_customerSection_contains_customer_note_cell_if_there_is_non_empty_note() {
        // Given
        let note = "Test"
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, customerNote: note, items: [item])
        let product = Product.fake().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let customerSection = viewModel.sections.first(where: { $0.category == .customerInformation })
        XCTAssertNotNil(customerSection)

        let customerNoteRow = customerSection?.rows.first(where: {
            if case .customerNote = $0 {
                return true
            }
            return false
        })
        XCTAssertNotNil(customerNoteRow)
    }

    func test_customerSection_does_not_contain_shipping_method_cell_if_there_is_no_shippingLines() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, items: [item], shippingLines: [])
        let product = Product.fake().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let customerSection = viewModel.sections.first(where: { $0.category == .customerInformation })
        XCTAssertNotNil(customerSection)

        let customerShippingMethodRow = customerSection?.rows.first(where: {
            if case .shippingMethod = $0 {
                return true
            }
            return false
        })
        XCTAssertNil(customerShippingMethodRow)
    }

    func test_customerSection_contains_shipping_method_cell_if_there_exist_shippingLines() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, items: [item], shippingLines: [ShippingLine.fake()])
        let product = Product.fake().copy(productID: productID)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let customerSection = viewModel.sections.first(where: { $0.category == .customerInformation })
        XCTAssertNotNil(customerSection)

        let customerShippingMethodRow = customerSection?.rows.first(where: {
            if case .shippingMethod = $0 {
                return true
            }
            return false
        })
        XCTAssertNotNil(customerShippingMethodRow)
    }

    func test_customerSection_does_not_contain_shipping_address_cell_if_there_are_only_virtual_products() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, items: [item])
        let product = Product.fake().copy(productID: productID, virtual: true)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let customerSection = viewModel.sections.first(where: { $0.category == .customerInformation })
        XCTAssertNotNil(customerSection)

        let customerAddressRow = customerSection?.rows.first(where: {
            if case .shippingAddress = $0 {
                return true
            }
            return false
        })
        XCTAssertNil(customerAddressRow)
    }

    func test_customerSection_does_not_contain_shipping_address_cell_if_there_is_virtual_product_and_shipping_address() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false)

        // Then
        let customerSection = viewModel.sections.first(where: { $0.category == .customerInformation })
        XCTAssertNotNil(customerSection)

        let customerAddressRow = customerSection?.rows.first(where: {
            if case .shippingAddress = $0 {
                return true
            }
            return false
        })
        XCTAssertNotNil(customerAddressRow)
    }

    func test_tracking_section_is_not_shown_when_there_is_nonrefunded_shipping_labels() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(siteID: siteID, orderID: orderID, refund: nil)
        insertShippingLabel(shippingLabel)
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false, storageManager: storageManager)
        viewModel.configureResultsControllers {}
        viewModel.syncTrackingsHidingAddButtonIfNecessary {}

        // Then
        XCTAssertNil(viewModel.sections.first(where: { $0.category == .tracking }))
    }

    func test_add_tracking_is_shown_when_there_is_no_nonrefunded_shipping_labels_and_tracking_is_reachable() {
        // Given
        let shippingLabel = ShippingLabel.fake().copy(siteID: siteID, orderID: orderID, refund: ShippingLabelRefund.fake())
        insertShippingLabel(shippingLabel)
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)
        let stores = MockShipmentActionStoresManager(syncSuccessfully: true)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false, stores: stores, storageManager: storageManager)
        viewModel.configureResultsControllers {}
        viewModel.syncTrackingsHidingAddButtonIfNecessary {}

        // Then
        let trackingSection = viewModel.sections.first(where: { $0.category == .tracking })
        XCTAssertNotNil(trackingSection)
        let addTrackingRow = trackingSection?.rows.first(where: {
            if case .trackingAdd = $0 {
                return true
            }
            return false
        })
        XCTAssertNotNil(addTrackingRow)
    }

    func test_add_tracking_is_shown_when_there_is_no_shipping_labels_and_tracking_is_reachable() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(orderID: orderID, status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)
        let stores = MockShipmentActionStoresManager(syncSuccessfully: true)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false, stores: stores)
        viewModel.configureResultsControllers {}
        viewModel.syncTrackingsHidingAddButtonIfNecessary {}

        // Then
        let trackingSection = viewModel.sections.first(where: { $0.category == .tracking })
        XCTAssertNotNil(trackingSection)
        let addTrackingRow = trackingSection?.rows.first(where: {
            if case .trackingAdd = $0 {
                return true
            }
            return false
        })
        XCTAssertNotNil(addTrackingRow)
    }

    func test_tracking_section_is_not_shown_when_tracking_is_not_reachable() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(orderID: orderID, status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)
        let stores = MockShipmentActionStoresManager(syncSuccessfully: false)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false, stores: stores)
        viewModel.configureResultsControllers {}
        viewModel.syncTrackingsHidingAddButtonIfNecessary {}

        // Then
        XCTAssertNil(viewModel.sections.first(where: { $0.category == .tracking }))
    }

    func test_no_tracking_row_is_shown_when_there_is_no_shipment_tracking() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(orderID: orderID, status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)
        let stores = MockShipmentActionStoresManager(syncSuccessfully: true)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false, stores: stores)
        viewModel.configureResultsControllers {}
        viewModel.syncTrackingsHidingAddButtonIfNecessary {}

        // Then
        let trackingSection = viewModel.sections.first(where: { $0.category == .tracking })
        XCTAssertNotNil(trackingSection)
        let trackingRow = trackingSection?.rows.first(where: {
            if case .tracking = $0 {
                return true
            }
            return false
        })
        XCTAssertNil(trackingRow)
    }

    func test_tracking_row_is_shown_when_there_is_shipment_tracking() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(siteID: siteID, orderID: orderID, status: .processing, items: [item], shippingAddress: Address.fake())
        let product = Product.fake().copy(productID: productID, virtual: false)
        let stores = MockShipmentActionStoresManager(syncSuccessfully: true)
        let shipmentTracking = ShipmentTracking.fake().copy(siteID: siteID, orderID: orderID, dateShipped: Date())
        insertShipmentTracking(shipmentTracking)

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: false, stores: stores, storageManager: storageManager)
        viewModel.configureResultsControllers {}
        viewModel.syncTrackingsHidingAddButtonIfNecessary {}

        // Then
        let trackingSection = viewModel.sections.first(where: { $0.category == .tracking })
        XCTAssertNotNil(trackingSection)
        let trackingRow = trackingSection?.rows.first(where: {
            if case .tracking = $0 {
                return true
            }
            return false
        })
        XCTAssertNotNil(trackingRow)
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

    func insertShippingLabel(_ readOnlyLabel: ShippingLabel) {
        let storageLabel = storage.insertNewObject(ofType: StorageShippingLabel.self)
        storageLabel.update(with: readOnlyLabel)
        if let readOnlyRefund = readOnlyLabel.refund {
            let storageRefund = storage.insertNewObject(ofType: StorageShippingLabelRefund.self)
            storageRefund.update(with: readOnlyRefund)
            storageLabel.refund = storageRefund
        }
        storage.saveIfNeeded()
    }

    func insertShipmentTracking(_ readOnlyTracking: ShipmentTracking) {
        let storageTracking = storage.insertNewObject(ofType: StorageShipmentTracking.self)
        storageTracking.update(with: readOnlyTracking)
        storage.saveIfNeeded()
    }
}
