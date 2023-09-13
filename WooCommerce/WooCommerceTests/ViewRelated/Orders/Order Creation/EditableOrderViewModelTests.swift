import XCTest
@testable import WooCommerce
import Yosemite
import WooFoundation
import Networking

final class EditableOrderViewModelTests: XCTestCase {
    var viewModel: EditableOrderViewModel!
    var stores: MockStoresManager!
    var storageManager: MockStorageManager!

    let sampleSiteID: Int64 = 123
    let sampleOrderID: Int64 = 1234
    let sampleProductID: Int64 = 5

    override func setUp() {
        super.setUp()
        stores = MockStoresManager(sessionManager: .testingInstance)
        storageManager = MockStorageManager()
        viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager)
    }

    // MARK: - Initialization

    func test_view_model_inits_with_expected_values() {
        // Then
        XCTAssertEqual(viewModel.flow, .creation)
        XCTAssertEqual(viewModel.navigationTrailingItem, .create)
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "pending")
        XCTAssertEqual(viewModel.productRows.count, 0)
    }

    func test_createProductSelectorViewModelWithOrderItemsSelected_returns_instance_initialized_with_expected_values() {
        // Then
        XCTAssertFalse(viewModel.createProductSelectorViewModelWithOrderItemsSelected().toggleAllVariationsOnSelection)
    }

    func test_edition_view_model_inits_with_expected_values() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // Then
        XCTAssertEqual(viewModel.flow, .editing(initialOrder: order))
    }

    // MARK: - Navigation

    func test_edition_view_model_has_a_navigation_done_button() {
        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: .fake()), stores: stores)

        // Then
        XCTAssertEqual(viewModel.navigationTrailingItem, .done)
    }

    func test_edition_view_model_has_a_navigation_loading_item_when_synching() {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let navigationItemDuringSync: EditableOrderViewModel.NavigationItem = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder:
                    promise(viewModel.navigationTrailingItem)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // Trigger remote sync
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertEqual(navigationItemDuringSync, .loading)
    }

    func test_loading_indicator_is_enabled_during_network_request() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let navigationItem: EditableOrderViewModel.NavigationItem = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
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
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let isViewDisabled: Bool = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
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
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

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
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        let error = NSError(domain: "Error", code: 0)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createOrder(_, _, onCompletion):
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.createOrder()

        // Then
        XCTAssertEqual(viewModel.fixedNotice, EditableOrderViewModel.NoticeFactory.createOrderErrorNotice(error, order: .fake()))
    }

    func test_view_model_fires_error_notice_when_order_sync_fails() {
        // Given
        let synchronizer = RemoteOrderSynchronizer(siteID: sampleSiteID, flow: .creation, stores: stores)
        let error = NSError(domain: "Error", code: 0)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        waitForExpectation { expectation in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, _, onCompletion):
                    onCompletion(.failure(error))
                    expectation.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When remote sync is triggered
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertEqual(viewModel.fixedNotice, EditableOrderViewModel.NoticeFactory.syncOrderErrorNotice(error, flow: .creation, with: synchronizer))
    }

    func test_view_model_fires_error_notice_when_order_sync_fails_because_of_coupons() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        waitForExpectation { expectation in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, _, onCompletion):
                    onCompletion(.failure(DotcomError.unknown(code: "woocommerce_rest_invalid_coupon", message: "")))
                    expectation.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When remote sync is triggered
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertEqual(viewModel.fixedNotice?.title, NSLocalizedString("Unable to add coupon.", comment: ""))
        XCTAssertEqual(viewModel.fixedNotice?.message, NSLocalizedString("Sorry, this coupon is not applicable to selected products.", comment: ""))
    }

    func test_view_model_clears_error_notice_when_order_is_syncing() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        let error = NSError(domain: "Error", code: 0)
        viewModel.fixedNotice = EditableOrderViewModel.NoticeFactory.createOrderErrorNotice(error, order: .fake())

        // When
        let notice: Notice? = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(viewModel.fixedNotice)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            // Remote sync is triggered
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertNil(notice)
    }

    func test_view_model_loads_synced_pending_order_status() {
        // Given
        storageManager.insertOrderStatus(.init(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 0))

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "Pending payment")
    }

    func test_view_model_is_updated_when_order_status_updated() {
        // Given
        storageManager.insertOrderStatus(.init(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 0))
        storageManager.insertOrderStatus(.init(name: "Processing", siteID: sampleSiteID, slug: "processing", total: 0))

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

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
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertTrue(viewModel.productRows.contains(where: { $0.productOrVariationID == sampleProductID }), "Product rows do not contain expected product")
    }

    func test_order_details_are_updated_when_product_quantity_changes() {
        // Given

        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        let anotherProduct = Product.fake().copy(siteID: sampleSiteID, productID: 123456, purchasable: true)

        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProduct(readOnlyProduct: anotherProduct)

        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.changeSelectionStateForProduct(with: anotherProduct.productID)
        productSelectorViewModel.completeMultipleSelection()
        // And when another product is added to the order (to confirm the first product's quantity change is retained)
        viewModel.productRows[0].incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.productRows[safe: 0]?.quantity, 2)
        XCTAssertEqual(viewModel.productRows[safe: 1]?.quantity, 1)
    }

    func test_product_is_removed_when_quantity_is_decremented_below_1() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // Product quantity is 1
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()
        XCTAssertEqual(viewModel.productRows[0].quantity, 1)

        // When
        viewModel.productRows[0].decrementQuantity()

        // Then
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productOrVariationID == product.productID }))
    }

    func test_selectOrderItem_selects_expected_order_item() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let expectedRow = viewModel.productRows[0]
        viewModel.selectOrderItem(expectedRow.id)

        // Then
        XCTAssertNotNil(viewModel.selectedProductViewModel)
        XCTAssertEqual(viewModel.selectedProductViewModel?.productRowViewModel.id, expectedRow.id)
    }

    func test_view_model_is_updated_when_product_is_removed_from_order() {
        // Given
        let product0 = Product.fake().copy(siteID: sampleSiteID, productID: 0, purchasable: true)
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        storageManager.insertProducts([product0, product1])
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // Given products are added to order
        productSelectorViewModel.changeSelectionStateForProduct(with: product0.productID)
        productSelectorViewModel.changeSelectionStateForProduct(with: product1.productID)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let expectedRemainingRow = viewModel.productRows[1]
        let itemToRemove = OrderItem.fake().copy(itemID: viewModel.productRows[0].id)
        viewModel.removeItemFromOrder(itemToRemove)

        // Then
        XCTAssertFalse(viewModel.productRows.contains(where: { $0.productOrVariationID == product0.productID }))
        XCTAssertEqual(viewModel.productRows.map { $0.id }, [expectedRemainingRow].map { $0.id })
    }

    func test_createProductRowViewModel_creates_expected_row_for_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(name: product.name, productID: product.productID, quantity: 1)
        let productRow = viewModel.createProductRowViewModel(for: orderItem, canChangeQuantity: true)

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
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: productVariation, on: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(name: product.name,
                                              productID: product.productID,
                                              variationID: productVariation.productVariationID,
                                              quantity: 2)
        let productRow = viewModel.createProductRowViewModel(for: orderItem, canChangeQuantity: false)

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
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        XCTAssertFalse(viewModel.customerDataViewModel.isDataAvailable)

        // When
        viewModel.addressFormViewModel.fields.firstName = sampleAddress1().firstName
        viewModel.addressFormViewModel.fields.lastName = sampleAddress1().lastName
        viewModel.addressFormViewModel.saveAddress(onFinish: { _ in })

        // Then
        XCTAssertTrue(viewModel.customerDataViewModel.isDataAvailable)
        XCTAssertEqual(viewModel.customerDataViewModel.fullName, sampleAddress1().fullName)
    }

    func test_customer_data_view_model_is_initialized_correctly_from_addresses() {
        // Given
        let sampleAddressWithoutNameAndEmail = sampleAddress2()

        // When
        let customerDataViewModel = EditableOrderViewModel.CustomerDataViewModel(billingAddress: sampleAddressWithoutNameAndEmail,
                                                                            shippingAddress: nil)

        // Then
        XCTAssertTrue(customerDataViewModel.isDataAvailable)
        XCTAssertNil(customerDataViewModel.fullName)
        XCTAssertNotNil(customerDataViewModel.billingAddressFormatted)
        XCTAssertNil(customerDataViewModel.shippingAddressFormatted)
    }

    func test_customer_data_view_model_is_initialized_correctly_from_empty_input() {
        // Given
        let customerDataViewModel = EditableOrderViewModel.CustomerDataViewModel(billingAddress: Address.empty, shippingAddress: Address.empty)

        // Then
        XCTAssertFalse(customerDataViewModel.isDataAvailable)
        XCTAssertNil(customerDataViewModel.fullName)
        XCTAssertEqual(customerDataViewModel.billingAddressFormatted, "")
        XCTAssertEqual(customerDataViewModel.shippingAddressFormatted, "")
    }

    func test_customer_data_view_model_is_initialized_correctly_with_only_phone() {
        // Given
        let addressWithOnlyPhone = Address.fake().copy(phone: "123-456-7890")

        // When
        let customerDataViewModel = EditableOrderViewModel.CustomerDataViewModel(billingAddress: addressWithOnlyPhone, shippingAddress: Address.empty)

        // Then
        XCTAssertTrue(customerDataViewModel.isDataAvailable)
        XCTAssertNil(customerDataViewModel.fullName)
        XCTAssertEqual(customerDataViewModel.billingAddressFormatted, "")
        XCTAssertEqual(customerDataViewModel.shippingAddressFormatted, "")
    }

    func test_payment_data_view_model_is_initialized_with_expected_values() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)

        // When
        let paymentDataViewModel = EditableOrderViewModel.PaymentDataViewModel(itemsTotal: "20.00",
                                                                          shippingTotal: "3.00",
                                                                          feesTotal: "2.00",
                                                                          taxesTotal: "5.00",
                                                                          orderTotal: "30.00",
                                                                          currencyFormatter: CurrencyFormatter(currencySettings: currencySettings))

        // Then
        XCTAssertEqual(paymentDataViewModel.itemsTotal, "£20.00")
        XCTAssertEqual(paymentDataViewModel.shippingTotal, "£3.00")
        XCTAssertEqual(paymentDataViewModel.feesTotal, "£2.00")
        XCTAssertEqual(paymentDataViewModel.taxesTotal, "£5.00")
        XCTAssertEqual(paymentDataViewModel.orderTotal, "£30.00")
    }

    func test_payment_data_view_model_is_initialized_with_expected_default_values_for_new_order() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.taxesTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£0.00")
    }

    func test_payment_data_view_model_when_calling_onGoToCouponsClosure_then_calls_to_track_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.paymentDataViewModel.onGoToCouponsClosure()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderGoToCouponsButtonTapped.rawValue)
    }

    func test_payment_data_view_model_when_calling_onTaxHelpButtonTappedClosure_then_calls_to_track_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.paymentDataViewModel.onTaxHelpButtonTappedClosure()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderTaxHelpButtonTapped.rawValue)
    }

    func test_payment_data_view_model_when_calling_onSetNewTaxRateTapped_then_calls_to_track_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.onSetNewTaxRateTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderCreationSetNewTaxRateTapped.rawValue)
    }

    // MARK: - Add Products to Order via SKU Scanner Tests

    func test_trackBarcodeScanningButtonTapped_tracks_right_event() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackBarcodeScanningButtonTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderCreationProductBarcodeScanningTapped.rawValue)
    }

    func test_trackBarcodeScanningNotPermitted_tracks_right_event() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.trackBarcodeScanningNotPermitted()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.barcodeScanningFailure.rawValue)
        XCTAssertEqual(analytics.receivedProperties.first?["reason"] as? String, "camera_access_not_permitted")
        XCTAssertEqual(analytics.receivedProperties.first?["source"] as? String, "order_creation")
    }

    func test_add_product_to_order_via_sku_scanner_when_feature_flag_is_enabled_then_feature_support_returns_true() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, featureFlagService: MockFeatureFlagService(isAddProductToOrderViaSKUScannerEnabled: true))

        // Then
        XCTAssertTrue(viewModel.isAddProductToOrderViaSKUScannerEnabled)
    }

    func test_add_product_to_order_via_sku_scanner_feature_flag_is_disabled_then_feature_support_returns_false() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, featureFlagService: MockFeatureFlagService(isAddProductToOrderViaSKUScannerEnabled: false))

        // Then
        XCTAssertFalse(viewModel.isAddProductToOrderViaSKUScannerEnabled)
    }

    // MARK: - Payment Section Tests

    func test_payment_section_is_updated_when_products_update() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When & Then
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£8.50")

        // When & Then
        viewModel.productRows[0].incrementQuantity()
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£17.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£17.00")
    }

    func test_payment_section_is_updated_when_shipping_line_updated() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()
        let testShippingLine = ShippingLine(shippingID: 0,
                                            methodTitle: "Flat Rate",
                                            methodID: "other",
                                            total: "10",
                                            totalTax: "",
                                            taxes: [])
        viewModel.saveShippingLine(testShippingLine)

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "£10.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£18.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 18.50)

        // When
        viewModel.saveShippingLine(nil)

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)
    }

    func test_payment_section_is_updated_when_fee_line_updated() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()
        viewModel.saveFeeLine("10")

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowFees)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "£10.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£18.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)

        // When
        viewModel.saveFeeLine(nil)

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowFees)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)
    }

    func test_payment_section_is_updated_when_coupon_line_updated() throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        let couponCode = "COUPONCODE"
        viewModel.saveCouponLine(result: .added(newCode: couponCode))

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowCoupon)
        let couponLineViewModel = try XCTUnwrap(viewModel.paymentDataViewModel.couponLineViewModels.first)
        XCTAssertEqual(couponLineViewModel.title, "Coupon (\(couponCode))")
        XCTAssertEqual(viewModel.paymentDataViewModel.couponCode, "COUPONCODE")

        // When
        viewModel.saveCouponLine(result: .removed(code: couponCode))

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowCoupon)
        XCTAssertTrue(viewModel.paymentDataViewModel.couponLineViewModels.isEmpty)
    }

    func test_payment_section_values_correct_when_shipping_line_is_negative() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        let testShippingLine = ShippingLine(shippingID: 0,
                                            methodTitle: "Flat Rate",
                                            methodID: "other",
                                            total: "-5",
                                            totalTax: "",
                                            taxes: [])
        viewModel.saveShippingLine(testShippingLine)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "-£5.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£3.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 3.50)

        // When
        viewModel.saveShippingLine(nil)

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)
    }

    func test_payment_section_values_correct_when_fee_line_is_negative() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        viewModel.saveFeeLine( "-5")
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowFees)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "-£5.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£3.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)

        // When
        viewModel.saveFeeLine(nil)

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowFees)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)
    }

    func test_payment_section_is_correct_when_shipping_line_and_fee_line_are_added() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()

        let testShippingLine = ShippingLine(shippingID: 0,
                                            methodTitle: "Flat Rate",
                                            methodID: "other",
                                            total: "-5",
                                            totalTax: "",
                                            taxes: [])
        viewModel.saveShippingLine(testShippingLine)
        viewModel.saveFeeLine("10")

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "-£5.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£13.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "£10.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 3.50)

        // When
        viewModel.saveShippingLine(nil)

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowShippingTotal)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.shippingTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.orderTotal, "£18.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesTotal, "£10.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 8.50)
    }

    func test_payment_section_loading_indicator_is_enabled_while_order_syncs() {
        // When
        let isLoadingDuringSync: Bool = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, _, onCompletion):
                    promise(self.viewModel.paymentDataViewModel.isLoading)
                    onCompletion(.success(.fake()))
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            // Trigger remote sync
            self.viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertTrue(isLoadingDuringSync)
        XCTAssertFalse(viewModel.paymentDataViewModel.isLoading) // Disabled after sync ends
    }

    func test_payment_section_loading_indicator_is_disabled_while_non_editable_order_syncs() {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID, isEditable: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let isPaymentsLoadingVisible: Bool = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder:
                    promise(viewModel.paymentDataViewModel.isLoading)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            // Trigger remote sync
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertFalse(isPaymentsLoadingVisible)
    }

    func test_payment_section_is_updated_when_order_has_taxes() {
        // Given
        let expectation = expectation(description: "Order with taxes is synced")
        let currencySettings = CurrencySettings()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, currencySettings: currencySettings)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .createOrder(_, _, onCompletion):
                let order = Order.fake().copy(siteID: self.sampleSiteID, totalTax: "2.50")
                onCompletion(.success(order))
                expectation.fulfill()
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        // Trigger remote sync
        viewModel.saveShippingLine(ShippingLine.fake())

        // Then
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertEqual(viewModel.paymentDataViewModel.taxesTotal, "$2.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.feesBaseAmountForPercentage, 2.50)

    }

    // MARK: - hasChanges Tests

    func test_hasChanges_returns_false_initially() {
        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertFalse(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_product_quantity_changes() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_order_status_is_updated() {
        // When
        viewModel.updateOrderStatus(newStatus: .completed)

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_customer_information_is_updated() {
        // When
        viewModel.addressFormViewModel.fields.firstName = sampleAddress1().firstName
        viewModel.addressFormViewModel.fields.lastName = sampleAddress1().lastName
        viewModel.addressFormViewModel.saveAddress(onFinish: { _ in })

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_customer_note_is_updated() {
        //When
        viewModel.noteViewModel.newNote = "Test"
        viewModel.updateCustomerNote()

        //Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_shipping_line_is_updated() {
        // Given
        let shippingLine = ShippingLine.fake()

        // When
        viewModel.saveShippingLine(shippingLine)

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_fee_line_is_updated() {
        // When
        viewModel.saveFeeLine("10")

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_coupon_line_is_updated() {
        // When
        viewModel.saveCouponLine(result: .added(newCode: "TESTCOUPON"))

        // Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    // MARK: - Tracking Tests

    func test_product_is_tracked_when_added() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertTrue(analytics.receivedEvents.contains(where: { $0.description == WooAnalyticsStat.orderProductAdd.rawValue}))

        guard let eventIndex = analytics.receivedEvents.firstIndex(where: { $0.description == WooAnalyticsStat.orderProductAdd.rawValue}) else {
            return XCTFail("No event received")
        }

        let eventProperties = analytics.receivedProperties[eventIndex]

        XCTAssertEqual(eventProperties["flow"] as? String, "creation")
        XCTAssertEqual(eventProperties["source"] as? String, "order_creation")
        XCTAssertEqual(eventProperties["added_via"] as? String, "manually")
    }

    func test_product_is_tracked_when_quantity_changes() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: .fake()),
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID)
        productSelectorViewModel.completeMultipleSelection()
        viewModel.productRows[0].incrementQuantity()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [
            WooAnalyticsStat.orderCreationProductSelectorItemSelected.rawValue,
            WooAnalyticsStat.orderProductAdd.rawValue,
            WooAnalyticsStat.orderProductQuantityChange.rawValue]
        )

        let properties = try XCTUnwrap(analytics.receivedProperties.last?["flow"] as? String)
        XCTAssertEqual(properties, "editing")
    }

    func test_product_is_tracked_when_removed_from_order() throws {
        // Given
        let product0 = Product.fake().copy(siteID: sampleSiteID, productID: 0, purchasable: true)
        storageManager.insertProducts([product0])
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))
        let productSelectorViewModel = viewModel.createProductSelectorViewModelWithOrderItemsSelected()

        // Given products are added to order
        productSelectorViewModel.changeSelectionStateForProduct(with: product0.productID)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let itemToRemove = OrderItem.fake().copy(itemID: viewModel.productRows[0].id)
        viewModel.removeItemFromOrder(itemToRemove)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [
            WooAnalyticsStat.orderCreationProductSelectorItemSelected.rawValue,
            WooAnalyticsStat.orderProductAdd.rawValue,
            WooAnalyticsStat.orderProductRemove.rawValue]
        )

        let properties = try XCTUnwrap(analytics.receivedProperties.last?["flow"] as? String)
        XCTAssertEqual(properties, "creation")
    }

    func test_product_selector_source_is_tracked_when_product_selector_clear_selection_button_is_tapped() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.createProductSelectorViewModelWithOrderItemsSelected().clearSelection()

        // Then
        XCTAssertTrue(analytics.receivedEvents.contains(where: {
            $0.description == WooAnalyticsStat.orderCreationProductSelectorClearSelectionButtonTapped.rawValue })
        )

        guard let eventIndex = analytics.receivedEvents.firstIndex(where: {
            $0.description == WooAnalyticsStat.orderCreationProductSelectorClearSelectionButtonTapped.rawValue }) else {
            return XCTFail("No event received")
        }

        let eventProperties = analytics.receivedProperties[eventIndex]
        guard let event = eventProperties.first(where: { $0.key as? String == "source"}) else {
            return XCTFail("No property received")
        }

        XCTAssertEqual(event.value as? String, "product_selector")
    }

    func test_shipping_method_tracked_when_added() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        let shippingLine = ShippingLine.fake()

        // When
        viewModel.saveShippingLine(shippingLine)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderShippingMethodAdd.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "creation")
    }

    func test_shipping_method_tracked_when_removed() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: .fake()),
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.saveShippingLine(nil)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderShippingMethodRemove.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "editing")
    }

    func test_fee_line_tracked_when_added() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.saveFeeLine("10")

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderFeeAdd.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "creation")
    }

    func test_fee_line_tracked_when_removed() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: .fake()),
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.saveFeeLine(nil)

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderFeeRemove.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "editing")
    }

    func test_coupon_line_tracked_when_added() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.saveCouponLine(result: .added(newCode: "TESTCOUPON"))

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCouponAdd.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "creation")
    }

    func test_coupon_line_tracked_when_removed() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: .fake()),
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.saveCouponLine(result: .removed(code: "TESTCOUPON"))

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCouponRemove.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        XCTAssertEqual(properties, "editing")
    }

    func test_customer_details_tracked_when_added() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.addressFormViewModel.fields.address1 = sampleAddress1().address1
        viewModel.addressFormViewModel.showDifferentAddressForm = true
        viewModel.addressFormViewModel.saveAddress(onFinish: { _ in })

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCustomerAdd.rawValue])

        let flowProperty = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        let hasDifferentShippingDetailsProperty = try XCTUnwrap(analytics.receivedProperties.first?["has_different_shipping_details"] as? Bool)
        XCTAssertEqual(flowProperty, "creation")
        XCTAssertTrue(hasDifferentShippingDetailsProperty)
    }

    func test_customer_details_tracked_when_only_billing_address_added() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: .fake()),
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.addressFormViewModel.fields.address1 = sampleAddress1().address1
        viewModel.addressFormViewModel.saveAddress(onFinish: { _ in })

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCustomerAdd.rawValue])

        let flowProperty = try XCTUnwrap(analytics.receivedProperties.first?["flow"] as? String)
        let hasDifferentShippingDetailsProperty = try XCTUnwrap(analytics.receivedProperties.first?["has_different_shipping_details"] as? Bool)
        XCTAssertEqual(flowProperty, "editing")
        XCTAssertFalse(hasDifferentShippingDetailsProperty)
    }

    func test_customer_details_not_tracked_when_removed() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.addressFormViewModel.fields.address1 = ""
        viewModel.addressFormViewModel.saveAddress(onFinish: { _ in })

        // Then
        XCTAssertTrue(analytics.receivedEvents.isEmpty)
    }

    func test_customer_note_tracked_when_added() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.noteViewModel.newNote = "Test"
        viewModel.updateCustomerNote()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderNoteAdd.rawValue])

        let properties = try XCTUnwrap(analytics.receivedProperties.first)
        XCTAssertEqual(properties["flow"] as? String, "creation")
        XCTAssertEqual(properties["parent_id"] as? Int64, 0)
        XCTAssertEqual(properties["status"] as? String, "pending")
        XCTAssertEqual(properties["type"] as? String, "customer")
    }

    func test_customer_note_not_tracked_when_removed() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.noteViewModel.newNote = ""
        viewModel.updateCustomerNote()

        // Then
        XCTAssertTrue(analytics.receivedEvents.isEmpty)
    }

    func test_sync_failure_tracked_when_sync_fails() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        waitForExpectation { expectation in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, _, onCompletion):
                    onCompletion(.failure(NSError(domain: "Error", code: 0)))
                    expectation.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When remote sync is triggered
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // Then
        XCTAssertTrue(analytics.receivedEvents.contains(WooAnalyticsStat.orderSyncFailed.rawValue))

        let indexOfEvent = try XCTUnwrap(analytics.receivedEvents.firstIndex(where: { $0 == WooAnalyticsStat.orderSyncFailed.rawValue}))
        let eventProperties = try XCTUnwrap(analytics.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["flow"] as? String, "creation")
    }

    // MARK: -

    func test_customer_note_section_is_updated_when_note_is_added_to_order() {
        // Given
        let expectedCustomerNote = "Test"

        //When
        viewModel.noteViewModel.newNote = expectedCustomerNote
        viewModel.updateCustomerNote()

        //Then
        XCTAssertEqual(viewModel.customerNoteDataViewModel.customerNote, expectedCustomerNote)
    }

    func test_discard_order_deletes_order_if_order_exists_remotely() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        waitForExpectation { expectation in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder(_, let order, let completion):
                    completion(.success(order.copy(orderID: 12)))
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            // Trigger remote sync
            viewModel.saveShippingLine(ShippingLine.fake())
        }

        // When
        let orderDeleted: Bool = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .deleteOrder:
                    promise(true)
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            viewModel.discardOrder()
        }

        // Then
        XCTAssertTrue(orderDeleted)
    }

    func test_discard_order_skips_remote_deletion_for_local_order() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            XCTFail("Unexpected action: \(action)")
        }

        // When
        viewModel.discardOrder()
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_customerBillingAddress_then_returns_true() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerBillingAddress))
            default:
                break
            }
        })

        stores.whenReceivingAction(ofType: AppSettingsAction.self, thenCall: { action in
            switch action {
            case .loadSelectedTaxRateID(_, let onCompletion):
                onCompletion(nil)
            default:
                break
            }
        })

        let featureFlagService = MockFeatureFlagService(manualTaxesInOrderM2: true)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)

        // Then
        waitUntil {
            viewModel.shouldShowNewTaxRateSection
        }
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_customerShippingAddress_then_returns_true() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerShippingAddress))
            default:
                break
            }
        })

        stores.whenReceivingAction(ofType: AppSettingsAction.self, thenCall: { action in
            switch action {
            case .loadSelectedTaxRateID(_, let onCompletion):
                onCompletion(nil)
            default:
                break
            }
        })

        let featureFlagService = MockFeatureFlagService(manualTaxesInOrderM2: true)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)

        // Then
        waitUntil {
            viewModel.shouldShowNewTaxRateSection
        }
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_shopBaseAddress_then_returns_true() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.shopBaseAddress))
            default:
                break
            }
        })

        let featureFlagService = MockFeatureFlagService(manualTaxesInOrderM2: true)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)

        // Then
        XCTAssertFalse(viewModel.shouldShowNewTaxRateSection)
    }

    func test_viewModel_when_taxRate_is_stored_then_resets_addressFormViewModel_fields_with_new_data() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerBillingAddress))
            default:
                break
            }
        })

        stores.whenReceivingAction(ofType: AppSettingsAction.self, thenCall: { action in
            switch action {
            case .loadSelectedTaxRateID(_, let onCompletion):
                onCompletion(1)
            default:
                break
            }
        })

        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])

        stores.whenReceivingAction(ofType: TaxAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxRate(_, _, let onCompletion):
                onCompletion(.success(taxRate))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        waitUntil {
            viewModel.addressFormViewModel.fields.state.isNotEmpty
        }

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.state, taxRate.state)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.country, taxRate.country)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.postcode, taxRate.postcodes.first)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.city, taxRate.cities.first)
    }

    func test_onTaxRateSelected_when_taxBasedOnSetting_is_customerBillingAddress_then_resets_addressFormViewModel_fields_with_new_data() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerBillingAddress))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])

        viewModel.onTaxRateSelected(taxRate)

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.state, taxRate.state)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.country, taxRate.country)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.postcode, taxRate.postcodes.first)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.city, taxRate.cities.first)
    }

    func test_onTaxRateSelected_when_taxBasedOnSetting_is_customerShippingAddress_then_resets_addressFormViewModel_secondaryFields_with_new_data() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerShippingAddress))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])

        viewModel.onTaxRateSelected(taxRate)

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.secondaryFields.state, taxRate.state)
        XCTAssertEqual(viewModel.addressFormViewModel.secondaryFields.country, taxRate.country)
        XCTAssertEqual(viewModel.addressFormViewModel.secondaryFields.postcode, taxRate.postcodes.first)
        XCTAssertEqual(viewModel.addressFormViewModel.secondaryFields.city, taxRate.cities.first)
    }

    func test_onTaxRateSelected_when_taxBasedOnSetting_is_shopBaseAddress_then_it_does_not_reset_addressFormViewModel_with_new_data() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.shopBaseAddress))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])

        viewModel.onTaxRateSelected(taxRate)

        // Then
        XCTAssertTrue(viewModel.addressFormViewModel.fields.state.isEmpty)
        XCTAssertTrue(viewModel.addressFormViewModel.fields.country.isEmpty)
        XCTAssertTrue(viewModel.addressFormViewModel.fields.postcode.isEmpty)
        XCTAssertTrue(viewModel.addressFormViewModel.fields.city.isEmpty)
    }

    func test_addCustomerAddressToOrder_resets_addressFormViewModel_with_new_data() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)
        let customer = Customer.fake().copy(
            email: "scrambled@scrambled.com",
            firstName: "Johnny",
            lastName: "Appleseed",
            billing: sampleAddress1(),
            shipping: sampleAddress2()
        )

        viewModel.addCustomerAddressToOrder(customer: customer)

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.firstName, customer.firstName)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.lastName, customer.lastName)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.email, customer.email)
    }

    func test_addCustomerAddressToOrder_when_feature_flag_is_enabled_and_a_customer_was_added_then_shows_the_form() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores,
                                               featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true))
        let customer = Customer.fake().copy(
            email: "scrambled@scrambled.com",
            firstName: "Johnny",
            lastName: "Appleseed",
            billing: sampleAddress1(),
            shipping: sampleAddress2()
        )

        viewModel.addCustomerAddressToOrder(customer: customer)

        // Then
        XCTAssertTrue(viewModel.customerNavigationScreen == .form)
    }

    func test_addCustomerAddressToOrder_when_feature_flag_is_enabled_and_no_customer_is_added_then_shows_the_selector() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores,
                                               featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true))
        // Then
        XCTAssertTrue(viewModel.customerNavigationScreen == .selector)
    }

    func test_resetAddressForm_discards_pending_address_field_changes() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Given there is a saved change and a pending change
        viewModel.addressFormViewModel.fields.firstName = sampleAddress1().firstName
        viewModel.addressFormViewModel.saveAddress(onFinish: { _ in })
        viewModel.addressFormViewModel.fields.lastName = sampleAddress1().lastName

        // When
        viewModel.resetAddressForm()

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.firstName, sampleAddress1().firstName,
                       "Saved change was unexpectedly discarded when address form was reset")
        XCTAssertEqual(viewModel.addressFormViewModel.fields.lastName, "",
                       "Pending change was not discarded when address form was reset")
    }

    func test_canBeDismissed_is_true_when_creating_order_without_changes() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID)

        // Then
        XCTAssertTrue(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_is_false_when_creating_order_with_changes() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID)

        // When
        viewModel.updateOrderStatus(newStatus: .failed)

        // Then
        XCTAssertFalse(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_is_true_when_editing_order_without_changes() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertTrue(viewModel.canBeDismissed)
    }

    func test_canBeDismissed_is_true_when_editing_order_with_changes() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // When
        viewModel.updateOrderStatus(newStatus: .failed)

        // Then
        XCTAssertTrue(viewModel.canBeDismissed)
    }

    func test_onFinished_is_called_when_creating_order() {
        // Given
        var isCallbackCalled = false
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .creation, stores: stores)
        viewModel.onFinished = { _ in
            isCallbackCalled = true
        }

        // When
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
        XCTAssertTrue(isCallbackCalled)
    }

    func test_onFinished_is_called_when_editing_order() {
        // Given
        var isCallbackCalled = false
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: .fake()))
        viewModel.onFinished = { _ in
            isCallbackCalled = true
        }

        // When
        viewModel.finishEditing()

        // Then
        XCTAssertTrue(isCallbackCalled)
    }

    func test_creating_order_does_not_shows_editable_indicator() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID)

        // When & Then
        XCTAssertFalse(viewModel.shouldShowNonEditableIndicators)
    }

    func test_editing_a_non_editable_order_shows_editable_indicator() {
        // Given
        let order = Order.fake().copy(isEditable: false)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertTrue(viewModel.shouldShowNonEditableIndicators)
    }

    func test_editing_an_editable_order_does_not_shows_editable_indicator() {
        // Given
        let order = Order.fake().copy(isEditable: true)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertFalse(viewModel.shouldShowNonEditableIndicators)
    }

    func test_zero_fees_and_shipping_lines_order_displays_nil_message() {
        // Given
        let order = Order.fake()

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertNil(viewModel.multipleLinesMessage)
    }

    func test_one_shipping_and_fee_line_order_displays_nil_message() {
        // Given
        let order = Order.fake().copy(shippingLines: [.fake()], fees: [.fake()])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertNil(viewModel.multipleLinesMessage)
    }

    func test_multiple_shipping_line_order_displays_info_message() {
        // Given
        let order = Order.fake().copy(shippingLines: [.fake(), .fake()])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertNotNil(viewModel.multipleLinesMessage)
    }

    func test_multiple_fee_line_order_displays_info_message() {
        // Given
        let order = Order.fake().copy(fees: [.fake(), .fake()])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertNotNil(viewModel.multipleLinesMessage)
    }

    func test_multiple_shipping_and_fee_line_order_displays_info_message() {
        // Given
        let order = Order.fake().copy(shippingLines: [.fake(), .fake()], fees: [.fake(), .fake()])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order))

        // Then
        XCTAssertNotNil(viewModel.multipleLinesMessage)
    }

    func test_capturePermissionStatus_is_notDetermined_when_permissionChecker_is_notDetermined() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .notDetermined)
    }

    func test_capturePermissionStatus_is_permitted_when_permissionChecker_is_authorized() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .authorized)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .permitted)
    }

    func test_capturePermissionStatus_is_notPermitted_when_permissionChecker_is_denied() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .denied)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .notPermitted)
    }

    func test_capturePermissionStatus_is_notPermitted_when_permissionChecker_is_restricted() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .restricted)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .notPermitted)
    }

    func test_requestCameraAccess_when_permission_is_granted_then_true_is_passed_to_the_completion_handler() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(thenReturn: true)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // When
        let permissionWasGranted: Bool = waitFor { promise in
            viewModel.requestCameraAccess(onCompletion: { isPermissionGranted in
                promise(isPermissionGranted)
            })
        }

        // Then
        XCTAssertTrue(permissionWasGranted)
    }

    func test_requestCameraAccess_when_permission_is_denied_then_false_is_passed_to_the_completion_handler() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(thenReturn: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // When
        let permissionWasGranted: Bool = waitFor { promise in
            viewModel.requestCameraAccess(onCompletion: { isPermissionGranted in
                promise(isPermissionGranted)
            })
        }

        // Then
        XCTAssertFalse(permissionWasGranted)
    }

    func test_requestCameraAccess_when_permission_is_granted_then_capturePermissionStatus_is_permitted() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(setAuthorizationStatus: .authorized)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // When
        waitFor { promise in
            viewModel.requestCameraAccess(onCompletion: { _ in
                promise(())
            })
        }

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .permitted)
    }

    func test_requestCameraAccess_when_permission_is_denied_then_capturePermissionStatus_is_notPermitted() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(setAuthorizationStatus: .denied)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // When
        waitFor { promise in
            viewModel.requestCameraAccess(onCompletion: { _ in
                promise(())
            })
        }

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .notPermitted)
    }

    func test_requestCameraAccess_when_permission_is_restricted_then_capturePermissionStatus_is_notPermitted() {
        // Given
        let permissionChecker = MockCaptureDevicePermissionChecker(authorizationStatus: .notDetermined)
        permissionChecker.whenRequestingAccess(setAuthorizationStatus: .restricted)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, permissionChecker: permissionChecker)

        // When
        waitFor { promise in
            viewModel.requestCameraAccess(onCompletion: { _ in
                promise(())
            })
        }

        // Then
        XCTAssertEqual(viewModel.capturePermissionStatus, .notPermitted)
    }

    func test_addScannedProductToOrder_when_sku_is_not_found_then_returns_productNotFound_error_and_shows_autodismissable_notice_with_retry_action() {
        // Given
        let actionError = NSError(domain: "Error", code: 0)
        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case .retrieveFirstPurchasableItemMatchFromSKU(_, _, let onCompletion):
                onCompletion(.failure(actionError))
            default:
                XCTFail("Expected failure, got success")
            }
        })

        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores,
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))
        let scannedBarcode = ScannedBarcode(payloadStringValue: "nonExistingSKU",
                                            symbology: BarcodeSymbology.ean8)

        // When
        var onRetryRequested = false
        let expectedError = waitFor { promise in
            viewModel.addScannedProductToOrder(barcode: scannedBarcode, onCompletion: { expectedError in
                switch expectedError {
                case let .failure(error as EditableOrderViewModel.ScannerError):
                    promise(error)
                default:
                    break
                }
            }, onRetryRequested: {
                onRetryRequested = true
            })
        }

        let expectedNotice = EditableOrderViewModel.NoticeFactory.createProductNotFoundAfterSKUScanningErrorNotice(for: actionError,
                                                                                                                   code: scannedBarcode,
                                                                                                                   withRetryAction: {})

        // Then
        XCTAssertEqual(expectedError, .productNotFound)
        XCTAssertEqual(viewModel.autodismissableNotice, expectedNotice)
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.barcodeScanningSuccess.rawValue)
        XCTAssertEqual(analytics.receivedProperties.first?["source"] as? String, "order_creation")

        viewModel.autodismissableNotice?.actionHandler?()

        waitUntil {
            onRetryRequested == true
        }
    }

    func test_addScannedProductToOrder_when_existing_sku_is_found_then_retrieving_a_matching_product_returns_success() {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores,
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))

        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { action in
            switch action {
            case .retrieveFirstPurchasableItemMatchFromSKU(_, _, let onCompletion):
                let product = Product.fake().copy(productID: self.sampleSiteID, purchasable: true)
                onCompletion(.success(.product(product)))
            default:
                break
            }
        })

        // When
        let successWasReceived: Bool = waitFor { promise in
            viewModel.addScannedProductToOrder(barcode: ScannedBarcode(payloadStringValue: "existingSKU",
                                                                            symbology: BarcodeSymbology.ean8), onCompletion: { result in
                switch result {
                case .success(()):
                    promise(true)
                default:
                    XCTFail("Expected success, got failure")
                }
            }, onRetryRequested: {})
        }

        // Then
        XCTAssertTrue(successWasReceived)
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.barcodeScanningSuccess.rawValue)
        XCTAssertEqual(analytics.receivedProperties.first?["source"] as? String, "order_creation")
        XCTAssertEqual(analytics.receivedEvents.last, WooAnalyticsStat.orderProductAdd.rawValue)
        XCTAssertEqual(analytics.receivedProperties.last?["source"] as? String, "order_creation")
        XCTAssertEqual(analytics.receivedProperties.last?["flow"] as? String, "creation")
        XCTAssertEqual(analytics.receivedProperties.last?["added_via"] as? String, "scanning")
    }

    func test_order_creation_when_withinitialItem_is_nil_then_currentOrderItems_are_zero() {
        // Given, When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, initialItem: nil)

        // Then
        XCTAssertEqual(viewModel.currentOrderItems.count, 0)
    }

    func test_addScannedProductToOrder_when_existing_sku_is_found_then_succeeds_to_add_product_to_order() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)

        stores.whenReceivingAction(ofType: ProductAction.self, thenCall: { [weak self] action in
            switch action {
            case .retrieveFirstPurchasableItemMatchFromSKU(_, _, let onCompletion):
                self?.storageManager.insertSampleProduct(readOnlyProduct: product)
                onCompletion(.success(.product(product)))
            default:
                break
            }
        })

        // When
       waitFor { [weak self] promise in
            self?.viewModel.addScannedProductToOrder(barcode: ScannedBarcode(payloadStringValue: "existingSKU",
                                                                            symbology: BarcodeSymbology.ean8), onCompletion: { result in
                switch result {
                case .success(()):
                    promise(())
                default:
                    XCTFail("Expected success, got failure")
                }
            }, onRetryRequested: {})
        }

        waitUntil { [weak self] in
            self?.viewModel.currentOrderItems.count ?? 0 > 0
        }

        // Then
        XCTAssertEqual(viewModel.currentOrderItems.count, 1)

        guard let item = viewModel.currentOrderItems.first else {
            return XCTFail("Expected 1 item, but got none")
        }
        XCTAssertEqual(item.productID, sampleProductID)
    }

    func test_order_creation_when_initialItem_is_not_nil_and_product_exists_then_product_is_added_to_the_order() {
        // Given, When
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        // Confidence check
        XCTAssertEqual(viewModel.currentOrderItems.count, 0)

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, initialItem: .product(product))

        // Then
        XCTAssertEqual(viewModel.currentOrderItems.count, 1)
    }

    func test_order_created_when_initialItem_is_product_type_then_initial_order_contains_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, initialItem: .product(product))
        let orderItem = viewModel.currentOrderItems.first(where: { $0.productID == product.productID})

        // Then
        XCTAssertEqual(viewModel.currentOrderItems.count, 1)
        XCTAssertEqual(orderItem?.productID, sampleProductID)
        XCTAssertEqual(orderItem?.variationID, 0) // Parent products do not have variation ID
        XCTAssertEqual(orderItem?.quantity, 1)
    }

    func test_order_created_when_initialItem_is_productVariation_type_then_initial_order_contains_productVariation() {
        // Given
        let variationID: Int64 = 33
        let variation = ProductVariation.fake().copy(siteID: sampleSiteID, productVariationID: variationID)

        storageManager.insertSampleProductVariation(readOnlyProductVariation: variation)

        //When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, initialItem: .variation(variation))
        guard let orderItem = viewModel.currentOrderItems.first else {
            XCTFail("The Order should contain one item")
            return
        }

        // Then
        XCTAssertEqual(viewModel.currentOrderItems.count, 1)
        XCTAssertEqual(orderItem.variationID, variationID)
        XCTAssertEqual(orderItem.quantity, 1)
    }

    func test_order_created_when_tax_based_on_is_customer_billing_address_then_property_is_updated() {
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerBillingAddress))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores)

        XCTAssertEqual(viewModel.paymentDataViewModel.taxBasedOnSetting?.displayString, NSLocalizedString("Calculated on billing address", comment: ""))
    }

    func test_order_created_when_tax_based_on_is_shop_base_address_then_property_is_updated() {
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.shopBaseAddress))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores)

        XCTAssertEqual(viewModel.paymentDataViewModel.taxBasedOnSetting?.displayString, NSLocalizedString("Calculated on shop base address", comment: ""))
    }

    func test_order_created_when_tax_based_on_is_customer_shipping_address_then_property_is_updated() {
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerShippingAddress))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores)

        XCTAssertEqual(viewModel.paymentDataViewModel.taxBasedOnSetting?.displayString, NSLocalizedString("Calculated on shipping address", comment: ""))
    }

    func test_payment_data_view_model_when_calling_onDismissWpAdminWebViewClosure_then_calls_to_update_elements() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let isUpdatingOrder: Bool = waitFor { [weak self] promise in
            // As we just created the view model, it will call to create the order instead of updating it
            self?.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(true)
                default:
                   break
                }
            }
            // Trigger remote sync
           viewModel.paymentDataViewModel.onDismissWpAdminWebViewClosure()
        }

        // Then
        XCTAssertTrue(isUpdatingOrder)
    }

    func test_payment_data_view_model_when_calling_onDismissWpAdminWebViewClosure_then_calls_to_retrieveTaxBasedOnSetting() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let isRetrievingTaxBasedOnSetting: Bool = waitFor { [weak self] promise in
            self?.stores.whenReceivingAction(ofType: SettingAction.self) { action in
                switch action {
                case .retrieveTaxBasedOnSetting:
                    promise(true)
                default:
                   break
                }
            }
            // Trigger remote sync
           viewModel.paymentDataViewModel.onDismissWpAdminWebViewClosure()
        }

        // Then
        XCTAssertTrue(isRetrievingTaxBasedOnSetting)
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

private extension EditableOrderViewModelTests {
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
