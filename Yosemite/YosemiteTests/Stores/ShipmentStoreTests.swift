import XCTest
@testable import Yosemite
@testable import Networking
@testable import Storage


/// ShipmentStoreTests Unit Tests
///
final class ShipmentStoreTests: XCTestCase {

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
    private let sampleSiteID: Int64 = 123

    /// Dummy Order ID
    ///
    private let sampleOrderID: Int64 = 963

    /// Mock Country name
    ///
    private let sampleCountryName = "Australia"

    /// Second Mock Country name
    ///
    private let sampleCountryName2 = "Sweden"

    // MARK: - Overridden Methods

    override func setUp() {
        super.setUp()
        dispatcher = Dispatcher()
        storageManager = MockupStorageManager()
        network = MockupNetwork()
    }

    override func tearDown() {
        dispatcher = nil
        storageManager = nil
        network = nil
        super.tearDown()
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

    // MARK: - ShipmentAction.synchronizeShipmentTrackingProviders

    /// Verifies that `ShipmentAction.synchronizeShipmentTrackingProviders` effectively persists any retrieved tracking providers data.
    ///
    func testRetrieveShipmentTrackingProviderListEffectivelyPersistsRetrievedShipmentTrackingProviderData() {
        let expectation = self.expectation(description: "Retrieve shipment tracking providers list")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/" + String(sampleOrderID) + "/" + "shipment-trackings/providers",
                                 filename: "shipment_tracking_providers")
        let action = ShipmentAction.synchronizeShipmentTrackingProviders(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNil(error)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 19)

            let group1 = self.viewStorage.loadShipmentTrackingProviderGroup(siteID: self.sampleSiteID, providerGroupName: self.sampleCountryName)

            let groupProviders = group1?.providers

            XCTAssertNotEqual(groupProviders?.count, 0)

            XCTAssertNotNil(group1)
            XCTAssertEqual(group1?.toReadOnly(), self.australia())

            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.synchronizeShipmentTrackingProviders` returns an error whenever there is an error response from the backend.
    ///
    func testRetrieveShipmentTrackingGroupListReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Retrieve shipment tracking provider group list error response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/" + String(sampleOrderID) + "/" + "shipment-trackings/providers",
                                 filename: "shipment_tracking_plugin_not_active")
        let action = ShipmentAction.synchronizeShipmentTrackingProviders(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.synchronizeShipmentTrackingProviders` returns an error whenever there is no backend response.
    ///
    func testRetrieveShipmentTrackingGroupListReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Retrieve shipment tracking provider grup list empty response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ShipmentAction.synchronizeShipmentTrackingProviders(siteID: sampleSiteID, orderID: sampleOrderID) { error in
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertShipmentTrackingProviderData` does not produce duplicate entries.
    ///
    func testUpdateRetrieveShipmentTrackingProviderGroupListEffectivelyUpdatesPreexistantShipmentTrackingData() {
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 0)
        shipmentStore.upsertTrackingProviderData(siteID: sampleSiteID, orderID: sampleOrderID, readOnlyShipmentTrackingProviderGroups: australiaAndSweden())
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 2)

        let group = DispatchGroup()
        group.enter()
        shipmentStore.upsertTrackingProviderDataInBackground(siteID: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             readOnlyShipmentTrackingProviderGroups: australiaMutatedAndSwedenMutated()) {
                                                                XCTAssertTrue(Thread.isMainThread)
                                                                group.leave()
        }

        let expectation = self.expectation(description: "Update shipment tracking provider group list")
        group.notify(queue: .main) {
            let originalGroups = self.australiaAndSweden().sorted()
            let expectedGroups = self.australiaMutatedAndSwedenMutated().sorted()
            let storageGroups = self.viewStorage.loadShipmentTrackingProviderGroupList(siteID: self.sampleSiteID)
            let readOnlyStorageGroups = storageGroups?.map({ $0.toReadOnly() }).sorted()

            XCTAssertNotEqual(readOnlyStorageGroups, originalGroups)
            XCTAssertEqual(readOnlyStorageGroups, expectedGroups)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 2)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `upsertShipmentTrackingProviderDataInBackground` removes duplicated data.
    ///
    func testUpdateRetrieveShipmentTrackingProviderGroupListEffectivelyRemovesDeletedShipmentTrackingGroupData() {
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 0)
        shipmentStore.upsertTrackingProviderData(siteID: sampleSiteID, orderID: sampleOrderID, readOnlyShipmentTrackingProviderGroups: australiaAndSweden())
        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 2)

        let group = DispatchGroup()
        group.enter()
        shipmentStore.upsertTrackingProviderDataInBackground(siteID: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             readOnlyShipmentTrackingProviderGroups: sampleShipmentTrackingProviderGroupListMutatedOneGroup()) {
                                                                XCTAssertTrue(Thread.isMainThread)
                                                                group.leave()
        }

        let expectation = self.expectation(description: "Update shipment tracking provider group list")
        group.notify(queue: .main) {
            let originalGroups = self.australiaAndSweden().sorted()
            let expectedGroups = self.sampleShipmentTrackingProviderGroupListMutatedOneGroup().sorted()
            let storageGroups = self.viewStorage.loadShipmentTrackingProviderGroupList(siteID: self.sampleSiteID)
            let readOnlyStorageGroups = storageGroups?.map({ $0.toReadOnly() }).sorted()

            XCTAssertNotEqual(readOnlyStorageGroups, originalGroups)
            XCTAssertEqual(readOnlyStorageGroups, expectedGroups)
            XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 1)

            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ShipmentAction.addTracking

    /// Verifies that `addTracking` saves a new tracking.
    ///
    func testAddTrackingEffectivelyAddsTrackingData() {
        let expectation = self.expectation(description: "Add shipment tracking")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 0)

        let mockProviderName = "A provider"
        // Mocks obtained from the content of shipment_tracking_new
        let mockTrackingNumber = "123456781234567812345678"
        let mockTrackingID = "f2e7783b40837b9e1ec503a149dab4a1"

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new")

        let action = ShipmentAction.addTracking(siteID: sampleSiteID,
                                                orderID: sampleOrderID,
                                                providerGroupName: "A country",
                                                providerName: mockProviderName,
                                                dateShipped: "2019-04-01",
                                                trackingNumber: mockTrackingNumber) { error in
                                                    XCTAssertNil(error)

                                                    XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 1)

                                                    let storedTracking = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                                                               orderID: self.sampleOrderID,
                                                                                                               trackingID: mockTrackingID)

                                                    XCTAssertEqual(storedTracking?.trackingNumber, mockTrackingNumber)

                                                    expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.addTracking` returns an error whenever there is an error response from the backend.
    ///
    func testAddTrackingListReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Add shipment tracking error response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/",
            filename: "shipment_tracking_plugin_not_active")
        let action = ShipmentAction.addTracking(siteID: sampleSiteID,
                                                orderID: sampleOrderID,
                                                providerGroupName: "",
                                                providerName: "",
                                                dateShipped: "",
                                                trackingNumber: "") { error in
                                                    XCTAssertNotNil(error)
                                                    expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.addTracking` returns an error whenever there is no backend response.
    ///
    func testAddTrackingReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Add tracking empty response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        let action = ShipmentAction.addTracking(siteID: sampleSiteID,
                                                orderID: sampleOrderID,
                                                providerGroupName: "",
                                                providerName: "",
                                                dateShipped: "",
                                                trackingNumber: "") { error in
                                                    XCTAssertNotNil(error)
                                                    expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ShipmentAction.addCustomTracking

    /// Verifies that `addTracking` saves a new tracking.
    ///
    func testAddCustomTrackingEffectivelyAddsTrackingData() {
        let expectation = self.expectation(description: "Add custom shipment tracking")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 0)

        // Mocks obtained from the content of shipment_tracking_new_custom_provider
        let customGroupName = ShipmentStore.customGroupName
        let mockProviderName = "HK Shipments"
        let mockTrackingNumber = "123456781234567812345678"
        let mockTrackingID = "c2911c8175e33466d3d9955b53f29f7a"
        let mockTrackingURL = "https://somewhere.online.net.com?q=%1$s"
        let mockDateShipped = "1234"

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new_custom_provider")

        let action = ShipmentAction.addCustomTracking(siteID: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      trackingProvider: mockProviderName,
                                                      trackingNumber: mockTrackingNumber,
                                                      trackingURL: mockTrackingURL,
                                                      dateShipped: mockDateShipped) { error in
                                                        XCTAssertNil(error)

                                                        /// As a result of adding one tracking with a custom provider,
                                                        /// we should have one group, one provider and one tracking
                                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 1)
                                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProvider.self), 1)
                                                        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTrackingProviderGroup.self), 1)

                                                        let storedTracking = self.viewStorage.loadShipmentTracking(siteID: self.sampleSiteID,
                                                                                                                   orderID: self.sampleOrderID,
                                                                                                                   trackingID: mockTrackingID)

                                                        XCTAssertEqual(storedTracking?.trackingNumber, mockTrackingNumber)

                                                        let storedProvider = self.viewStorage.loadShipmentTrackingProvider(siteID: self.sampleSiteID,
                                                                                                                           name: mockProviderName)

                                                        XCTAssertEqual(storedProvider?.name, mockProviderName)

                                                        let storedGroup = self.viewStorage.loadShipmentTrackingProviderGroup(siteID: self.sampleSiteID,
                                                                                                                             providerGroupName: customGroupName)

                                                        XCTAssertEqual(storedGroup?.name, customGroupName)

                                                        expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.addCustomTracking` returns an error whenever there is an error response from the backend.
    ///
    func testAddCustomTrackingListReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Add custom tracking error response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/",
            filename: "shipment_tracking_plugin_not_active")
        let action = ShipmentAction.addCustomTracking(siteID: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      trackingProvider: "",
                                                      trackingNumber: "",
                                                      trackingURL: "",
                                                      dateShipped: "") { error in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.addCustomTracking` returns an error whenever there is no backend response.
    ///
    func testAddCustomTrackingReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Add customtracking empty response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        let action = ShipmentAction.addCustomTracking(siteID: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      trackingProvider: "",
                                                      trackingNumber: "",
                                                      trackingURL: "",
                                                      dateShipped: "") { error in
                                                        XCTAssertNotNil(error)
                                                        expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - ShipmentAction.deleteTracking

    /// Verifies that `deleteTracking` removes saved tracking.
    ///
    func testDeleteTrackingEffectivelyDeletesTrackingData() {
        let shipmentStore = ShipmentStore(dispatcher: dispatcher,
                                          storageManager: storageManager,
                                          network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new")

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 0)

        let mockGroupName = "Australia"
        let mockProviderName = "A provider"
        // Mocks obtained from the content of shipment_tracking_new
        let mockTrackingNumber = "123456781234567812345678"
        let mockTrackingID = "f2e7783b40837b9e1ec503a149dab4a1"
        let mockDateShipped = "2019-04-01"

        shipmentStore.addTracking(siteID: sampleSiteID,
                                  orderID: sampleOrderID,
                                  providerGroupName: mockGroupName,
                                  providerName: mockProviderName,
                                  trackingNumber: mockTrackingNumber, dateShipped: mockDateShipped) { error in
                                    XCTAssertNil(error)
        }

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 1)

        shipmentStore.deleteStoredShipment(siteID: sampleSiteID, orderID: sampleOrderID, trackingID: mockTrackingID)

        XCTAssertEqual(self.viewStorage.countObjects(ofType: Storage.ShipmentTracking.self), 0)
    }

    /// Verifies that `ShipmentAction.deleteTracking` returns an error whenever there is an error response from the backend.
    ///
    func testDeleteTrackingListReturnsErrorUponReponseError() {
        let expectation = self.expectation(description: "Delete shipment tracking error response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")
        let action = ShipmentAction.deleteTracking(siteID: sampleSiteID,
                                                   orderID: sampleOrderID,
                                                   trackingID: "") { error in
                                                    XCTAssertNotNil(error)
                                                    expectation.fulfill()
        }

        shipmentStore.onAction(action)
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `ShipmentAction.deleteTracking` returns an error whenever there is no backend response.
    ///
    func testDeleteTrackingReturnsErrorUponEmptyResponse() {
        let expectation = self.expectation(description: "Delete tracking empty response")
        let shipmentStore = ShipmentStore(dispatcher: dispatcher, storageManager: storageManager, network: network)

        let action = ShipmentAction.deleteTracking(siteID: sampleSiteID,
                                                orderID: sampleOrderID,
                                                trackingID: "") { error in
                                                    XCTAssertNotNil(error)
                                                    expectation.fulfill()
        }

        shipmentStore.onAction(action)
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
        return [sampleShipmentTracking1Mutated(),
                sampleShipmentTracking2(),
                sampleShipmentTracking4()]
    }

    func sampleShipmentTrackingProviderSingleGroup() -> Networking.ShipmentTrackingProviderGroup {
        return ShipmentTrackingProviderGroup(name: sampleCountryName,
                                             siteID: sampleSiteID,
                                             providers: [australiaSampleShipmentTrackingProvider1()])
    }

    func australia() -> Networking.ShipmentTrackingProviderGroup {
        return ShipmentTrackingProviderGroup(name: sampleCountryName,
                                             siteID: sampleSiteID,
                                             providers: [australiaSampleShipmentTrackingProvider1(),
                                                         australiaSampleShipmentTrackingProvider2()])
    }

    func sweden() -> Networking.ShipmentTrackingProviderGroup {
        return ShipmentTrackingProviderGroup(name: sampleCountryName2,
                                             siteID: sampleSiteID,
                                             providers: [swedenSampleShipmentTrackingProvider1(),
                                                         swedenSampleShipmentTrackingProvider2()])
    }

    func australiaSampleShipmentTrackingProvider1() -> Networking.ShipmentTrackingProvider {
        return ShipmentTrackingProvider(siteID: sampleSiteID,
                                        name: "Fastway Couriers",
                                        url: "http://www.fastway.com.au/courier-services/track-your-parcel?l=%1$s")
    }

    func australiaSampleShipmentTrackingProvider2() -> Networking.ShipmentTrackingProvider {
        return ShipmentTrackingProvider(siteID: sampleSiteID,
                                        name: "Australia Post",
                                        url: "http://auspost.com.au/track/track.html?id=%1$s")
    }

    func swedenSampleShipmentTrackingProvider1() -> Networking.ShipmentTrackingProvider {
        return ShipmentTrackingProvider(siteID: sampleSiteID,
                                        name: "PostNord Sverige AB",
                                        url: "http://www.fastway.com.au/courier-services/track-your-parcel?l=%1$s")
    }

    func swedenSampleShipmentTrackingProvider2() -> Networking.ShipmentTrackingProvider {
        return ShipmentTrackingProvider(siteID: sampleSiteID,
                                        name: "DHL.se",
                                        url: "http://auspost.com.au/track/track.html?id=%1$s")
    }

    func australiaAndSweden() -> [Networking.ShipmentTrackingProviderGroup] {
        return [australia(), sweden()]
    }

    func australiaMutated() -> Networking.ShipmentTrackingProviderGroup {
        return ShipmentTrackingProviderGroup(name: sampleCountryName,
                                             siteID: sampleSiteID,
                                             providers: [ShipmentTrackingProvider(siteID: sampleSiteID,
                                                                                                                                 name: "Australia mutated",
                                                                                                                                 url: "url mutated")])
    }

    func swedenMutated() -> Networking.ShipmentTrackingProviderGroup {
        return ShipmentTrackingProviderGroup(name: sampleCountryName2,
                                             siteID: sampleSiteID,
                                             providers: [ShipmentTrackingProvider(siteID: sampleSiteID,
                                                                                  name: "Sweden mutated",
                                                                                  url: "none")])
    }

    func sampleShipmentTrackingProviderGroupListMutatedOneGroup() -> [Networking.ShipmentTrackingProviderGroup] {
        return [australiaMutated()]
    }

    func australiaMutatedAndSwedenMutated() -> [Networking.ShipmentTrackingProviderGroup] {
        return [australiaMutated(), swedenMutated()]
    }
}
