import XCTest
import TestKit
import Yosemite
import YosemiteTestHelpers
@testable import WooCommerce
import protocol Storage.StorageManagerType
import protocol Storage.StorageType

final class LastOrdersDashboardCardViewModelTests: XCTestCase {
    private let sampleSiteID: Int64 = 134
    private var stores: MockStoresManager!
    private let sampleOrders = [Order.fake().copy(siteID: 134, orderID: 1, status: .processing, dateCreated: .now),
                                Order.fake().copy(siteID: 134, orderID: 2, status: .completed, dateCreated: .now.adding(days: -5)),
                                Order.fake().copy(siteID: 134, orderID: 3, status: .refunded, dateCreated: .now.adding(days: -7))]
    private let sampleOrderStatuses = [OrderStatus.fake().copy(siteID: 134, slug: "waiting-pickup"),
                                       OrderStatus.fake().copy(siteID: 134, slug: "pending"),
                                       OrderStatus.fake().copy(siteID: 134, slug: "failed"),
                                       OrderStatus.fake().copy(siteID: 134, slug: "completed")]
    /// Mock Storage: InMemory
    private var storageManager: StorageManagerType!

    private var application: MockApplicationAdapter!
    private var notificationCenter: NotificationCenter!

    private var orderFetchCount = 0
    /// Orders returned by `mockFetchFilteredOrders()`.
    private lazy var remoteOrders = sampleOrders

