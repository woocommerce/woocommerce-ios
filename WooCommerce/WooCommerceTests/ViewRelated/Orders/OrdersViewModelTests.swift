
import Foundation
import XCTest
@testable import WooCommerce
import Yosemite
import Storage

private typealias SyncReason = OrderListSyncActionUseCase.SyncReason
private typealias Defaults = OrdersViewModel.Defaults

/// Tests for `OrdersViewModel`.
///
final class OrdersViewModelTests: XCTestCase {
    /// The `siteID` value doesn't matter.
    private let siteID: Int64 = 1_000_000
    private let pageSize = 50

    private let unimportantCompletionHandler: ((Error?) -> Void) = { _ in
        // noop
    }

    private var storageManager: StorageManagerType!
    private var stores: StoresManager!

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
        stores = MockupStoresManager(sessionManager: .makeForTesting(authenticated: true))
        stores.sessionManager.setStoreId(siteID)
    }

    override func tearDown() {
        // If not resetting store ID back to `nil`, it could cause other test failures since `setStoreId` changes UserDefaults.
        stores.sessionManager.setStoreId(nil)
        stores = nil
        storageManager = nil
        super.tearDown()
    }

    // MARK: - Future Orders

    func test_given_a_filter_it_loads_the_orders_matching_that_filter_from_the_DB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager,
                                        statusFilter: orderStatus(with: .processing),
                                        stores: stores)

        let processingOrders = (0..<10).map { insertOrder(id: $0, status: .processing) }
        let completedOrders = (100..<105).map { insertOrder(id: $0, status: .completed) }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), processingOrders.count + completedOrders.count)

        // Act
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.numberOfObjects, processingOrders.count)

        XCTAssertEqual(viewModel.fetchedOrders.orderIDs, processingOrders.orderIDs)
    }

    func test_given_no_filter_it_loads_all_the_today_and_past_orders_from_the_DB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager, statusFilter: nil, stores: stores)

        let allInsertedOrders = [
            (0..<10).map { insertOrder(id: $0, status: .processing) },
            (100..<105).map { insertOrder(id: $0, status: .completed, dateCreated: Date().adding(days: -2)!) },
            (200..<203).map { insertOrder(id: $0, status: .pending) },
        ].flatMap { $0 }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), allInsertedOrders.count)

        // Act
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.numberOfObjects, allInsertedOrders.count)

        XCTAssertEqual(viewModel.fetchedOrders.orderIDs, allInsertedOrders.orderIDs)
    }

    /// If `includeFutureOrders` is `true`, all orders including orders dated in the future (dateCreated) will
    /// be fetched.
    func test_given_including_future_orders_it_also_loads_future_orders_from_the_DB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager,
                                        statusFilter: orderStatus(with: .pending),
                                        includesFutureOrders: true,
                                        stores: stores)

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
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertEqual(viewModel.numberOfObjects, expectedOrders.count)
        XCTAssertEqual(viewModel.fetchedOrders.orderIDs, expectedOrders.orderIDs)

        XCTAssertFalse(viewModel.fetchedOrders.orderIDs.contains(ignoredFutureOrder.orderID))
    }

    /// If `includesFutureOrders` is `false`, only orders created up to the current day are returned. Orders before
    /// midnight are included.
    func test_given_excluding_future_orders_it_only_loads_orders_up_to_midnight_from_the_DB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager, statusFilter: nil, includesFutureOrders: false, stores: stores)

        let ignoredOrders = [
            // Orders in the future
            insertOrder(id: 1_001, status: .pending, dateCreated: Date().adding(days: 1)!),
            insertOrder(id: 1_002, status: .cancelled, dateCreated: Date().adding(days: 3)!),
            // Exactly midnight is also ignored because it is technically "tomorrow"
            insertOrder(id: 1_003, status: .processing, dateCreated: Date().nextMidnight()!),
        ]

        let expectedOrders = [
            insertOrder(id: 4_001, status: .completed, dateCreated: Date()),
            insertOrder(id: 4_002, status: .pending, dateCreated: Date().adding(days: -1)!),
            insertOrder(id: 4_003, status: .pending, dateCreated: Date().adding(days: -20)!),
            // 1 second before midnight is included because it is technically "today"
            insertOrder(id: 4_004, status: .processing, dateCreated: Date().nextMidnight()!.adding(seconds: -1)!),
        ]

        // Act
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertTrue(viewModel.fetchedOrders.orderIDs.isDisjoint(with: ignoredOrders.orderIDs))

        XCTAssertEqual(viewModel.numberOfObjects, expectedOrders.count)
        XCTAssertEqual(viewModel.fetchedOrders.orderIDs, expectedOrders.orderIDs)
    }

    /// Orders with dateCreated in the future should be grouped in an "Upcoming" section.
    func test_it_groups_future_orders_in_upcoming_section() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager, statusFilter: orderStatus(with: .failed), stores: stores)

        let expectedOrders = (
            future: [
                insertOrder(id: 1_000, status: .failed, dateCreated: Date().adding(days: 3)!),
                insertOrder(id: 1_000, status: .failed, dateCreated: Date().adding(days: 4)!),
            ],
            past: [
                insertOrder(id: 4_000, status: .failed, dateCreated: Date().adding(days: -1)!),
            ]
        )

        // Act
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertEqual(viewModel.numberOfSections, 2)

        // The first section should be the Upcoming section
        let upcomingSection = viewModel.sectionInfo(at: 0)
        XCTAssertEqual(Age(rawValue: upcomingSection.name), .upcoming)
        XCTAssertEqual(upcomingSection.numberOfObjects, expectedOrders.future.count)
    }

    // MARK: - App Activation

    func test_it_requests_a_resynchronization_when_the_app_is_activated() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrdersViewModel(notificationCenter: notificationCenter, statusFilter: nil, stores: stores)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activateAndForwardUpdates(to: UITableView())

        // Act
        notificationCenter.post(name: UIApplication.willResignActiveNotification, object: nil)
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_no_previous_deactivation_it_does_not_request_a_resynchronization_when_the_app_is_activated() {
        // Arrange
        let notificationCenter = NotificationCenter()
        let viewModel = OrdersViewModel(notificationCenter: notificationCenter, statusFilter: nil, stores: stores)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activateAndForwardUpdates(to: UITableView())

        // Act
        notificationCenter.post(name: UIApplication.didBecomeActiveNotification, object: nil)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }

    // MARK: - Foreground Notifications

    func test_given_a_new_order_notification_it_requests_a_resynchronization() {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrdersViewModel(pushNotificationsManager: pushNotificationsManager, statusFilter: nil, stores: stores)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activateAndForwardUpdates(to: UITableView())

        // Act
        let notification = PushNotification(noteID: 1, kind: .storeOrder, message: "")
        pushNotificationsManager.sendForegroundNotification(notification)

        // Assert
        XCTAssertTrue(resynchronizeRequested)
    }

    func test_given_a_non_order_notification_it_does_not_request_a_resynchronization() {
        // Arrange
        let pushNotificationsManager = MockPushNotificationsManager()
        let viewModel = OrdersViewModel(pushNotificationsManager: pushNotificationsManager, statusFilter: nil, stores: stores)

        var resynchronizeRequested = false
        viewModel.onShouldResynchronizeIfViewIsVisible = {
            resynchronizeRequested = true
        }

        viewModel.activateAndForwardUpdates(to: UITableView())

        // Act
        let notification = PushNotification(noteID: 1, kind: .comment, message: "")
        pushNotificationsManager.sendForegroundNotification(notification)

        // Assert
        XCTAssertFalse(resynchronizeRequested)
    }
}

