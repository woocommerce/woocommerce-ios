import XCTest

import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

@testable import WooCommerce

class OrderStatusListDataSourceTests: XCTestCase {

    private var storageManager: MockOrderStatusesStoresManager!

    override func setUp() {
        super.setUp()
        storageManager = MockOrderStatusesStoresManager()
    }

    override func tearDown() {
        storageManager = nil
        super.tearDown()
    }

    func test_order_of_statuses_matches_the_orders_lifecycle() throws {
        // Given
        let expectedStatusesOrder: [OrderStatusEnum] = [.pending, .processing, .onHold, .completed, .cancelled, .failed, .custom("aCustomStatus")]
        // refunded status is not shown
        let storedStatuses: [OrderStatusEnum] = [.cancelled, .completed, .failed, .onHold, .pending, .processing, .refunded, .custom("aCustomStatus")]
        storedStatuses.forEach { status in
            storageManager.insertOrderStatus(name: status.rawValue)
        }
        storageManager.viewStorage.saveIfNeeded()

        let orderStatusListDataSource = OrderStatusListDataSource(siteID: MockOrderStatusesStoresManager.siteID, storageManager: storageManager)

        // When
        try orderStatusListDataSource.performFetch()
        let statuses = orderStatusListDataSource.statuses()

        // Then
        let actualStatusesOrder = statuses.map({ $0.status })
        XCTAssertEqual(actualStatusesOrder, expectedStatusesOrder)
    }
}

/// Mock Order Statuses Store Manager
///
private final class MockOrderStatusesStoresManager: MockStorageManager {
    fileprivate static let siteID: Int64 = 1

    /// Inserts an order status
    ///
    @discardableResult
    func insertOrderStatus(name: String) -> StorageOrderStatus {
        let orderStatus = viewStorage.insertNewObject(ofType: StorageOrderStatus.self)
        orderStatus.name = name
        orderStatus.slug = name
        orderStatus.siteID = MockOrderStatusesStoresManager.siteID
        return orderStatus
    }
}
