import Alamofire
import Foundation
import Testing
@testable import NetworkingCore

struct UnexpectedStoreResponseClassifierTests {
    @Test(arguments: [200, 500, 503])
    func test_classify_when_merchant_returns_html_then_returns_safe_error(status: Int) throws {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .get, path: "products")
        let body = Data("<html><body>Service unavailable</body></html>".utf8)

        // When
        let error = try #require(UnexpectedStoreResponseClassifier.classify(responseData: body, request: request, statusCode: status))

        // Then
        #expect(error == UnexpectedStoreResponseError())
    }

    @Test(arguments: [400, 401, 403, 404, 426])
    func test_classify_when_merchant_returns_html_client_error_then_preserves_existing_handling(status: Int) {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .get, path: "products")
        let body = Data("<html><body>Blocked</body></html>".utf8)

        // When
        let error = UnexpectedStoreResponseClassifier.classify(responseData: body, request: request, statusCode: status)

        // Then
        #expect(error == nil)
    }

    @Test(arguments: ["{\"message\":\"<html>maintenance mode</html>\"}", "[1]", "\"<html>\"", "null", "false", "42"])
    func test_classify_when_response_is_json_then_preserves_existing_handling(body: String) {
        // When
        let error = UnexpectedStoreResponseClassifier.classify(responseData: Data(body.utf8), statusCode: 500)

        // Then
        #expect(error == nil)
    }

    @Test func test_classify_when_account_or_web_page_returns_html_then_does_not_report_store_error() throws {
        // Given
        let body = Data("<html>Server error</html>".utf8)
        let url = try #require(URL(string: "https://example.com/wp-login.php"))
        let requests: [NetworkingCore.Request] = [
            DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: "me"),
            UnauthenticatedRequest(request: URLRequest(url: url))
        ]

        // Then
        for request in requests {
            #expect(UnexpectedStoreResponseClassifier.classify(responseData: body, request: request, statusCode: 500) == nil)
        }
    }

    @Test func test_classify_when_jetpack_request_uses_direct_transport_and_returns_html_then_returns_safe_error() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: 1, path: "orders")
        let body = Data("<html>Server error</html>".utf8)

        // When
        let error = try #require(UnexpectedStoreResponseClassifier.classify(responseData: body, request: request, statusCode: 500))

        // Then
        #expect(error == UnexpectedStoreResponseError())
    }

    @Test func test_classify_when_tunnel_raw_body_has_no_status_then_returns_safe_error() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: 1, path: "orders")
        let body = Data(#"{"error":"no_response_body","data":{"raw_body":"Server temporarily unavailable"}}"#.utf8)

        // When
        let error = try #require(UnexpectedStoreResponseClassifier.classify(responseData: body, request: request))

        // Then
        #expect(error == UnexpectedStoreResponseError())
    }

    @Test func test_classify_when_tunnel_envelope_contains_json_raw_body_then_preserves_existing_handling() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark3, method: .get, siteID: 1, path: "orders")
        let rawBody = #"{"code":"rest_forbidden","message":"Unauthorized"}"#
        let payload: [String: Any] = [
            "error": "no_response_body",
            "data": ["raw_body": rawBody]
        ]
        let payloadData = try JSONSerialization.data(withJSONObject: payload)
        let stringifiedPayload = try #require(String(data: payloadData, encoding: .utf8))
        let envelopes: [[String: Any]] = [
            payload,
            ["error": "no_response_body", "body": payload],
            ["error": "no_response_body", "body": stringifiedPayload]
        ]

        // Then
        for envelope in envelopes {
            let responseData = try JSONSerialization.data(withJSONObject: envelope)
            #expect(UnexpectedStoreResponseClassifier.classify(responseData: responseData, request: request) == nil)
        }
    }

    @Test(arguments: [200, 429, 500])
    func test_classify_when_rest_returns_plain_text_then_returns_safe_error(status: Int) {
        // When
        let error = UnexpectedStoreResponseClassifier.classify(responseData: Data("Server unavailable".utf8), statusCode: status)

        // Then
        #expect(error != nil)
    }

    @Test func test_classify_when_successful_plain_text_does_not_expect_json_then_preserves_existing_handling() {
        // When
        let error = UnexpectedStoreResponseClassifier.classify(responseData: Data("nonce".utf8),
                                                               statusCode: 200,
                                                               expectsJSON: false)

        // Then
        #expect(error == nil)
    }

    @Test(arguments: [401, 403, 404])
    func test_classify_when_plain_text_authentication_error_then_preserves_existing_error(status: Int) {
        // When
        let error = UnexpectedStoreResponseClassifier.classify(responseData: Data("Unauthorized".utf8), statusCode: status)

        // Then
        #expect(error == nil)
    }

    @Test func test_classify_when_empty_response_has_429_status_then_reports_rate_limiting() throws {
        // When
        let error = try #require(UnexpectedStoreResponseClassifier.classify(responseData: Data(), statusCode: 429))

        // Then
        #expect(error == UnexpectedStoreResponseError())
    }

    @Test func test_network_response_when_429_has_no_body_then_returns_safe_error() throws {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .get, path: "products")
        let urlRequest = try request.asURLRequest()
        let url = try #require(urlRequest.url)
        let response = DataResponse<Data, AFError>(
            request: urlRequest,
            response: HTTPURLResponse(url: url, statusCode: 429, httpVersion: nil, headerFields: nil),
            data: nil,
            metrics: nil,
            serializationDuration: 0,
            result: .failure(.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
        )

        // When
        let error = try #require(response.unexpectedStoreResponse(for: request))

        // Then
        #expect(error == UnexpectedStoreResponseError())
    }

    @Test(arguments: [404, 408, 500, 503])
    func test_network_response_when_non429_status_has_no_body_then_preserves_status(status: Int) throws {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .get, path: "products")
        let urlRequest = try request.asURLRequest()
        let url = try #require(urlRequest.url)
        let response = DataResponse<Data, AFError>(
            request: urlRequest,
            response: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil),
            data: nil,
            metrics: nil,
            serializationDuration: 0,
            result: .failure(.responseSerializationFailed(reason: .inputDataNilOrZeroLength))
        )

        // Then
        #expect(response.unexpectedStoreResponse(for: request) == nil)
        #expect((response.networkingError as? NetworkError)?.responseCode == status)
    }

    @Test func test_network_response_when_cancelled_after_receiving_html_then_does_not_classify_store_response() throws {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .get, path: "products")
        let urlRequest = try request.asURLRequest()
        let url = try #require(urlRequest.url)
        let response = DataResponse<Data, AFError>(request: urlRequest,
                                                response: HTTPURLResponse(url: url, statusCode: 500, httpVersion: nil, headerFields: nil),
                                                data: Data("<html>Server error</html>".utf8),
                                                metrics: nil,
                                                serializationDuration: 0,
                                                result: .failure(.explicitlyCancelled))

        // Then
        #expect(response.unexpectedStoreResponse(for: request) == nil)
    }

    @Test(arguments: [200, 500])
    func test_network_response_when_application_password_endpoint_returns_html_then_returns_safe_error(status: Int) throws {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .post, path: "wp/v2/users/me/application-passwords")
        let urlRequest = try request.asURLRequest()
        let url = try #require(urlRequest.url)
        let data = Data("<html>Server error</html>".utf8)
        let response = DataResponse<Data, AFError>(request: urlRequest,
                                                response: HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                                                          headerFields: ["Content-Type": "text/html"]),
                                                data: data, metrics: nil, serializationDuration: 0, result: .success(data))

        // When
        let error = try #require(response.unexpectedStoreResponse(for: request))

        // Then
        #expect(error == UnexpectedStoreResponseError())
    }

    @Test func test_classify_when_content_type_is_html_with_parameters_then_returns_safe_error() {
        // When
        let error = UnexpectedStoreResponseClassifier.classify(responseData: Data("Forbidden".utf8),
                                                               statusCode: 500,
                                                               contentType: "Text/HTML; arbitrary=private-value")

        // Then
        #expect(error != nil)
    }
}
