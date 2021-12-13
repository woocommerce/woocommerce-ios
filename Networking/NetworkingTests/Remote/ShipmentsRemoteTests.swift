import XCTest
@testable import Networking


/// ShipmentsRemote Unit Tests
///
final class ShipmentsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID: Int64 = 567

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - loadShipmentTrackings
    //

    /// Verifies that `loadShipmentTrackings` properly parses the sample response.
    ///
    func testLoadShipmentTrackingsProperlyReturnsParsedShipmentTrackings() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_multiple")
        remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID, completion: { (shipmentTrackings, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(shipmentTrackings)
            XCTAssertEqual(shipmentTrackings?.count, 4)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadShipmentTrackings` properly relays generic Networking Layer errors.
    ///
    func testLoadShipmentTrackingsProperlyRelaysNetworkingErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information contains errors")

        remote.loadShipmentTrackings(for: sampleSiteID,
                                     orderID: sampleOrderID,
                                     completion: { (shipmentTrackings, error) in
            XCTAssertNil(shipmentTrackings)
            XCTAssertNotNil(error)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadShipmentTrackings` properly relays HTTP 404 errors.
    ///
    func testLoadShipmentTrackingsProperlyRelays404Errors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information contains errors")

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound)
        remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID, completion: { (shipmentTrackings, error) in
            XCTAssertNil(shipmentTrackings)
            XCTAssertNotNil(error)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadShipmentTrackings` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testLoadShipmentTrackingsProperlyRelaysPluginNotInstalledErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")
        remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID, completion: { (shipmentTrackings, error) in
            XCTAssertNil(shipmentTrackings)
            XCTAssertNotNil(error)

            guard let dotComError = error as? DotcomError else {
                XCTFail()
                return
            }
            XCTAssertTrue(dotComError == .noRestRoute)
            expectation.fulfill()
        })

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - createShipmentTracking
    //

    /// Verifies that `createShipmentTracking` properly parses the sample response.
    ///
    func testCreateShipmentTrackingProperlyReturnsParsedShipmentTracking() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information")

        let orderID = sampleOrderID
        let siteID = sampleSiteID

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new")
        remote.createShipmentTracking(for: siteID,
                                      orderID: orderID,
                                      trackingProvider: "Some provider",
                                      dateShipped: "2019-04-01",
                                      trackingNumber: "1111") { (shipmentTracking, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(shipmentTracking)
            XCTAssertEqual(shipmentTracking?.orderID, orderID)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `createShipmentTracking` properly relays generic Networking Layer errors.
    ///
    func testCreateShipmentTrackingProperlyRelaysNetworkingErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information contains errors")

        remote.createShipmentTracking(for: sampleSiteID,
                                      orderID: sampleOrderID,
                                      trackingProvider: "Some provider",
                                      dateShipped: "2019-04-01",
                                      trackingNumber: "11111") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `createhipmentTracking` properly relays HTTP 404 errors.
    ///
    func testCreateShipmentTrackingProperlyRelays404Errors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information contains errors")

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound)

        remote.createShipmentTracking(for: sampleSiteID,
                                      orderID: sampleOrderID,
                                      trackingProvider: "Some provider",
                                      dateShipped: "2019-04-01",
                                      trackingNumber: "1111") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `createShipmentTracking` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testCreateShipmentTrackingProperlyRelaysPluginNotInstalledErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")
        remote.createShipmentTracking(for: sampleSiteID,
                                      orderID: sampleOrderID,
                                      trackingProvider: "some tracking provider",
                                      dateShipped: "2019-04-01",
                                      trackingNumber: "1111") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)

            guard let dotComError = error as? DotcomError else {
                XCTFail()
                return
            }
            XCTAssertTrue(dotComError == .noRestRoute)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - createShipmentTrackingWithCustomProvider
    //

    /// Verifies that `createShipmentTrackingWithCustomProvider` properly parses the sample response.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyReturnsParsedShipmentTracking() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information")

        let orderID = sampleOrderID
        let siteID = sampleSiteID

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new_custom_provider")
        remote.createShipmentTrackingWithCustomProvider(for: siteID,
                                                        orderID: orderID,
                                                        trackingProvider: "Some provider",
                                                        trackingNumber: "1111",
                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                        dateShipped: "12345") { (shipmentTracking, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(shipmentTracking)
            XCTAssertEqual(shipmentTracking?.orderID, orderID)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `createShipmentTracking` properly relays generic Networking Layer errors.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyRelaysNetworkingErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information contains errors")

        remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                        orderID: sampleOrderID,
                                                        trackingProvider: "Some provider",
                                                        trackingNumber: "11111",
                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                        dateShipped: "12345") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `createShipmentTrackingWithCustomProvider` properly relays HTTP 404 errors.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyRelays404Errors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information contains errors")

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound)

        remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                        orderID: sampleOrderID,
                                                        trackingProvider: "Some provider",
                                                        trackingNumber: "1111",
                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                        dateShipped: "1234") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `createShipmentTrackingWithCustomProvider` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyRelaysPluginNotInstalledErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")
        remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                        orderID: sampleOrderID,
                                                        trackingProvider: "some tracking provider",
                                                        trackingNumber: "1111",
                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                        dateShipped: "1234") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)

            guard let dotComError = error as? DotcomError else {
                XCTFail()
                return
            }
            XCTAssertTrue(dotComError == .noRestRoute)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - deleteShipmentTracking
    //

    /// Verifies that `deleteShipmentTracking` properly parses the sample response.
    ///
    func testDeleteShipmentTrackingProperlyReturnsParsedShipmentTracking() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Delete shipment tracking information")

        let orderID = sampleOrderID
        let siteID = sampleSiteID
        let trackingID = "trackingID"

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/\(trackingID)", filename: "shipment_tracking_delete")
        remote.deleteShipmentTracking(for: siteID, orderID: orderID, trackingID: trackingID) { shipmentTracking, error in
            XCTAssertNil(error)
            XCTAssertNotNil(shipmentTracking)
            XCTAssertEqual(shipmentTracking?.orderID, orderID)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `deleteShipmentTracking` properly relays networking errors.
    ///
    func testDeleteShipmentTrackingProperlyRelaysNetworkingErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Delete shipment tracking information contains errors")

        remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: "trackingID") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `deleteShipmentTracking` properly relays HTTP 404 errors.
    ///
    func testDeleteShipmentTrackingProperlyRelays404Errors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information contains errors")

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound)

        remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: "1111") { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `deleteShipmentTracking` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testDeleteShipmentTrackingProperlyRelaysPluginNotInstalledErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information")

        let trackingID = "trackingID"

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/\(trackingID)", filename: "shipment_tracking_plugin_not_active")
        remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: trackingID) { (shipmentTracking, error) in
            XCTAssertNil(shipmentTracking)
            XCTAssertNotNil(error)

            guard let dotComError = error as? DotcomError else {
                XCTFail()
                return
            }
            XCTAssertTrue(dotComError == .noRestRoute)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    // MARK: - loadShipmentTrackingProviderGroups
    //

    /// Verifies that `loadShipmentTrackingProviderGroups` properly parses the sample response.
    ///
    func testLoadShipmentTrackingProviderGroupsReturnsParsedData() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking providers information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/providers", filename: "shipment_tracking_providers")
        remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID) { (groups, error) in
            XCTAssertNil(error)
            XCTAssertNotNil(groups)
            XCTAssertEqual(groups?.count, 19)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadShipmentTrackingProviderGroups` properly parses the sample response.
    ///
    func testLoadShipmentTrackingProviderGroupsProperlyRelaysNetworkingErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking providers information contains errors")

        remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID) { (shipmentTrackingGroups, error) in
            XCTAssertNil(shipmentTrackingGroups)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadShipmentTrackingProviderGroups` properly relays HTTP 404 errors.
    ///
    func testLoadShipmentTrackingProviderGroupsProperlyRelays404Errors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking providers information contains errors")

        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/providers", error: NetworkError.notFound)

        remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID) { (shipmentTrackingGroups, error) in
            XCTAssertNil(shipmentTrackingGroups)
            XCTAssertNotNil(error)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }

    /// Verifies that `loadShipmentTrackingProviderGroups` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testLoadShipmentTrackingProviderGroupsProperlyRelaysPluginNotInstalledErrors() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Load shipment tracking information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/providers", filename: "shipment_tracking_plugin_not_active")
        remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID) { (shipmentTrackingGroups, error) in
            XCTAssertNil(shipmentTrackingGroups)
            XCTAssertNotNil(error)

            guard let dotComError = error as? DotcomError else {
                XCTFail()
                return
            }
            XCTAssertTrue(dotComError == .noRestRoute)
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
