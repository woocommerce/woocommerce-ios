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
        let result = waitFor { promise in
            remote.loadAllPaymentGateways(siteID: self.sampleSiteID) { result in
                promise(result)
            }
        }

        // Then
        let gateways = try result.get()
        XCTAssertFalse(gateways.isEmpty)
    }

    // MARK: - Update Payment Gateway tests

    /// Verifies that updatepaymentGateway properly parses the `paymentGateway` sample response.
    ///
    func test_updatePaymentGateway_properly_returns_parsed_paymentGateway() throws {
        // Given
        let remote = PaymentGatewayRemote(network: network)
        let paymentGateway = samplePaymentGateway()
        network.simulateResponse(requestUrlSuffix: "payment_gateways/\(paymentGateway.gatewayID)", filename: "payment-gateway-cod")

        // When
        let result = waitFor { promise in
            remote.updatePaymentGateway(paymentGateway) { result in
                promise(result)
            }
        }

        // Then
        XCTAssert(result.isSuccess)
        let returnedPaymentGateway = try XCTUnwrap(result.get())
        XCTAssertEqual(returnedPaymentGateway, paymentGateway)
    }

    /// Verifies that updatepaymentGateway properly relays Networking Layer errors.
    ///
    func test_updatePaymentGateway_properly_relays_networking_errors() throws {
        // Given
        let remote = PaymentGatewayRemote(network: network)
        let paymentGateway = samplePaymentGateway()

        let error = NetworkError.unacceptableStatusCode(statusCode: 500)
        network.simulateError(requestUrlSuffix: "payment_gateways/\(paymentGateway.gatewayID)", error: error)

        // When
        let result = waitFor { promise in
            remote.updatePaymentGateway(paymentGateway) { (result) in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isFailure)
        let resultError = try XCTUnwrap(result.failure as? NetworkError)
        XCTAssertEqual(resultError, .unacceptableStatusCode(statusCode: 500))
    }
}

// MARK: - Helper methods

private extension PaymentsGatewayRemoteTests {
    func samplePaymentGateway() -> PaymentGateway {
        PaymentGateway.fake().copy(siteID: sampleSiteID,
                                   gatewayID: "cod",
                                   title: "Cash on delivery",
                                   description: "Pay with cash upon delivery.",
                                   enabled: true,
                                   features: [.products],
                                   instructions: "Pay with cash upon delivery.")
    }
}
