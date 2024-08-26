import XCTest
@testable import WooCommerce
import Yosemite
import Storage
import Combine

/// Tests for `OrderListViewModel`.
///
final class OrderListViewModelTests: XCTestCase {
    /// The `siteID` value doesn't matter.
    private let siteID: Int64 = 1_000_000

    private var storageManager: MockStorageManager!

    private var stores: MockStoresManager!

    private var analyticsProvider: MockAnalyticsProvider!
    private var analytics: WooAnalytics!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    private var cancellables = Set<AnyCancellable>()

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(siteID)
        analyticsProvider = MockAnalyticsProvider()
        analytics = WooAnalytics(analyticsProvider: analyticsProvider)
        ServiceLocator.setSelectedSiteSettings(SelectedSiteSettings(stores: stores, storageManager: storageManager))
    }

    override func tearDown() {
        cancellables.forEach {
            $0.cancel()
        }
        cancellables.removeAll()

        super.tearDown()
    }

    // MARK: - Orders Loading

    func test_given_a_filter_it_loads_the_orders_matching_that_filter_from_the_DB() throws {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: nil,
                                                       product: nil,
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           storageManager: storageManager,
                                           filters: filters)

        let processingOrders = (0..<10).map { insertOrder(id: $0, status: .processing) }
        let completedOrders = (100..<105).map { insertOrder(id: $0, status: .completed) }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), processingOrders.count + completedOrders.count)

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertTrue(snapshot.numberOfItems > 0)
        XCTAssertEqual(snapshot.numberOfItems, processingOrders.count)

        XCTAssertEqual(viewModel.orderIDs(from: snapshot), processingOrders.orderIDs)
    }

    func test_given_no_filter_it_loads_all_the_today_and_past_orders_from_the_DB() throws {
        // Arrange
        let viewModel = OrderListViewModel(siteID: siteID, storageManager: storageManager, filters: nil)

        let allInsertedOrders = [
            (0..<10).map { insertOrder(id: $0, status: .processing) },
            (100..<105).map { insertOrder(id: $0, status: .completed, dateCreated: Date().adding(days: -2)!) },
            (200..<203).map { insertOrder(id: $0, status: .pending) },
        ].flatMap { $0 }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), allInsertedOrders.count)

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertTrue(snapshot.numberOfItems > 0)
        XCTAssertEqual(snapshot.numberOfItems, allInsertedOrders.count)

        XCTAssertEqual(viewModel.orderIDs(from: snapshot), allInsertedOrders.orderIDs)
    }

    /// Test that all orders including orders dated in the future (dateCreated) will be fetched.
    func test_it_also_loads_future_orders_from_the_DB() throws {

        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.pending],
                                                       dateRange: nil,
                                                       product: nil,
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           storageManager: storageManager,
                                           filters: filters)

        let expectedOrders = [
            // Future orders
            insertOrder(id: 1_000, status: .pending, dateCreated: Date().adding(days: 1)!),
            insertOrder(id: 1_001, status: .pending, dateCreated: Date().adding(days: 2)!),
            insertOrder(id: 1_002, status: .pending, dateCreated: Date().adding(days: 3)!),
            // Past orders
            insertOrder(id: 4_000, status: .pending, dateCreated: Date().adding(days: -1)!),
            insertOrder(id: 4_001, status: .pending, dateCreated: Date().adding(days: -20)!),
        ]

        // This should be ignored because it is not the same filter
        let ignoredFutureOrder = insertOrder(id: 2_000, status: .cancelled, dateCreated: Date().adding(days: 1)!)

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertEqual(snapshot.numberOfItems, expectedOrders.count)

        let orderIDs = viewModel.orderIDs(from: snapshot)
        XCTAssertEqual(orderIDs, expectedOrders.orderIDs)
        XCTAssertFalse(orderIDs.contains(ignoredFutureOrder.orderID))
    }

    /// Orders with dateCreated in the future should be grouped in an "Upcoming" section.
    func test_it_groups_future_orders_in_upcoming_section() throws {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.failed],
                                                       dateRange: nil,
                                                       product: nil,
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let viewModel = OrderListViewModel(siteID: siteID,
                                           storageManager: storageManager,
                                           filters: filters)

        let expectedOrders = (
            future: [
                insertOrder(id: 1_000, status: .failed, dateCreated: Date().adding(days: 3)!),
                insertOrder(id: 1_001, status: .failed, dateCreated: Date().adding(days: 4)!),
                insertOrder(id: 1_002, status: .failed, dateCreated: Date().adding(days: 5)!),
            ],
            past: [
                insertOrder(id: 4_000, status: .failed, dateCreated: Date().adding(days: -1)!),
            ]
        )

        // Act
        let snapshot = try activateAndRetrieveSnapshot(of: viewModel)

        // Assert
        XCTAssertEqual(snapshot.numberOfSections, 2)

        // The first section should be the Upcoming section
        let sectionID = try XCTUnwrap(snapshot.sectionIdentifiers.first)
        XCTAssertEqual(Age(rawValue: sectionID), .upcoming)

        let sectionTitle = try XCTUnwrap(viewModel.sectionTitleFor(sectionIdentifier: sectionID))
        XCTAssertEqual(sectionTitle, Age(rawValue: sectionID)?.description)

        XCTAssertEqual(snapshot.numberOfItems(inSection: sectionID), expectedOrders.future.count)
    }

    // MARK: - App Activation

    func test_it_requests_a_resynchronization_when_the_app_is_activated() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_no_previous_deactivation_it_does_not_request_a_resynchronization_when_the_app_is_activated() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    // MARK: - Foreground Notifications

    func test_given_a_new_order_notification_it_requests_a_resynchronization() {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrderListViewModel(siteID: siteID, pushNotificationsManager: pushNotificationsManager, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        let notification = PushNotification(noteID: 1, siteID: 1, kind: .storeOrder, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendForegroundNotification(notification)

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_a_non_order_notification_it_does_not_request_a_resynchronization() {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrderListViewModel(siteID: siteID, pushNotificationsManager: pushNotificationsManager, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        let notification = PushNotification(noteID: 1, siteID: 1, kind: .comment, title: "", subtitle: "", message: "")
        pushNotificationsManager.sendForegroundNotification(notification)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    // MARK: - Banner visibility

    func test_banner_should_not_be_shown_when_there_is_no_error() {
        // Given
        let viewModel = OrderListViewModel(siteID: siteID, stores: stores, filters: nil)
        stores.whenReceivingAction(ofType: AppSettingsAction.self) { action in
            switch action {
            case let .loadFeedbackVisibility(_, onCompletion):
                onCompletion(.success(false))
            default:
                break
            }
        }

        // When
        viewModel.activate()

        // Then
        waitUntil {
            viewModel.topBanner == .none
        }
    }

    func test_storing_error_shows_error_banner() {
        // Given
        let expectedError = MockError()
        let viewModel = OrderListViewModel(siteID: siteID, filters: nil)

        // When
        viewModel.dataLoadingError = expectedError
        viewModel.activate()

        // Then
        waitUntil {
            viewModel.topBanner == .error(expectedError)
        }
    }

    // MARK: - Filters Applied
    func test_it_requests_a_resynchronization_when_the_new_filters_are_applied() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: nil)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        viewModel.updateFilters(filters: FilterOrderListViewModel.Filters(orderStatus: [.completed],
                                                                          dateRange: nil,
                                                                          product: nil,
                                                                          customer: nil,
                                                                          numberOfActiveFilters: 1))

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_identical_filters_it_does_not_request_a_resynchronization() {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.pending],
                                                       dateRange: nil,
                                                       product: nil,
                                                       customer: nil,
                                                       numberOfActiveFilters: 0)
        let notificationCenter = NotificationCenter()
        let viewModel = OrderListViewModel(siteID: siteID, notificationCenter: notificationCenter, filters: filters)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfNewFiltersAreApplied = {
            resynchronizeRequested = true
        }

        viewModel.activate()

        // Act
        viewModel.updateFilters(filters: filters)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    // MARK: - `shouldEnableTestOrder`
    func test_shouldEnableTestOrder_returns_true_when_site_is_public_and_has_a_published_product_and_set_up_payment() {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: siteID, statusKey: "publish"))
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: siteID, enabled: true))
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // When
        let isEnabled = viewModel.shouldEnableTestOrder

        // Then
        XCTAssertTrue(isEnabled)
    }

    func test_shouldEnableTestOrder_returns_false_when_site_is_not_public() {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .privateSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: siteID, statusKey: "publish"))
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: siteID, enabled: true))
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // When
        let isEnabled = viewModel.shouldEnableTestOrder

        // Then
        XCTAssertFalse(isEnabled)
    }

    func test_shouldEnableTestOrder_returns_false_when_site_has_no_published_product() {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: siteID, statusKey: "draft"))
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: siteID, enabled: true))
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // When
        let isEnabled = viewModel.shouldEnableTestOrder

        // Then
        XCTAssertFalse(isEnabled)
    }

    func test_shouldEnableTestOrder_returns_false_when_site_has_no_payment_gateway() {
        // Given
        let siteID: Int64 = 123
        let site = Site.fake().copy(siteID: siteID, url: "https://example.com", visibility: .publicSite)
        let stores = MockStoresManager(sessionManager: .makeForTesting(authenticated: true, defaultSite: site))
        storageManager.insertSampleProduct(readOnlyProduct: Product.fake().copy(siteID: siteID, statusKey: "publish"))
        storageManager.insertSamplePaymentGateway(readOnlyGateway: PaymentGateway.fake().copy(siteID: siteID, enabled: false))
        let viewModel = OrderListViewModel(siteID: siteID,
                                           stores: stores,
                                           storageManager: storageManager,
                                           filters: nil)

        // When
        let isEnabled = viewModel.shouldEnableTestOrder

        // Then
        XCTAssertFalse(isEnabled)
    }
}