// MARK: - Helpers

private extension OrdersViewModel {
    /// Returns the Order instances for all the rows
    ///
    var fetchedOrders: [Yosemite.Order] {
        (0..<numberOfSections).flatMap { section in
            (0..<numberOfRows(in: section)).compactMap { row in
                detailsViewModel(at: IndexPath(row: row, section: section))?.order
            }
        }
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

private extension OrdersViewModelTests {
    func orderStatus(with status: OrderStatusEnum) -> Yosemite.OrderStatus {
        OrderStatus(name: nil, siteID: siteID, slug: status.rawValue, total: 0)
    }

    func insertOrder(id orderID: Int64,
                     status: OrderStatusEnum,
                     dateCreated: Date = Date()) -> Yosemite.Order {
        let readonlyOrder = Order(siteID: siteID,
                                  orderID: orderID,
                                  parentID: 0,
                                  customerID: 11,
                                  number: "963",
                                  status: status,
                                  currency: "USD",
                                  customerNote: "",
                                  dateCreated: dateCreated,
                                  dateModified: Date(),
                                  datePaid: nil,
                                  discountTotal: "30.00",
                                  discountTax: "1.20",
                                  shippingTotal: "0.00",
                                  shippingTax: "0.00",
                                  total: "31.20",
                                  totalTax: "1.20",
                                  paymentMethodTitle: "Credit Card (Stripe)",
                                  items: [],
                                  billingAddress: nil,
                                  shippingAddress: nil,
                                  shippingLines: [],
                                  coupons: [],
                                  refunds: [])

        let storageOrder = storage.insertNewObject(ofType: StorageOrder.self)
        storageOrder.update(with: readonlyOrder)

        return readonlyOrder
    }
}
