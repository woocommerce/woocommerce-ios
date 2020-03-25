
import Foundation
import XCTest
@testable import WooCommerce
import Yosemite

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

    // Test that when fetching the first page of a filtered list (e.g. Processing) for reasons
    // other than pull-to-refresh (e.g. `viewWillAppear`), the action returned will only be for
    // dual fetching of the filtered list and the all orders list.
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
    func testPullingToRefreshOnAllOrdersListDeletesAndFetchesFirstPageOfAllOrdersOnly() {
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
        XCTAssertNil(statusKey, "No filtered list will be fetched.")
    }

    // Test that when fetching the first page of the All Orders list for reasons other than
    // pull-to-refresh (e.g. `viewWillAppear`), the action returned will only be for fetching the
    // all the orders (any status).
    //
    func testFirstPageLoadOnAllOrdersListWithNonPullToRefreshReasonsWillOnlyPerformSingleFetch() {
        // Arrange
        let viewModel = OrdersViewModel()

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            statusKey: nil,
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
        let viewModel = OrdersViewModel()

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            statusKey: OrderStatusEnum.pending.rawValue,
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
        let viewModel = OrdersViewModel()

        // Act
        let action = viewModel.synchronizationAction(
            siteID: siteID,
            statusKey: nil,
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
}
