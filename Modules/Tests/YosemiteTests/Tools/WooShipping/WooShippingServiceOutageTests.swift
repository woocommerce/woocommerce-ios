import Foundation
import Testing
@testable import Networking
@testable import Yosemite

/// Error bodies match what WooCommerce Shipping returns to the app, always with HTTP 500.
@Suite("WooShippingServiceOutage")
struct WooShippingServiceOutageTests {

    @Test(arguments: [500, 502, 503, 504])
    func test_isOutage_when_upstream_status_is_5xx_then_returns_true(status: Int) {
        // Given
        let tunnelError = DotcomError.unknown(code: "wcc_server_error",
                                              message: "Error: The WooCommerce Shipping server returned HTTP code: \(status)",
                                              data: ["response_status_code": AnyDecodable(status)])
        let restError = restError(code: "wcc_server_error_response", data: #"{"response_status_code": \#(status)}"#)

        // Then
        #expect(WooShippingServiceOutage.isOutage(tunnelError))
        #expect(WooShippingServiceOutage.isOutage(restError))
    }

    @Test func test_isOutage_when_upstream_status_is_a_string_5xx_then_returns_true() {
        // Given
        let error = DotcomError.unknown(code: "wcc_server_error_response",
                                        message: nil,
                                        data: ["response_status_code": AnyDecodable("503")])

        // Then
        #expect(WooShippingServiceOutage.isOutage(error))
    }

    @Test func test_isOutage_when_upstream_status_is_0_then_falls_back_to_code_and_returns_true() {
        // Given
        let tunnelError = DotcomError.unknown(code: "wcc_server_error",
                                              message: "Error: The WooCommerce Shipping server returned HTTP code: 0",
                                              data: ["response_status_code": AnyDecodable(0)])
        let restError = restError(code: "wcc_server_error", data: #"{"response_status_code": 0}"#)

        // Then
        #expect(WooShippingServiceOutage.isOutage(tunnelError))
        #expect(WooShippingServiceOutage.isOutage(restError))
    }

    @Test(arguments: ["wcc_server_error", "wcc_server_error_response", "wcc_server_empty_response"])
    func test_isOutage_when_connect_server_code_has_no_upstream_status_then_returns_true(code: String) {
        // Given
        let rateError = DotcomError.unknown(code: code,
                                            message: "Error: The WooCommerce Shipping server returned HTTP code: 503",
                                            data: ["message": AnyDecodable("Error: The WooCommerce Shipping server returned HTTP code: 503")])
        let restRateError = restError(code: code, data: #"{"message": "Error"}"#)

        // Then
        #expect(WooShippingServiceOutage.isOutage(rateError))
        #expect(WooShippingServiceOutage.isOutage(restRateError))
    }

    @Test func test_isOutage_when_upstream_status_is_402_card_decline_then_returns_false() {
        // Given
        let tunnelError = DotcomError.unknown(code: "wcc_server_error_response",
                                              message: "Error: The WooCommerce Shipping server returned: Payment Required Your card was declined. ( 402 )",
                                              data: ["response_status_code": AnyDecodable(402)])
        let restError = restError(code: "wcc_server_error_response", data: #"{"response_status_code": 402}"#)

        // Then
        #expect(WooShippingServiceOutage.isOutage(tunnelError) == false)
        #expect(WooShippingServiceOutage.isOutage(restError) == false)
    }

    @Test(arguments: ["missing_upsdap_terms_of_service_acceptance", "wcc_server_error_response"])
    func test_isOutage_when_upstream_status_is_pass_through_4xx_then_returns_false(code: String) {
        // Given
        let error = DotcomError.unknown(code: code,
                                        message: "Invalid phone number",
                                        data: ["response_status_code": AnyDecodable(400)])

        // Then
        #expect(WooShippingServiceOutage.isOutage(error) == false)
    }

    @Test func test_isOutage_when_store_returns_plain_500_then_returns_false() {
        // Given
        let tunnelError = DotcomError.unknown(code: "internal_server_error",
                                              message: "There has been a critical error on this website.",
                                              data: ["status": AnyDecodable(500)])
        let restError = restError(code: "internal_server_error", data: #"{"status": 503}"#)

        // Then
        #expect(WooShippingServiceOutage.isOutage(tunnelError) == false)
        #expect(WooShippingServiceOutage.isOutage(restError) == false)
    }

    @Test func test_isOutage_when_store_host_returns_non_JSON_5xx_then_returns_false() {
        // Given
        let error = NetworkError.unacceptableStatusCode(statusCode: 503,
                                                        response: Data("<html>503 Service Unavailable</html>".utf8))

        // Then
        #expect(WooShippingServiceOutage.isOutage(error) == false)
    }

    @Test func test_isOutage_when_error_is_not_a_network_error_then_returns_false() {
        // Given
        let errors: [Error] = [
            NSError(domain: "wcc_server_error", code: 503),
            WooShippingLabelPurchaseError.purchaseErrorStatus,
            DotcomError.requestFailed(message: nil, data: nil)
        ]

        // Then
        for error in errors {
            #expect(WooShippingServiceOutage.isOutage(error) == false)
        }
    }
}

private extension WooShippingServiceOutageTests {
    func restError(code: String, data: String) -> NetworkError {
        let body = #"{"code": "\#(code)", "message": "Error", "data": \#(data)}"#
        return NetworkError.unacceptableStatusCode(statusCode: 500, response: Data(body.utf8))
    }
}
