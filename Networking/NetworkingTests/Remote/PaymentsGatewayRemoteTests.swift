import XCTest
import TestKit

@testable import Networking

/// PaymentGatewayRemote Unit Tests
///
final class PaymentsGatewayRemoteTests: XCTestCase {

    /// Dummy Network Wrapper
    ///
    private let network = MockNetwork()

    /// Dummy Site ID
    ///
    private let sampleSiteID: Int64 = 1234

    /// Repeat always!
    ///
    override func setUp() {
        super.setUp()
        network.removeAllSimulatedResponses()
    }

    func test_load_payment_gateways_return_all_gateways() throws {
        // Given
        let remote = PaymentGatewayRemote(network: network)
        network.simulateResponse(requestUrlSuffix: "payment_gateways", filename: "payment-gateway-list")

        // When
        let result = try waitFor { promise in
            remote.loadAllPaymentGateways(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let gateways = try result.get()
        XCTAssertFalse(gateways.isEmpty)
    }
}
