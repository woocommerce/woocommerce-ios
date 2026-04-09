import XCTest
import YosemiteTestHelpers
@testable import Yosemite
@testable import Networking
@testable import Storage


/// OrderFulfillmentStore Unit Tests
///
final class OrderFulfillmentStoreTests: XCTestCase {

    /// Mock Dispatcher
    ///
    private var dispatcher: Dispatcher!

    /// Mock Storage: InMemory
    ///
    private var storageManager: MockStorageManager!

    /// Mock Network: Allows us to inject predefined responses
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

    /// Dummy Order ID
    ///
    private let sampleOrderID: Int64 = 963

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockStorageManager()
        network = MockNetwork()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        super.tearDown()
    }

    // MARK: - synchronizeOrderFulfillments

    /// Verifies that `synchronizeOrderFulfillments` persists retrieved fulfillment data.
    ///
    func test_synchronizeOrderFulfillments_when_successful_then_persists_fulfillments() {
        // Given
        let expectation = self.expectation(description: "Synchronize order fulfillments")
        let store = OrderFulfillmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/fulfillments", filename: "order_fulfillment_list")

        // When
        let action = OrderFulfillmentAction.synchronizeOrderFulfillments(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            // Then
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderFulfillment.self), 2)

            let storedFulfillment = self.viewStorage.loadOrderFulfillment(siteID: self.sampleSiteID,
                                                                          orderID: self.sampleOrderID,
                                                                          fulfillmentID: 42)
            XCTAssertNotNil(storedFulfillment)
            XCTAssertEqual(storedFulfillment?.statusKey, "fulfilled")
            XCTAssertEqual(storedFulfillment?.isFulfilled, true)
            XCTAssertEqual(storedFulfillment?.trackingNumber, "1Z999AA10123456784")
            XCTAssertEqual(storedFulfillment?.shipmentProvider, "ups")
            XCTAssertEqual(storedFulfillment?.providerName, "")
            XCTAssertNotNil(storedFulfillment?.dateUpdated)
            XCTAssertNotNil(storedFulfillment?.dateFulfilled)

            let storedFulfillment2 = self.viewStorage.loadOrderFulfillment(siteID: self.sampleSiteID,
                                                                           orderID: self.sampleOrderID,
                                                                           fulfillmentID: 43)
            XCTAssertNotNil(storedFulfillment2)
            XCTAssertEqual(storedFulfillment2?.statusKey, "unfulfilled")
            XCTAssertEqual(storedFulfillment2?.isFulfilled, false)

            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `synchronizeOrderFulfillments` returns an error on network failure.
    ///
    func test_synchronizeOrderFulfillments_when_network_error_then_returns_error() {
        // Given
        let expectation = self.expectation(description: "Synchronize order fulfillments error")
        let store = OrderFulfillmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/fulfillments", error: NetworkError.notFound())

        // When
        let action = OrderFulfillmentAction.synchronizeOrderFulfillments(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            // Then
            XCTAssertNotNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.OrderFulfillment.self), 0)
            expectation.fulfill()
        }

        store.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `synchronizeOrderFulfillments` removes stale fulfillments not in the fresh response.
    ///
    @MainActor
    func test_synchronizeOrderFulfillments_when_stale_data_exists_then_removes_stale_entries() async {
        // Given
        let store = OrderFulfillmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        // Insert a stale fulfillment that won't be in the response
        let insertExpectation = expectation(description: "Insert stale fulfillment")
        storageManager.performAndSave({ storage in
            let staleFulfillment = storage.insertNewObject(ofType: Storage.OrderFulfillment.self)
            staleFulfillment.siteID = self.sampleSiteID
            staleFulfillment.orderID = self.sampleOrderID
            staleFulfillment.fulfillmentID = 999
            staleFulfillment.statusKey = "stale"
        }, completion: { insertExpectation.fulfill() }, on: .main)
        await fulfillment(of: [insertExpectation], timeout: Constants.expectationTimeout)

        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderFulfillment.self), 1)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/fulfillments", filename: "order_fulfillment_list")

        // When
        await withCheckedContinuation { continuation in
            let action = OrderFulfillmentAction.synchronizeOrderFulfillments(siteID: sampleSiteID, orderID: sampleOrderID) { error in
                continuation.resume(returning: ())
            }
            store.onAction(action)
        }

        // Then — stale entry removed, 2 fresh entries persisted
        XCTAssertEqual(viewStorage.countObjects(ofType: Storage.OrderFulfillment.self), 2)
        XCTAssertNil(viewStorage.loadOrderFulfillment(siteID: sampleSiteID, orderID: sampleOrderID, fulfillmentID: 999))
    }
}


// MARK: - Constants
//
private extension OrderFulfillmentStoreTests {
    enum Constants {
        static let expectationTimeout: TimeInterval = 10.0
    }
}
