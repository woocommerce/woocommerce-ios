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
            "raw_body_snippet=<html>\\n Fatal error consumer_key=[redacted] Authorization: Bearer [redacted] Cookie: [redacted]\\n</html>"
        ))
        #expect(!message.contains("\n"))
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

    @Test func logIfNeeded_when_raw_body_contains_basic_authorization_then_redacts_header_value() throws {
        // Given
        let rawBody = "<html>Authorization: Basic basic-secret failed</html>"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        #expect(message.contains("Authorization: Basic [redacted]"))
        #expect(!message.contains("basic-secret"))
    }

    @Test func logIfNeeded_when_raw_body_contains_newlines_and_tabs_then_keeps_visible_boundaries_on_one_log_line() throws {
        // Given
        let rawBody = "<html>\n\tFatal error\nAuthorization: Bearer newline-secret\nCookie: session=cookie-secret\n</html>"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        let expectedSnippet = "raw_body_snippet=<html>\\n\\tFatal error\\n Authorization: Bearer [redacted]" +
            "\\n Cookie: [redacted]\\n</html>"
        #expect(message.contains(expectedSnippet))
        #expect(!message.contains("\n"))
        #expect(!message.contains("\t"))
        #expect(!message.contains("newline-secret"))
        #expect(!message.contains("cookie-secret"))
    }

    @Test func logIfNeeded_when_flattened_html_glues_authorization_to_previous_text_then_redacts_and_inserts_readable_boundaries() throws {
        // Given
        let rawBody = "WOOMOB-3429 forced HTMLForced HTML response for WOOMOB-3429" +
            "Authorization: Bearer fake-review-token" +
            "Cookie: wordpress_logged_in_test=wpLoginSecret; session=abc"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        let expectedSnippet = "raw_body_snippet=WOOMOB-3429 forced HTMLForced HTML response for WOOMOB-3429" +
            " Authorization: Bearer [redacted] Cookie: [redacted]"
        #expect(message.contains(expectedSnippet))
        #expect(!message.contains("WOOMOB-3429Authorization"))
        #expect(!message.contains("[redacted]Cookie"))
        #expect(!message.contains("fake-review-token"))
        #expect(!message.contains("wpLoginSecret"))
        #expect(!message.contains("session=abc"))
    }

    @Test func logIfNeeded_when_sensitive_labels_are_glued_then_redacts_without_erasing_following_boundaries() throws {
        // Given
        let rawBody = "prefixCookie: wordpress_logged_in_test=wpLoginSecret" +
            "Authorization: Bearer authSecret" +
            "Set-Cookie: session=setSecret\n" +
            "footer9session=standaloneSecret tail9wordpress_logged_in_xyz=loginSecret"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        let expectedSnippet = "raw_body_snippet=prefix Cookie: [redacted] Authorization: Bearer [redacted] " +
            "Set-Cookie: [redacted]\\nfooter9 session=[redacted] tail9 wordpress_logged_in_xyz=[redacted]"
        #expect(message.contains(expectedSnippet))
        #expect(!message.contains("prefixCookie"))
        #expect(!message.contains("authSecretSet-Cookie"))
        #expect(!message.contains("wpLoginSecret"))
        #expect(!message.contains("authSecret"))
        #expect(!message.contains("setSecret"))
        #expect(!message.contains("standaloneSecret"))
        #expect(!message.contains("loginSecret"))
    }

    @Test func logIfNeeded_when_raw_body_contains_standalone_session_cookie_then_redacts_value() throws {
        // Given
        let rawBody = "<html>Fatal error session=abc failed</html>"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        #expect(message.contains("session=[redacted]"))
        #expect(!message.contains("session=abc"))
    }

    @Test func logIfNeeded_when_raw_body_contains_standalone_wordpress_logged_in_cookie_then_redacts_value() throws {
        // Given
        let rawBody = "<html>Fatal error wordpress_logged_in_123=secret failed</html>"

        // When
        let message = try message(forRawBody: rawBody)

        // Then
        #expect(message.contains("wordpress_logged_in_123=[redacted]"))
        #expect(!message.contains("secret"))
    }

    @Test func logIfNeeded_when_raw_body_is_missing_then_emits_no_message() throws {
        // Given
        let responseData = Data("""
        {
          "error": "no_response_body",
          "message": "Server could not read response.",
          "data": { "status": 500 }
        }
        """.utf8)

        // When
        let messages = messages(forResponseData: responseData)

        // Then
        #expect(messages.isEmpty)
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

    @Test func logIfNeeded_includes_original_request_methods() throws {
        // Given
        let responseData = try #require(Loader.contentsOf("jetpack-tunnel-raw-body-error"))
        let methods: [HTTPMethod] = [.get, .post, .put, .delete]

        for method in methods {
            // When
            let message = try message(forResponseData: responseData, method: method)

            // Then
            #expect(message.contains("method=\(method.rawValue.uppercased())"))
        }
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
