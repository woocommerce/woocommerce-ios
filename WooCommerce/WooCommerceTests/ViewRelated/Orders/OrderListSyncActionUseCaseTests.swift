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

    private let unimportantCompletionHandler: ((Error?) -> Void) = { _ in
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
                                                 statusFilter: orderStatus(with: .processing),
                                                 includesFutureOrders: true)

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
}

private extension OrderListSyncActionUseCaseTests {
    func orderStatus(with status: OrderStatusEnum) -> Yosemite.OrderStatus {
        OrderStatus(name: nil, siteID: siteID, slug: status.rawValue, total: 0)
    }
}
