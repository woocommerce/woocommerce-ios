import XCTest
@testable import Networking
import TestKit

/// ShippingMethodsRemote Unit Tests
///
final class ShippingMethodsRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 12345

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    // MARK: - Load shipping methods

    /// Verifies that loadShippingMethods properly parses the sample response.
    ///
    func test_loadShippingMethods_properly_returns_shipping_methods() async throws {
        // Given
        let remote = ShippingMethodsRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "shipping_methods", filename: "shipping-methods")

        // When
        let shippingMethods = try await remote.loadShippingMethods(for: sampleSiteID)

        // Then
        XCTAssertEqual(shippingMethods.count, 6)
    }

    /// Verifies that loadShippingMethods properly relays Networking Layer errors.
    ///
    func test_loadShippingMethods_properly_relays_networking_errors() async {
        // Given
        let remote = ShippingMethodsRemote(network: network)
        let expectedError = NetworkError.unacceptableStatusCode(statusCode: 403)
        network.simulateError(requestUrlSuffix: "shipping_methods", error: expectedError)

        // When & Then
        await assertThrowsError({
            _ = try await remote.loadShippingMethods(for: self.sampleSiteID)
        }, errorAssert: { ($0 as? NetworkError) == expectedError })
    }

}
