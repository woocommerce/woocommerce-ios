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

    /// Verifies that `ShipmentAction.synchronizeShipmentTrackingData` effectively persists any retrieved tracking data.
    ///
    func testRetrieveShipmentTrackingListEffectivelyPersistsRetrievedShipmentTrackingData() {
        let expectation = self.expectation(description: "Retrieve shipment tracking list")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_multiple")
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 4)

            let storageTracking1 = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                         orderID: self.sampleOrderID,
                                                                         trackingID: self.sampleShipmentTracking1().trackingID)
            XCTAssertNotNil(storageTracking1)
            XCTAssertEqual(storageTracking1?.toReadOnly(), self.sampleShipmentTracking1())

            let storageTracking2 = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                         orderID: self.sampleOrderID,
                                                                         trackingID: self.sampleShipmentTracking2().trackingID)
            XCTAssertNotNil(storageTracking2)
            XCTAssertEqual(storageTracking2?.toReadOnly(), self.sampleShipmentTracking2())

            let storageTracking3 = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                         orderID: self.sampleOrderID,
                                                                         trackingID: self.sampleShipmentTracking3().trackingID)
            XCTAssertNotNil(storageTracking3)
            XCTAssertEqual(storageTracking3?.toReadOnly(), self.sampleShipmentTracking3())

            let storageTracking4 = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                         orderID: self.sampleOrderID,
                                                                         trackingID: self.sampleShipmentTracking4().trackingID)
            XCTAssertNotNil(storageTracking4)
            XCTAssertEqual(storageTracking4?.toReadOnly(), self.sampleShipmentTracking4())

            // For grins, lets all check that viewStorage.loadShipmentTrackingList returns the same results 😇
            let storageTrackingList = self.viewStorage.loadShipmentTrackingList(siteID: self.sampleSiteID, orderID: self.sampleOrderID)
            XCTAssertNotNil(storageTrackingList)
            let readOnlyList = storageTrackingList?.map({ $0.toReadOnly() })
            XCTAssertEqual(readOnlyList?.sorted(), self.sampleShipmentTrackingList().sorted())

            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.synchronizeShipmentTrackingData` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveShipmentTrackingListReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve shipment tracking list error response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")
        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.synchronizeShipmentTrackingData` returns an error whenever there is no backend response.
    ///
    func testRetrieveShipmentTrackingListReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve shipment tracking list empty response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ShipmentAction.synchronizeShipmentTrackingData(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertShipmentTrackingDataInBackground` does not produce duplicate entries.
    ///
    func testUpdateRetrieveShipmentTrackingListEffectivelyUpdatesPreexistantShipmentTrackingData() {
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 0)

        let group = DispatchGroup()

        group.enter()
        shipmentStore.upsertShipmentTrackingDataInBackground(siteID: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             readOnlyShipmentTrackingData: sampleShipmentTrackingList()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        group.enter()
        shipmentStore.upsertShipmentTrackingDataInBackground(siteID: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             readOnlyShipmentTrackingData: sampleShipmentTrackingListMutated()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        let expectation = self.expectation(description: "Update shipment tracking list")
        group.notify(queue: .main) {
            let originalShipmentTracking = self.sampleShipmentTracking1()
            let expectedShipmentTracking = self.sampleShipmentTracking1Mutated()
            let storageShipmentTracking = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                                orderID: self.sampleOrderID,
                                                                                trackingID: expectedShipmentTracking.trackingID)
            XCTAssertNotEqual(storageShipmentTracking?.toReadOnly(), originalShipmentTracking)
            XCTAssertEqual(storageShipmentTracking?.toReadOnly(), expectedShipmentTracking)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 4)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertShipmentTrackingDataInBackground` removes deleted entities.
    ///
    func testUpdateRetrieveShipmentTrackingListEffectivelyRemovesDeletedShipmentTrackingData() {
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 0)

        let group = DispatchGroup()

        group.enter()
        shipmentStore.upsertShipmentTrackingDataInBackground(siteID: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             readOnlyShipmentTrackingData: sampleShipmentTrackingList()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        group.enter()
        shipmentStore.upsertShipmentTrackingDataInBackground(siteID: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             readOnlyShipmentTrackingData: sampleShipmentTrackingListDeleted()) {
            XCTAssertTrue(Thread.isMainThread)
            group.leave()
        }

        let expectation = self.expectation(description: "Delete item from shipment tracking list")
        group.notify(queue: .main) {
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 3)
            XCTAssertNil(self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                               orderID: self.sampleOrderID,
                                                               trackingID: self.sampleShipmentTracking3().trackingID))

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}


// MARK: - Sample Data
//
private extension ShipmentStoreTests {

    // MARK: - ShipmentTracking Samples

    func sampleShipmentTracking1() -> Networking.ShipmentTracking {
        return ShipmentTracking(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                trackingID: "b1b94eecb1eb1c1edf3fa041efffd015",
                                trackingNumber: "345645674567",
                                trackingProvider: "USPS",
                                trackingURL: "https://tools.usps.com/go/TrackConfirmAction_input?qtc_tLabels1=345645674567",
                                dateShipped: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-02-15"))
    }

    func sampleShipmentTracking2() -> Networking.ShipmentTracking {
        return ShipmentTracking(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                trackingID: "6f2c2fb15474c97eae8ed6287f7f33f9",
                                trackingNumber: "56734563456",
                                trackingProvider: "UPS",
                                trackingURL: "http://wwwapps.ups.com/WebTracking/track?track=yes&trackNums=56734563456",
                                dateShipped: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-02-14"))
    }

    func sampleShipmentTracking3() -> Networking.ShipmentTracking {
        return ShipmentTracking(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                trackingID: "6fc204bea3bf7f5565985e1b127a5d8d",
                                trackingNumber: "456345623453454352323452345235",
                                trackingProvider: "Flybynight Courriers",
                                trackingURL: "",
                                dateShipped: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-02-11"))
    }

    func sampleShipmentTracking4() -> Networking.ShipmentTracking {
        return ShipmentTracking(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                trackingID: "2222",
                                trackingNumber: "asdfasdf7787775756786789",
                                trackingProvider: nil,
                                trackingURL: nil,
                                dateShipped: nil)
    }

    func sampleShipmentTracking1Mutated() -> Networking.ShipmentTracking {
        return ShipmentTracking(siteID: sampleSiteID,
                                orderID: sampleOrderID,
                                trackingID: "b1b94eecb1eb1c1edf3fa041efffd015",
                                trackingNumber: "5678567ujfgh",
                                trackingProvider: "dfggter454",
                                trackingURL: "https://google.com",
                                dateShipped: DateFormatter.Defaults.yearMonthDayDateFormatter.date(from: "2019-01-01"))
    }

    func sampleShipmentTrackingList() -> [Networking.ShipmentTracking] {
        return [sampleShipmentTracking1(), sampleShipmentTracking2(), sampleShipmentTracking3(), sampleShipmentTracking4()]
    }

    func sampleShipmentTrackingListMutated() -> [Networking.ShipmentTracking] {
        return [sampleShipmentTracking1Mutated(), sampleShipmentTracking2(), sampleShipmentTracking3(), sampleShipmentTracking4()]
    }

    func sampleShipmentTrackingListDeleted() -> [Networking.ShipmentTracking] {
        return [sampleShipmentTracking1Mutated(), sampleShipmentTracking2(), sampleShipmentTracking4()]
    }
}
