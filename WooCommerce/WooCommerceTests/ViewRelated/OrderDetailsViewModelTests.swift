import TestKit
import WooFoundation
import XCTest
import Yosemite

import YosemiteTestHelpers
@testable import WooCommerce

@MainActor
final class OrderDetailsViewModelTests: XCTestCase {
    private var order: Order!
    private var viewModel: OrderDetailsViewModel!

    private var storesManager: MockStoresManager!
    private var storageManager: MockStorageManager!

    override func setUp() {
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        storageManager = MockStorageManager()

        order = MockOrders().sampleOrder()

        viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)

        let analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())
        ServiceLocator.setAnalytics(analytics)
        super.setUp()
    }

    override func tearDown() {
        super.tearDown()
        viewModel = nil
        order = nil
        storesManager = nil
    }

    func test_deleteTracking_fires_orderTrackingDelete_Tracks_event() {
        // Given
        let mockShipmentTracking = ShipmentTracking(siteID: 1111,
                                                    orderID: 1111,
                                                    trackingID: "1111",
                                                    trackingNumber: "1111",
                                                    trackingProvider: nil,
                                                    trackingURL: nil,
                                                    dateShipped: nil)

        // When
        viewModel.deleteTracking(mockShipmentTracking) { _ in }

        // Then
        let analytics = ServiceLocator.analytics.analyticsProvider as! MockAnalyticsProvider
        let receivedEvents = analytics.receivedEvents

        XCTAssert(receivedEvents.contains(WooAnalyticsStat.orderTrackingDelete.rawValue))
    }

    func test_markComplete_dispatches_updateOrder_action() throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        _ = viewModel.markCompleted(flow: .editing)

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? OrderAction)
        guard case let .updateOrderStatus(siteID: siteID, orderID: orderID, status: status, onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(OrderAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertEqual(status, .completed)
    }

    // MARK: - `syncShippingLabelsOrShipments`

    func test_syncShippingLabelsOrShipments_when_wooShipping_fails_then_tracks_revamped_flow() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        whenHandlingWooShippingActions(shipmentsResult: .failure(NSError(domain: "test", code: 1)))
        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelsOrShipments(for: .wooShipping)

        // Then
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelsAPIRequest.rawValue,
                                         with: ["action": "failed", "is_revamped_flow": true])
    }

    func test_syncShippingLabelsOrShipments_when_legacyWCShip_fails_then_tracks_legacy_flow_and_clears_labels() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        viewModel.update(order: order.copy(shippingLabels: [.fake().copy(shippingLabelID: 123)]))
        whenHandlingLegacyShippingLabelActions(labelsResult: .failure(NSError(domain: "test", code: 1)))
        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelsOrShipments(for: .legacyWCShip)

        // Then
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelsAPIRequest.rawValue,
                                         with: ["action": "failed", "is_revamped_flow": false])
        XCTAssertTrue(viewModel.order.shippingLabels.isEmpty)
    }

    func test_syncShippingLabelsOrShipments_when_unsupported_then_does_not_dispatch() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelsOrShipments(for: .unsupported)

        // Then
        XCTAssertTrue(storesManager.receivedActions.isEmpty)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.shippingLabelsAPIRequest.rawValue))
    }

    func test_syncShippingLabels_without_a_non_virtual_product_does_not_dispatch_actions() async throws {
        // Given
        configureDefaultStoreCountry("US")
        whenHandlingWooShippingActions()
        whenHandlingLegacyShippingLabelActions()
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        await viewModel.syncShippingLabelsOrShipments(for: .wooShipping)

        // Then no actions are dispatched
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_syncShippingLabelsOrShipments_when_legacyWCShip_then_dispatches_and_tracks_flow() async throws {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        let labels = [ShippingLabel.fake().copy(shippingLabelID: 123)]
        whenHandlingLegacyShippingLabelActions(labelsResult: .success(labels))
        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelsOrShipments(for: .legacyWCShip)

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
        guard case let .synchronizeShippingLabels(siteID, orderID, _) = action else {
            XCTFail("Expected synchronizeShippingLabels")
            return
        }
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelsAPIRequest.rawValue,
                                         with: ["action": "success", "is_revamped_flow": false])
        XCTAssertEqual(viewModel.order.shippingLabels, labels)
    }

    func test_syncShippingLabelsOrShipments_when_wooShipping_then_dispatches_and_tracks_flow() async throws {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelsOrShipments(for: .wooShipping)

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        let action = try XCTUnwrap(storesManager.receivedActions.first as? WooShippingAction)
        guard case let .syncShipments(siteID, orderID, _) = action else {
            XCTFail("Expected syncShipments")
            return
        }
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelsAPIRequest.rawValue,
                                         with: ["action": "success", "is_revamped_flow": true])
    }

    func test_syncShippingLabels_when_store_country_is_not_supported_does_not_dispatch_actions() async throws {
        for storeCountry in ["FR", "DE", "BR", "IN"] {
            // Given
            let viewModel = configureShippingLabelContext(storeCountry: storeCountry)

            // When
            await viewModel.syncShippingLabelsOrShipments(for: .wooShipping)

            // Then
            XCTAssertEqual(storesManager.receivedActions.count, 0, "Expected no actions for \(storeCountry)")
        }
    }

    func test_syncShippingLabels_when_store_country_is_unknown_dispatches_actions() async throws {
        for storeCountry in [nil, ""] {
            // Given
            let viewModel = configureShippingLabelContext(storeCountry: storeCountry)

            // When
            await viewModel.syncShippingLabelsOrShipments(for: .wooShipping)

            // Then
            XCTAssertEqual(storesManager.receivedActions.count, 1, "Expected fail-open shipment sync for \(String(describing: storeCountry))")

            let action = try XCTUnwrap(storesManager.receivedActions.first as? WooShippingAction)
            guard case let WooShippingAction.syncShipments(siteID, orderID, _) = action else {
                XCTFail("Expected \(action) to be \(WooShippingAction.self)")
                return
            }

            XCTAssertEqual(siteID, order.siteID)
            XCTAssertEqual(orderID, order.orderID)
        }
    }

    // MARK: - `checkShippingLabelCreationEligibility`

    func test_checkShippingLabelCreationEligibility_when_ineligible_then_returns_false_without_tracking() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        whenHandlingWooShippingActions(isEligible: false)
        whenHandlingLegacyShippingLabelActions(isEligible: false)

        for support in [OrderDetailsViewModel.ShippingLabelSupport.wooShipping, .legacyWCShip] {
            analyticsProvider.clearEvents()

            // When
            let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: support)

            // Then
            XCTAssertFalse(isEligible)
            XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue))
        }
    }

    func test_checkShippingLabelCreationEligibility_when_unsupported_then_returns_false_without_dispatching() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        analyticsProvider.clearEvents()

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .unsupported)

        // Then
        XCTAssertFalse(isEligible)
        XCTAssertTrue(storesManager.receivedActions.isEmpty)
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue))
    }

    func test_checkShippingLabelCreationEligibility_when_products_are_not_loaded_then_dispatches_check() async throws {
        // Given
        configureDefaultStoreCountry("US")
        let order = order.copy(items: [.fake().copy(productID: 987)])
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        whenHandlingWooShippingActions()
        XCTAssertTrue(viewModel.products.isEmpty)

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

        // Then
        XCTAssertTrue(isEligible)
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        let action = try XCTUnwrap(storesManager.receivedActions.first as? WooShippingAction)
        guard case .checkCreationEligibility = action else {
            XCTFail("Expected eligibility check with incomplete product data")
            return
        }
    }

    func test_checkShippingLabelCreationEligibility_without_a_non_virtual_product_returns_false() async throws {
        // Given
        configureDefaultStoreCountry("US")
        whenHandlingWooShippingActions()
        whenHandlingLegacyShippingLabelActions()
        storesManager.reset()

        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager)

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

        // Then no actions are dispatched
        XCTAssertFalse(isEligible)
        XCTAssertTrue(storesManager.receivedActions.isEmpty)
    }

    func test_checkShippingLabelCreationEligibility_with_a_non_virtual_product_returns_value_from_action() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])
        configureDefaultStoreCountry("US")
        whenHandlingWooShippingActions()

        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager)

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

        // Then
        XCTAssertTrue(isEligible)
    }

    func test_checkShippingLabelCreationEligibility_without_a_non_virtual_product_does_not_dispatch_actions() async throws {
        // Given
        configureDefaultStoreCountry("US")
        whenHandlingWooShippingActions()
        whenHandlingLegacyShippingLabelActions()
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

        // Then no actions are dispatched
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_checkShippingLabelCreationEligibility_when_legacyWCShip_then_dispatches_and_tracks_flow() async throws {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        analyticsProvider.clearEvents()

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .legacyWCShip)

        // Then
        XCTAssertTrue(isEligible)
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
        guard case let .checkCreationEligibility(siteID, orderID, _) = action else {
            XCTFail("Expected checkCreationEligibility")
            return
        }
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue,
                                         with: ["order_status": order.status.rawValue, "is_revamped_flow": false])
    }

    func test_checkShippingLabelCreationEligibility_when_wooShipping_then_dispatches_and_tracks_flow() async throws {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        analyticsProvider.clearEvents()

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

        // Then
        XCTAssertTrue(isEligible)
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        let action = try XCTUnwrap(storesManager.receivedActions.first as? WooShippingAction)
        guard case let .checkCreationEligibility(siteID, orderID, _) = action else {
            XCTFail("Expected checkCreationEligibility")
            return
        }
        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue,
                                         with: ["order_status": order.status.rawValue, "is_revamped_flow": true])
    }

    func test_checkShippingLabelCreationEligibility_when_store_country_is_not_supported_returns_false_without_dispatching_actions() async throws {
        for storeCountry in ["FR", "DE", "BR", "IN"] {
            // Given
            let viewModel = configureShippingLabelContext(storeCountry: storeCountry)

            // When
            let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

            // Then
            XCTAssertFalse(isEligible, "Expected ineligible for \(storeCountry)")
            XCTAssertEqual(storesManager.receivedActions.count, 0, "Expected no actions for \(storeCountry)")
        }
    }

    func test_checkShippingLabelCreationEligibility_when_store_country_is_unknown_defers_to_eligibility_check() async throws {
        for storeCountry in [nil, "", "us", "Pr"] {
            // Given
            let viewModel = configureShippingLabelContext(storeCountry: storeCountry)

            // When
            let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

            // Then
            XCTAssertTrue(isEligible, "Expected fail-open eligibility result from action for \(String(describing: storeCountry))")
            XCTAssertEqual(storesManager.receivedActions.count, 1, "Expected eligibility check for \(String(describing: storeCountry))")
        }
    }

    func test_checkShippingLabelCreationEligibility_when_store_country_is_supported_dispatches_action() async throws {
        for storeCountry in ["US", "PR", "VI", "GU", "AS", "MP", "UM", "FM", "MH", "PW"] {
            // Given
            let viewModel = configureShippingLabelContext(storeCountry: storeCountry)

            // When
            let isEligible = await viewModel.checkShippingLabelCreationEligibility(for: .wooShipping)

            // Then
            XCTAssertTrue(isEligible, "Expected eligible result from action for \(storeCountry)")
            XCTAssertEqual(storesManager.receivedActions.count, 1, "Expected eligibility check for \(storeCountry)")

            let action = try XCTUnwrap(storesManager.receivedActions.first as? WooShippingAction)
            guard case let WooShippingAction.checkCreationEligibility(siteID, orderID, _) = action else {
                XCTFail("Expected \(action) to be \(WooShippingAction.self)")
                return
            }

            XCTAssertEqual(siteID, order.siteID)
            XCTAssertEqual(orderID, order.orderID)
        }
    }

    func test_there_should_not_be_edit_order_action_if_order_is_not_synced() {
        // Given
        let sessionManager = SessionManager.makeForTesting(cachedWooCommerceVersion: "11.1.0")
        let storesManager = MockStoresManager(sessionManager: sessionManager)
        let order = Order.fake().copy(currency: "USD", total: "10.0")

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              siteCurrencyProvider: { _ in CurrencyCode.GBP.rawValue })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.disabledForSyncing)
    }

    func test_edit_order_action_is_blocked_for_currency_mismatch_when_woocommerce_version_is_unknown() {
        // Given
        let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: usdOrder,
                                              stores: storesManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in CurrencyCode.GBP.rawValue })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.showNoticeForCurrencyConflict)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_blocked_for_currency_mismatch_when_woocommerce_version_is_older_than_11_1() {
        // Given
        let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)
        let currencySetting = SiteSetting.fake().copy(siteID: usdOrder.siteID,
                                                      settingID: CurrencySettings.Constants.currencyCodeKey,
                                                      value: CurrencyCode.GBP.rawValue,
                                                      settingGroupKey: SiteSettingGroup.general.rawValue)
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: currencySetting)
        let pluginsService = MockPluginsService()
        pluginsService.setMockPlugin(.wooCommerce, systemPlugin: .fake().copy(version: "11.0.9", active: true))

        // When
        let viewModel = OrderDetailsViewModel(order: usdOrder,
                                              storageManager: storageManager,
                                              syncStateController: syncStateController,
                                              pluginsService: pluginsService)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.showNoticeForCurrencyConflict)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_enabled_for_currency_mismatch_when_woocommerce_version_is_at_least_11_1() {
        for version in ["11.1.0", "11.1.0-dev", "11.1.1", "12.0.0"] {
            // Given
            let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")
            let syncStateController = OrderDetailsSyncStateController(syncState: .synced)
            let pluginsService = MockPluginsService()
            pluginsService.setMockPlugin(.wooCommerce, systemPlugin: .fake().copy(version: version, active: true))

            // When
            let viewModel = OrderDetailsViewModel(order: usdOrder,
                                                  syncStateController: syncStateController,
                                                  siteCurrencyProvider: { _ in CurrencyCode.GBP.rawValue },
                                                  pluginsService: pluginsService)

            // Then
            XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.enabled,
                           "Expected WooCommerce \(version) to support editing an order in another currency")
            XCTAssertEqual(viewModel.editOrderRequestCurrency, CurrencyCode.USD.rawValue)
        }
    }

    func test_edit_order_action_uses_active_stored_woocommerce_version_instead_of_inactive_or_session_versions() {
        // Given
        let order = Order.fake().copy(currency: "USD", total: "10.0")
        let sessionManager = SessionManager.makeForTesting(cachedWooCommerceVersion: "11.0.0")
        let storesManager = MockStoresManager(sessionManager: sessionManager)
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)
        let inactivePlugin = SystemPlugin.fake().copy(siteID: order.siteID,
                                                      plugin: "woocommerce/woocommerce.php",
                                                      version: "11.0.0",
                                                      active: false)
        let activePlugin = SystemPlugin.fake().copy(siteID: order.siteID,
                                                    plugin: "woocommerce/woocommerce.php",
                                                    version: "11.1.0-dev-31112307844-gb1a51de3",
                                                    active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: inactivePlugin)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: activePlugin)

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in CurrencyCode.GBP.rawValue })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, .enabled)
        XCTAssertEqual(viewModel.editOrderRequestCurrency, CurrencyCode.USD.rawValue)
    }

    func test_edit_order_action_does_not_use_session_woocommerce_version_when_site_has_no_stored_version() {
        // Given
        let order = Order.fake().copy(currency: "USD", total: "10.0")
        let sessionManager = SessionManager.makeForTesting(cachedWooCommerceVersion: "11.1.0")
        let storesManager = MockStoresManager(sessionManager: sessionManager)
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in CurrencyCode.GBP.rawValue })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, .showNoticeForCurrencyConflict)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_enabled_when_site_currency_is_missing() {
        // Given
        let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: usdOrder,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              syncStateController: syncStateController)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.enabled)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_enabled_when_order_currency_is_empty() {
        // Given
        let order = Order.fake().copy(currency: "", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in CurrencyCode.GBP.rawValue })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.enabled)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_blocked_when_order_currency_is_unsupported_and_differs_from_site_currency() {
        // Given
        let order = Order.fake().copy(currency: "XBT", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)
        let pluginsService = MockPluginsService()
        pluginsService.setMockPlugin(.wooCommerce, systemPlugin: .fake().copy(version: "11.1.0", active: true))

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in CurrencyCode.USD.rawValue },
                                              pluginsService: pluginsService)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, .showNoticeForCurrencyConflict)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_blocked_when_site_currency_is_unsupported_and_differs_from_order_currency() {
        // Given
        let order = Order.fake().copy(currency: "USD", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)
        let pluginsService = MockPluginsService()
        pluginsService.setMockPlugin(.wooCommerce, systemPlugin: .fake().copy(version: "11.1.0", active: true))

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in "XBT" },
                                              pluginsService: pluginsService)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, .showNoticeForCurrencyConflict)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_enabled_when_matching_currency_is_unsupported() {
        // Given
        let order = Order.fake().copy(currency: "XBT", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in "xbt" })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, .enabled)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_edit_order_action_is_enabled_when_order_is_synced_and_matches_site_currency() {
        // Given
        let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")
        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: usdOrder,
                                              stores: storesManager,
                                              syncStateController: syncStateController,
                                              siteCurrencyProvider: { _ in CurrencyCode.USD.rawValue })

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.enabled)
        XCTAssertNil(viewModel.editOrderRequestCurrency)
    }

    func test_paymentMethodsViewModel_title_contains_formatted_order_amount() {
        // Given
        let order = Order.fake().copy(currency: "EUR", total: "10.0")

        // When
        let currencyFormatter = CurrencyFormatter(currencySettings: .init())
        let title = OrderDetailsViewModel(order: order, currencyFormatter: currencyFormatter).paymentMethodsViewModel.title

        // Then
        XCTAssertTrue(title.contains("\u{20AC}10.0"))
    }

    func test_syncSubscriptions_loads_subscription_into_dataSource() throws {
        // Given

        // Make sure the are plugins synced
        let plugin = SystemPlugin.fake().copy(siteID: order.siteID, plugin: "woocommerce-subscriptions/woocommerce-subscriptions.php", active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        let subscriptionsCount: Int = waitFor { promise in

            // Return the active WCExtensions plugin.
            self.whenFetchingSystemPlugin(thenReturn: plugin)

            // Return the synced subscription.
            self.storesManager.whenReceivingAction(ofType: SubscriptionAction.self) { action in
                switch action {
                case .loadSubscriptions(_, let onCompletion):
                    onCompletion(.success([Subscription.fake()]))
                    promise(self.viewModel.dataSource.orderSubscriptions.count)
                }
            }

            self.viewModel.syncSubscriptions()
        }

        // Then
        XCTAssertEqual(subscriptionsCount, 1)
    }

    func test_syncRefunds_dispatches_retrieveRefund_action_when_order_has_refunds() throws {
        // Given
        let order = Order.fake().copy(refunds: [.fake()])
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.syncRefunds()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? RefundAction)
        guard case let .retrieveRefunds(siteID, orderID, refundIDs, deleteStaleRefunds, _) = action else {
            XCTFail("Unexpected action: \(action)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertEqual(refundIDs, [OrderRefundCondensed.fake().refundID])
        XCTAssert(deleteStaleRefunds)
    }

    func test_syncRefunds_does_not_dispatch_retrieveRefund_action_when_order_has_no_refunds() throws {
        // Given
        XCTAssert(order.refunds.isEmpty)
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.syncRefunds()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    // MARK: - `isShipmentTrackingEnabled`

    func test_isShipmentTrackingEnabled_without_a_non_virtual_product_returns_false_and_does_not_dispatch_actions() async throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        let isEnabled = viewModel.isShipmentTrackingEnabled()

        // Then
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_isShipmentTrackingEnabled_with_a_non_virtual_product_returns_plugin_isActive() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let plugin = insertSystemPlugin(path: "woocommerce-shipment-tracking/woocommerce-shipment-tracking.php", siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isEnabled = viewModel.isShipmentTrackingEnabled()

        // Then
        XCTAssertTrue(isEnabled)
    }

    // MARK: - `syncTrackingsWhenShipmentTrackingIsEnabled`

    func test_syncTrackingsWhenShipmentTrackingIsEnabled_dispatches_ShipmentAction() async throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        storesManager.whenReceivingAction(ofType: ShipmentAction.self) { action in
            // Then
            guard case let ShipmentAction.synchronizeShipmentTrackingData(siteID, orderID, completion) = action else {
                return XCTFail("Unexpected action: \(action)")
            }
            XCTAssertEqual(siteID, self.order.siteID)
            XCTAssertEqual(orderID, self.order.orderID)
            completion(nil)
        }

        // When
        await viewModel.syncTrackingsWhenShipmentTrackingIsEnabled()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)
        assertThat(storesManager.receivedActions.first, isAnInstanceOf: ShipmentAction.self)
    }

    // MARK: - `fetchShippingLabelSupport`

    func test_fetchShippingLabelSupport_when_wooShipping_is_supported_then_returns_wooShipping() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.6")

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .wooShipping)
        XCTAssertFalse(storesManager.receivedActions.contains { $0 is SystemStatusAction })
    }

    func test_fetchShippingLabelSupport_when_both_plugins_are_active_then_returns_wooShipping() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.6")
        insertSystemPlugin(path: PluginPath.wooShippingAndTax, siteID: order.siteID, isActive: true)

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .wooShipping)
    }

    func test_fetchShippingLabelSupport_when_wooShipping_is_old_and_legacy_is_active_then_returns_legacyWCShip() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.5")
        insertSystemPlugin(path: PluginPath.wooShippingAndTax, siteID: order.siteID, isActive: true)

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .legacyWCShip)
    }

    func test_fetchShippingLabelSupport_when_only_old_wooShipping_is_active_then_returns_unsupported() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.5")

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .unsupported)
    }

    func test_fetchShippingLabelSupport_when_wooShipping_is_inactive_and_legacy_is_active_then_returns_legacyWCShip() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: false, version: "1.0.6")
        insertSystemPlugin(path: PluginPath.wooShippingAndTax, siteID: order.siteID, isActive: true)

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .legacyWCShip)
    }

    func test_fetchShippingLabelSupport_when_no_shipping_plugins_are_active_then_returns_unsupported() {
        // Given
        insertSystemPlugin(path: "woocommerce/woocommerce.php", siteID: order.siteID, isActive: true)

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .unsupported)
    }

    func test_fetchShippingLabelSupport_when_wooShipping_folder_is_renamed_then_returns_wooShipping() {
        // Given
        insertSystemPlugin(path: "woocommerce-shipping-renamed/woocommerce-shipping.php",
                           siteID: order.siteID, isActive: true, version: "1.0.6")

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .wooShipping)
    }

    func test_fetchShippingLabelSupport_when_plugins_are_not_synced_then_returns_unsupported() {
        // Given
        analyticsProvider.clearEvents()

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .unsupported)
        XCTAssertTrue(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.pluginsNotSyncedYet.rawValue))
    }

    func test_fetchShippingLabelSupport_when_active_duplicate_is_old_and_legacy_is_active_then_returns_legacyWCShip() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: false, version: "1.0.9")
        insertSystemPlugin(path: "woocommerce-shipping-2/woocommerce-shipping.php",
                           siteID: order.siteID, isActive: true, version: "1.0.5")
        insertSystemPlugin(path: PluginPath.wooShippingAndTax, siteID: order.siteID, isActive: true)

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .legacyWCShip)
    }

    func test_fetchShippingLabelSupport_when_active_duplicate_is_supported_then_returns_wooShipping() {
        // Given
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: false, version: "1.0.5")
        insertSystemPlugin(path: "woocommerce-shipping-2/woocommerce-shipping.php",
                           siteID: order.siteID, isActive: true, version: "1.0.6")

        // When
        let support = viewModel.fetchShippingLabelSupport()

        // Then
        XCTAssertEqual(support, .wooShipping)
    }

    // MARK: - `syncShippingLabelState`

    func test_syncShippingLabelState_when_unpaid_cash_order_then_checks_creation_eligibility() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        viewModel.update(order: order.copy(datePaid: .some(nil), paymentMethodID: "cod"))
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.6")

        // When
        await viewModel.syncShippingLabelState()

        // Then
        XCTAssertTrue(viewModel.dataSource.isEligibleForShippingLabelCreation)
        let actions = storesManager.receivedActions.compactMap { $0 as? WooShippingAction }
        XCTAssertTrue(actions.contains {
            if case .checkCreationEligibility = $0 {
                return true
            }
            return false
        })
    }

    func test_syncShippingLabelState_when_wooShipping_is_supported_then_uses_wooShipping() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.6")

        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelState()

        // Then
        XCTAssertTrue(viewModel.dataSource.isEligibleForWooShipping)
        XCTAssertTrue(viewModel.shouldNavigateToNewShippingLabelFlow)
        XCTAssertTrue(viewModel.dataSource.isEligibleForShippingLabelCreation)
        XCTAssertFalse(storesManager.receivedActions.contains { $0 is ShippingLabelAction })
        let actions = storesManager.receivedActions.compactMap { $0 as? WooShippingAction }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions.contains {
            if case .checkCreationEligibility = $0 {
                return true
            }
            return false
        })
        XCTAssertTrue(actions.contains {
            if case .syncShipments = $0 {
                return true
            }
            return false
        })
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue,
                                         with: ["order_status": order.status.rawValue, "is_revamped_flow": true])
    }

    func test_syncShippingLabelState_when_wooShipping_is_old_and_legacy_is_active_then_uses_legacyWCShip() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.5")
        insertSystemPlugin(path: PluginPath.wooShippingAndTax, siteID: order.siteID, isActive: true)

        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelState()

        // Then
        XCTAssertFalse(viewModel.dataSource.isEligibleForWooShipping)
        XCTAssertFalse(viewModel.shouldNavigateToNewShippingLabelFlow)
        XCTAssertTrue(viewModel.dataSource.isEligibleForShippingLabelCreation)
        XCTAssertFalse(storesManager.receivedActions.contains { $0 is WooShippingAction })
        let actions = storesManager.receivedActions.compactMap { $0 as? ShippingLabelAction }
        XCTAssertEqual(actions.count, 2)
        XCTAssertTrue(actions.contains {
            if case .checkCreationEligibility = $0 {
                return true
            }
            return false
        })
        XCTAssertTrue(actions.contains {
            if case .synchronizeShippingLabels = $0 {
                return true
            }
            return false
        })
        analyticsProvider.assertReceived(event: WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue,
                                         with: ["order_status": order.status.rawValue, "is_revamped_flow": false])
    }

    func test_syncShippingLabelState_when_only_old_wooShipping_is_active_then_uses_unsupported() async {
        // Given
        let viewModel = configureShippingLabelContext(storeCountry: "US")
        viewModel.dataSource.isEligibleForWooShipping = true
        viewModel.dataSource.isEligibleForShippingLabelCreation = true
        insertSystemPlugin(path: PluginPath.wooShipping,
                           siteID: order.siteID, isActive: true, version: "1.0.5")

        analyticsProvider.clearEvents()

        // When
        await viewModel.syncShippingLabelState()

        // Then
        XCTAssertFalse(viewModel.dataSource.isEligibleForWooShipping)
        XCTAssertFalse(viewModel.shouldNavigateToNewShippingLabelFlow)
        XCTAssertFalse(viewModel.dataSource.isEligibleForShippingLabelCreation)
        XCTAssertFalse(storesManager.receivedActions.contains { $0 is WooShippingAction || $0 is ShippingLabelAction })
        XCTAssertFalse(analyticsProvider.receivedEvents.contains(WooAnalyticsStat.shippingLabelOrderIsEligible.rawValue))
    }

    // MARK: - `isWooShippingSupported`

    func test_isWooShippingSupported_returns_true_when_plugin_is_active_and_version_is_supported() {
        // Given
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        insertSystemPlugin(path: PluginPath.wooShipping, siteID: order.siteID, isActive: true, version: "1.0.6")

        // When
        let isWooShippingSupported = viewModel.isWooShippingSupported()

        // Then
        XCTAssertTrue(isWooShippingSupported)
    }

    func test_isWooShippingSupported_returns_false_when_woo_shipping_plugin_not_active() {
        // Given
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        insertSystemPlugin(path: PluginPath.wooShipping, siteID: order.siteID, isActive: false, version: "1.0.6")

        // When
        let isWooShippingSupported = viewModel.isWooShippingSupported()

        // Then
        XCTAssertFalse(isWooShippingSupported)
    }

    func test_isWooShippingSupported_returns_false_when_woo_shipping_plugin_is_not_minimum_version() {
        // Given
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)
        insertSystemPlugin(path: PluginPath.wooShipping, siteID: order.siteID, isActive: true, version: "1.0.5")

        // When
        let isWooShippingSupported = viewModel.isWooShippingSupported()

        // Then
        XCTAssertFalse(isWooShippingSupported)
    }

    // MARK: - `refreshReceiptEligibility`

    func test_refreshReceiptEligibility_when_order_is_eligible_then_updates_dataSource() async {
        // Given
        let order = Order.fake().copy(siteID: 123, orderID: 456, status: .completed)
        let receiptEligibilityUseCase = MockReceiptEligibilityUseCase()
        receiptEligibilityUseCase.isEligibleForReceipt = true
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              receiptEligibilityUseCase: receiptEligibilityUseCase)
        XCTAssertFalse(viewModel.dataSource.isEligibleForBackendReceipt)

        // When
        await viewModel.refreshReceiptEligibility()

        // Then
        XCTAssertTrue(viewModel.dataSource.isEligibleForBackendReceipt)
    }

    func test_refreshReceiptEligibility_when_order_is_not_eligible_then_dataSource_remains_false() async {
        // Given
        let order = Order.fake().copy(siteID: 123, orderID: 456, status: .pending)
        let receiptEligibilityUseCase = MockReceiptEligibilityUseCase()
        receiptEligibilityUseCase.isEligibleForReceipt = false
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              receiptEligibilityUseCase: receiptEligibilityUseCase)

        // When
        await viewModel.refreshReceiptEligibility()

        // Then
        XCTAssertFalse(viewModel.dataSource.isEligibleForBackendReceipt)
    }
}

