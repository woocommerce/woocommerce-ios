import XCTest
import Yosemite

@testable import WooCommerce

final class OrderDetailsViewModelTests: XCTestCase {
    private var order: Order!
    private var viewModel: OrderDetailsViewModel!

    private var storesManager: MockStoresManager!

    override func setUp() {
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())

        order = MockOrders().sampleOrder()

        viewModel = OrderDetailsViewModel(order: order, stores: storesManager)

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
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        _ = viewModel.markCompleted()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? OrderAction)
        guard case let .updateOrder(siteID: siteID, orderID: orderID, status: status, onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(OrderAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertEqual(status, .completed)
    }
}
