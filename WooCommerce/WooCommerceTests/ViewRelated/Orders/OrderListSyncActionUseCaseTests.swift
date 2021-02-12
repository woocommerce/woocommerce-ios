import XCTest

@testable import WooCommerce
import Yosemite

private typealias SyncReason = OrderListSyncActionUseCase.SyncReason
private typealias Defaults = OrderListSyncActionUseCase.Defaults

/// Tests for `OrderListSyncActionUseCase`.
final class OrderListSyncActionUseCaseTests: XCTestCase {
    /// The `siteID` value doesn't matter.
    private let siteID: Int64 = 1_000_000
    private let pageSize = 50

    private let unimportantCompletionHandler: ((TimeInterval, Error?) -> Void) = { _, _ in
        // noop
    }

    // Test that when pulling to refresh on a filtered list (e.g. Processing tab), the action
    // returned will be for:
    //
    // 1. deleting all orders
    // 2. fetching both the filtered list and the "all orders" list
    //
    func test_pulling_to_refresh_on_filtered_list_it_deletes_and_performs_dual_fetch() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: orderStatus(with: .processing))

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: .pullToRefresh,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, _, let deleteAllBeforeSaving, _, _) = action else {
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
    func test_first_page_load_on_filtered_list_with_non_pull_to_refresh_reasons_will_only_perform_dual_fetch() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: orderStatus(with: .processing))

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, _, let deleteAllBeforeSaving, _, _) = action else {
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
    func test_pulling_to_refresh_on_all_orders_list_deletes_and_fetches_first_page_of_all_orders_only() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: nil)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: .pullToRefresh,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, _, let deleteAllBeforeSaving, _, _) = action else {
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
    func test_first_page_load_on_all_orders_list_with_non_pull_to_refresh_reasons_will_only_perform_single_fetch() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: nil)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredAndAllOrders(_, let statusKey, _, let deleteAllBeforeSaving, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertFalse(deleteAllBeforeSaving)
        XCTAssertNil(statusKey, "No filtered list will be fetched.")
    }

    func test_subsequent_page_loads_on_filtered_list_will_fetch_the_given_page_on_that_list() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: orderStatus(with: .pending))

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex + 3,
                                       pageSize: pageSize,
                                       reason: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .synchronizeOrders(_, let statusKey, _, let pageNumber, let pageSize, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(statusKey, OrderStatusEnum.pending.rawValue)
        XCTAssertEqual(pageNumber, Defaults.pageFirstIndex + 3)
        XCTAssertEqual(pageSize, self.pageSize)
    }

    func test_subsequent_page_loads_on_all_orders_list_will_fetch_the_given_page_on_that_list() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 statusFilter: nil)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex + 5,
                                       pageSize: pageSize,
                                       reason: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .synchronizeOrders(_, let statusKey, _, let pageNumber, let pageSize, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertNil(statusKey)
        XCTAssertEqual(pageNumber, Defaults.pageFirstIndex + 5)
        XCTAssertEqual(pageSize, self.pageSize)
    }
}

private extension OrderListSyncActionUseCaseTests {
    func orderStatus(with status: OrderStatusEnum) -> Yosemite.OrderStatus {
        OrderStatus(name: nil, siteID: siteID, slug: status.rawValue, total: 0)
    }
}
