import TestKit
import WooFoundation
import XCTest
import Yosemite

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

    // MARK: - `syncShippingLabels`

    func test_syncShippingLabels_without_a_non_virtual_product_does_not_dispatch_actions() async throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        await viewModel.syncShippingLabels()

        // Then no actions are dispatched
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_syncShippingLabels_with_a_non_virtual_product_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.LegacyWCShip, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(thenReturn: plugin)
        whenSyncingShippingLabels(thenReturn: .success(()))

        // When
        await viewModel.syncShippingLabels()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 2)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions.first as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginListWithNameList(siteID, systemPluginNameList, _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(systemPluginNameList, [SitePlugin.SupportedPlugin.LegacyWCShip])

        // ShippingLabelAction.synchronizeShippingLabels
        let secondAction = try XCTUnwrap(storesManager.receivedActions.last as? ShippingLabelAction)
        guard case let ShippingLabelAction.synchronizeShippingLabels(siteID, orderID, _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
    }

    // MARK: - `checkShippingLabelCreationEligibility`

    func test_checkShippingLabelCreationEligibility_without_a_non_virtual_product_returns_false() async throws {
        // Given
        storesManager.reset()

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility()

        // Then no actions are dispatched
        XCTAssertFalse(isEligible)
    }

    func test_checkShippingLabelCreationEligibility_with_a_non_virtual_product_returns_value_from_action() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])
        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.LegacyWCShip, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(thenReturn: plugin)
        whenCheckingShippingLabelCreationEligibility(thenReturn: true)

        // When
        let isEligible = await viewModel.checkShippingLabelCreationEligibility()

        // Then no actions are dispatched
        XCTAssertTrue(isEligible)
    }

    func test_checkShippingLabelCreationEligibility_without_a_non_virtual_product_does_not_dispatch_actions() async throws {
        // Given
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility()

        // Then no actions are dispatched
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_checkShippingLabelCreationEligibility_with_a_non_virtual_product_dispatches_actions_correctly() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // Make sure the are plugins synced
        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.LegacyWCShip, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(thenReturn: plugin)
        whenCheckingShippingLabelCreationEligibility(thenReturn: true)

        // When
        _ = await viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 2)

        // SystemStatusAction.fetchSystemPlugin
        let firstAction = try XCTUnwrap(storesManager.receivedActions.first as? SystemStatusAction)
        guard case let SystemStatusAction.fetchSystemPluginListWithNameList(siteID, systemPluginNameList, _) = firstAction else {
            XCTFail("Expected \(firstAction) to be \(SystemStatusAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(systemPluginNameList, [SitePlugin.SupportedPlugin.LegacyWCShip])

        // ShippingLabelAction.synchronizeShippingLabels
        let secondAction = try XCTUnwrap(storesManager.receivedActions.last as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID, orderID, _) = secondAction else {
            XCTFail("Expected \(secondAction) to be \(ShippingLabelAction.self)")
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
        XCTAssertFalse(viewModel.editButtonIsEnabled)
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

    func test_syncSubscriptions_loads_subscription_into_dataSource_with_legacy_plugin_name() throws {
        // Given
        let plugin = SystemPlugin.fake().copy(siteID: order.siteID, name: "WooCommerce Subscriptions", active: true)
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

    func test_syncSubscriptions_loads_subscription_into_dataSource_with_current_plugin_name() throws {
        // Given

        // Make sure the are plugins synced
        let plugin = SystemPlugin.fake().copy(siteID: order.siteID, name: "Woo Subscriptions", active: true)
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
        let isEnabled = await viewModel.isShipmentTrackingEnabled()

        // Then
        XCTAssertFalse(isEnabled)
        XCTAssertEqual(storesManager.receivedActions.count, 0)
    }

    func test_isShipmentTrackingEnabled_with_a_non_virtual_product_returns_plugin_isActive() async throws {
        // Given
        configureOrderWithProductsInStorage(products: [.fake().copy(productID: 6, virtual: false)])

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.WCTracking, siteID: order.siteID, isActive: true)
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isEnabled = await viewModel.isShipmentTrackingEnabled()

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
        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.WooShipping[0], siteID: order.siteID, isActive: true, version: "1.0.5")
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
        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.WooShipping[0], siteID: order.siteID, isActive: true, version: "1.0.5")
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
        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.WooShipping[0], siteID: order.siteID, isActive: false, version: "1.0.5")
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
        let plugin = insertSystemPlugin(name: SitePlugin.SupportedPlugin.WooShipping[0], siteID: order.siteID, isActive: false, version: "1.0.4")
        whenFetchingSystemPlugin(thenReturn: plugin)

        // When
        let isWooShippingSupported = await viewModel.isWooShippingSupported()

        // Then
        XCTAssertFalse(isWooShippingSupported)
    }
}

private extension OrderDetailsViewModelTests {
    @discardableResult
    func insertSystemPlugin(name: String, siteID: Int64, isActive: Bool, version: String? = nil) -> SystemPlugin {
        let plugin = SystemPlugin.fake().copy(siteID: siteID, name: name, version: version, active: isActive)
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

    func whenFetchingSystemPlugin(thenReturn plugin: SystemPlugin?) {
        storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
            switch action {
            case let .fetchSystemPlugin(_, _, onCompletion):
                onCompletion(plugin)
            case let .fetchSystemPluginListWithNameList(_, _, onCompletion):
                onCompletion(plugin)
                default:
                    break
            }
        }
    }

    func whenSyncingShippingLabels(thenReturn result: Result<Void, Error>) {
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
                case let .synchronizeShippingLabels(_, _, completion):
                    completion(result)
                default:
                    break
            }
        }
    }

    func whenCheckingShippingLabelCreationEligibility(thenReturn isEligible: Bool) {
        storesManager.whenReceivingAction(ofType: ShippingLabelAction.self) { action in
            switch action {
                case let .checkCreationEligibility(_, _, onCompletion):
                    onCompletion(isEligible)
                default:
                    break
            }
        }
    }
}
