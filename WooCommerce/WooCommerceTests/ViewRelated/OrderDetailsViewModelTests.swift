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

    func test_syncShippingLabels_without_a_non_virtual_product_does_not_dispatch_actions() async throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        await viewModel.syncShippingLabelsOrShipments()

        // Then no actions are dispatched
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_syncShippingLabels_with_legacy_extension_and_feature_flag_enabled_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.LegacyWCShip, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(path: SitePlugin.SupportedPluginPath.LegacyWCShip, thenReturn: plugin)
        whenSyncingLegacyShippingLabels(thenReturn: .success([]))

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        await viewModel.syncShippingLabelsOrShipments()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 3)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions[0] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID, path, _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.WooShipping)

        // SystemStatusAction.fetchSystemPlugin
        let secondAction = try XCTUnwrap(storesManager.receivedActions[1] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID, path, _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.LegacyWCShip)

        // ShippingLabelAction.synchronizeShippingLabels
        let thirdAction = try XCTUnwrap(storesManager.receivedActions[2] as? ShippingLabelAction)
        guard case let ShippingLabelAction.synchronizeShippingLabels(siteID, orderID, _) = thirdAction else {
            XCTFail("Expected \(thirdAction) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_syncShippingLabels_with_wooShipping_extension_and_feature_flag_enabled_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, thenReturn: plugin)
        whenSyncingShipments(thenReturn: .success([]))

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        await viewModel.syncShippingLabelsOrShipments()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 2)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions[0] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID, path, _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.WooShipping)

        // WooShippingAction.syncShippingLabels
        let secondAction = try XCTUnwrap(storesManager.receivedActions[1] as? WooShippingAction)
        guard case let WooShippingAction.syncShipments(siteID, orderID, _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(WooShippingAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_syncShippingLabels_with_wooShipping_extension_and_feature_flag_disabled_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, thenReturn: plugin)
        whenSyncingLegacyShippingLabels(thenReturn: .success([]))

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: false)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        await viewModel.syncShippingLabelsOrShipments()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 3)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions[0] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID, path, _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.LegacyWCShip)

        // SystemStatusAction.fetchSystemPlugin
        let secondAction = try XCTUnwrap(storesManager.receivedActions[1] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID, path, _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.WooShipping)

        // ShippingLabelAction.synchronizeShippingLabels
        let thirdAction = try XCTUnwrap(storesManager.receivedActions[2] as? ShippingLabelAction)
        guard case let ShippingLabelAction.synchronizeShippingLabels(siteID, orderID, _) = thirdAction else {
            XCTFail("Expected \(thirdAction) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    // MARK: - `checkShippingLabelCreationEligibility`

    func test_checkShippingLabelCreationEligibility_without_a_non_virtual_product_returns_false() async throws {
        // Given
        storesManager.reset()

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility()

        // Then no actions are dispatched
        XCTAssertFalse(isEligible)
    }

    func test_checkShippingLabelCreationEligibility_with_a_non_virtual_product_returns_value_from_action() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])
        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.LegacyWCShip, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(thenReturn: plugin)
        whenCheckingShippingLabelCreationEligibility(thenReturn: true)

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility()

        // Then no actions are dispatched
        XCTAssertTrue(isEligible)
    }

    func test_checkShippingLabelCreationEligibility_without_a_non_virtual_product_does_not_dispatch_actions() async throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility()

        // Then no actions are dispatched
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_checkShippingLabelCreationEligibility_with_legacy_extension_and_feature_flag_enabled_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // Make sure the are plugins synced
        let path = SitePlugin.SupportedPluginPath.LegacyWCShip
        let plugin = insertSystemPlugin(path: path, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(path: path, thenReturn: plugin)
        whenCheckingLegacyShippingLabelCreationEligibility(thenReturn: true)

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 3)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions[0] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: path, onCompletion: _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.WooShipping)

        // SystemStatusAction.fetchSystemPlugin
        let secondAction = try XCTUnwrap(storesManager.receivedActions[1] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: path, onCompletion: _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.LegacyWCShip)

        // WooShippingAction.checkCreationEligibility
        let thirdAction = try XCTUnwrap(storesManager.receivedActions[2] as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID, orderID, _) = thirdAction else {
            XCTFail("Expected \(thirdAction) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_checkShippingLabelCreationEligibility_with_wooshipping_and_feature_flag_enabled_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // Make sure the are plugins synced
        let path = SitePlugin.SupportedPluginPath.WooShipping
        let plugin = insertSystemPlugin(path: path, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(path: path, thenReturn: plugin)
        whenCheckingShippingLabelCreationEligibility(thenReturn: true)

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 2)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions[0] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: path, onCompletion: _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.WooShipping)

        // WooShippingAction.checkCreationEligibility
        let secondAction = try XCTUnwrap(storesManager.receivedActions[1] as? WooShippingAction)
        guard case let WooShippingAction.checkCreationEligibility(siteID, orderID, _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(WooShippingAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_checkShippingLabelCreationEligibility_when_feature_flag_disabled_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // Make sure the are plugins synced
        let path = SitePlugin.SupportedPluginPath.WooShipping
        let plugin = insertSystemPlugin(path: path, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(path: path, thenReturn: plugin)
        whenCheckingLegacyShippingLabelCreationEligibility(thenReturn: true)

        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: false)
        let viewModel = OrderDetailsViewModel(order: order,
                                              stores: storesManager,
                                              storageManager: storageManager,
                                              featureFlagService: featureFlagService)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 3)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions[0] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: path, onCompletion: _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.LegacyWCShip)

        // SystemStatusAction.fetchSystemPlugin
        let secondAction = try XCTUnwrap(storesManager.receivedActions[1] as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginWithPath(siteID: siteID, pluginPath: path, onCompletion: _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(path, SitePlugin.SupportedPluginPath.WooShipping)

        // WooShippingAction.checkCreationEligibility
        let thirdAction = try XCTUnwrap(storesManager.receivedActions[2] as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID, orderID, _) = thirdAction else {
            XCTFail("Expected \(thirdAction) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    func test_there_should_not_be_edit_order_action_if_order_is_not_synced() {
        // Given
        let order = Order.fake().copy(total: "10.0")

        // When
        let viewModel = OrderDetailsViewModel(order: order)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.disabledForSyncing)
    }

    // Context: https://github.com/woocommerce/woocommerce-ios/issues/14304
    func test_there_should_not_be_an_edit_order_action_if_order_currency_doesnt_match_site_currency() {
        // Given
        let gbp = CurrencySettings(currencyCode: .GBP,
                                   currencyPosition: .left,
                                   thousandSeparator: "",
                                   decimalSeparator: ".",
                                   numberOfDecimals: 2)
        ServiceLocator.setCurrencySettings(gbp)

        let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")

        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: usdOrder, syncStateController: syncStateController)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.showNoticeForCurrencyConflict)
    }

    func test_the_edit_order_action_should_be_enabled_when_the_order_is_synced_and_matches_site_currency() {
        // Given
        let usd = CurrencySettings(currencyCode: .USD,
                                   currencyPosition: .left,
                                   thousandSeparator: "",
                                   decimalSeparator: ".",
                                   numberOfDecimals: 2)
        ServiceLocator.setCurrencySettings(usd)

        let usdOrder = Order.fake().copy(currency: "usd", total: "10.0")

        let syncStateController = OrderDetailsSyncStateController(syncState: .synced)

        // When
        let viewModel = OrderDetailsViewModel(order: usdOrder, syncStateController: syncStateController)

        // Then
        XCTAssertEqual(viewModel.editButtonBehaviour, OrderDetailsViewModel.EditButtonBehaviour.enabled)
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

    // MARK: - `isWooShippingSupported`

    func test_isWooShippingSupported_returns_true_with_expected_feature_flag_and_version() async {
        // Given
        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager, featureFlagService: featureFlagService)
        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, siteID: order.siteID, isActive: true, version: "1.0.5")
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isWooShippingSupported = await viewModel.isWooShippingSupported()

        // Then
        XCTAssertTrue(isWooShippingSupported)
    }

    func test_isWooShippingSupported_returns_false_when_feature_flag_disabled() async {
        // Given
        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: false)
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager, featureFlagService: featureFlagService)
        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, siteID: order.siteID, isActive: true, version: "1.0.5")
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isWooShippingSupported = await viewModel.isWooShippingSupported()

        // Then
        XCTAssertFalse(isWooShippingSupported)
    }

    func test_isWooShippingSupported_returns_false_when_woo_shipping_plugin_not_active() async {
        // Given
        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager, featureFlagService: featureFlagService)
        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, siteID: order.siteID, isActive: false, version: "1.0.5")
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isWooShippingSupported = await viewModel.isWooShippingSupported()

        // Then
        XCTAssertFalse(isWooShippingSupported)
    }

    func test_isWooShippingSupported_returns_false_when_woo_shipping_plugin_is_not_minimum_version() async {
        // Given
        let featureFlagService = MockFeatureFlagService(revampedShippingLabelCreation: true)
        let viewModel = OrderDetailsViewModel(order: order, stores: storesManager, storageManager: storageManager, featureFlagService: featureFlagService)
        let plugin = insertSystemPlugin(path: SitePlugin.SupportedPluginPath.WooShipping, siteID: order.siteID, isActive: false, version: "1.0.4")
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isWooShippingSupported = await viewModel.isWooShippingSupported()

        // Then
        XCTAssertFalse(isWooShippingSupported)
    }
}

private extension OrderDetailsViewModelTests {
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

    func whenSyncingLegacyShippingLabels(thenReturn result: Result<[ShippingLabel], Error>) {
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
                case let .synchronizeShippingLabels(_, _, completion):
                    completion(result)
                default:
                    break
            }
        }
    }

    func whenSyncingShipments(thenReturn result: Result<[WooShippingShipment], Error>) {
        storesManager.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
                case let .syncShipments(_, _, completion):
                    completion(result)
                default:
                    break
            }
        }
    }

    func whenCheckingLegacyShippingLabelCreationEligibility(thenReturn isEligible: Bool) {
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
                case let .checkCreationEligibility(_, _, onCompletion):
                    onCompletion(isEligible)
                default:
                    break
            }
        }
    }

    func whenCheckingShippingLabelCreationEligibility(thenReturn isEligible: Bool) {
        storesManager.whenReceivingAction(ofType: WooShippingAction.self) { action in
            switch action {
                case let .checkCreationEligibility(_, _, onCompletion):
                    onCompletion(isEligible)
                default:
                    break
            }
        }
    }
}
