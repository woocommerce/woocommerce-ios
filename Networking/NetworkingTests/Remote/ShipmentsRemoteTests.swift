import XCTest
@testable import Networking


/// ShipmentsRemote Unit Tests
///
final class ShipmentsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID = 1234

    /// Dummy Order ID
    ///
    let sampleOrderID = 567

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

        remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID, completion: { (shipmentTrackings, error) in
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

    // MARK: - createShipmentTrackings
    //

    /// Verifies that `createShipmentTracking` properly parses the sample response.
    ///
    func testCreateShipmentTrackingProperlyReturnsParsedShipmentTracking() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information")

        let orderID = sampleOrderID
        let siteID = sampleSiteID

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "new-shipment-tracking")
        remote.createShipmentTracking(for: siteID, orderID: orderID, trackingProvider: "Some provider", trackingNumber: "1111") { (shipmentTracking, error) in
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

        remote.createShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "Some provider", trackingNumber: "11111") { (shipmentTracking, error) in
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

        remote.createShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "Some provider", trackingNumber: "1111") { (shipmentTracking, error) in
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
        remote.createShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "some tracking provider", trackingNumber: "1111") { (shipmentTracking, error) in
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

    // MARK: - createShipmentTrackingsWithCustomProvider
    //

    /// Verifies that `createShipmentTrackingWithCustomProvider` properly parses the sample response.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyReturnsParsedShipmentTracking() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information")

        let orderID = sampleOrderID
        let siteID = sampleSiteID

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "new-shipment-tracking-custom-provider")
        remote.createShipmentTrackingWithCustomProvider(for: siteID, orderID: orderID, trackingProvider: "Some provider", trackingNumber: "1111", trackingLink: "https://somewhere.online.net.com?q=%1$s") { (shipmentTracking, error) in
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

        remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "Some provider", trackingNumber: "11111", trackingLink: "https://somewhere.online.net.com?q=%1$s") { (shipmentTracking, error) in
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

        remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "Some provider", trackingNumber: "1111", trackingLink: "https://somewhere.online.net.com?q=%1$s") { (shipmentTracking, error) in
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
        remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "some tracking provider", trackingNumber: "1111", trackingLink: "https://somewhere.online.net.com?q=%1$s") { (shipmentTracking, error) in
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
}
