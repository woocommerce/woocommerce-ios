import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ShipmentStoreTests Unit Tests
///
class ShipmentStoreTests: XCTestCase {

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

    /// Dummy Order ID
    ///
    private let sampleOrderID = 963

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }


    // MARK: - ShipmentAction.synchronizeShipmentTrackingData

    /// Verifies that ShipmentAction.synchronizeShipmentTrackingData returns the expected shipment tracking data.
    ///
    func testRetrieveShipmentTrackingListReturnsExpectedFields() {
        let expectation = self.expectation(description: "Retrieve shipment tracking list")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_multiple")
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 4)
            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
