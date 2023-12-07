import XCTest
@testable import Networking

final class PaymentGatewayMapperTests: XCTestCase {

    /// Dummy Site ID.
    ///
    fileprivate let dummySiteID: Int64 = 12983476

    /// Verifies that the PaymentGateway is parsed.
    ///
    func test_PaymentGateway_map_parses_all_paymentGateways_in_response() async throws {
        let paymentGateway = try await mapRetrievePaymentGatewayResponse()
        XCTAssertNotNil(paymentGateway)
    }

    /// Verifies that the `siteID` is added in the mapper, because it's not provided by the API endpoint
    ///
    func test_PaymentGatewaysList_map_includes_siteID_in_parsed_results() async throws {
        let paymentGateway = try await mapRetrievePaymentGatewayResponse()
        XCTAssertEqual(paymentGateway.siteID, dummySiteID)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_PaymentGatewaysList_map_parses_all_fields_in_result() async throws {
        let paymentGateway = try await mapRetrievePaymentGatewayResponse()

        let expectedPaymentGateway = PaymentGateway(siteID: dummySiteID,
                                                    gatewayID: "cod",
                                                    title: "Cash on delivery",
                                                    description: "Pay with cash upon delivery.",
                                                    enabled: true,
                                                    features: [.products],
                                                    instructions: "Pay with cash upon delivery.")

        XCTAssertEqual(paymentGateway, expectedPaymentGateway)
    }

    /// Verifies that the fields are all parsed correctly
    ///
    func test_PaymentGatewaysList_map_parses_all_fields_in_result_when_response_has_no_data_envelope() async throws {
        let paymentGateway = try await mapRetrievePaymentGatewayResponseWithoutDataEnvelope()

        let expectedPaymentGateway = PaymentGateway(siteID: dummySiteID,
                                                    gatewayID: "cod",
                                                    title: "Cash on delivery",
                                                    description: "Pay with cash upon delivery.",
                                                    enabled: true,
                                                    features: [.products],
                                                    instructions: "Pay with cash upon delivery.")

        XCTAssertEqual(paymentGateway, expectedPaymentGateway)
    }
}


// MARK: - Test Helpers
///
private extension PaymentGatewayMapperTests {

    /// Returns the PaymentGatewayMapper output upon receiving `filename` (Data Encoded)
    ///
    func mapPaymentGateway(from filename: String) async throws -> PaymentGateway {
        guard let response = Loader.contentsOf(filename) else {
            throw FileNotFoundError()
        }

        return try await PaymentGatewayMapper(siteID: dummySiteID).map(response: response)
    }

    /// Returns the PaymentGateway output from `payment-gateway-cod.json`
    ///
    func mapRetrievePaymentGatewayResponse() async throws -> PaymentGateway {
        try await mapPaymentGateway(from: "payment-gateway-cod")
    }

    /// Returns the PaymentGateway output from `payment-gateway-cod-without-data.json`
    ///
    func mapRetrievePaymentGatewayResponseWithoutDataEnvelope() async throws -> PaymentGateway {
        try await mapPaymentGateway(from: "payment-gateway-cod-without-data")
    }

    struct FileNotFoundError: Error {}
}
