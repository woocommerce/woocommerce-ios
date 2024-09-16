import XCTest
@testable import WooCommerce
import Yosemite
import WooFoundation
import Networking
import Combine

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
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           featureFlagService: featureFlagService,
                                           quantityDebounceDuration: 0)
    }

    // MARK: - Initialization

    func test_view_model_inits_with_expected_values() {
        // Then
        XCTAssertEqual(viewModel.flow, .creation)
        XCTAssertEqual(viewModel.navigationTrailingItem, .create)
        XCTAssertEqual(viewModel.statusBadgeViewModel.title, "pending")
        XCTAssertEqual(viewModel.productRows.count, 0)
    }

    func test_createProductSelectorViewModelWithOrderItemsSelected_returns_instance_initialized_with_expected_values() throws {
        // When
        viewModel.toggleProductSelectorVisibility()

        // Then
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)
        XCTAssertFalse(productSelectorViewModel.toggleAllVariationsOnSelection)
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

    func test_edition_view_model_has_no_navigation_done_button() {
        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: .fake()), stores: stores)

        // Then
        XCTAssertNil(viewModel.navigationTrailingItem)
    }

    func test_edition_view_model_has_a_navigation_loading_item_when_synching() {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores)

        // When
        let navigationItemDuringSync: EditableOrderViewModel.NavigationItem? = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .updateOrder:
                    promise(viewModel.navigationTrailingItem)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // Trigger remote sync
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
        }

        // Then
        XCTAssertEqual(navigationItemDuringSync, .loading)
    }

    func test_loading_indicator_is_enabled_during_network_request() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // When
        let navigationItem: EditableOrderViewModel.NavigationItem? = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case .createOrder:
                    promise(viewModel.navigationTrailingItem)
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            viewModel.onCreateOrderTapped()
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
            viewModel.onCreateOrderTapped()
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
            case let .createOrder(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.onCreateOrderTapped()

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
            case let .createOrder(_, _, _, onCompletion):
                onCompletion(.failure(error))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.onCreateOrderTapped()

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
                case let .createOrder(_, _, _, onCompletion):
                    onCompletion(.failure(error))
                    expectation.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When remote sync is triggered
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
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
                case let .createOrder(_, _, _, onCompletion):
                    onCompletion(.failure(DotcomError.unknown(code: "woocommerce_rest_invalid_coupon", message: "")))
                    expectation.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When remote sync is triggered
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
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
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
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

    func test_view_model_is_updated_when_product_is_added_to_order() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertTrue(viewModel.productRows.map { $0.productRow }.contains(where: { $0.productOrVariationID == sampleProductID }),
                      "Product rows do not contain expected product")
    }

    func test_view_model_is_updated_immediately_when_product_is_added_to_order_using_immediate_sync_approach() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               featureFlagService: MockFeatureFlagService(sideBySideViewForOrderForm: true))
        viewModel.toggleProductSelectorVisibility()

        viewModel.selectionSyncApproach = .immediate
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)

        // Then
        XCTAssertTrue(viewModel.productRows.map { $0.productRow }.contains(where: { $0.productOrVariationID == sampleProductID }),
                      "Product rows do not contain expected product")
    }

    func test_button_changes_to_recalculate_when_product_is_added_to_order_using_onRecalculateButtonTap_sync_approach() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               featureFlagService: MockFeatureFlagService(sideBySideViewForOrderForm: true))
        viewModel.toggleProductSelectorVisibility()

        viewModel.selectionSyncApproach = .onRecalculateButtonTap
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)

        // Then
        switch viewModel.doneButtonType {
        case .recalculate:
            // Success – we just don't care about the `loading` parameter
            break
        default:
            XCTFail("Unexpected doneButtonType")
        }
    }

    func test_view_model_is_updated_when_product_is_added_to_order_using_buttonTap_sync_approach_then_changes_to_immediate() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               featureFlagService: MockFeatureFlagService(sideBySideViewForOrderForm: true))
        viewModel.toggleProductSelectorVisibility()

        viewModel.selectionSyncApproach = .onSelectorButtonTap
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)

        XCTAssertFalse(viewModel.productRows.map { $0.productRow }.contains(where: { $0.productOrVariationID == sampleProductID }),
                      "Product rows unexpectedly contain product")

        // When
        viewModel.selectionSyncApproach = .immediate

        // Then
        XCTAssertTrue(viewModel.productRows.map { $0.productRow }.contains(where: { $0.productOrVariationID == sampleProductID }),
                      "Product rows do not contain expected product")
    }

    func test_order_details_are_updated_when_product_quantity_changes() throws {
        // Given

        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        let anotherProduct = Product.fake().copy(siteID: sampleSiteID, productID: 123456, purchasable: true)

        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProduct(readOnlyProduct: anotherProduct)

        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.changeSelectionStateForProduct(with: anotherProduct.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()
        // And when another product is added to the order (to confirm the first product's quantity change is retained)
        viewModel.productRows[0].productRow.stepperViewModel.incrementQuantity()

        // Then
        XCTAssertEqual(viewModel.productRows.map { $0.productRow.stepperViewModel }[safe: 0]?.quantity, 2)
        XCTAssertEqual(viewModel.productRows.map { $0.productRow.stepperViewModel }[safe: 1]?.quantity, 1)
    }

    func test_bundle_order_item_with_child_items_includes_full_bundle_configuration_when_quantity_is_incremented() throws {
        // Given
        let bundledProduct = Product.fake().copy(siteID: sampleSiteID, productID: 665, productTypeKey: ProductType.simple.rawValue)
        let bundleItem = ProductBundleItem.fake().copy(bundledItemID: 1, productID: bundledProduct.productID)

        let bundledVariableProduct = Product.fake().copy(siteID: sampleSiteID, productID: 668, productTypeKey: ProductType.variable.rawValue, attributes: [
            .fake().copy(name: "Fabric", options: ["Cotton", "Organic cotton"])
        ], variations: [17])
        let variableBundleItem = ProductBundleItem.fake().copy(bundledItemID: 2, productID: bundledVariableProduct.productID, isOptional: true)

        let bundleProduct = Product.fake().copy(siteID: sampleSiteID,
                                                productID: 600,
                                                productTypeKey: ProductType.bundle.rawValue,
                                                bundledItems: [
                                                    bundleItem, variableBundleItem
                                                ])
        // Inserts necessary objects to storage.
        storageManager.insertSampleProduct(readOnlyProduct: bundledProduct)
        storageManager.insertSampleProduct(readOnlyProduct: bundledVariableProduct)
        let storageBundleProduct = storageManager.insertSampleProduct(readOnlyProduct: bundleProduct)
        storageManager.insert(bundleItem, for: storageBundleProduct)
        storageManager.insert(variableBundleItem, for: storageBundleProduct)

        let order = Order.fake().copy(siteID: sampleSiteID, orderID: sampleOrderID, items: [
            // Bundle order item
            .fake().copy(itemID: 1, productID: bundleProduct.productID, quantity: 2),
            // Bundled child order item for the simple product
            .fake().copy(itemID: 2, productID: bundledProduct.productID, quantity: 6, parent: 1),
        ])
        viewModel = .init(siteID: sampleSiteID,
                          flow: .editing(initialOrder: order),
                          stores: stores,
                          storageManager: storageManager,
                          quantityDebounceDuration: 0)

        waitUntil {
            self.viewModel.productRows.count == 1
        }

        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, _, _, onCompletion):
                    promise(order)
                    onCompletion(.success(.fake()))
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When
            self.viewModel.productRows[0].productRow.stepperViewModel.incrementQuantity()
        }

        // Then
        let bundleOrderItemToUpdate = try XCTUnwrap(orderToUpdate.items.first)
        assertEqual([
            .init(bundledItemID: 1, productID: 665, quantity: 3, isOptionalAndSelected: nil, variationID: nil, variationAttributes: nil),
            // Even though the variable bundle item is not selected, it still needs to be included in the bundle configuration
            .init(bundledItemID: 2, productID: 668, quantity: 0, isOptionalAndSelected: false, variationID: nil, variationAttributes: nil),
        ], bundleOrderItemToUpdate.bundleConfiguration)
    }

    func test_setDiscountViewModel_sets_discountViewModel_for_expected_row() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let expectedRow = viewModel.productRows.map { $0.productRow }[0]
        viewModel.setDiscountViewModel(expectedRow.id)

        // Then
        XCTAssertNotNil(viewModel.discountViewModel)
        assertEqual(expectedRow.id, viewModel.discountViewModel?.id)
    }

    func test_view_model_is_updated_when_product_is_removed_from_order_using_order_item() throws {
        // Given
        let product0 = Product.fake().copy(siteID: sampleSiteID, productID: 0, purchasable: true)
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        storageManager.insertProducts([product0, product1])
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // Given products are added to order
        productSelectorViewModel.changeSelectionStateForProduct(with: product0.productID, selected: true)
        productSelectorViewModel.changeSelectionStateForProduct(with: product1.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let expectedRemainingRow = viewModel.productRows[1]
        let itemToRemove = OrderItem.fake().copy(itemID: viewModel.productRows.map { $0.productRow }[0].id)
        viewModel.removeItemFromOrder(itemToRemove)

        // Then
        XCTAssertFalse(viewModel.productRows.map { $0.productRow }.contains(where: { $0.productOrVariationID == product0.productID }))
        XCTAssertEqual(viewModel.productRows.map { $0.productRow }.map { $0.id },
                       [expectedRemainingRow].map { $0.productRow }.map { $0.id })
    }

    func test_view_model_is_updated_when_product_is_removed_from_order_using_product_row_ID() throws {
        // Given
        let product0 = Product.fake().copy(siteID: sampleSiteID, productID: 0, purchasable: true)
        let product1 = Product.fake().copy(siteID: sampleSiteID, productID: 1, purchasable: true)
        storageManager.insertProducts([product0, product1])
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // Given products are added to order
        productSelectorViewModel.changeSelectionStateForProduct(with: product0.productID, selected: true)
        productSelectorViewModel.changeSelectionStateForProduct(with: product1.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let expectedRemainingRow = viewModel.productRows[1]
        let itemToRemove = OrderItem.fake().copy(itemID: viewModel.productRows.map { $0.productRow }[0].id)
        viewModel.removeItemFromOrder(itemToRemove.itemID)

        // Then
        XCTAssertFalse(viewModel.productRows.map { $0.productRow }.contains(where: { $0.productOrVariationID == product0.productID }))
        XCTAssertEqual(viewModel.productRows.map { $0.productRow }.map { $0.id },
                       [expectedRemainingRow].map { $0.productRow }.map { $0.id })
    }

    func test_createProductRowViewModel_creates_expected_row_for_product() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "10")
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(name: product.name, productID: product.productID, quantity: 1, price: 8)
        let productRow = viewModel.createProductRowViewModel(for: orderItem)

        // Then
        let expectedProductRow = ProductRowViewModel(product: product)
        XCTAssertEqual(productRow?.productRow.name, expectedProductRow.name)
        XCTAssertEqual(productRow?.productRow.stepperViewModel.quantity, expectedProductRow.quantity)
        XCTAssertEqual(productRow?.productRow.price, orderItem.basePrice.stringValue)
    }

    func test_createProductRowViewModel_creates_expected_row_for_product_variation() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, productTypeKey: "variable", variations: [33])
        let productVariation = ProductVariation.fake().copy(siteID: sampleSiteID,
                                                            productID: sampleProductID,
                                                            productVariationID: 33,
                                                            sku: "product-variation",
                                                            price: "10")
        storageManager.insertSampleProduct(readOnlyProduct: product)
        storageManager.insertSampleProductVariation(readOnlyProductVariation: productVariation, on: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(name: product.name,
                                              productID: product.productID,
                                              variationID: productVariation.productVariationID,
                                              quantity: 2,
                                              price: 8)
        let productRow = viewModel.createProductRowViewModel(for: orderItem)

        // Then
        let expectedProductRow = ProductRowViewModel(productVariation: productVariation,
                                                     name: product.name,
                                                     quantity: 2,
                                                     displayMode: .stock)
        XCTAssertEqual(productRow?.productRow.name, expectedProductRow.name)
        XCTAssertEqual(productRow?.productRow.skuLabel, expectedProductRow.skuLabel)
        XCTAssertEqual(productRow?.productRow.stepperViewModel.quantity, expectedProductRow.quantity)
        XCTAssertEqual(productRow?.productRow.price, orderItem.basePrice.stringValue)
    }

    func test_createProductRowViewModel_sets_expected_discount_for_discounted_order_item() {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(productID: product.productID, quantity: 1, price: 10, subtotal: "10", total: "9")
        let productRow = viewModel.createProductRowViewModel(for: orderItem)

        // Then
        let expectedDiscount: Decimal = 1 // Order item subtotal - total
        assertEqual(expectedDiscount, productRow?.productRow.discount)
    }

    func test_view_model_is_updated_when_custom_amount_is_added_to_order() {
        // Given
        let customAmountName = "Test"

        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.name = customAmountName
        addCustomAmountViewModel.doneButtonPressed()

        // Then
        XCTAssertTrue(viewModel.customAmountRows.contains(where: { $0.name == customAmountName }))
    }

    func test_onAddCustomAmountButtonTapped_then_it_tracks_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.onAddCustomAmountButtonTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderCreationAddCustomAmountTapped.rawValue)
    }

    func test_addCustomAmountViewModel_doneButtonPressed_then_it_tracks_event() {
        // Given
        let analytics = MockAnalyticsProvider()

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.addCustomAmountViewModel(with: .fixedAmount).doneButtonPressed()

        // Then
        XCTAssertEqual(analytics.receivedEvents.first, WooAnalyticsStat.orderFeeAdd.rawValue)
    }

    func test_view_model_is_updated_when_custom_amount_is_removed_from_order() {
        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.name = "Test"
        addCustomAmountViewModel.doneButtonPressed()

        // Check previous condition
        XCTAssertEqual(viewModel.customAmountRows.count, 1)

        viewModel.customAmountRows.first?.onEditCustomAmount()
        viewModel.addCustomAmountViewModel(with: nil).deleteButtonPressed()

        // Then
        XCTAssertTrue(viewModel.customAmountRows.isEmpty)
    }

    func test_customAmountRows_onRemoveCustomAmount_then_it_tracks_events() {
        // Given
        let analytics = MockAnalyticsProvider()

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.addCustomAmountViewModel(with: .fixedAmount).doneButtonPressed()

        // When
        viewModel.customAmountRows.first?.onEditCustomAmount()
        viewModel.addCustomAmountViewModel(with: nil).deleteButtonPressed()

        // Then
        XCTAssertNotNil(analytics.receivedEvents.first(where: { $0 == WooAnalyticsStat.orderFeeRemove.rawValue }))
        XCTAssertNotNil(analytics.receivedEvents.first(where: { $0 == WooAnalyticsStat.orderCreationRemoveCustomAmountTapped.rawValue }))
    }

    func test_view_model_is_updated_when_custom_amount_is_edited() {
        // Given
        let newFeeName = "Test 2"

        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.name = "Test"
        addCustomAmountViewModel.doneButtonPressed()

        // Check previous condition
        XCTAssertEqual(viewModel.customAmountRows.count, 1)

        addCustomAmountViewModel.preset(with: OrderFeeLine.fake().copy(feeID: viewModel.customAmountRows.first?.id ?? 0))
        addCustomAmountViewModel.name = newFeeName
        addCustomAmountViewModel.doneButtonPressed()

        // Then
        XCTAssertEqual(viewModel.customAmountRows.first?.name, newFeeName)
    }

    func test_customAmountRows_onEditCustomAmount_then_it_tracks_events() {
        // Given
        let analytics = MockAnalyticsProvider()

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.name = "Test"
        addCustomAmountViewModel.doneButtonPressed()

        // Check previous condition
        XCTAssertEqual(viewModel.customAmountRows.count, 1)

        addCustomAmountViewModel.preset(with: OrderFeeLine.fake().copy(feeID: viewModel.customAmountRows.first?.id ?? 0))
        viewModel.customAmountRows.first?.onEditCustomAmount()
        addCustomAmountViewModel.doneButtonPressed()

        // Then
        XCTAssertNotNil(analytics.receivedEvents.first(where: { $0 == WooAnalyticsStat.orderFeeUpdate.rawValue }))
        XCTAssertNotNil(analytics.receivedEvents.first(where: { $0 == WooAnalyticsStat.orderCreationEditCustomAmountTapped.rawValue }))
    }

    func test_view_model_is_updated_when_address_updated_and_feature_flag_disabled() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)
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
                                                                               customAmountsTotal: "2.00",
                                                                               taxesTotal: "5.00",
                                                                               currencyFormatter: CurrencyFormatter(currencySettings: currencySettings))

        // Then
        XCTAssertEqual(paymentDataViewModel.itemsTotal, "£20.00")
        XCTAssertEqual(paymentDataViewModel.customAmountsTotal, "£2.00")
        XCTAssertEqual(paymentDataViewModel.taxesTotal, "£5.00")
    }

    func test_payment_data_view_model_is_initialized_with_expected_default_values_for_new_order() {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, currencySettings: currencySettings)

        // Then
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.customAmountsTotal, "£0.00")
        XCTAssertEqual(viewModel.paymentDataViewModel.taxesTotal, "£0.00")
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

    // MARK: - Payment Section Tests

    func test_payment_section_when_products_and_custom_amounts_are_added_then_paymentDataViewModel_is_updated() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // Pre-check
        XCTAssertTrue(viewModel.paymentDataViewModel.orderIsEmpty)
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowProductsTotal)

        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.formattableAmountTextFieldViewModel?.updateAmount("10")
        addCustomAmountViewModel.doneButtonPressed()

        // Pre-check
        XCTAssertFalse(viewModel.paymentDataViewModel.orderIsEmpty)
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowProductsTotal)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.orderIsEmpty)
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowProductsTotal)
    }

    func test_payment_section_is_updated_when_products_update() throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings,
                                               quantityDebounceDuration: 0)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When & Then
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.orderTotal, "£8.50")

        // When & Then
        viewModel.productRows[0].productRow.stepperViewModel.incrementQuantity()

        // Debounce makes the quantity update async even though the duration is 0.
        waitUntil {
            viewModel.paymentDataViewModel.itemsTotal != "£8.50"
        }
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£17.00")
        XCTAssertEqual(viewModel.orderTotal, "£17.00")
    }

    func test_payment_when_custom_amount_is_added_then_section_is_updated() throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.formattableAmountTextFieldViewModel?.updateAmount("10")
        addCustomAmountViewModel.doneButtonPressed()

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowTotalCustomAmounts)
        XCTAssertEqual(viewModel.paymentDataViewModel.itemsTotal, "£8.50")
        XCTAssertEqual(viewModel.paymentDataViewModel.customAmountsTotal, "£10.00")
        XCTAssertEqual(viewModel.orderTotal, "£18.50")
    }

    func test_payment_section_is_updated_when_coupon_line_updated() throws {
        // Given
        let currencySettings = CurrencySettings(currencyCode: .GBP, currencyPosition: .left, thousandSeparator: "", decimalSeparator: ".", numberOfDecimals: 2)
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, price: "8.50", purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               currencySettings: currencySettings)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
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

    func test_payment_section_loading_indicator_is_enabled_while_order_syncs() {
        // When
        let isLoadingDuringSync: Bool = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, _, _, onCompletion):
                    promise(self.viewModel.paymentDataViewModel.isLoading)
                    onCompletion(.success(.fake()))
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }
            // Trigger remote sync
            self.viewModel.shippingLineViewModel.saveShippingLine(.fake())
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
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
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
            case let .createOrder(_, _, _, onCompletion):
                let order = Order.fake().copy(siteID: self.sampleSiteID, totalTax: "2.50")
                onCompletion(.success(order))
                expectation.fulfill()
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        // Trigger remote sync
        viewModel.shippingLineViewModel.saveShippingLine(.fake())

        // Then
        waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
        XCTAssertEqual(viewModel.paymentDataViewModel.taxesTotal, "$2.50")

    }

    // MARK: - hasChanges Tests

    func test_hasChanges_returns_false_initially() {
        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertFalse(viewModel.hasChanges)
    }

    func test_hasChanges_returns_true_when_product_quantity_changes() throws {
        // Given
        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
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
        viewModel.shippingLineViewModel.saveShippingLine(shippingLine)

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
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
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
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()
        viewModel.productRows[0].productRow.stepperViewModel.incrementQuantity()

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
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // Given products are added to order
        productSelectorViewModel.changeSelectionStateForProduct(with: product0.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // When
        let itemToRemove = OrderItem.fake().copy(itemID: viewModel.productRows.map { $0.productRow }[0].id)
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

    func test_product_selector_source_is_tracked_when_product_selector_clear_selection_button_is_tapped() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               storageManager: storageManager,
                                               analytics: WooAnalytics(analyticsProvider: analytics))
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.clearSelection()

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

    func test_customer_details_tracked_when_added_and_feature_flag_disabled() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               analytics: WooAnalytics(analyticsProvider: analytics),
                                               featureFlagService: featureFlagService)

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

    func test_customer_details_tracked_when_only_billing_address_added_and_feature_flag_disabled() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: .fake()),
                                               analytics: WooAnalytics(analyticsProvider: analytics),
                                               featureFlagService: featureFlagService)

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
                case let .createOrder(_, _, _, onCompletion):
                    onCompletion(.failure(NSError(domain: "Error", code: 0)))
                    expectation.fulfill()
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            // When remote sync is triggered
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
        }

        // Then
        XCTAssertTrue(analytics.receivedEvents.contains(WooAnalyticsStat.orderSyncFailed.rawValue))

        let indexOfEvent = try XCTUnwrap(analytics.receivedEvents.firstIndex(where: { $0 == WooAnalyticsStat.orderSyncFailed.rawValue}))
        let eventProperties = try XCTUnwrap(analytics.receivedProperties[indexOfEvent])
        XCTAssertEqual(eventProperties["flow"] as? String, "creation")
    }

    func test_onStoredTaxRateBottomSheetAppear_then_tracks_event() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.onStoredTaxRateBottomSheetAppear()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCreationStoredTaxRateBottomSheetAppear.rawValue])
    }

    func test_onSetNewTaxRateFromBottomSheetTapped_then_tracks_event() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.onSetNewTaxRateFromBottomSheetTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCreationSetNewTaxRateFromBottomSheetTapped.rawValue])
    }

    func test_onClearAddressFromBottomSheetTapped_then_tracks_event() throws {
        // Given
        let analytics = MockAnalyticsProvider()
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, analytics: WooAnalytics(analyticsProvider: analytics))

        // When
        viewModel.onClearAddressFromBottomSheetTapped()

        // Then
        XCTAssertEqual(analytics.receivedEvents, [WooAnalyticsStat.orderCreationClearAddressFromBottomSheetTapped.rawValue])
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
                case .createOrder(_, let order, _, let completion):
                    completion(.success(order.copy(orderID: 12)))
                    expectation.fulfill()
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            // Trigger remote sync
            viewModel.shippingLineViewModel.saveShippingLine(.fake())
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

    func test_shouldShowNewTaxRateSection_when_there_are_not_items_then_it_returns_false() {
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

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        XCTAssertFalse(viewModel.shouldShowNewTaxRateSection)
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_customerBillingAddress_and_there_are_items_then_returns_true() throws {
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

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        waitUntil {
            viewModel.shouldShowNewTaxRateSection
        }
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_customerShippingAddress_and_there_are_items_then_returns_true() throws {
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

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        waitUntil {
            viewModel.shouldShowNewTaxRateSection
        }
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_customerBillingAddress_and_there_are_custom_amounts_then_returns_true() {
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

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.doneButtonPressed()

        // Then
        waitUntil {
            viewModel.shouldShowNewTaxRateSection
        }
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_customerShippingAddress_and_there_are_custom_amounts_then_returns_true() {
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

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, storageManager: storageManager)

        // When
        let addCustomAmountViewModel = viewModel.addCustomAmountViewModel(with: .fixedAmount)
        addCustomAmountViewModel.doneButtonPressed()

        // Then
        waitUntil {
            viewModel.shouldShowNewTaxRateSection
        }
    }

    func test_shouldShowNewTaxRateSection_when_taxBasedOnSetting_is_shopBaseAddress_and_there_are_items_then_returns_false() throws {
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

        let product = Product.fake().copy(siteID: sampleSiteID, productID: sampleProductID, purchasable: true)
        storageManager.insertSampleProduct(readOnlyProduct: product)
        viewModel.toggleProductSelectorVisibility()
        let productSelectorViewModel = try XCTUnwrap(viewModel.productSelectorViewModel)

        // When
        productSelectorViewModel.changeSelectionStateForProduct(with: product.productID, selected: true)
        productSelectorViewModel.completeMultipleSelection()

        // Then
        XCTAssertFalse(viewModel.shouldShowNewTaxRateSection)
    }

    func test_shouldShowNewTaxRateSection_when_order_is_not_editable_and_flow_is_editing_then_returns_false() {
            // Given
            stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
                switch action {
                case .retrieveTaxBasedOnSetting(_, let onCompletion):
                    onCompletion(.success(.customerShippingAddress))
                default:
                    break
                }
            })

            let order = Order.fake().copy(isEditable: false)
            let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                                   flow: .editing(initialOrder: order),
                                                   stores: stores)

            // Then
            XCTAssertFalse(viewModel.shouldShowNewTaxRateSection)
        }

    func test_shouldShowTaxesInfoButton_when_order_is_not_editable_then_returns_false() {
        // Given
        let order = Order.fake().copy(isEditable: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: order),
                                               stores: stores)

        // Then
        XCTAssertFalse(viewModel.paymentDataViewModel.shouldShowTaxesInfoButton)
    }

    func test_shouldShowTaxesInfoButton_when_order_is_editable_then_returns_true() {
        // Given
        let order = Order.fake().copy(isEditable: true)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: order),
                                               stores: stores)

        // Then
        XCTAssertTrue(viewModel.paymentDataViewModel.shouldShowTaxesInfoButton)
    }

    func test_onTaxRateSelected_when_taxBasedOnSetting_is_customerBillingAddress_then_updates_only_addressFormViewModel_location_fields_with_new_data() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerBillingAddress))
            default:
                break
            }
        })

        let customer = Customer.fake().copy(
            email: "scrambled@scrambled.com",
            firstName: "Johnny",
            lastName: "Appleseed",
            billing: sampleAddress1(),
            shipping: sampleAddress2()
        )

        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])
        viewModel.addCustomerAddressToOrder(customer: customer)
        viewModel.onTaxRateSelected(taxRate)

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.firstName, customer.firstName)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.lastName, customer.lastName)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.email, customer.email)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.state, taxRate.state)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.country, taxRate.country)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.postcode, taxRate.postcodes.first)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.city, taxRate.cities.first)
    }

    func test_onTaxRateSelected_when_taxBasedOnSetting_is_customerShippingAddress_then_updates_only_addressFormViewModel_location_fields_with_new_data() {
        // Given
        stores.whenReceivingAction(ofType: SettingAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxBasedOnSetting(_, let onCompletion):
                onCompletion(.success(.customerShippingAddress))
            default:
                break
            }
        })

        let customer = Customer.fake().copy(
            email: "scrambled@scrambled.com",
            firstName: "Johnny",
            lastName: "Appleseed",
            billing: sampleAddress1(),
            shipping: sampleAddress2()
        )

        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)
        let taxRate = TaxRate.fake().copy(siteID: sampleSiteID, name: "test tax rate", country: "US", state: "CA", postcodes: ["12345"], cities: ["San Diego"])

        viewModel.addCustomerAddressToOrder(customer: customer)
        viewModel.onTaxRateSelected(taxRate)

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.firstName, customer.firstName)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.lastName, customer.lastName)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.email, customer.email)
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
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)
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
                                               featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true,
                                                                                          isSubscriptionsInOrderCreationCustomersEnabled: false))
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

    func test_addCustomerAddressToOrder_when_feature_flag_is_enabled_and_an_empty_address_was_added_then_shows_the_selector() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               stores: stores,
                                               featureFlagService: MockFeatureFlagService(betterCustomerSelectionInOrder: true))
        let customer = Customer.fake().copy(
            email: "",
            firstName: "",
            lastName: "",
            billing: .empty,
            shipping: .empty
        )

        viewModel.addCustomerAddressToOrder(customer: customer)

        // Then
        XCTAssertTrue(viewModel.customerNavigationScreen == .selector)
    }

    func test_resetAddressForm_discards_pending_address_field_changes() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)

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
            case let .createOrder(_, order, _, onCompletion):
                onCompletion(.success(order))
            default:
                XCTFail("Received unsupported action: \(action)")
            }
        }
        viewModel.onCreateOrderTapped()

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
            case .synchronizeProducts:
                return
            case .retrieveFirstPurchasableItemMatchFromSKU(_, _, let onCompletion):
                onCompletion(.failure(actionError))
            default:
                XCTFail("Unexpected ProductAction received")
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

    func test_when_initialItem_is_bundle_product_it_sets_configurableScannedProductViewModel_without_order_items() throws {
        // Given
        let bundleProduct = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: 1, bundleItems: [.fake()])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager, initialItem: .product(bundleProduct))

        // Then
        XCTAssertNotNil(viewModel.configurableScannedProductViewModel)
        XCTAssertEqual(viewModel.currentOrderItems.count, 0)
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

        XCTAssertEqual(viewModel.paymentDataViewModel.taxBasedOnSetting?.displayString, NSLocalizedString("Calculated on billing address.", comment: ""))
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

        XCTAssertEqual(viewModel.paymentDataViewModel.taxBasedOnSetting?.displayString, NSLocalizedString("Calculated on shop base address.", comment: ""))
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

        XCTAssertEqual(viewModel.paymentDataViewModel.taxBasedOnSetting?.displayString, NSLocalizedString("Calculated on shipping address.", comment: ""))
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

        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)

        waitUntil {
            viewModel.addressFormViewModel.fields.state.isNotEmpty
        }

        // Then
        XCTAssertEqual(viewModel.addressFormViewModel.fields.state, taxRate.state)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.country, taxRate.country)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.postcode, taxRate.postcodes.first)
        XCTAssertEqual(viewModel.addressFormViewModel.fields.city, taxRate.cities.first)
    }

    func test_forgetTaxRate_then_resets_addressFormViewModel_fields() {
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

        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores, featureFlagService: featureFlagService)

        waitUntil {
            viewModel.addressFormViewModel.fields.state.isNotEmpty
        }

        viewModel.onClearAddressFromBottomSheetTapped()

        // Then
        XCTAssertTrue(viewModel.addressFormViewModel.fields.state.isEmpty)
        XCTAssertTrue(viewModel.addressFormViewModel.fields.country.isEmpty)
        XCTAssertTrue(viewModel.addressFormViewModel.fields.postcode.isEmpty)
        XCTAssertTrue(viewModel.addressFormViewModel.fields.city.isEmpty)
    }

    func test_viewModel_when_taxRate_is_stored_then_taxRateRowAction_is_storedTaxRateSheet() {
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

        let taxRate = TaxRate.fake()

        stores.whenReceivingAction(ofType: TaxAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxRate(_, _, let onCompletion):
                onCompletion(.success(taxRate))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        waitUntil {
            viewModel.taxRateRowAction == .storedTaxRateSheet
        }
    }

    func test_viewModel_when_taxRate_is_stored_then_shouldStoreTaxRateInSelectorByDefault_is_true() {
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

        let taxRate = TaxRate.fake()

        stores.whenReceivingAction(ofType: TaxAction.self, thenCall: { action in
            switch action {
            case .retrieveTaxRate(_, _, let onCompletion):
                onCompletion(.success(taxRate))
            default:
                break
            }
        })

        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, stores: stores)

        // Then
        waitUntil {
            viewModel.shouldStoreTaxRateInSelectorByDefault == true
        }
    }

    func test_isGiftCardEnabled_becomes_true_when_gift_cards_plugin_is_active() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)

        var viewModel: EditableOrderViewModel?
        waitFor { promise in
            stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
                guard case let .fetchSystemPluginWithPath(_, pluginPath, onCompletion) = action else {
                    return
                }
                XCTAssertEqual(pluginPath, "woocommerce-gift-cards/woocommerce-gift-cards.php")
                onCompletion(.fake().copy(active: true))
                promise(())
            }

            // When
            viewModel = EditableOrderViewModel(siteID: self.sampleSiteID, stores: stores, storageManager: self.storageManager)
            XCTAssertEqual(viewModel?.paymentDataViewModel.isGiftCardEnabled, false)
        }

        // Then
        XCTAssertEqual(viewModel?.paymentDataViewModel.isGiftCardEnabled, true)
    }

    func test_isGiftCardEnabled_stays_false_when_gift_cards_plugin_is_not_active() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)

        var viewModel: EditableOrderViewModel?
        waitFor { promise in
            stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
                guard case let .fetchSystemPluginWithPath(_, pluginPath, onCompletion) = action else {
                    return
                }
                XCTAssertEqual(pluginPath, "woocommerce-gift-cards/woocommerce-gift-cards.php")
                onCompletion(.fake().copy(active: false))
                promise(())
            }

            // When
            viewModel = EditableOrderViewModel(siteID: self.sampleSiteID, stores: stores, storageManager: self.storageManager)
            XCTAssertEqual(viewModel?.paymentDataViewModel.isGiftCardEnabled, false)
        }

        // Then
        XCTAssertEqual(viewModel?.paymentDataViewModel.isGiftCardEnabled, false)
    }

    func test_isGiftCardEnabled_stays_false_when_gift_cards_plugin_is_not_installed() {
        // Given
        let stores = MockStoresManager(sessionManager: .testingInstance)

        var viewModel: EditableOrderViewModel?
        waitFor { promise in
            stores.whenReceivingAction(ofType: SystemStatusAction.self) { action in
                guard case let .fetchSystemPluginWithPath(_, pluginPath, onCompletion) = action else {
                    return
                }
                XCTAssertEqual(pluginPath, "woocommerce-gift-cards/woocommerce-gift-cards.php")
                onCompletion(nil)
                promise(())
            }

            // When
            viewModel = EditableOrderViewModel(siteID: self.sampleSiteID, stores: stores, storageManager: self.storageManager)
            XCTAssertEqual(viewModel?.paymentDataViewModel.isGiftCardEnabled, false)
        }

        // Then
        XCTAssertEqual(viewModel?.paymentDataViewModel.isGiftCardEnabled, false)
    }

    func test_isAddGiftCardActionEnabled_is_false_when_order_total_is_zero() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID)

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), currencySettings: .init())

        // Then
        XCTAssertEqual(viewModel.paymentDataViewModel.isAddGiftCardActionEnabled, false)
    }

    func test_isAddGiftCardActionEnabled_is_true_when_order_total_is_positive() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID, total: "0.01")

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), currencySettings: .init())

        // Then
        XCTAssertEqual(viewModel.paymentDataViewModel.isAddGiftCardActionEnabled, true)
    }

    func test_appliedGiftCards_have_negative_formatted_amount() {
        // Given
        let order = Order.fake().copy(orderID: sampleOrderID, appliedGiftCards: [
            .init(giftCardID: 1, code: "AAAA-BBBB-AAAA-BBBB", amount: 15.3333),
            .init(giftCardID: 1, code: "AAAA-BBBB-AAAA-BBBB", amount: 2),
            .init(giftCardID: 2, code: "BBBB-AAAA-BBBB-AAAA", amount: 5.6)
        ])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), currencySettings: .init())

        // Then
        let expectedGiftCards: [EditableOrderViewModel.PaymentDataViewModel.AppliedGiftCard] = [
            .init(code: "AAAA-BBBB-AAAA-BBBB", amount: "-$15.33"),
            .init(code: "AAAA-BBBB-AAAA-BBBB", amount: "-$2.00"),
            .init(code: "BBBB-AAAA-BBBB-AAAA", amount: "-$5.60")
        ]
        assertEqual(expectedGiftCards, viewModel.paymentDataViewModel.appliedGiftCards)
    }

    func test_when_order_has_no_coupons_then_shouldDisallowDiscounts_is_false() {
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID)

        XCTAssertFalse(viewModel.shouldDisallowDiscounts)
    }

    func test_when_order_has_coupons_then_shouldDisallowDiscounts_is_true() {
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID)

        viewModel.saveCouponLine(result: .added(newCode: "Some coupon"))

        XCTAssertTrue(viewModel.shouldDisallowDiscounts)
    }

    func test_PaymentDataViewModel_when_initialized_then_shouldRenderCouponsInfoTooltip_returns_false() {
        // Given, When
        let paymentDataViewModel = EditableOrderViewModel.PaymentDataViewModel()

        // Then
        XCTAssertFalse(paymentDataViewModel.shouldRenderCouponsInfoTooltip)
    }


    func test_PaymentDataViewModel_when_order_should_show_coupons_then_shouldRenderCouponsInfoTooltip_returns_false() {
        // Given, When
        let paymentDataViewModel = EditableOrderViewModel.PaymentDataViewModel(shouldShowCoupon: true)

        // Then
        XCTAssertFalse(paymentDataViewModel.shouldRenderCouponsInfoTooltip)
    }

    func test_PaymentDataViewModel_when_order_should_show_discounts_then_shouldRenderCouponsInfoTooltip_returns_true() {
        // Given, When
        let paymentDataViewModel = EditableOrderViewModel.PaymentDataViewModel(shouldShowDiscountTotal: true)

        // Then
        XCTAssertTrue(paymentDataViewModel.shouldRenderCouponsInfoTooltip)
    }

    // MARK: Parent/child order items

    func test_bundle_child_order_items_excluded_from_productRows_and_added_to_parent_childProductRows() throws {
        let bundleItem = ProductBundleItem.fake().copy(productID: 5)
        let bundleProduct = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: 606, bundleItems: [bundleItem])
        storageManager.insertProducts([.fake().copy(siteID: sampleSiteID, productID: bundleItem.productID, purchasable: true)])
        let order = Order.fake().copy(siteID: sampleSiteID, orderID: 1, items: [
            // Bundle product order item.
            .fake().copy(itemID: 6, productID: bundleProduct.productID, quantity: 2),
            // Child bundled item with `parent` equal to the bundle parent item ID.
            .fake().copy(itemID: 2, productID: bundleItem.productID, quantity: 1, parent: 6),
        ])

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: order),
                                               stores: stores,
                                               storageManager: storageManager)

        // Then
        XCTAssertEqual(viewModel.productRows.count, 1)

        let parentOrderItemRow = try XCTUnwrap(viewModel.productRows[0])
        XCTAssertEqual(parentOrderItemRow.productRow.stepperViewModel.quantity, 2)

        let childOrderItemRow = try XCTUnwrap(parentOrderItemRow.childProductRows[0])
        XCTAssertEqual(childOrderItemRow.stepperViewModel.quantity, 1)
    }

    // Existing items: bundle A with child item, non-bundle B —> select bundle A again and configure in product selector
    // —> order items to update remotely: bundle A with child item, non-bundle B, bundle A with bundle configuration
    func test_when_existing_items_contain_bundle_and_non_bundle_then_selecting_same_bundle_results_in_two_bundles() throws {
        // Given
        let bundleItem = ProductBundleItem.fake().copy(productID: 5)
        let bundleProduct = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: 606, bundleItems: [bundleItem])
        let nonBundleProduct = Product.fake().copy(siteID: sampleSiteID, productID: 777, purchasable: true)
        storageManager.insertProducts([nonBundleProduct,
                                       // Product of the bundled item.
                                       .fake().copy(siteID: sampleSiteID, productID: bundleItem.productID, purchasable: true)])
        let order = Order.fake().copy(siteID: sampleSiteID, orderID: 1, items: [
            // Bundle product order item.
            .fake().copy(itemID: 6, productID: bundleProduct.productID, quantity: 2),
            // Child bundled item with `parent` equal to the bundle parent item ID.
            .fake().copy(itemID: 2, productID: bundleItem.productID, quantity: 1, parent: 6),
            // Non-bundle simple item.
            .fake().copy(itemID: 8, productID: 777, quantity: 2),
        ])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores, storageManager: storageManager)

        // When entering the product selector
        viewModel.toggleProductSelectorVisibility()
        let productSelector = try XCTUnwrap(viewModel.productSelectorViewModel)

        // The child bundled item is not counted as a product in the product selector
        XCTAssertEqual(productSelector.totalSelectedItemsCount, 2)

        // When selecting & configuring a bundle product
        try selectAndConfigureBundleProduct(from: productSelector, productID: bundleProduct.productID, viewModel: viewModel)

        // When completing the product selector, then it triggers `OrderAction.updateOrder`
        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .updateOrder(_, order, _, _, onCompletion):
                    promise(order)
                        onCompletion(.success(order))
                default:
                    XCTFail("Received unsupported action: \(action)")
                }
            }

            productSelector.completeMultipleSelection()
        }

        // Then order to be updated remotely contains the expected items
        XCTAssertEqual(orderToUpdate.items.count, 4)

        let existingBundleOrderItem = try XCTUnwrap(orderToUpdate.items[0])
        XCTAssertEqual(existingBundleOrderItem.productID, bundleProduct.productID)
        XCTAssertEqual(existingBundleOrderItem.bundleConfiguration, [])
        XCTAssertEqual(existingBundleOrderItem.quantity, 2)

        let existingChildBundleOrderItem = try XCTUnwrap(orderToUpdate.items[1])
        XCTAssertEqual(existingChildBundleOrderItem.productID, 5)
        XCTAssertEqual(existingChildBundleOrderItem.quantity, 1)

        let existingNonBundleOrderItem = try XCTUnwrap(orderToUpdate.items[2])
        XCTAssertEqual(existingNonBundleOrderItem.productID, nonBundleProduct.productID)
        XCTAssertEqual(existingNonBundleOrderItem.quantity, 2)

        let newBundleOrderItem = try XCTUnwrap(orderToUpdate.items[3])
        XCTAssertEqual(newBundleOrderItem.productID, bundleProduct.productID)
        XCTAssertTrue(newBundleOrderItem.bundleConfiguration.isNotEmpty)
    }

    // Existing items: bundle A with child item —> select non-bundle B which is A's child item in product selector
    // —> order items to update remotely: bundle A with child item, non-bundle B
    func test_when_existing_items_contain_bundle_then_selecting_non_bundle_child_item_results_in_same_bundle_and_new_non_bundle_item() throws {
        // Given
        let itemProductID: Int64 = 777
        let bundleItem = ProductBundleItem.fake().copy(productID: itemProductID)
        let bundleProduct = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: 606, bundleItems: [bundleItem])
        // Non-bundle product is in storage but not part of the order.
        let nonBundleProduct = Product.fake().copy(siteID: sampleSiteID, productID: itemProductID, purchasable: true)
        storageManager.insertProducts([nonBundleProduct,
                                       // Product of the bundled item.
                                       .fake().copy(siteID: sampleSiteID, productID: bundleItem.productID, purchasable: true)])

        let order = Order.fake().copy(siteID: sampleSiteID, orderID: 1, items: [
            // Bundle product order item.
            .fake().copy(itemID: 6, productID: bundleProduct.productID, quantity: 2),
            // Child bundled item with `parent` equal to the bundle parent item ID.
            .fake().copy(itemID: 2, productID: bundleItem.productID, quantity: 1, parent: 6),
        ])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores, storageManager: storageManager)

        // When entering the product selector
        viewModel.toggleProductSelectorVisibility()
        let productSelector = try XCTUnwrap(viewModel.productSelectorViewModel)

        // The child bundled item is not counted as a product in the product selector
        XCTAssertEqual(productSelector.totalSelectedItemsCount, 1)

        // When selecting the non-bundle product
        productSelector.changeSelectionStateForProduct(with: nonBundleProduct.productID, selected: true)

        XCTAssertEqual(productSelector.totalSelectedItemsCount, 2)

        // When completing the product selector, then it triggers `OrderAction.updateOrder`
        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                    case let .updateOrder(_, order, _, _, onCompletion):
                        promise(order)
                        onCompletion(.success(order))
                    default:
                        XCTFail("Received unsupported action: \(action)")
                }
            }

            productSelector.completeMultipleSelection()
        }

        // Then order to be updated remotely contains the expected items
        XCTAssertEqual(orderToUpdate.items.count, 3)

        let existingBundleOrderItem = try XCTUnwrap(orderToUpdate.items[0])
        XCTAssertEqual(existingBundleOrderItem.productID, bundleProduct.productID)
        XCTAssertEqual(existingBundleOrderItem.bundleConfiguration, [])
        XCTAssertEqual(existingBundleOrderItem.quantity, 2)

        let existingChildBundleOrderItem = try XCTUnwrap(orderToUpdate.items[1])
        XCTAssertEqual(existingChildBundleOrderItem.productID, itemProductID)
        XCTAssertEqual(existingChildBundleOrderItem.quantity, 1)

        let newNonBundleOrderItem = try XCTUnwrap(orderToUpdate.items[2])
        XCTAssertEqual(newNonBundleOrderItem.productID, nonBundleProduct.productID)
        XCTAssertEqual(newNonBundleOrderItem.quantity, 1)
        XCTAssertEqual(newNonBundleOrderItem.itemID, .zero)
    }

    // No existing items —> select bundle A and configure, repeat selecting and configuring bundle A in product selector
    // —> order items to update remotely: bundle A with bundle configuration, bundle A with bundle configuration
    func test_when_no_existing_items_then_selecting_bundle_twice_results_in_two_bundle_items() throws {
        // Given
        let bundleItem = ProductBundleItem.fake().copy(productID: 5)
        let bundleProduct = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: 606, bundleItems: [bundleItem])
        // Product of the bundled item.
        storageManager.insertProducts([.fake().copy(siteID: sampleSiteID, productID: bundleItem.productID, purchasable: true)])

        let order = Order.fake().copy(siteID: sampleSiteID, orderID: 1, items: [])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores, storageManager: storageManager)

        // When entering the product selector
        viewModel.toggleProductSelectorVisibility()
        let productSelector = try XCTUnwrap(viewModel.productSelectorViewModel)

        // The child bundled item is not counted as a product in the product selector
        XCTAssertEqual(productSelector.totalSelectedItemsCount, 0)

        // When selecting the bundle product twice
        let firstBundleConfiguration: [BundledProductConfiguration] = [
            .init(bundledItemID: 2, productOrVariation: .product(id: 5), quantity: 1, isOptionalAndSelected: true)
        ]
        try selectAndConfigureBundleProduct(from: productSelector,
                                            productID: bundleProduct.productID,
                                            bundleConfiguration: firstBundleConfiguration,
                                            viewModel: viewModel)

        let secondBundleConfiguration: [BundledProductConfiguration] = [
            .init(bundledItemID: 2, productOrVariation: .product(id: 5), quantity: 5, isOptionalAndSelected: false)
        ]
        try selectAndConfigureBundleProduct(from: productSelector,
                                            productID: bundleProduct.productID,
                                            bundleConfiguration: secondBundleConfiguration,
                                            viewModel: viewModel)

        // When completing the product selector, then it triggers `OrderAction.updateOrder`
        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                    case let .updateOrder(_, order, _, _, onCompletion):
                        promise(order)
                        onCompletion(.success(order))
                    default:
                        XCTFail("Received unsupported action: \(action)")
                }
            }

            productSelector.completeMultipleSelection()
        }

        // Then order to be updated remotely contains the expected items
        XCTAssertEqual(orderToUpdate.items.count, 2)

        let firstNewBundleOrderItem = try XCTUnwrap(orderToUpdate.items[0])
        XCTAssertEqual(firstNewBundleOrderItem.productID, bundleProduct.productID)
        XCTAssertEqual(firstNewBundleOrderItem.bundleConfiguration, [.fake().copy(bundledItemID: 2, productID: 5, quantity: 1, isOptionalAndSelected: true)])
        XCTAssertEqual(firstNewBundleOrderItem.quantity, 1)

        let secondNewBundleOrderItem = try XCTUnwrap(orderToUpdate.items[1])
        XCTAssertEqual(secondNewBundleOrderItem.productID, bundleProduct.productID)
        XCTAssertEqual(secondNewBundleOrderItem.bundleConfiguration, [.fake().copy(bundledItemID: 2, productID: 5, quantity: 5, isOptionalAndSelected: false)])
        XCTAssertEqual(secondNewBundleOrderItem.quantity, 1)
    }

    // No existing items —> select bundle A and configure in product selector -> close product selector
    // —> select bundle A and configure in product selector
    // —> order items to update remotely: bundle A with the latest bundle configuration
    func test_selecting_bundle_then_canceling_then_selecting_bundle_again_results_in_one_bundle_item_with_the_latest_configuration() throws {
        // Given
        let bundleItem = ProductBundleItem.fake().copy(productID: 5)
        let bundleProduct = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: 606, bundleItems: [bundleItem])
        // Product of the bundled item.
        storageManager.insertProducts([.fake().copy(siteID: sampleSiteID, productID: bundleItem.productID, purchasable: true)])

        let order = Order.fake().copy(siteID: sampleSiteID, orderID: 1, items: [])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, flow: .editing(initialOrder: order), stores: stores, storageManager: storageManager)

        // When entering the product selector
        viewModel.toggleProductSelectorVisibility()
        let productSelector = try XCTUnwrap(viewModel.productSelectorViewModel)

        // The child bundled item is not counted as a product in the product selector
        XCTAssertEqual(productSelector.totalSelectedItemsCount, 0)

        // When selecting the bundle product twice
        let firstBundleConfiguration: [BundledProductConfiguration] = [
            .init(bundledItemID: 2, productOrVariation: .product(id: 5), quantity: 1, isOptionalAndSelected: true)
        ]
        try selectAndConfigureBundleProduct(from: productSelector,
                                            productID: bundleProduct.productID,
                                            bundleConfiguration: firstBundleConfiguration,
                                            viewModel: viewModel)
        productSelector.closeButtonTapped()

        let secondBundleConfiguration: [BundledProductConfiguration] = [
            .init(bundledItemID: 2, productOrVariation: .product(id: 5), quantity: 5, isOptionalAndSelected: false)
        ]
        try selectAndConfigureBundleProduct(from: productSelector,
                                            productID: bundleProduct.productID,
                                            bundleConfiguration: secondBundleConfiguration,
                                            viewModel: viewModel)

        // When completing the product selector, then it triggers `OrderAction.updateOrder`
        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                    case let .updateOrder(_, order, _, _, onCompletion):
                        promise(order)
                        onCompletion(.success(order))
                    default:
                        XCTFail("Received unsupported action: \(action)")
                }
            }

            productSelector.completeMultipleSelection()
        }

        // Then order to be updated remotely contains the expected items
        XCTAssertEqual(orderToUpdate.items.count, 1)

        let newBundleOrderItem = try XCTUnwrap(orderToUpdate.items[0])
        XCTAssertEqual(newBundleOrderItem.productID, bundleProduct.productID)
        XCTAssertEqual(newBundleOrderItem.bundleConfiguration, [.fake().copy(bundledItemID: 2, productID: 5, quantity: 5, isOptionalAndSelected: false)])
        XCTAssertEqual(newBundleOrderItem.quantity, 1)
    }

    func test_createProductRowViewModel_correctly_sets_pricedIndividually_for_product_bundle_row() throws {
        // Given
        let bundledItems = [ProductBundleItem.fake().copy(productID: 2, pricedIndividually: false),
                            ProductBundleItem.fake().copy(productID: 3, pricedIndividually: true)]
        let product = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: sampleProductID, bundleItems: bundledItems)
        storageManager.insertProducts([Product.fake().copy(siteID: sampleSiteID, productID: 2),
                                       Product.fake().copy(siteID: sampleSiteID, productID: 3)])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(productID: product.productID, quantity: 1)
        let childItems = [OrderItem.fake().copy(productID: 2, quantity: 1),
                          OrderItem.fake().copy(productID: 3, quantity: 1)]
        let productRow = viewModel.createProductRowViewModel(for: orderItem, childItems: childItems)

        // Then
        XCTAssertTrue(try XCTUnwrap(productRow).productRow.priceSummaryViewModel.pricedIndividually)
        XCTAssertFalse(try XCTUnwrap(productRow?.childProductRows[0]).priceSummaryViewModel.pricedIndividually)
        XCTAssertTrue(try XCTUnwrap(productRow?.childProductRows[1]).priceSummaryViewModel.pricedIndividually)
    }

    func test_createProductRowViewModel_sets_isReadOnly_to_false_for_bundle_parent_and_true_for_bundle_child_items() throws {
        // Given
        let bundledItems = [ProductBundleItem.fake().copy(productID: 2, pricedIndividually: false),
                            ProductBundleItem.fake().copy(productID: 3, pricedIndividually: true)]
        let product = storageManager.createAndInsertBundleProduct(siteID: sampleSiteID, productID: sampleProductID, bundleItems: bundledItems)
        storageManager.insertProducts([Product.fake().copy(siteID: sampleSiteID, productID: 2),
                                       Product.fake().copy(siteID: sampleSiteID, productID: 3)])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(productID: product.productID, quantity: 1)
        let childItems = [OrderItem.fake().copy(productID: 2, quantity: 1),
                          OrderItem.fake().copy(productID: 3, variationID: 4, quantity: 1)]
        let productRow = try XCTUnwrap(viewModel.createProductRowViewModel(for: orderItem, childItems: childItems))

        // Then
        XCTAssertFalse(productRow.productRow.isReadOnly, "Parent product should not be read only")
        XCTAssertTrue(try XCTUnwrap(productRow.childProductRows[0]).isReadOnly, "Child product should be read only")
        XCTAssertTrue(try XCTUnwrap(productRow.childProductRows[1]).isReadOnly, "Child product variation should be read only")
    }

    func test_createProductRowViewModel_sets_isReadOnly_to_false_for_non_bundle_parent_and_child_items() throws {
        // Given
        storageManager.insertProducts([Product.fake().copy(siteID: sampleSiteID, productID: 1),
                                       Product.fake().copy(siteID: sampleSiteID, productID: 2),
                                       Product.fake().copy(siteID: sampleSiteID, productID: 3)])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)

        // When
        let orderItem = OrderItem.fake().copy(productID: 1, quantity: 1)
        let childItems = [OrderItem.fake().copy(productID: 2, quantity: 1),
                          OrderItem.fake().copy(productID: 3, variationID: 4, quantity: 1)]
        let productRow = try XCTUnwrap(viewModel.createProductRowViewModel(for: orderItem, childItems: childItems))

        // Then
        XCTAssertFalse(productRow.productRow.isReadOnly, "Parent product should not be read only")
        XCTAssertFalse(try XCTUnwrap(productRow.childProductRows[0]).isReadOnly, "Child product should not be read only")
        XCTAssertFalse(try XCTUnwrap(productRow.childProductRows[1]).isReadOnly, "Child product variation should not be read only")
    }

    func test_addCustomAmount_toggles_showAddCustomAmount_to_true_when_order_is_new() {
        // Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, storageManager: storageManager)
        XCTAssertFalse(viewModel.customAmountsSectionViewModel.showAddCustomAmount)

        // When
        viewModel.addCustomAmount()

        // Then
        XCTAssertTrue(viewModel.customAmountsSectionViewModel.showAddCustomAmount)
    }

    func test_init_with_initialItem_which_is_a_parent_product_shows_notice() {
        // Given
        let parentProductItem = OrderBaseItem.product(.fake().copy(variations: [123]))

        // When
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, initialItem: parentProductItem)

        // Then
        XCTAssertNotNil(viewModel.autodismissableNotice)
        assertEqual("You cannot add a variable product directly.", viewModel.autodismissableNotice?.title)
    }

    func test_when_feature_flag_disabled_saveInflightCustomerDetails_is_invoked_then_order_is_updated_with_latestAddressFormFields() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID, featureFlagService: featureFlagService)
        let sampleAddress = sampleAddress1()
        let expectedFullName = sampleAddress1().fullName

        XCTAssertEqual(viewModel.latestAddressFormFields?.firstName, "", "Address form fields should be empty on initialization")
        XCTAssertEqual(viewModel.latestAddressFormFields?.lastName, "", "Address form fields should be empty on initialization")

        viewModel.addressFormViewModel.fields.firstName = sampleAddress.firstName
        viewModel.addressFormViewModel.fields.lastName = sampleAddress.lastName

        XCTAssertFalse(viewModel.customerDataViewModel.isDataAvailable)
        XCTAssertNil(viewModel.customerDataViewModel.fullName, "No customer details have been added to the order")

        // When
        viewModel.saveInflightCustomerDetails()

        // Then
        XCTAssertTrue(viewModel.hasChanges)
        XCTAssertTrue(viewModel.customerDataViewModel.isDataAvailable)
        XCTAssertEqual(viewModel.customerDataViewModel.fullName, expectedFullName, "Customer details have been added to the order")

    }

    func test_when_saveInFlightOrderNotes_is_invoked_then_customer_note_is_updated() {
        //Given
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID)
        viewModel.noteViewModel.newNote = "This is a note"

        // When
        viewModel.saveInFlightOrderNotes()

        //Then
        XCTAssertTrue(viewModel.hasChanges)
    }

    func test_editing_existing_shipping_line_sets_expected_shippingLineDetails_view_model() throws {
        // Given
        let shippingLine = ShippingLine.fake().copy(shippingID: 1, methodTitle: "Package 1")
        let order = Order.fake().copy(siteID: sampleSiteID, shippingLines: [shippingLine])
        let viewModel = EditableOrderViewModel(siteID: sampleSiteID,
                                               flow: .editing(initialOrder: order),
                                               storageManager: storageManager)

        // When
        viewModel.shippingLineViewModel.shippingLineRows.first?.editShippingLine()

        // Then
        let editShippingLineViewModel = try XCTUnwrap(viewModel.shippingLineViewModel.shippingLineDetails)
        assertEqual(shippingLine.methodTitle, editShippingLineViewModel.methodTitle)
    }

    func test_order_creation_when_initialCustomer_is_nil_does_not_trigger_sync() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: true)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        _ = EditableOrderViewModel(siteID: sampleSiteID,
                                   stores: stores,
                                   featureFlagService: featureFlagService,
                                   initialCustomer: nil)
    }

    func test_order_creation_when_initialCustomer_is_nil_does_not_trigger_sync_in_legacy_customer_flow() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            // Then
            XCTFail("Unexpected action: \(action)")
        }
        _ = EditableOrderViewModel(siteID: sampleSiteID,
                                   stores: stores,
                                   featureFlagService: featureFlagService,
                                   initialCustomer: nil)
    }

    func test_order_creation_when_initialCustomer_is_not_nil_syncs_order_with_customer_data() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: true)
        let address = Address.fake().copy(address1: "1 Main Street")
        let customerData: (id: Int64, billing: Address, shipping: Address) = (123, address, address)

        // When
        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, order, _, onCompletion):
                    promise(order)
                    onCompletion(.success(.fake()))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            _ = EditableOrderViewModel(siteID: self.sampleSiteID,
                                       stores: self.stores,
                                       featureFlagService: featureFlagService,
                                       initialCustomer: customerData)
        }

        // Then
        assertEqual(customerData.id, orderToUpdate.customerID)
        assertEqual(customerData.billing, orderToUpdate.billingAddress)
        assertEqual(customerData.shipping, orderToUpdate.shippingAddress)
    }

    func test_order_creation_when_initialCustomer_is_not_nil_syncs_order_with_customer_data_in_legacy_customer_flow() {
        // Given
        let featureFlagService = MockFeatureFlagService(isSubscriptionsInOrderCreationCustomersEnabled: false)
        let address = Address.fake().copy(address1: "1 Main Street")
        let customerData: (id: Int64, billing: Address, shipping: Address) = (123, address, address)

        // When
        let orderToUpdate: Order = waitFor { promise in
            self.stores.whenReceivingAction(ofType: OrderAction.self) { action in
                switch action {
                case let .createOrder(_, order, _, onCompletion):
                    promise(order)
                    onCompletion(.success(.fake()))
                default:
                    XCTFail("Unexpected action: \(action)")
                }
            }
            _ = EditableOrderViewModel(siteID: self.sampleSiteID,
                                       stores: self.stores,
                                       featureFlagService: featureFlagService,
                                       initialCustomer: customerData)
        }

        // Then
        assertEqual(customerData.id, orderToUpdate.customerID)
        assertEqual(customerData.billing, orderToUpdate.billingAddress)
        assertEqual(customerData.shipping, orderToUpdate.shippingAddress)
    }
}