// MARK: - Helpers

private extension OrderListViewModel {
    /// Returns the corresponding order IDs instances for all the given FetchResultSnapshot IDs.
    ///
    func orderIDs(from snapshot: FetchResultSnapshot) -> Set<Int64> {
        Set(snapshot.itemIdentifiers.compactMap { objectID in
            detailsViewModel(withID: objectID)?.order.orderID
        })
    }
}

private extension OrderListViewModelTests {
    // MARK: - Country helpers
    func setupCountry(country: Country) {
        let setting = SiteSetting.fake()
            .copy(
                siteID: siteID,
                settingID: "woocommerce_default_country",
                value: country.rawValue,
                settingGroupKey: SiteSettingGroup.general.rawValue
            )
        storageManager.insertSampleSiteSetting(readOnlySiteSetting: setting)
        ServiceLocator.selectedSiteSettings.refresh()
    }

    enum Country: String {
        case us = "US:CA"
        case es = "ES"
    }
}

private extension Array where Element == Yosemite.Order {
    /// Returns all the IDs
    ///
    var orderIDs: Set<Int64> {
        Set(map(\.orderID))
    }
}

// MARK: - Builders

private extension OrderListViewModelTests {

    /// Activate the viewModel to start fetching and then return the first
    /// valid `FetchResultSnapshot` triggered.
    func activateAndRetrieveSnapshot(of viewModel: OrderListViewModel) throws -> FetchResultSnapshot {
        return waitFor { promise in
            // The first snapshot is dropped because it's just the default empty one.
            viewModel.snapshot.dropFirst().sink { snapshot in
                promise(snapshot)
            }.store(in: &self.cancellables)

            viewModel.activate()
        }
    }

    func orderStatus(with status: OrderStatusEnum) -> Yosemite.OrderStatus {
        OrderStatus(name: nil, siteID: siteID, slug: status.rawValue, total: 0)
    }

    func insertOrder(id orderID: Int64,
                     status: OrderStatusEnum,
                     dateCreated: Date = Date(),
                     datePaid: Date? = nil,
                     customFields: [Yosemite.MetaData] = [],
                     paymentMethodID: String? = nil) -> Yosemite.Order {
        let readonlyOrder = MockOrders().empty().copy(siteID: siteID,
                                                      orderID: orderID,
                                                      status: status,
                                                      dateCreated: dateCreated,
                                                      datePaid: datePaid,
                                                      paymentMethodID: paymentMethodID,
                                                      customFields: customFields)
        let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
        storageOrder.update(with: readonlyOrder)

        for field in customFields {
            let storageMetaData = storage.insertNewObject(ofType: Storage.MetaData.self)
            storageMetaData.update(with: field)
            storageOrder.addToCustomFields(storageMetaData)
        }

        return readonlyOrder
    }

    final class MockError: Error { }
}
