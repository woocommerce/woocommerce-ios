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
    func testLoadShipmentTrackingsProperlyReturnsParsedShipmentTrackings() async throws {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_multiple")

        // When
        let shipmentTrackings = try await remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID)

        // Then
        XCTAssertEqual(shipmentTrackings.count, 4)
    }

    /// Verifies that `loadShipmentTrackings` properly relays generic Networking Layer errors.
    ///
    func testLoadShipmentTrackingsProperlyRelaysNetworkingErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)

        // When/Then
        do {
            _ = try await remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `loadShipmentTrackings` properly relays HTTP 404 errors.
    ///
    func testLoadShipmentTrackingsProperlyRelays404Errors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound())

        // When/Then
        do {
            _ = try await remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `loadShipmentTrackings` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testLoadShipmentTrackingsProperlyRelaysPluginNotInstalledErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")

        // When/Then
        do {
            _ = try await remote.loadShipmentTrackings(for: sampleSiteID, orderID: sampleOrderID)
            XCTFail("Expected error to be thrown")
        } catch let error as DotcomError {
            XCTAssertTrue(error == .noRestRoute)
        } catch {
            XCTFail("Expected DotcomError.noRestRoute")
        }
    }

    // MARK: - createShipmentTracking
    //

    /// Verifies that `createShipmentTracking` properly parses the sample response.
    ///
    func testCreateShipmentTrackingProperlyReturnsParsedShipmentTracking() async throws {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new")

        // When
        let tracking = try await remote.createShipmentTracking(for: sampleSiteID,
                                                             orderID: sampleOrderID,
                                                             trackingProvider: "Some provider",
                                                             dateShipped: "2019-04-01",
                                                             trackingNumber: "1111")

        // Then
        XCTAssertEqual(tracking.orderID, sampleOrderID)
    }

    /// Verifies that `createShipmentTracking` properly relays generic Networking Layer errors.
    ///
    func testCreateShipmentTrackingProperlyRelaysNetworkingErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)

        // When/Then
        do {
            _ = try await remote.createShipmentTracking(for: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      trackingProvider: "Some provider",
                                                      dateShipped: "2019-04-01",
                                                      trackingNumber: "11111")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `createhipmentTracking` properly relays HTTP 404 errors.
    ///
    func testCreateShipmentTrackingProperlyRelays404Errors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound())

        // When/Then
        do {
            _ = try await remote.createShipmentTracking(for: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      trackingProvider: "Some provider",
                                                      dateShipped: "2019-04-01",
                                                      trackingNumber: "1111")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `createShipmentTracking` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testCreateShipmentTrackingProperlyRelaysPluginNotInstalledErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")

        // When/Then
        do {
            _ = try await remote.createShipmentTracking(for: sampleSiteID,
                                                      orderID: sampleOrderID,
                                                      trackingProvider: "some tracking provider",
                                                      dateShipped: "2019-04-01",
                                                      trackingNumber: "1111")
            XCTFail("Expected error to be thrown")
        } catch let error as DotcomError {
            XCTAssertTrue(error == .noRestRoute)
        } catch {
            XCTFail("Expected DotcomError.noRestRoute")
        }
    }

    // MARK: - createShipmentTrackingWithCustomProvider
    //

    /// Verifies that `createShipmentTrackingWithCustomProvider` properly parses the sample response.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyReturnsParsedShipmentTracking() async throws {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_new_custom_provider")

        // When
        let tracking = try await remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                                               orderID: sampleOrderID,
                                                                               trackingProvider: "Some provider",
                                                                               trackingNumber: "1111",
                                                                               trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                                               dateShipped: "12345")

        // Then
        XCTAssertEqual(tracking.orderID, sampleOrderID)
    }

    /// Verifies that `createShipmentTracking` properly relays generic Networking Layer errors.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyRelaysNetworkingErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)

        // When/Then
        do {
            _ = try await remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                                        orderID: sampleOrderID,
                                                                        trackingProvider: "Some provider",
                                                                        trackingNumber: "11111",
                                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                                        dateShipped: "12345")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `createShipmentTrackingWithCustomProvider` properly relays HTTP 404 errors.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyRelays404Errors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound())

        // When/Then
        do {
            _ = try await remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                                        orderID: sampleOrderID,
                                                                        trackingProvider: "Some provider",
                                                                        trackingNumber: "1111",
                                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                                        dateShipped: "1234")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `createShipmentTrackingWithCustomProvider` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testCreateShipmentTrackingWithCustomProviderProperlyRelaysPluginNotInstalledErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", filename: "shipment_tracking_plugin_not_active")

        // When/Then
        do {
            _ = try await remote.createShipmentTrackingWithCustomProvider(for: sampleSiteID,
                                                                        orderID: sampleOrderID,
                                                                        trackingProvider: "some tracking provider",
                                                                        trackingNumber: "1111",
                                                                        trackingURL: "https://somewhere.online.net.com?q=%1$s",
                                                                        dateShipped: "1234")
            XCTFail("Expected error to be thrown")
        } catch let error as DotcomError {
            XCTAssertTrue(error == .noRestRoute)
        } catch {
            XCTFail("Expected DotcomError.noRestRoute")
        }
    }

    // MARK: - deleteShipmentTracking
    //

    /// Verifies that `deleteShipmentTracking` properly parses the sample response.
    ///
    func testDeleteShipmentTrackingProperlyReturnsParsedShipmentTracking() async throws {
        // Given
        let remote = ShipmentsRemote(network: network)
        let trackingID = "trackingID"
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/\(trackingID)", filename: "shipment_tracking_delete")

        // When
        let tracking = try await remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: trackingID)

        // Then
        XCTAssertEqual(tracking.orderID, sampleOrderID)
    }

    /// Verifies that `deleteShipmentTracking` properly relays networking errors.
    ///
    func testDeleteShipmentTrackingProperlyRelaysNetworkingErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)

        // When/Then
        do {
            _ = try await remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: "trackingID")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `deleteShipmentTracking` properly relays HTTP 404 errors.
    ///
    func testDeleteShipmentTrackingProperlyRelays404Errors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/", error: NetworkError.notFound())

        // When/Then
        do {
            _ = try await remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: "1111")
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `deleteShipmentTracking` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testDeleteShipmentTrackingProperlyRelaysPluginNotInstalledErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        let trackingID = "trackingID"
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/\(trackingID)", filename: "shipment_tracking_plugin_not_active")

        // When/Then
        do {
            _ = try await remote.deleteShipmentTracking(for: sampleSiteID, orderID: sampleOrderID, trackingID: trackingID)
            XCTFail("Expected error to be thrown")
        } catch let error as DotcomError {
            XCTAssertTrue(error == .noRestRoute)
        } catch {
            XCTFail("Expected DotcomError.noRestRoute")
        }
    }

    // MARK: - loadShipmentTrackingProviderGroups
    //

    /// Verifies that `loadShipmentTrackingProviderGroups` properly parses the sample response.
    ///
    func testLoadShipmentTrackingProviderGroupsReturnsParsedData() async throws {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/providers", filename: "shipment_tracking_providers")

        // When
        let groups = try await remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID)

        // Then
        XCTAssertEqual(groups.count, 19)
    }

    /// Verifies that `loadShipmentTrackingProviderGroups` properly parses the sample response.
    ///
    func testLoadShipmentTrackingProviderGroupsProperlyRelaysNetworkingErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)

        // When/Then
        do {
            _ = try await remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `loadShipmentTrackingProviderGroups` properly relays HTTP 404 errors.
    ///
    func testLoadShipmentTrackingProviderGroupsProperlyRelays404Errors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateError(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/providers", error: NetworkError.notFound())

        // When/Then
        do {
            _ = try await remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID)
            XCTFail("Expected error to be thrown")
        } catch {
            // Success
        }
    }

    /// Verifies that `loadShipmentTrackingProviderGroups` correctly returns a Dotcom Error whenever `rest_no_route`
    /// is returned because the shipment tracking extension is not installed.
    ///
    func testLoadShipmentTrackingProviderGroupsProperlyRelaysPluginNotInstalledErrors() async {
        // Given
        let remote = ShipmentsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "orders/\(sampleOrderID)/shipment-trackings/providers", filename: "shipment_tracking_plugin_not_active")

        // When/Then
        do {
            _ = try await remote.loadShipmentTrackingProviderGroups(for: sampleSiteID, orderID: sampleOrderID)
            XCTFail("Expected error to be thrown")
        } catch let error as DotcomError {
            XCTAssertTrue(error == .noRestRoute)
        } catch {
            XCTFail("Expected DotcomError.noRestRoute")
        }
    }
}
