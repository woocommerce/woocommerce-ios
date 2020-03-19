
import Foundation
import XCTest
@testable import WooCommerce
import Yosemite

private typealias SyncReason = OrdersViewModel.SyncReason
private typealias Defaults = OrdersViewModel.Defaults

final class OrdersViewModelTests: XCTestCase {
    /// The `siteID` value doesn't matter.
    private let siteID: Int64 = 1_000_000
    /// The `pageSize` value doesn't matter.
    private let pageSize = 50

    private let unimportantCompletionHandler: ((Error?) -> Void) = { _ in
        // noop
    }

    // Test that when pulling to refresh on a filtered list (e.g. Processing tab), the action
    // returned will be for:
    //
    // 1. deleting all orders
    // 2. fetching both the filtered list and the "all orders" list
    //
    func testPullingToRefreshOnFilteredListItDeletesAndPerformsDualFetch() {
        // Arrange
        let viewModel = OrdersViewModel()

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            statusKey: OrderStatusEnum.processing.rawValue,
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

    // Test that when fetching the first page for reasons other than pull-to-refresh
    // (e.g. `viewWillAppear`), the action returned will only be for dual fetching of the
    // filtered list and the all orders list.
    //
    func testFirstPageLoadOnFilteredListWithNonPullToRefreshReasonsWillOnlyPerformDualFetch() {
        // Arrange
        let viewModel = OrdersViewModel()

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            statusKey: OrderStatusEnum.processing.rawValue,
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
    func testPullingToRefreshOnAllOrdersListDeletesAndFetchesFirstPage() {
        // Arrange
        let viewModel = OrdersViewModel()

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            statusKey: nil,
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
        XCTAssertNil(statusKey)
    }
}
