import WooFoundation
import XCTest
import Yosemite

@testable import WooCommerce

final class OrderDetailsViewModelTests: XCTestCase {

    private var storageManager: MockStorageManager!
    private var storesManager: MockStoresManager!
    private var order: Order!
    private var viewModel: OrderDetailsViewModel!
    private var configurationLoader: MockCardPresentConfigurationLoader!
    private let sampleSiteID: Int64 = 1111
    private let sampleOrderID: Int64 = 1111

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        storesManager = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        storesManager.sessionManager.setStoreId(sampleSiteID)
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: storesManager, storageManager: storageManager))
        order = MockOrders().sampleOrder()
        configurationLoader = MockCardPresentConfigurationLoader.init()
        viewModel = OrderDetailsViewModel(order: order, stores: storesManager, configurationLoader: configurationLoader)

        let analytics = WooAnalytics(analyticsProvider: MockAnalyticsProvider())
        ServiceLocator.setAnalytics(analytics)
    }

    override func tearDown() {
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings())
        storageManager.reset()
        storageManager = nil
        storesManager = nil
        viewModel = nil
        order = nil
        super.tearDown()
    }

    func test_deleteTracking_fires_orderTrackingDelete_Tracks_event() {
        // Given
        let mockShipmentTracking = ShipmentTracking(siteID: sampleSiteID,
                                                    orderID: sampleOrderID,
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

    func test_viewModel_when_country_is_not_eligible_for_card_payment_then_is_not_supported() {

        // Given
        let order = Order.fake().copy(orderID: sampleOrderID, currency: "EUR", total: "10.0")
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: "ES",
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()

        // When
        let viewModel = OrderDetailsViewModel(
            order: order,
            stores: storesManager,
            configurationLoader: configurationLoader
        )

        // Then
        XCTAssertFalse(viewModel.configurationLoader.configuration.isSupportedCountry)
    }

    func test_viewModel_when_country_is_eligible_for_card_payment_then_is_supported() {

        // Given
        let order = Order.fake().copy(orderID: sampleOrderID, currency: "USD", total: "10.0")
        let setting = SiteSetting.fake()
            .copy(
                siteID: sampleSiteID,
                settingID: "woocommerce_default_country",
                value: "US:CA",
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()

        // When
        let viewModel = OrderDetailsViewModel(
            order: order,
            stores: storesManager,
            configurationLoader: configurationLoader
        )

        // Then
        XCTAssertTrue(viewModel.configurationLoader.configuration.isSupportedCountry)
    }
}