    /// View storage for tests
    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
        stores = MockStoresManager(sessionManager: SessionManager.makeForTesting())
        application = MockApplicationAdapter()
        application.applicationState = .active
        notificationCenter = NotificationCenter()
    }

    override func tearDown() {
        // Releases the view models so they don't react to notifications posted by later tests: their start-up task waits
        // for the last selected status, answered only now so it can't replace a status a test selected, and some order
        // handlers capture them.
        stores.receivedActions.forEach { action in
            if case let AppSettingsAction.loadLastSelectedOrderStatus(_, onCompletion) = action {
                onCompletion(nil)
            }
        }
        stores.whenReceivingAction(ofType: OrderAction.self) { _ in }
        stores = nil
        storageManager = nil
        application = nil
        notificationCenter = nil
        super.tearDown()
    }

    @MainActor
    func test_last_3_orders_are_loaded_when_available() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        mockFetchFilteredOrders()
        mockOrderStatuses()

        // When
        await viewModel.reloadData()

        // Then
        let orderIDs = Array(
            sampleOrders
                .map({ $0.orderID })
        )
        XCTAssertEqual(viewModel.rows.map({ $0.id }), orderIDs)
    }

    @MainActor
    func test_syncingData_is_updated_correctly() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        XCTAssertFalse(viewModel.syncingData)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, _, completion):
                XCTAssertTrue(viewModel.syncingData)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }

        await viewModel.reloadData()

        // Then
        XCTAssertFalse(viewModel.syncingData)
    }

    @MainActor
    func test_syncingError_is_updated_correctly_when_loading_orders_fails() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        XCTAssertNil(viewModel.syncingError)
        let error = NSError(domain: "test", code: 500)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, _, completion):
                completion(1, .failure(error))
            default:
                break
            }
        }
        await viewModel.reloadData()

        // Then
        XCTAssertEqual(viewModel.syncingError as? NSError, error)
    }


    @MainActor
    func test_order_statuses_are_loaded_from_storage_when_available() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        insertOrderStatuses(sampleOrderStatuses)

        mockFetchFilteredOrders()
        mockOrderStatuses()

        // When
        await viewModel.reloadData()

        let statusSlugs = sampleOrderStatuses
            .map { $0.slug }
            .sorted()

        // Then
        XCTAssertEqual(viewModel.allStatuses.map { $0.id }, (["any"] + statusSlugs))
    }

    @MainActor
    func test_orders_are_fetched_based_on_selected_status() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        let sampleOrderStatus = LastOrdersDashboardCardViewModel.OrderStatusRow.cancelled
        mockOrderStatuses()

        var requestedOrderStatuses: [String]?

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .fetchFilteredOrders(_, let statuses, _, _, _, _, _, _, _, _, let completion):
                requestedOrderStatuses = statuses
                XCTAssertTrue(viewModel.syncingData)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }

        // When
        await viewModel.updateOrderStatus(sampleOrderStatus)

        let statuses = try XCTUnwrap(requestedOrderStatuses)
        XCTAssertEqual(statuses, [sampleOrderStatus.status?.rawValue])
    }

    @MainActor
    func test_fetch_orders_request_asks_for_only_3_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, let pageSize, let completion):
                // Then
                XCTAssertEqual(pageSize, 3)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }
        await viewModel.reloadData()
    }

    @MainActor
    func test_title_when_known_status_is_stored_then_returns_server_name() {
        // Given
        insertOrderStatuses([OrderStatus(name: "Server Processing", siteID: sampleSiteID, slug: "processing", total: 0)])
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)

        // When
        let title = viewModel.title(for: .processing)

        // Then — the stored server name is preferred over the app-localized name
        XCTAssertEqual(title, "Server Processing")
    }

    @MainActor
    func test_title_when_status_not_stored_then_falls_back_to_localizedName() {
        // Given — no statuses stored, so nothing matches `.processing`
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)

        // When
        let title = viewModel.title(for: .processing)

        // Then
        XCTAssertEqual(title, OrderStatusEnum.processing.localizedName)
    }

    @MainActor
    func test_title_when_any_row_then_returns_localized_any_case() {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)

        // When
        let title = viewModel.title(for: .any)

        // Then
        XCTAssertEqual(title, "Any")
    }

    func test_LastOrderDashboardRowViewModel_statusDescription_when_matching_site_status_then_uses_server_name() {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID, status: .processing)
        let siteStatuses = [OrderStatus(name: "Server Processing", siteID: sampleSiteID, slug: "processing", total: 0)]

        // When
        let rowViewModel = LastOrderDashboardRowViewModel(order: order, siteStatuses: siteStatuses)

        // Then
        XCTAssertEqual(rowViewModel.statusDescription, "Server Processing")
    }

    func test_LastOrderDashboardRowViewModel_statusDescription_when_no_matching_site_status_then_falls_back_to_localizedName() {
        // Given
        let order = Order.fake().copy(siteID: sampleSiteID, status: .processing)

        // When — no site statuses provided
        let rowViewModel = LastOrderDashboardRowViewModel(order: order)

        // Then
        XCTAssertEqual(rowViewModel.statusDescription, OrderStatusEnum.processing.localizedName)
    }

    @MainActor
    func test_fetch_orders_request_asks_to_skip_saving_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager)
        mockOrderStatuses()

        // When
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case .fetchFilteredOrders(_, _, _, _, _, _, _, _, let writeStrategy, _, let completion):
                // Then
                XCTAssertEqual(writeStrategy, .doNotSave)
                completion(1, .success(self.sampleOrders))
            default:
                break
            }
        }
        await viewModel.reloadData()
    }

    @MainActor
    func test_saving_shown_order_when_status_changes_then_shows_reloaded_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application)
        mockFetchFilteredOrders()
        mockOrderStatuses()
        await viewModel.reloadData()

        // When
        let completedOrder = sampleOrders[0].copy(status: .completed)
        remoteOrders = [completedOrder] + sampleOrders.dropFirst()
        await saveOrder(completedOrder)

        // Then
        await until { viewModel.rows.first?.order.status == .completed }
    }

    @MainActor
    func test_saving_shown_order_when_billing_name_changes_then_shows_reloaded_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application)
        mockFetchFilteredOrders()
        mockOrderStatuses()
        await viewModel.reloadData()

        // When
        let renamedOrder = sampleOrders[0].copy(billingAddress: Address.fake().copy(firstName: "Alma", lastName: "Reyes"))
        remoteOrders = [renamedOrder] + sampleOrders.dropFirst()
        await saveOrder(renamedOrder)

        // Then
        await until { viewModel.rows.first?.customerName == renamedOrder.billingAddress?.fullName }
    }

    @MainActor
    func test_saving_shown_order_when_displayed_details_are_unchanged_then_does_not_reload_orders() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application)
        mockFetchFilteredOrders()
        mockOrderStatuses()
        await viewModel.reloadData()

        // When
        await saveOrder(sampleOrders[0].copy(customerNote: "Leave at the door"))
        try await Task.sleep(for: .milliseconds(500)) // Longer than the reload debounce

        // Then
        XCTAssertEqual(orderFetchCount, 1)
    }

    @MainActor
    func test_ordersBadgeReloadRequired_when_card_has_loaded_then_reloads_orders() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application,
                                                         notificationCenter: notificationCenter)
        mockFetchFilteredOrders()
        mockOrderStatuses()
        await viewModel.reloadData()

        // When
        notificationCenter.post(name: .ordersBadgeReloadRequired, object: nil)

        // Then
        await until { self.orderFetchCount == 2 }
    }

    @MainActor
    func test_ordersBadgeReloadRequired_when_card_has_not_loaded_then_does_not_fetch_orders() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application,
                                                         notificationCenter: notificationCenter)
        mockFetchFilteredOrders()
        mockOrderStatuses()

        // When
        notificationCenter.post(name: .ordersBadgeReloadRequired, object: nil)
        try await Task.sleep(for: .milliseconds(500)) // Longer than the reload debounce

        // Then
        withExtendedLifetime(viewModel) {
            XCTAssertEqual(orderFetchCount, 0)
        }
    }

    @MainActor
    func test_ordersBadgeReloadRequired_when_app_is_in_background_then_reloads_orders_once_app_is_active() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application,
                                                         notificationCenter: notificationCenter)
        mockFetchFilteredOrders()
        mockOrderStatuses()
        await viewModel.reloadData()
        application.applicationState = .background

        // When
        notificationCenter.post(name: .ordersBadgeReloadRequired, object: nil)
        try await Task.sleep(for: .milliseconds(500)) // Longer than the reload debounce
        // Handled after the app went back to the background.
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        try await Task.sleep(for: .milliseconds(300))
        let fetchCountInBackground = orderFetchCount
        application.applicationState = .active
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Then
        XCTAssertEqual(fetchCountInBackground, 1)
        await until { self.orderFetchCount == 2 }
    }

    @MainActor
    func test_didBecomeActive_when_no_orders_changed_in_background_then_does_not_reload_orders() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application,
                                                         notificationCenter: notificationCenter)
        mockFetchFilteredOrders()
        mockOrderStatuses()
        await viewModel.reloadData()

        // When
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)
        try await Task.sleep(for: .milliseconds(300))

        // Then
        XCTAssertEqual(orderFetchCount, 1)
    }

    @MainActor
    func test_ordersBadgeReloadRequired_when_refreshing_then_keeps_current_rows_on_screen() async throws {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application,
                                                         notificationCenter: notificationCenter)
        var completeRefresh: ((TimeInterval, Result<[Order], Error>) -> Void)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, _, completion) = action else {
                return
            }
            self.orderFetchCount += 1
            if self.orderFetchCount == 1 {
                completion(1, .success(self.sampleOrders))
            } else {
                completeRefresh = completion
            }
        }
        mockOrderStatuses()
        await viewModel.reloadData()

        // When
        notificationCenter.post(name: .ordersBadgeReloadRequired, object: nil)
        await until { completeRefresh != nil }
        let finishRefresh = try XCTUnwrap(completeRefresh)
        let rowsDuringRefresh = viewModel.rows.map(\.id)
        let syncingDataDuringRefresh = viewModel.syncingData
        let completedOrder = sampleOrders[0].copy(status: .completed)
        finishRefresh(1, .success([completedOrder] + sampleOrders.dropFirst()))

        // Then
        XCTAssertEqual(rowsDuringRefresh, sampleOrders.map(\.orderID))
        XCTAssertFalse(syncingDataDuringRefresh)
        await until { viewModel.rows.first?.order.status == .completed }
    }

    @MainActor
    func test_ordersBadgeReloadRequired_when_last_load_failed_then_shows_orders_without_error() async {
        // Given
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         application: application,
                                                         notificationCenter: notificationCenter)
        var fetchResult: Result<[Order], Error> = .failure(NSError(domain: "test", code: 500))
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            if case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, _, completion) = action {
                completion(1, fetchResult)
            }
        }
        mockOrderStatuses()
        await viewModel.reloadData()
        XCTAssertNotNil(viewModel.syncingError)
        fetchResult = .success(sampleOrders)

        // When
        notificationCenter.post(name: .ordersBadgeReloadRequired, object: nil)

        // Then
        await until { viewModel.syncingError == nil && viewModel.rows.count == self.sampleOrders.count }
    }

    @MainActor
    func test_reloadData_when_earlier_reload_finishes_last_then_shows_orders_of_latest_reload() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        let completedOrder = sampleOrders[1]
        var completeFirstFetch: ((TimeInterval, Result<[Order], Error>) -> Void)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .fetchFilteredOrders(_, statuses, _, _, _, _, _, _, _, _, completion) = action else {
                return
            }
            if statuses == [OrderStatusEnum.completed.rawValue] {
                completion(1, .success([completedOrder]))
            } else {
                completeFirstFetch = completion
            }
        }
        mockOrderStatuses()
        let firstReload = Task {
            await viewModel.reloadData()
        }
        await until { completeFirstFetch != nil }
        let finishFirstFetch = try XCTUnwrap(completeFirstFetch)

        // When
        await viewModel.updateOrderStatus(.completed)
        finishFirstFetch(1, .success(sampleOrders))
        await firstReload.value

        // Then
        XCTAssertEqual(viewModel.rows.map(\.id), [completedOrder.orderID])
        XCTAssertFalse(viewModel.syncingData)
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0.hasPrefix("dynamic_dashboard_card_data_loading") },
                       ["dynamic_dashboard_card_data_loading_started",
                        "dynamic_dashboard_card_data_loading_started",
                        "dynamic_dashboard_card_data_loading_completed",
                        "dynamic_dashboard_card_data_loading_completed"])
    }

    @MainActor
    func test_reloadData_when_earlier_reload_fails_last_then_shows_orders_of_latest_reload_without_error() async throws {
        // Given
        let analyticsProvider = MockAnalyticsProvider()
        let viewModel = LastOrdersDashboardCardViewModel(siteID: sampleSiteID,
                                                         stores: stores,
                                                         storageManager: storageManager,
                                                         analytics: WooAnalytics(analyticsProvider: analyticsProvider))
        let completedOrder = sampleOrders[1]
        var completeFirstFetch: ((TimeInterval, Result<[Order], Error>) -> Void)?
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            guard case let .fetchFilteredOrders(_, statuses, _, _, _, _, _, _, _, _, completion) = action else {
                return
            }
            if statuses == [OrderStatusEnum.completed.rawValue] {
                completion(1, .success([completedOrder]))
            } else {
                completeFirstFetch = completion
            }
        }
        mockOrderStatuses()
        let firstReload = Task {
            await viewModel.reloadData()
        }
        await until { completeFirstFetch != nil }
        let finishFirstFetch = try XCTUnwrap(completeFirstFetch)

        // When
        await viewModel.updateOrderStatus(.completed)
        finishFirstFetch(1, .failure(NSError(domain: "test", code: 500)))
        await firstReload.value

        // Then
        XCTAssertNil(viewModel.syncingError)
        XCTAssertEqual(viewModel.rows.map(\.id), [completedOrder.orderID])
        XCTAssertEqual(analyticsProvider.receivedEvents.filter { $0.hasPrefix("dynamic_dashboard_card_data_loading") },
                       ["dynamic_dashboard_card_data_loading_started",
                        "dynamic_dashboard_card_data_loading_started",
                        "dynamic_dashboard_card_data_loading_completed",
                        "dynamic_dashboard_card_data_loading_failed"])
    }
}

private extension LastOrdersDashboardCardViewModelTests {
    func insertOrderStatuses(_ readOnlyOrderStatuses: [OrderStatus]) {
        readOnlyOrderStatuses.forEach { orderStatus in
            let newOrderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
            newOrderStatus.update(with: orderStatus)
        }
        storage.saveIfNeeded()
    }

    func mockFetchFilteredOrders() {
        stores.whenReceivingAction(ofType: OrderAction.self) { action in
            switch action {
            case let .fetchFilteredOrders(_, _, _, _, _, _, _, _, _, _, completion):
                self.orderFetchCount += 1
                completion(1, .success(self.remoteOrders))
            default:
                break
            }
        }
    }

    func mockOrderStatuses() {
        stores.whenReceivingAction(ofType: OrderStatusAction.self) { action in
            switch action {
            case let .retrieveOrderStatuses(_, completion):
                completion(.success([]))
            default:
                break
            }
        }
    }

    func saveOrder(_ order: Order) async {
        await withCheckedContinuation { continuation in
            storageManager.performAndSave({ storage in
                let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
                storageOrder.update(with: order)
            }, completion: {
                continuation.resume()
            }, on: .main)
        }
    }
}
