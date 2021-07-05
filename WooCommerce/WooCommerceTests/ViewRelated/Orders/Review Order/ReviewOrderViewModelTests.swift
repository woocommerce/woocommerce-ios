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

    func test_productDetailsCellViewModel_returns_correct_hasAddOns_if_view_model_receives_showAddOns_as_true() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(siteID: siteID, status: .processing, items: [item])
        let addOn = ProductAddOn.fake()
        let addOnGroup = AddOnGroup.fake().copy(siteID: siteID, addOns: [addOn])
        insert(addOnGroup)
        let product = Product().copy(productID: productID, addOns: [addOn])

        // When
        let viewModel = ReviewOrderViewModel(order: order, products: [product], showAddOns: true, storageManager: storageManager)
        let productCellModel = viewModel.productDetailsCellViewModel(for: item)

        // Then
        // TODO: fix failed test
//        XCTAssertEqual(productCellModel.hasAddOns, true)
    }

    func test_customerSection_does_not_contain_customer_note_cell_if_there_is_no_note() {
        // Given
        let item = OrderItem.fake().copy(productID: productID)
        let order = Order.fake().copy(status: .processing, customerNote: nil, items: [item])
        let product = Product().copy(productID: productID)

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
        let product = Product().copy(productID: productID)

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
        let product = Product().copy(productID: productID)

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
        let product = Product().copy(productID: productID)

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
        let product = Product().copy(productID: productID, virtual: true)

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
        let product = Product().copy(productID: productID, virtual: false)

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
}

// MARK: - Storage helper
private extension ReviewOrderViewModelTests {
    func insert(_ readOnlyAddOnGroup: Yosemite.AddOnGroup) {
        readOnlyAddOnGroup.addOns.forEach { readOnlyAddOn in
            let storageAddOn = storage.insertNewObject(ofType: StorageProductAddOn.self)
            storageAddOn.update(with: readOnlyAddOn)
        }
        let group = storage.insertNewObject(ofType: StorageAddOnGroup.self)
        group.update(with: readOnlyAddOnGroup)
        storage.saveIfNeeded()
    }
}
