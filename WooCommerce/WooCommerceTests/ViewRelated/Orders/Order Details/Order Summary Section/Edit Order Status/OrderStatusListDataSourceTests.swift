import XCTest

import Yosemite

import protocol Storage.StorageManagerType
import protocol Storage.StorageType

import YosemiteTestHelpers
@testable import WooCommerce

class OrderStatusListDataSourceTests: XCTestCase {

    private var storageManager: MockStorageManager!

    override func setUp() {
        super.setUp()
        storageManager = MockStorageManager()
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
        let siteID: Int64 = 1
        storageManager.performAndSave({ storage in
            for status in storedStatuses {
                let orderStatus = storage.insertNewObject(ofType: StorageOrderStatus.self)
                orderStatus.name = status.rawValue
                orderStatus.slug = status.rawValue
                orderStatus.siteID = siteID
            }
        }, completion: nil, on: .main)

        let orderStatusListDataSource = OrderStatusListDataSource(siteID: siteID, storageManager: storageManager)

        // When
        try orderStatusListDataSource.performFetch()
        let statuses = orderStatusListDataSource.statuses()

        // Then
        let actualStatusesOrder = statuses.map({ $0.status })
        XCTAssertEqual(actualStatusesOrder, expectedStatusesOrder)
    }
}
