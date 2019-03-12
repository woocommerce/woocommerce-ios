import XCTest
@testable import Networking


/// ShipmentsRemote Unit Tests
///
class ShipmentsRemoteTests: XCTestCase {

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

    /// Verifies that `createShipmentTracking` properly parses the sample response.
    ///
    func testCreateShipmentTrackingProperlyReturnsParsedShipmentTrackings() {
        let remote = ShipmentsRemote(network: network)
        let expectation = self.expectation(description: "Create shipment tracking information")

        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "new-shipment-tracking")
        remote.createShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingProvider: "ctarda", trackingNumber: "1111") { (shipmentTracking, error) in
                XCTAssertNil(error)
                XCTAssertNotNil(shipmentTracking)
                //XCTAssertEqual(shipmentTrackings?.count, 1)
                expectation.fulfill()
        }

        wait(for: [expectation], timeout: Constants.expectationTimeout)
    }
}
