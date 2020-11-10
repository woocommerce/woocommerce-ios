import XCTest
import TestKit

@testable import Networking

/// PaymentsGatewayRemote Unit Tests
///
final class PaymentsGatewayRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    let network = MockupNetwork()

    /// Dummy Site ID
    ///
    let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        network.removeAllSimulatedResponses()
    }

    func test_load_payment_gateways_return_all_gateways() throws {
        // Given
        let remote = PaymentsGatewayRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list")

        // When
        var gatewaysResult: Result<[PaymentGateway], Error>?
        waitForExpectation { exp in
            remote.loadAllPaymentGateways(siteID: sampleSiteID) { result in
                gatewaysResult = result
                exp.fulfill()
            }
        }

        // Then
        let gateways = try XCTUnwrap(gatewaysResult?.get())
        XCTAssertFalse(gateways.isEmpty)
    }
}
