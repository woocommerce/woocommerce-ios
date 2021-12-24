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
        guard case let .updateOrderStatus(siteID: siteID, orderID: orderID, status: status, onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(OrderAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertEqual(status, .completed)
    }

    // MARK: Shipping Labels feature flags

    func test_checkShippingLabelCreationEligibility_returns_ineligible_when_shippingLabelsM2M3_is_disabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShippingLabelsM2M3On: false)
        ServiceLocator.setFeatureFlagService(featureFlagService)

        // When
        viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 0)
        XCTAssertFalse(viewModel.dataSource.isEligibleForShippingLabelCreation)
    }

    func test_checkShippingLabelCreationEligibility_dispatches_eligibility_check_without_client_features_when_only_shippingLabelsM2M3_is_enabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShippingLabelsM2M3On: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID: siteID,
                                                                    orderID: orderID,
                                                                    canCreatePaymentMethod: canCreatePaymentMethod,
                                                                    canCreateCustomsForm: canCreateCustomsForm,
                                                                    canCreatePackage: canCreatePackage,
                                                                    onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertFalse(canCreatePaymentMethod)
        XCTAssertFalse(canCreateCustomsForm)
        XCTAssertFalse(canCreatePackage)
    }

    func test_checkShippingLabelCreationEligibility_dispatches_correct_check_when_M2M3_and_international_flags_are_enabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShippingLabelsM2M3On: true, isInternationalShippingLabelsOn: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID: siteID,
                                                                    orderID: orderID,
                                                                    canCreatePaymentMethod: canCreatePaymentMethod,
                                                                    canCreateCustomsForm: canCreateCustomsForm,
                                                                    canCreatePackage: canCreatePackage,
                                                                    onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertFalse(canCreatePaymentMethod)
        XCTAssertTrue(canCreateCustomsForm)
        XCTAssertFalse(canCreatePackage)
    }

    func test_checkShippingLabelCreationEligibility_dispatches_correct_check_when_M2M3_international_and_addPaymentMethod_flags_are_enabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShippingLabelsM2M3On: true,
                                                        isInternationalShippingLabelsOn: true,
                                                        isShippingLabelsPaymentMethodCreationOn: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID: siteID,
                                                                    orderID: orderID,
                                                                    canCreatePaymentMethod: canCreatePaymentMethod,
                                                                    canCreateCustomsForm: canCreateCustomsForm,
                                                                    canCreatePackage: canCreatePackage,
                                                                    onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertTrue(canCreatePaymentMethod)
        XCTAssertTrue(canCreateCustomsForm)
        XCTAssertFalse(canCreatePackage)
    }

    func test_checkShippingLabelCreationEligibility_dispatches_correct_check_when_M2M3_and_M4_flags_are_enabled() throws {
        // Given
        let featureFlagService = MockFeatureFlagService(isShippingLabelsM2M3On: true,
                                                        isInternationalShippingLabelsOn: true,
                                                        isShippingLabelsPaymentMethodCreationOn: true,
                                                        isShippingLabelsPackageCreationOn: true)
        ServiceLocator.setFeatureFlagService(featureFlagService)
        XCTAssertEqual(storesManager.receivedActions.count, 0)

        // When
        viewModel.checkShippingLabelCreationEligibility()

        // Then
        XCTAssertEqual(storesManager.receivedActions.count, 1)

        let action = try XCTUnwrap(storesManager.receivedActions.first as? ShippingLabelAction)
        guard case let ShippingLabelAction.checkCreationEligibility(siteID: siteID,
                                                                    orderID: orderID,
                                                                    canCreatePaymentMethod: canCreatePaymentMethod,
                                                                    canCreateCustomsForm: canCreateCustomsForm,
                                                                    canCreatePackage: canCreatePackage,
                                                                    onCompletion: _) = action else {
            XCTFail("Expected \(action) to be \(ShippingLabelAction.self)")
            return
        }

        XCTAssertEqual(siteID, order.siteID)
        XCTAssertEqual(orderID, order.orderID)
        XCTAssertTrue(canCreatePaymentMethod)
        XCTAssertTrue(canCreateCustomsForm)
        XCTAssertTrue(canCreatePackage)
    }
}