private extension OrderDetailsViewModelTests {
    enum PluginPath {
        static let wooShipping = "woocommerce-shipping/woocommerce-shipping.php"
        static let wooShippingAndTax = "woocommerce-services/woocommerce-services.php"
    }

    /// The analytics provider installed by `setUp()`.
    var analyticsProvider: MockAnalyticsProvider {
        guard let provider = ServiceLocator.analytics.analyticsProvider as? MockAnalyticsProvider else {
            XCTFail("Expected setUp() to install a MockAnalyticsProvider")
            return MockAnalyticsProvider()
        }
        return provider
    }

    @discardableResult
    func insertSystemPlugin(path: String, siteID: Int64, isActive: Bool, version: String? = nil) -> SystemPlugin {
        let plugin = SystemPlugin.fake().copy(siteID: siteID, plugin: path, version: version, active: isActive)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)
        return plugin
    }

    func configureOrderWithProductsInStorage(products: [Product]) {
        order = MockOrders().sampleOrder().copy(items: products.map { OrderItem.fake().copy(productID: $0.productID) })
        viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager)

        // Inserts products to storage.
        products.forEach { product in
            storageManager.insertSampleProduct(readOnlyProduct: product)
        }
    }

    func configureDefaultStoreCountry(_ country: String) {
        let setting = SiteSetting.fake().copy(siteID: order.siteID,
                                              settingID: "woocommerce_default_country",
                                              value: country,
                                              settingGroupKey: "general")
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
    }

    func configureShippingLabelContext(storeCountry: String?) -> OrderDetailsViewModel {
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        storageManager = MockStorageManager()
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        if let storeCountry {
            configureDefaultStoreCountry(storeCountry)
        }

        whenHandlingWooShippingActions()
        whenHandlingLegacyShippingLabelActions()
        storesManager.reset()

        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager)
        viewModel.dataSource.currentSiteStatuses = [.fake().copy(siteID: order.siteID, slug: order.status.rawValue)]
        self.viewModel = viewModel
        return viewModel
    }

    func whenFetchingSystemPlugin(path: String? = nil, thenReturn plugin: SystemPlugin?) {
        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPluginWithPath(_, pluginPath, onCompletion):
                if let path, path != pluginPath {
                    onCompletion(nil)
                } else {
                    onCompletion(plugin)
                }
            default:
                break
            }
        }
    }

    func whenHandlingWooShippingActions(isEligible: Bool = true,
                                        shipmentsResult: Result<[WooShippingShipment], Error> = .success([])) {
        storesManager.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
            case let .checkCreationEligibility(_, _, onCompletion):
                onCompletion(isEligible)
            case let .syncShipments(_, _, completion):
                completion(shipmentsResult)
            default:
                break
            }
        }
    }

    func whenHandlingLegacyShippingLabelActions(isEligible: Bool = true,
                                                labelsResult: Result<[ShippingLabel], Error> = .success([])) {
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
            case let .checkCreationEligibility(_, _, onCompletion):
                onCompletion(isEligible)
            case let .synchronizeShippingLabels(_, _, completion):
                completion(labelsResult)
            default:
                break
            }
        }
    }
}
