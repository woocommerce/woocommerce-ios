import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// OrderStatusStore Unit Tests
///
class OrderStatusStoreTests: XCTestCase {

    /// Mock Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses!
    ///
    private var network: MockNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 123

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    // MARK: - OrderStatusAction.resetStoredOrderStatuses

    /// Verifies that OrderStatusAction.resetStoredOrderStatuses nukes the Orders Cache.
    ///
    func testResetStoredOrderStatusesEffectivelyNukesTheStoredOrderStatuses() {
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        let group = DispatchGroup()

        group.enter()
        orderStatusStore.upsertStatusesInBackground(siteID: sampleSiteID, readOnlyOrderStatuses: sampleOrderStatuses()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        let expectation = self.expectation(description: "Order Statii Reset")
        group.notify(queue: .main) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), 9)
            let action = OrderStatusAction.resetStoredOrderStatuses() {
                XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)
                expectation.fulfill()
            }
            orderStatusStore.onAction(action)
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - OrderStatusAction.retrieveOrderStatuses

    /// Verifies that OrderStatusAction.retrieveOrderStatuses returns the expected statuses.
    ///
    func testRetrieveOrderStatusesReturnsExpectedStatuses() {
        let expectation = self.expectation(description: "Retrieve order statuses")
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")
        let action = OrderStatusAction.retrieveOrderStatuses(siteID: sampleSiteID) { (statuses, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(statuses)
            XCTAssertEqual(statuses?.count, 9)
            XCTAssertEqual(statuses, self.sampleOrderStatuses())
            expectation.fulfill()
        }

        orderStatusStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderStatusAction.retrieveOrderStatuses returns an error, whenever there is an error response.
    ///
    func testRetrieveOrderStatusesReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve order statuses error response")
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "generic_error")
        let action = OrderStatusAction.retrieveOrderStatuses(siteID: sampleSiteID) { (statuses, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(statuses)
            expectation.fulfill()
        }

        orderStatusStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderStatusAction.retrieveOrderStatuses returns an error, whenever there is not backend response.
    ///
    func testRetrieveOrderStatusesReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve order statuses empty response error")
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = OrderStatusAction.retrieveOrderStatuses(siteID: sampleSiteID) { (statuses, error) in
            XCTAssertNotNil(error)
            XCTAssertNil(statuses)
            expectation.fulfill()
        }

        orderStatusStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that OrderStatusAction.retrieveOrderStatuses effectively persists any retrieved statuses.
    ///
    func testRetrieveOrderStatusesEffectivelyPersistsRetrievedOrderStatuses() {
        let expectation = self.expectation(description: "Retrieving order statii shall persist order statii")
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "reports/orders/totals", filename: "report-orders")
        let action = OrderStatusAction.retrieveOrderStatuses(siteID: sampleSiteID) { (statuses, error) in
            XCTAssertNil(error)

            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), 9)
            let storageOrderStatuses = self.viewStorage.loadOrderStatuses(siteID: self.sampleSiteID)
            XCTAssertNotNil(storageOrderStatuses)
            let readOnlyList = storageOrderStatuses?.map({ $0.toReadOnly() })
            XCTAssertEqual(readOnlyList?.sorted(), self.sampleOrderStatuses().sorted())

            expectation.fulfill()
        }

        orderStatusStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredStatusesInBackground` does not produce duplicate entries.
    ///
    func testUpdateRetrieveOrderStatusesEffectivelyUpdatesPreexistantOrderStatuses() {
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        let group = DispatchGroup()

        group.enter()
        orderStatusStore.upsertStatusesInBackground(siteID: sampleSiteID, readOnlyOrderStatuses: sampleOrderStatuses()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        group.enter()
        orderStatusStore.upsertStatusesInBackground(siteID: sampleSiteID, readOnlyOrderStatuses: sampleOrderStatusesMutated()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        let expectation = self.expectation(description: "Update existing stored order statii")
        group.notify(queue: .main) {
            let originalStatuses = self.sampleOrderStatuses()
            let expectedStatuses = self.sampleOrderStatusesMutated()
            let storageStatuses = self.viewStorage.loadOrderStatuses(siteID: self.sampleSiteID)
            let readOnlyList = storageStatuses?.map({ $0.toReadOnly() })

            XCTAssertNotEqual(readOnlyList, originalStatuses)
            XCTAssertEqual(readOnlyList?.sorted(), expectedStatuses.sorted())
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), expectedStatuses.count)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertStoredStatusesInBackground` removes deleted entities.
    ///
    func testUpdateRetrieveShipmentTrackingListEffectivelyRemovesDeletedShipmentTrackingData() {
        let orderStatusStore = OrderStatusStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), 0)

        let group = DispatchGroup()

        group.enter()
        orderStatusStore.upsertStatusesInBackground(siteID: sampleSiteID, readOnlyOrderStatuses: sampleOrderStatuses()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        group.enter()
        orderStatusStore.upsertStatusesInBackground(siteID: sampleSiteID, readOnlyOrderStatuses: sampleOrderStatusesDeleted()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        let expectation = self.expectation(description: "Delete existing stored order statii")
        group.notify(queue: .main) {
            let originalStatuses = self.sampleOrderStatuses()
            let expectedStatuses = self.sampleOrderStatusesDeleted()
            let storageStatuses = self.viewStorage.loadOrderStatuses(siteID: self.sampleSiteID)
            let readOnlyList = storageStatuses?.map({ $0.toReadOnly() })

            XCTAssertNotEqual(readOnlyList, originalStatuses)
            XCTAssertEqual(readOnlyList?.sorted(), expectedStatuses.sorted())
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderStatus.self), expectedStatuses.count)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - OrderStatus Samples
//
private extension OrderStatusStoreTests {

    func sampleOrderStatuses() -> [Networking.OrderStatus] {
        return [
            OrderStatus(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 123),
            OrderStatus(name: "Processing", siteID: sampleSiteID, slug: "processing", total: 4),
            OrderStatus(name: "On hold", siteID: sampleSiteID, slug: "on-hold", total: 5),
            OrderStatus(name: "Completed", siteID: sampleSiteID, slug: "completed", total: 6),
            OrderStatus(name: "Cancelled", siteID: sampleSiteID, slug: "cancelled", total: 7),
            OrderStatus(name: "Refunded", siteID: sampleSiteID, slug: "refunded", total: 8),
            OrderStatus(name: "Failed", siteID: sampleSiteID, slug: "failed", total: 9),
            OrderStatus(name: "CIA Investigation", siteID: sampleSiteID, slug: "cia-investigation", total: 10),
            OrderStatus(name: "Pre ordered", siteID: sampleSiteID, slug: "pre-ordered", total: 1)
        ]
    }

    func sampleOrderStatusesMutated() -> [Networking.OrderStatus] {
        return [
            OrderStatus(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 123),
            OrderStatus(name: "Processing", siteID: sampleSiteID, slug: "processing", total: 4),
            OrderStatus(name: "On hold", siteID: sampleSiteID, slug: "on-hold", total: 5),
            OrderStatus(name: "Test Status", siteID: sampleSiteID, slug: "test-status", total: 234),
            OrderStatus(name: "Cancelled", siteID: sampleSiteID, slug: "cancelled", total: 7),
            OrderStatus(name: "Refunded", siteID: sampleSiteID, slug: "refunded", total: 8),
            OrderStatus(name: "Failed", siteID: sampleSiteID, slug: "failed", total: 9),
            OrderStatus(name: "CIA Investigation", siteID: sampleSiteID, slug: "cia-investigation", total: 10),
            OrderStatus(name: "Pre ordered", siteID: sampleSiteID, slug: "pre-ordered", total: 1)
        ]
    }

    func sampleOrderStatusesDeleted() -> [Networking.OrderStatus] {
        return [
            OrderStatus(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 123),
            OrderStatus(name: "Processing", siteID: sampleSiteID, slug: "processing", total: 4),
            OrderStatus(name: "Pre ordered", siteID: sampleSiteID, slug: "pre-ordered", total: 1)
        ]
    }
}
