import XCTest
@testable import Networking

final class PaymentGatewayMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    fileprivate let dummySiteID: Int64 = 12983476

    /// Verifies that the PaymentGateway is parsed.
    ///
    func test_PaymentGateway_map_parses_all_paymentGateways_in_response() throws {
        let paymentGateway = try mapRetrievePaymentGatewayResponse()
        XCTAssertNotNil(paymentGateway)
    }

    /// Verifies that the `siteID` is added in the mapper, because it's not provided by the API endpoint
    ///
    func test_PaymentGatewaysList_map_includes_siteID_in_parsed_results() throws {
        let paymentGateway = try mapRetrievePaymentGatewayResponse()
        XCTAssertEqual(paymentGateway.siteID, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_PaymentGatewaysList_map_parses_all_fields_in_result() throws {
        let paymentGateway = try mapRetrievePaymentGatewayResponse()

        let expectedPaymentGateway = PaymentGateway(siteID: dummySiteID,
                                                    gatewayID: "cod",
                                                    title: "Cash on delivery",
                                                    description: "Pay with cash upon delivery.",
                                                    enabled: true,
                                                    features: [.products])

        XCTAssertEqual(paymentGateway, expectedPaymentGateway)
    }
}


// MARK: - Test Helpers
///
private extension PaymentGatewayMapperTests {

    /// Returns the PaymentGatewayMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapPaymentGateway(from filename: String) throws -> PaymentGateway {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try PaymentGatewayMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the PaymentGatewayMapper output from `paymentGateway.json`
    ///
    func mapRetrievePaymentGatewayResponse() throws -> PaymentGateway {
        return try mapPaymentGateway(from: "payment-gateway-cod")
    }

    struct FileNotFoundError: Error {}
}