private extension EditableOrderViewModelTests {
    func selectAndConfigureBundleProduct(from productSelector: ProductSelectorViewModel,
                                         productID: Int64,
                                         bundleConfiguration: [BundledProductConfiguration] = [
                                            .init(bundledItemID: 1, productOrVariation: .product(id: 2), quantity: 5, isOptionalAndSelected: nil)
                                         ],
                                         viewModel: EditableOrderViewModel) throws {
        let bundleProductRow = try XCTUnwrap(productSelector.productsSectionViewModels.first?.productRows
            .first(where: { $0.productOrVariationID == productID }))
        bundleProductRow.configure?()

        // Then the configurable product view model becomes non-nil
        let configurableProductViewModel = try XCTUnwrap(viewModel.productToConfigureViewModel)

        // When saving the bundle configuration of the bundle product
        configurableProductViewModel
            .onConfigure(bundleConfiguration)
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

    @discardableResult
    func insert(_ readOnlyProduct: Product) -> StorageProduct {
        let product = viewStorage.insertNewObject(ofType: StorageProduct.self)
        product.update(with: readOnlyProduct)
        return product
    }

    func insert(_ readOnlyProductBundleItem: ProductBundleItem, for product: StorageProduct) {
        let bundleItem = viewStorage.insertNewObject(ofType: StorageProductBundleItem.self)
        bundleItem.update(with: readOnlyProductBundleItem)
        bundleItem.product = product
    }

    func createAndInsertBundleProduct(siteID: Int64, productID: Int64, bundleItems: [Yosemite.ProductBundleItem]) -> Yosemite.Product {
        let bundleProduct = Product.fake().copy(siteID: siteID,
                                                productID: productID,
                                                productTypeKey: ProductType.bundle.rawValue,
                                                purchasable: true,
                                                bundledItems: bundleItems)
        let storageProduct = insert(bundleProduct)

        bundleItems.forEach { bundleItem in
            insert(bundleItem, for: storageProduct)
        }

        return bundleProduct
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
