
import XCTest
import Foundation
import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

@testable import WooCommerce

/// Tests for `OrderSearchStarterViewModel`
///
final class OrderSearchStarterViewModelTests: XCTestCase {
    private let siteID: Int64 = 1_000_000

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

    func testItLoadsAllTheOrderStatusForTheGivenSite() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        let expectedItems = [
            insertOrderStatus(siteID: siteID, status: .completed),
            insertOrderStatus(siteID: siteID, status: .failed),
            insertOrderStatus(siteID: siteID, status: .processing),
        ]

        let unexpectedItem = insertOrderStatus(siteID: 511_315, status: .pending)

        // When
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Then
        XCTAssertEqual(viewModel.numberOfObjects, expectedItems.count)
        XCTAssertEqual(viewModel.fetchedOrderStatuses, expectedItems)
        XCTAssertFalse(viewModel.fetchedOrderStatuses.contains(where: { $0.siteID != siteID }))
        XCTAssertFalse(viewModel.fetchedOrderStatuses.contains(unexpectedItem))
    }

    func testItSortsTheOrderStatusesBySlug() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        insert(OrderStatus(name: "autem", siteID: siteID, slug: "delta", total: 0))
        insert(OrderStatus(name: "dolores", siteID: siteID, slug: "charlie", total: 0))
        insert(OrderStatus(name: "fugit", siteID: siteID, slug: "echo", total: 0))
        insert(OrderStatus(name: "itaque", siteID: siteID, slug: "alpha", total: 0))
        insert(OrderStatus(name: "eos", siteID: siteID, slug: "beta", total: 0))

        // When
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Then
        let expectedSlugs = ["alpha", "beta", "charlie", "delta", "echo"]
        let actualSlugs = viewModel.fetchedOrderStatuses.map(\.slug)
        XCTAssertEqual(actualSlugs, expectedSlugs)
    }

    func testItReturnsTheNameSlugAndTotalInTheCellViewModel() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        insert(OrderStatus(name: "autem", siteID: siteID, slug: "delta", total: 18))
        insert(OrderStatus(name: "dolores", siteID: siteID, slug: "charlie", total: 73))

        viewModel.activateAndForwardUpdates(to: UITableView())

        // When
        // Retrieve "delta" which is the second row
        let cellViewModel = viewModel.cellViewModel(at: IndexPath(row: 1, section: 0))

        // Then
        XCTAssertEqual(cellViewModel.name, "autem")
        XCTAssertEqual(cellViewModel.slug, "delta")
        XCTAssertEqual(cellViewModel.total,
                       NumberFormatter.localizedString(from: NSNumber(value: 18), number: .none))
    }

    func testGivenAnOrderStatusTotalOfMoreThanNinetyNineItUsesNinetyNinePlus() {
        // Given
        let viewModel = OrderSearchStarterViewModel(siteID: siteID, storageManager: storageManager)

        insert(OrderStatus(name: "Processing", siteID: siteID, slug: "slug", total: 200))

        viewModel.activateAndForwardUpdates(to: UITableView())

        // When
        let cellViewModel = viewModel.cellViewModel(at: IndexPath(row: 0, section: 0))

        // Then
        XCTAssertEqual(cellViewModel.total, NSLocalizedString("99+", comment: ""))
    }
}

// MARK: - Helpers

private extension OrderSearchStarterViewModel {
    /// Returns the `OrderStatus` for all the rows
    ///
    var fetchedOrderStatuses: [OrderStatus] {
        (0..<numberOfObjects).map { orderStatus(at: IndexPath(row: $0, section: 0)) }
    }
}

// MARK: - Fixtures

private extension OrderSearchStarterViewModelTests {
    @discardableResult
    func insert(_ readOnlyOrderStatus: OrderStatus) -> OrderStatus {
        let storageOrderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
        storageOrderStatus.update(with: readOnlyOrderStatus)
        return readOnlyOrderStatus
    }

    @discardableResult
    func insertOrderStatus(siteID: Int64, status: OrderStatusEnum) -> OrderStatus {
        let readOnlyOrderStatus = OrderStatus(name: status.rawValue,
                                              siteID: siteID,
                                              slug: status.rawValue,
                                              total: 0)

        return insert(readOnlyOrderStatus)
    }
}
