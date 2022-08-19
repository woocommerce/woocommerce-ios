import WooFoundation
import XCTest
import Yosemite

@testable import WooCommerce

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

    func test_checkShippingLabelCreationEligibility_dispatches_correctly() throws {
        // Given

        // Make sure the are plugins synced
        let plugin = SystemPlugin.fake().copy(siteID: order.siteID, name: SitePlugin.SupportedPlugin.WCShip, active: true)
        storageManager.insertSampleSystemPlugin(readOnlySystemPlugin: plugin)

        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        waitForExpectation { exp in

            // Return the active WCShip plugin.
            storesManager.whenReceivingAction(ofType: SystemStatusAction.self) { action in
                switch action {
                case .fetchSystemPlugin(_, _, let onCompletion):
                    onCompletion(plugin)
                    exp.fulfill()
                default:
                    break
                }
            }

            viewModel.checkShippingLabelCreationEligibility()
        }

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 2)

        let action = try XCTUnwrap(storesManager.receivedActions.last as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID: siteID,
                                                                    orderID: orderID,
                                                                    onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(ShippingLabelAction.self)")
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
}
