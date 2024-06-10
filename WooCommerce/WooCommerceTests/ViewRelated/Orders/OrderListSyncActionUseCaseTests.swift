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

    // Test that when pulling to refresh on a filtered list,
    // the action returned will be for:
    //
    // 1. deleting all orders
    // 2. fetching the filtered list (any date modified)
    //
    func test_pulling_to_refresh_on_filtered_list_it_deletes_and_performs_fetch() {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: nil,
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: filters)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: .pullToRefresh,
                                       lastFullSyncTimestamp: Date(),
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredOrders(_, let statuses, _, _, let modifiedAfter, _, _, let writeStrategy, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(writeStrategy, .deleteAllBeforeSaving)
        XCTAssertEqual(statuses, [OrderStatusEnum.processing.rawValue])
        XCTAssertNil(modifiedAfter)
    }

    // Test that when fetching the first page of a filtered list for reasons
    // other than pull-to-refresh (e.g. `viewWillAppear`), the action returned will only be the filtered list,
    // and only for orders modified after the last full sync.
    //
    func test_first_page_load_on_filtered_list_with_non_pull_to_refresh_reasons_will_only_perform_fetch() {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: nil,
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: filters)

        // Act
        let lastSyncDate = Date()
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: nil,
                                       lastFullSyncTimestamp: lastSyncDate,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredOrders(_, let statuses, _, _, let modifiedAfter, _, _, let writeStrategy, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(writeStrategy, .save)
        XCTAssertEqual(statuses, [OrderStatusEnum.processing.rawValue])
        XCTAssertEqual(modifiedAfter, lastSyncDate)
    }

    // Test that when pulling to refresh, the action returned will be for:
    //
    // 1. Deleting all the orders
    // 2. Fetching the first page of all orders (any status, any date modified)
    //
    func test_pulling_to_refresh_on_all_orders_list_deletes_and_fetches_first_page_of_all_orders_only() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: nil)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: .pullToRefresh,
                                       lastFullSyncTimestamp: Date(),
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredOrders(_, let statuses, _, _, let modifiedAfter, _, _, let writeStrategy, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(writeStrategy, .deleteAllBeforeSaving)
        XCTAssertNil(statuses?.first)
        XCTAssertNil(modifiedAfter)
    }

    // Test when fetching the first page of order list for reasons other than
    // pull-to-refresh (e.g. `viewWillAppear`), the action should return all the orders modified after the last sync.
    //
    func test_first_page_load_with_non_pull_to_refresh_reasons_will_only_perform_single_fetch() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: nil)

        // Act
        let lastSyncDate = Date()
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: nil,
                                       lastFullSyncTimestamp: lastSyncDate,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredOrders(_, let statuses, _, _, let modifiedAfter, _, _, let writeStrategy, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(writeStrategy, .save)
        XCTAssertNil(statuses?.first)
        XCTAssertEqual(modifiedAfter, lastSyncDate)
    }

    func test_subsequent_page_loads_on_filtered_list_will_fetch_the_given_page_on_that_list() {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.pending],
                                                       dateRange: nil,
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: filters)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex + 3,
                                       pageSize: pageSize,
                                       reason: nil,
                                       lastFullSyncTimestamp: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .synchronizeOrders(_, let statuses, _, _, _, _, _, let pageNumber, let pageSize, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(statuses, [OrderStatusEnum.pending.rawValue])
        XCTAssertEqual(pageNumber, Defaults.pageFirstIndex + 3)
        XCTAssertEqual(pageSize, self.pageSize)
    }

    func test_subsequent_page_loads_on_all_orders_list_will_fetch_the_given_page_on_that_list() {
        // Arrange
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: nil)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex + 5,
                                       pageSize: pageSize,
                                       reason: nil,
                                       lastFullSyncTimestamp: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .synchronizeOrders(_, let statuses, _, _, _, _, _, let pageNumber, let pageSize, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertNil(statuses?.first)
        XCTAssertEqual(pageNumber, Defaults.pageFirstIndex + 5)
        XCTAssertEqual(pageSize, self.pageSize)
    }

    // Test that when refresh on a filtered list, the action
    // returned will be for:
    //
    // 1. deleting all orders
    // 2. fetching all the orders filtered
    //
    func test_refresh_with_new_filters_applied_deletes_and_performs_single_fetch() {
        // Arrange
        let filters = FilterOrderListViewModel.Filters(orderStatus: [.processing],
                                                       dateRange: nil,
                                                       product: FilterOrdersByProduct(id: 1, name: "Sample product"),
                                                       customer: nil,
                                                       numberOfActiveFilters: 1)
        let useCase = OrderListSyncActionUseCase(siteID: siteID,
                                                 filters: filters)

        // Act
        let action = useCase.actionFor(pageNumber: Defaults.pageFirstIndex,
                                       pageSize: pageSize,
                                       reason: .newFiltersApplied,
                                       lastFullSyncTimestamp: nil,
                                       completionHandler: unimportantCompletionHandler)

        // Assert
        guard case .fetchFilteredOrders(_, let statuses, _, _, _, _, _, let writeStrategy, _, _) = action else {
            XCTFail("Unexpected OrderAction type: \(action)")
            return
        }

        XCTAssertEqual(writeStrategy, .deleteAllBeforeSaving)
        XCTAssertEqual(statuses, [OrderStatusEnum.processing.rawValue])
    }
}

private extension OrderListSyncActionUseCaseTests {
    func orderStatus(with status: OrderStatusEnum) -> Yosemite.OrderStatus {
        OrderStatus(name: nil, siteID: siteID, slug: status.rawValue, total: 0)
    }
}
