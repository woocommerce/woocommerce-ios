
import Foundation
import XCTest
@testable import WooCommerce
import Yosemite
import Storage

private typealias SyncReason = OrdersViewModel.SyncReason
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

    private var storage: StorageType {
        storageManager.viewStorage
    }

    override func setUp() {
        super.setUp()
        storageManager = MockupStorageManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    // Test that when pulling to refresh on a filtered list (e.g. Processing tab), the action
    // returned will be for:
    //
    // 1. deleting all orders
    // 2. fetching both the filtered list and the "all orders" list
    //
    func testPullingToRefreshOnFilteredListItDeletesAndPerformsDualFetch() {
        // Arrange
        let viewModel = OrdersViewModel(statusFilter: orderStatus(with: .processing))

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: Defaults.pageFirstIndex,
            pageSize: pageSize,
            reason: SyncReason.pullToRefresh,
            completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, let deleteAllBeforeSaving, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertTrue(deleteAllBeforeSaving)
        XCTAssertEqual(statusKey, OrderStatusEnum.processing.rawValue)
    }

    // Test that when fetching the first page of a filtered list (e.g. Processing) for reasons
    // other than pull-to-refresh (e.g. `viewWillAppear`), the action returned will only be for
    // dual fetching of the filtered list and the all orders list.
    //
    func testFirstPageLoadOnFilteredListWithNonPullToRefreshReasonsWillOnlyPerformDualFetch() {
        // Arrange
        let viewModel = OrdersViewModel(statusFilter: orderStatus(with: .processing))

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: Defaults.pageFirstIndex,
            pageSize: pageSize,
            reason: nil,
            completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, let deleteAllBeforeSaving, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertFalse(deleteAllBeforeSaving)
        XCTAssertEqual(statusKey, OrderStatusEnum.processing.rawValue)
    }

    // Test that when pulling to refresh on the All Orders tab, the action returned will be for:
    //
    // 1. Deleting all the orders
    // 2. Fetching the first page of all orders (any status)
    //
    func testPullingToRefreshOnAllOrdersListDeletesAndFetchesFirstPageOfAllOrdersOnly() {
        // Arrange
        let viewModel = OrdersViewModel(statusFilter: nil)

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: Defaults.pageFirstIndex,
            pageSize: pageSize,
            reason: SyncReason.pullToRefresh,
            completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, let deleteAllBeforeSaving, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertTrue(deleteAllBeforeSaving)
        XCTAssertNil(statusKey, "No filtered list will be fetched.")
    }

    // Test that when fetching the first page of the All Orders list for reasons other than
    // pull-to-refresh (e.g. `viewWillAppear`), the action returned will only be for fetching the
    // all the orders (any status).
    //
    func testFirstPageLoadOnAllOrdersListWithNonPullToRefreshReasonsWillOnlyPerformSingleFetch() {
        // Arrange
        let viewModel = OrdersViewModel(statusFilter: nil)

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: Defaults.pageFirstIndex,
            pageSize: pageSize,
            reason: nil,
            completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, let deleteAllBeforeSaving, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertFalse(deleteAllBeforeSaving)
        XCTAssertNil(statusKey, "No filtered list will be fetched.")
    }

    func testSubsequentPageLoadsOnFilteredListWillFetchTheGivenPageOnThatList() {
        // Arrange
        let viewModel = OrdersViewModel(statusFilter: orderStatus(with: .pending))

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: Defaults.pageFirstIndex + 3,
            pageSize: pageSize,
            reason: nil,
            completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .synchronizeOrders(_, let statusKey, let pageNumber, let pageSize, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(statusKey, OrderStatusEnum.pending.rawValue)
        XCTAssertEqual(pageNumber, Defaults.pageFirstIndex + 3)
        XCTAssertEqual(pageSize, self.pageSize)
    }

    func testSubsequentPageLoadsOnAllOrdersListWillFetchTheGivenPageOnThatList() {
        // Arrange
        let viewModel = OrdersViewModel(statusFilter: nil)

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            pageNumber: Defaults.pageFirstIndex + 5,
            pageSize: pageSize,
            reason: nil,
            completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .synchronizeOrders(_, let statusKey, let pageNumber, let pageSize, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertNil(statusKey)
        XCTAssertEqual(pageNumber, Defaults.pageFirstIndex + 5)
        XCTAssertEqual(pageSize, self.pageSize)
    }

    func testGivenAFilterItLoadsTheOrdersMatchingThatFilterFromTheDB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager,
                                        statusFilter: orderStatus(with: .processing))

        let processingOrders = (0..<10).map { insertOrder(id: $0, status: .processing) }
        let completedOrders = (100..<105).map { insertOrder(id: $0, status: .completed) }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), processingOrders.count + completedOrders.count)

        // Act
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertTrue(viewModel.isFiltered)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.numberOfObjects, processingOrders.count)

        XCTAssertEqual(viewModel.fetchedOrderIDs, processingOrders.orderIDs)
    }

    func testGivenNoFilterItLoadsAllTheTodayAndPastOrdersFromTheDB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager, statusFilter: nil)

        let allInsertedOrders = [
            (0..<10).map { insertOrder(id: $0, status: .processing) },
            (100..<105).map { insertOrder(id: $0, status: .completed, dateCreated: Date().adding(days: -2)!) },
            (200..<203).map { insertOrder(id: $0, status: .pending) },
        ].flatMap { $0 }

        XCTAssertEqual(storage.countObjects(ofType: StorageOrder.self), allInsertedOrders.count)

        // Act
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Assert
        XCTAssertFalse(viewModel.isFiltered)
        XCTAssertFalse(viewModel.isEmpty)
        XCTAssertEqual(viewModel.numberOfObjects, allInsertedOrders.count)

        XCTAssertEqual(viewModel.fetchedOrderIDs, allInsertedOrders.orderIDs)
    }

    /// If `includeFutureOrders` is `true`, all orders including orders dated in the future (dateCreated) will
    /// be fetched.
    func testGivenIncludingFutureOrdersItAlsoLoadsFutureOrdersFromTheDB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager,
                                        statusFilter: orderStatus(with: .pending),
                                        includesFutureOrders: true)

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
        XCTAssertEqual(viewModel.fetchedOrderIDs, expectedOrders.orderIDs)

        XCTAssertFalse(viewModel.fetchedOrderIDs.contains(ignoredFutureOrder.orderID))
    }

    /// If `includesFutureOrders` is `false`, only orders created up to the current day are returned. Orders before
    /// midnight are included.
    func testGivenExcludingFutureOrdersItOnlyLoadsOrdersUpToMidnightFromTheDB() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager, statusFilter: nil, includesFutureOrders: false)

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
        XCTAssertTrue(viewModel.fetchedOrderIDs.isDisjoint(with: ignoredOrders.orderIDs))

        XCTAssertEqual(viewModel.numberOfObjects, expectedOrders.count)
        XCTAssertEqual(viewModel.fetchedOrderIDs, expectedOrders.orderIDs)
    }

    /// Orders with dateCreated in the future should be grouped in an "Upcoming" section.
    func testItGroupsFutureOrdersInUpcomingSection() {
        // Arrange
        let viewModel = OrdersViewModel(storageManager: storageManager, statusFilter: orderStatus(with: .failed))

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
}

// MARK: - Helpers

private extension OrdersViewModel {
    /// Returns the Order instances for all the rows
    ///
    var fetchedOrders: [Yosemite.Order] {
        (0..<numberOfSections).flatMap { section in
            (0..<numberOfRows(in: section)).map { row in
                detailsViewModel(at: IndexPath(row: row, section: section)).order
            }
        }
    }

    /// Returns the IDs for all the Order rows
    ///
    var fetchedOrderIDs: Set<Int64> {
        Set(fetchedOrders.map(\.orderID))
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
                                  statusKey: status.rawValue,
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
