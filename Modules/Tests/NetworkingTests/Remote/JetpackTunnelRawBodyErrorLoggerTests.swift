import Alamofire
import Foundation
import Testing

@testable import Networking
@testable import NetworkingCore

@Suite("JetpackTunnelRawBodyErrorLoggerTests")
struct JetpackTunnelRawBodyErrorLoggerTests {
    @Test func logIfNeeded_when_root_raw_body_exists_then_emits_expected_context_and_sanitized_snippet() throws {
        // Given
        let fixture = "jetpack-tunnel-raw-body-error"

        // When
        let message = try message(fromFixture: fixture)

        // Then
        #expect(message.contains("Jetpack Tunnel raw_body error:"))
        #expect(message.contains("method=GET"))
        #expect(message.contains("path=/wc/v3/products"))
        #expect(message.contains("transport_status=500"))
        #expect(message.contains("proxy_status=502"))
        #expect(message.contains("error_code=no_response_body"))
        #expect(message.contains("error_message=Server could not read response."))
        #expect(message.contains("raw_body_truncated=false"))
        #expect(message.contains(
            "raw_body_snippet=<html> Fatal error consumer_key=[redacted] Authorization: Bearer [redacted] Cookie: [redacted] </html>"
        ))
        #expect(!message.contains("\n"))
        #expect(!message.contains("\\n"))
        #expect(!message.contains("ck_secret"))
        #expect(!message.contains("bearer-secret"))
        #expect(!message.contains("session=abc"))
    }

    @Test func logIfNeeded_when_body_envelope_has_raw_body_then_uses_nested_error_context() throws {
        // Given
        let fixture = "jetpack-tunnel-raw-body-envelope-error"

        // When
        let message = try message(fromFixture: fixture, method: .post, path: "orders")

        // Then
        #expect(message.contains("method=POST"))
        #expect(message.contains("path=/wc/v3/orders"))
        #expect(message.contains("transport_status=500"))
        #expect(message.contains("proxy_status=503"))
        #expect(message.contains("error_code=no_response_body"))
        #expect(message.contains("error_message=Remote site returned non-JSON response"))
        #expect(message.contains("application_password=[redacted]"))
        #expect(!message.contains("app-pass"))
    }

    @Test func logIfNeeded_when_body_envelope_is_stringified_json_then_uses_nested_error_context() throws {
        // Given
        let body = """
        {"code":"no_response_body_code","message":"Stringified body","data":{"raw_body":"<html>Fatal error</html>"}}
        """
        let responseData = try JSONSerialization.data(withJSONObject: [
            "status": "504",
            "body": body
        ])

        // When
        let message = try message(forResponseData: responseData, method: .post, path: "orders")

        // Then
        #expect(message.contains("method=POST"))
        #expect(message.contains("path=/wc/v3/orders"))
        #expect(message.contains("proxy_status=504"))
        #expect(message.contains("error_code=no_response_body_code"))
        #expect(message.contains("error_message=Stringified body"))
        #expect(message.contains("raw_body_snippet=<html>Fatal error</html>"))
    }

    @Test func logIfNeeded_when_data_status_is_string_then_prefers_it_over_root_status() throws {
        // Given
        let responseData = Data("""
        {
          "status": 500,
          "code": "no_response_body_code",
          "message": "Server could not read response.",
          "data": {
            "status": "503",
            "raw_body": "<html>Fatal error</html>"
          }
        }
        """.utf8)

        // When
        let message = try message(forResponseData: responseData)

        // Then
        #expect(message.contains("proxy_status=503"))
        #expect(message.contains("error_code=no_response_body_code"))
    }

    @Test func logIfNeeded_when_raw_body_contains_sensitive_labels_then_redacts_secret_values() throws {
        // Given
        let rawBody = """
        Authorization: Bearer abc123
        Cookie: wordpress_logged_in=wpLoginValue
        Set-Cookie: session=sessionValue
        consumer_key=ckValue
        consumer_secret=csValue
        {
          "consumer_key": "jsonConsumerKey",
          "consumer_secret": "jsonConsumerSecret",
          "access_token": "jsonAccessToken",
          "token": "jsonToken",
          "application_password": "jsonApplicationPassword",
          "password": "jsonPassword"
        }
        """

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        #expect(message.contains("[redacted]"))
        [
            "abc123",
            "wpLoginValue",
            "sessionValue",
            "ckValue",
            "csValue",
            "jsonConsumerKey",
            "jsonConsumerSecret",
            "jsonAccessToken",
            "jsonToken",
            "jsonApplicationPassword",
            "jsonPassword"
        ].forEach { secretValue in
            #expect(!message.contains(secretValue))
        }
    }

    @Test func logIfNeeded_when_raw_body_contains_newlines_and_tabs_then_collapses_whitespace() throws {
        // Given
        let rawBody = "<html>\n\tFatal error\nAuthorization: Bearer newline-secret\nCookie: session=cookie-secret\n</html>"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        let expectedSnippet = "raw_body_snippet=<html> Fatal error Authorization: Bearer [redacted] Cookie: [redacted] </html>"
        #expect(message.contains(expectedSnippet))
        #expect(!message.contains("\n"))
        #expect(!message.contains("\\n"))
        #expect(!message.contains("\t"))
        #expect(!message.contains("newline-secret"))
        #expect(!message.contains("cookie-secret"))
    }

    @Test func logIfNeeded_when_sensitive_labels_are_glued_then_does_not_insert_boundaries() throws {
        // Given
        let rawBody = "WOOMOB-3429 forced HTMLForced HTML response for WOOMOB-3429" +
            "Authorization: Bearer fake-review-token" +
            "Cookie: wordpress_logged_in_test=wpLoginValue; session=abc"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        let expectedSnippet = "raw_body_snippet=WOOMOB-3429 forced HTMLForced HTML response for WOOMOB-3429" +
            "Authorization: Bearer [redacted] wordpress_logged_in_test=wpLoginValue; session=abc"
        #expect(message.contains(expectedSnippet))
        #expect(message.contains("WOOMOB-3429Authorization"))
        #expect(!message.contains("fake-review-token"))
    }

    @Test func logIfNeeded_when_raw_body_is_missing_or_blank_then_emits_no_message() throws {
        // Given
        let missingRawBodyData = Data("""
        {
          "error": "no_response_body",
          "message": "Server could not read response.",
          "data": { "status": 500 }
        }
        """.utf8)
        let blankRawBodyData = try responseData(rawBody: " \n\t ")

        // When
        let missingRawBodyMessages = messages(forResponseData: missingRawBodyData)
        let blankRawBodyMessages = messages(forResponseData: blankRawBodyData)

        // Then
        #expect(missingRawBodyMessages.isEmpty)
        #expect(blankRawBodyMessages.isEmpty)
    }

    @Test func logIfNeeded_when_request_is_not_jetpack_then_emits_no_message() throws {
        // Given
        let responseData = try #require(Loader.contentsOf("jetpack-tunnel-raw-body-error"))
        let request = DotcomRequest(wordpressApiVersion: .mark1_1, method: .get, path: "products")

        // When
        let messages = messages(forResponseData: responseData, request: request)

        // Then
        #expect(messages.isEmpty)
    }

    @Test func logIfNeeded_when_context_contains_secret_query_values_then_redacts_context() throws {
        // Given
        let path = "orders?consumer_secret=cs_secret&access_token=access-secret"

        // When
        let message = try message(fromFixture: "jetpack-tunnel-raw-body-error", path: path)

        // Then
        #expect(message.contains("path=/wc/v3/orders?consumer_secret=[redacted]&access_token=[redacted]"))
        #expect(!message.contains("cs_secret"))
        #expect(!message.contains("access-secret"))
    }

    @Test func logIfNeeded_when_relative_path_starts_with_slash_then_removes_duplicate_separator() throws {
        // Given
        let path = "/products"

        // When
        let message = try message(fromFixture: "jetpack-tunnel-raw-body-error", path: path)

        // Then
        #expect(message.contains("path=/wc/v3/products"))
    }

    @Test func logIfNeeded_when_context_contains_full_url_then_logs_path_without_host() throws {
        // Given
        let path = "https://example.com/wp-json/wc/v3/orders?consumer_key=ck_secret"

        // When
        let message = try message(fromFixture: "jetpack-tunnel-raw-body-error", path: path)

        // Then
        #expect(message.contains("path=/wp-json/wc/v3/orders?consumer_key=[redacted]"))
        #expect(!message.contains("example.com"))
        #expect(!message.contains("ck_secret"))
    }

    @Test func logIfNeeded_when_sanitized_raw_body_exceeds_limit_then_truncates_and_marks_true() throws {
        // Given
        let longRawBody = String(repeating: "a", count: 2055)

        // When
        let message = try message(forRawBody: longRawBody, method: .delete, path: "products/1")

        // Then
        let snippet = try #require(message.components(separatedBy: "raw_body_snippet=").last)
        #expect(message.contains("raw_body_truncated=true"))
        #expect(snippet.count == 2048)
    }

    private func message(
        forRawBody rawBody: String,
        method: HTTPMethod = .get,
        path: String = "products",
        transportStatus: Int = 500
    ) throws -> String {
        let responseData = try responseData(rawBody: rawBody)
        return try message(forResponseData: responseData, method: method, path: path, transportStatus: transportStatus)
    }

    private func message(
        fromFixture fixture: String,
        method: HTTPMethod = .get,
        path: String = "products",
        transportStatus: Int = 500
    ) throws -> String {
        let responseData = try #require(Loader.contentsOf(fixture))
        return try message(forResponseData: responseData, method: method, path: path, transportStatus: transportStatus)
    }

    private func message(
        forResponseData responseData: Data,
        method: HTTPMethod = .get,
        path: String = "products",
        transportStatus: Int = 500
    ) throws -> String {
        let messages = messages(forResponseData: responseData, method: method, path: path, transportStatus: transportStatus)
        #expect(messages.count == 1)
        return try #require(messages.first)
    }

    private func messages(
        forResponseData responseData: Data,
        method: HTTPMethod = .get,
        path: String = "products",
        transportStatus: Int = 500
    ) -> [String] {
        let request = JetpackRequest(wooApiVersion: .mark3, method: method, siteID: 123, path: path, parameters: [:])
        return messages(forResponseData: responseData, request: request, transportStatus: transportStatus)
    }

    private func messages(
        forResponseData responseData: Data,
        request: NetworkingCore.Request,
        transportStatus: Int = 500
    ) -> [String] {
        var messages: [String] = []
        let logger = JetpackTunnelRawBodyErrorLogger(warningSink: { messages.append($0) })

        logger.logIfNeeded(responseData: responseData, request: request, transportStatus: transportStatus)

        return messages
    }

    private func responseData(rawBody: String) throws -> Data {
        let payload: [String: Any] = [
            "error": "no_response_body",
            "message": "Server could not read response.",
            "data": [
                "status": 500,
                "raw_body": rawBody
            ]
        ]
        return try JSONSerialization.data(withJSONObject: payload)
    }
}
