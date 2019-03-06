import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// OrderStatusStore Unit Tests
///
class OrderStatusStoreTests: XCTestCase {

    /// Mockup Dispatcher!
    ///
    private var dispatcher: Dispatcher!

    /// Mockup Storage: InMemory
    ///
    private var storageManager: MockupStorageManager!

    /// Mockup Network: Allows us to inject predefined responses!
    ///
    private var network: MockupNetwork!

    /// Convenience Property: Returns the StorageType associated with the main thread.
    ///
    private var viewStorage: StorageType {
        return storageManager.viewStorage
    }

    /// Dummy Site ID
    ///
    private let sampleSiteID = 123

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
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
}


//  MARK: - OrderStatus Samples
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
            OrderStatus(name: "Pending payment", siteID: sampleSiteID, slug: "pending", total: 1123),
            OrderStatus(name: "Processing", siteID: sampleSiteID, slug: "processing", total: 14),
            OrderStatus(name: "On hold", siteID: sampleSiteID, slug: "on-hold", total: 15),
            OrderStatus(name: "Completed", siteID: sampleSiteID, slug: "completed", total: 16),
            OrderStatus(name: "Refunded", siteID: sampleSiteID, slug: "refunded", total: 18),
            OrderStatus(name: "Failed", siteID: sampleSiteID, slug: "failed", total: 19),
            OrderStatus(name: "Pre ordered", siteID: sampleSiteID, slug: "pre-ordered", total: 11)
        ]
    }
}
