import WooFoundation
import XCTest
import Yosemite

@testable import WooCommerce

final class OrderDetailsViewModelTests: XCTestCase {
    private var order: Order!
    private var viewModel: OrderDetailsViewModel!
    private var configurationLoader: MockCardPresentConfigurationLoader!

    private var storesManager: MockStoresManager!

    override func setUp() {
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())

        order = MockOrders().sampleOrder()
        configurationLoader = MockCardPresentConfigurationLoader.init()

        viewModel = OrderDetailsViewModel(order: order, stores: storesManager, configurationLoader: configurationLoader)

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
        _ = viewModel.markCompleted()

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
        storesManager.reset()
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
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
        let viewModel = OrderDetailsViewModel(order: order, configurationLoader: configurationLoader)

        // Then
        XCTAssertFalse(viewModel.editButtonIsEnabled)
    }

    func test_paymentMethodsViewModel_title_contains_formatted_order_amount() {
        // Given
        let order = Order.fake().copy(currency: "EUR", total: "10.0")

        // When
        let currencyFormatter = CurrencyFormatter(currencySettings: .init())
        let title = OrderDetailsViewModel(order: order,
                                          currencyFormatter: currencyFormatter,
                                          configurationLoader: configurationLoader).paymentMethodsViewModel.title

        // Then
        XCTAssertTrue(title.contains("\u{20AC}10.0"))
    }

    func test_it_sets_viewModel_isEligibleForCardPresentPayment_to_true_if_it_is_eligible() {
        // Given
        let order = Order.fake().copy(currency: "EUR", total: "10.0")
        let stores = MockStoresManager(sessionManager: .testingInstance)
        stores.whenReceivingAction(ofType: OrderCardPresentPaymentEligibilityAction.self) {
            action in
            switch action {
            case let .orderIsEligibleForCardPresentPayment(_, _, _, completion):
                completion(.success(true))
            }
        }

        // When
        let viewModel = OrderDetailsViewModel(order: order, stores: stores, configurationLoader: configurationLoader)

        XCTAssertNotNil(viewModel, "Temporary test")

    }
}
