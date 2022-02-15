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
        XCTAssertFalse(viewModel.shouldShowPaymentSection)
    }

    func test_create_button_is_enabled_when_order_detail_changes_from_default_value() {
        // Given
        let viewModel = NewOrderViewModel(siteID: sampleSiteID)

        // When
        viewModel.updateOrderStatus(newStatus: .processing)

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

    func test_view_is_disabled_during_network_request() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let isViewDisabled: Bool = waitFor { promise in
            stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(viewModel.disabled)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.createOrder()
        }

        // Then
        XCTAssertTrue(isViewDisabled)
    }

    func test_create_button_is_enabled_after_the_network_operation_completes() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        viewModel.updateOrderStatus(newStatus: .processing)
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
        XCTAssertEqual(viewModel.notice, NewOrderViewModel.NoticeFactory.createOrderCreationErrorNotice())
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
        viewModel.updateOrderStatus(newStatus: .processing)

        // Then
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "Processing")
    }

    func test_view_model_is_updated_when_product_is_added_to_order() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.addProductViewModel.selectProduct(product.productID)

        // Then
        let expectedOrderItem = NewOrderViewModel.NewOrderItem(product: product, quantity: 1).orderItem
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productOrVariationID == sampleProductID }), "Product rows do not contain expected product")
        XCTAssertTrue(viewModel.orderDetails.items.contains(where: { $0.orderItem == expectedOrderItem }), "Order details do not contain expected order item")
    }

    func test_order_details_are_updated_when_product_quantity_changes() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        viewModel.addProductViewModel.selectProduct(product.productID)
        viewModel.productRows[0].incrementQuantity()

        // And when another product is added to the order (to confirm the first product's quantity change is retained)
        viewModel.addProductViewModel.selectProduct(product.productID)

        // Then
        let expectedOrderItem = NewOrderViewModel.NewOrderItem(product: product, quantity: 2).orderItem
        XCTAssertTrue(viewModel.orderDetails.items.contains(where: { $0.orderItem == expectedOrderItem }),
                      "Order details do not contain order item with updated quantity")
    }

    func test_selectOrderItem_selects_expected_order_item() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
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
        let product0 = Product.fake().copy(siteID: sampleSiteID, productID: 0, purchasable: true)
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
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
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productOrVariationID == product0.productID }))
        XCTAssertEqual(viewModel.orderDetails.items, [expectedRemainingItem])
    }

    func test_createProductRowViewModel_creates_expected_row_for_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID)
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let newOrderItem = NewOrderViewModel.NewOrderItem(product: product, quantity: 1)
        let productRow = viewModel.createProductRowViewModel(for: newOrderItem, canChangeQuantity: true)

        // Then
        let expectedProductRow = ProductRowViewModel(product: product, canChangeQuantity: true)
        XCTAssertEqual(productRow?.name, expectedProductRow.name)
        XCTAssertEqual(productRow?.quantity, expectedProductRow.quantity)
        XCTAssertEqual(productRow?.canChangeQuantity, expectedProductRow.canChangeQuantity)
    }

    func test_createProductRowViewModel_creates_expected_row_for_product_variation() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, productTypeKey: "variable", variations: [33])
        let productVariation = ProductVariation.fake().copy(siteID: sampleSiteID,
                                                            productID: sampleProductID,
                                                            productVariationID: 33,
                                                            sku: "product-variation")
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: productVariation, on: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let newOrderItem = NewOrderViewModel.NewOrderItem(variation: productVariation, quantity: 2)
        let productRow = viewModel.createProductRowViewModel(for: newOrderItem, canChangeQuantity: false)

        // Then
        let expectedProductRow = ProductRowViewModel(productVariation: productVariation,
                                                     name: product.name,
                                                     quantity: 2,
                                                     canChangeQuantity: false,
                                                     displayMode: .stock)
        XCTAssertEqual(productRow?.name, expectedProductRow.name)
        XCTAssertEqual(productRow?.skuLabel, expectedProductRow.skuLabel)
        XCTAssertEqual(productRow?.quantity, expectedProductRow.quantity)
        XCTAssertEqual(productRow?.canChangeQuantity, expectedProductRow.canChangeQuantity)
    }

    func test_view_model_is_updated_when_address_updated() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, stores: stores)
        let addressViewModel = viewModel.createOrderAddressFormViewModel()
        XCTAssertFalse(viewModel.customerDataViewModel.isDataAvailable)

        // When
        addressViewModel.fields.firstName = sampleAddress1().firstName
        addressViewModel.fields.lastName = sampleAddress1().lastName
        addressViewModel.saveAddress(onFinish: { _ in })

        // Then
        XCTAssertTrue(viewModel.customerDataViewModel.isDataAvailable)
        XCTAssertEqual(viewModel.customerDataViewModel.fullName, sampleAddress1().fullName)
    }

    func test_customer_data_view_model_is_initialized_correctly_from_addresses() {
        // Given
        let sampleAddressWithoutNameAndEmail = sampleAddress2()

        // When
        let customerDataViewModel = NewOrderViewModel.CustomerDataViewModel(billingAddress: sampleAddressWithoutNameAndEmail,
                                                                            shippingAddress: nil)

        // Then
        XCTAssertTrue(customerDataViewModel.isDataAvailable)
        XCTAssertNil(customerDataViewModel.fullName)
        XCTAssertNil(customerDataViewModel.email)
        XCTAssertNotNil(customerDataViewModel.billingAddressFormatted)
        XCTAssertNil(customerDataViewModel.shippingAddressFormatted)
    }

    func test_payment_data_view_model_is_initialized_with_expected_values() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let itemsTotal = "20.00"
        let orderTotal = "30.00"

        // When
        let paymentDataViewModel = NewOrderViewModel.PaymentDataViewModel(itemsTotal: itemsTotal,
                                                                          orderTotal: orderTotal,
                                                                          currencyFormatter: CurrencyFormatter(currencySettings: currencySettings))

        // Then
        XCTAssertEqual(paymentDataViewModel.itemsTotal, "£20.00")
        XCTAssertEqual(paymentDataViewModel.orderTotal, "£30.00")
    }

    func test_payment_section_only_displayed_when_order_has_products() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When & Then
        viewModel.addProductViewModel.selectProduct(product.productID)
        XCTAssertTrue(viewModel.shouldShowPaymentSection)

        // When & Then
        viewModel.removeItemFromOrder(viewModel.orderDetails.items[0])
        XCTAssertFalse(viewModel.shouldShowPaymentSection)
    }

    func test_payment_section_is_updated_when_products_update() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        let storageManager = MockStorageManager()
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = NewOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, currencySettings: currencySettings)

        // When & Then
        viewModel.addProductViewModel.selectProduct(product.productID)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£8.50")

        // When & Then
        viewModel.productRows[0].incrementQuantity()
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£17.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£17.00")
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

private extension NewOrderViewModelTests {
    func sampleAddress1() -> Address {
        return Address(firstName: "Johnny",
                       lastName: "Appleseed",
                       company: nil,
                       address1: "234 70th Street",
                       address2: nil,
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "scrambled@scrambled.com")
    }

    func sampleAddress2() -> Address {
        return Address(firstName: "",
                       lastName: "",
                       company: "Automattic",
                       address1: "234 70th Street",
                       address2: nil,
                       city: "Niagara Falls",
                       state: "NY",
                       postcode: "14304",
                       country: "US",
                       phone: "333-333-3333",
                       email: "")
    }
}
