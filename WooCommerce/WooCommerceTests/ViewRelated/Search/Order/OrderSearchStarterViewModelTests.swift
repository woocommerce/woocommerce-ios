
import XCTest
import Foundation
import Yosemite
import Storage

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

        insertOrderStatus(siteID: siteID, status: .completed, slug: "delta")
        insertOrderStatus(siteID: siteID, status: .processing, slug: "charlie")
        insertOrderStatus(siteID: siteID, status: .failed, slug: "echo")
        insertOrderStatus(siteID: siteID, status: .cancelled, slug: "alpha")
        insertOrderStatus(siteID: siteID, status: .cancelled, slug: "beta")

        // When
        viewModel.activateAndForwardUpdates(to: UITableView())

        // Then
        let expectedSlugs = ["alpha", "beta", "charlie", "delta", "echo"]
        let actualSlugs = viewModel.fetchedOrderStatuses.map(\.slug)
        XCTAssertEqual(actualSlugs, expectedSlugs)
    }
}

// MARK: - Helpers

private extension OrderSearchStarterViewModel {
    /// Returns the `OrderStatus` for all the rows
    ///
    var fetchedOrderStatuses: [Yosemite.OrderStatus] {
        (0..<numberOfObjects).map { orderStatus(at: IndexPath(row: $0, section: 0)) }
    }
}

// MARK: - Fixtures

private extension OrderSearchStarterViewModelTests {
    @discardableResult
    func insertOrderStatus(siteID: Int64,
                           status: OrderStatusEnum,
                           slug: String? = nil) -> Yosemite.OrderStatus {
        let readOnlyOrderStatus = OrderStatus(name: status.rawValue,
                                              siteID: siteID,
                                              slug: slug ?? status.rawValue,
                                              total: 0)

        let storageOrderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
        storageOrderStatus.update(with: readOnlyOrderStatus)

        return readOnlyOrderStatus
    }
}
