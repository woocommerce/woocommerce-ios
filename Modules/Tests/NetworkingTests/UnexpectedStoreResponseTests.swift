import Foundation
import Testing
@testable import NetworkingCore

struct UnexpectedStoreResponseTests {
    @Test func test_metadata_when_direct_response_falls_back_to_tunnel_then_discards_outer_metadata() {
        // Given
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: 123, path: "wp/v2/users/me")
        let policy = UnexpectedResponseRequest(original: request)
        policy.recordResponse(status: 202, contentType: "application/json", tunneled: false)

        // When
        policy.recordResponse(status: 200, contentType: "application/json", tunneled: true)
        let error = policy.makeError(kind: .unexpectedContent)

        // Then
        #expect(error.statusCode == nil)
        #expect(error.diagnostics?.contentType == nil)
    }

    @Test func test_policy_when_disabled_password_error_then_preserves_business_error() {
        // Given
        let request = RESTRequest(siteURL: "https://example.com", method: .post, path: "wp/v2/users/me/application-passwords")
        let policy = UnexpectedResponseRequest(original: request)
        for code in ["application_passwords_disabled", "application_passwords_disabled_for_user"] {
            // When
            let body = Data("{\"code\":\"\(code)\",\"message\":\"Disabled\"}".utf8)
            let error = policy.responseError(data: body, status: 501, tunneled: false)
            // Then
            #expect((error as? ApplicationPasswordUseCaseError) == .applicationPasswordsDisabled)
        }
    }

    @Test func test_policy_when_tunnel_transport_fails_then_requires_store_evidence() {
        // Given
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: 123, path: "wp/v2/users/me")
        let policy = UnexpectedResponseRequest(original: request)
        // When / Then
        #expect(policy.responseError(data: Data("<html>Proxy error</html>".utf8), status: 502, tunneled: true) == nil)
        let body = Data("{\"data\":{\"status\":403,\"raw_body\":\"<html>Blocked</html>\"}}".utf8)
        let error = policy.responseError(data: body, status: 500, tunneled: true) as? UnexpectedStoreResponseError
        #expect(error?.statusCode == 403)
        #expect(error?.kind == .unacceptableStatusCode)
        #expect(error?.diagnostics?.request == "GET /wp/v2/users/me")
    }

    @Test func test_policy_when_request_has_credentials_and_query_then_diagnostics_omit_them() {
        // Given
        let request = RESTRequest(siteURL: "https://user:secret@example.com", method: .get, path: "", parameters: ["token": "secret"])
        // When
        let error = UnexpectedResponseRequest(original: request).makeError(kind: .unexpectedContent)
        // Then
        #expect(error.diagnostics?.request == "GET /wp-json")
        #expect(!error.logMessage.contains("secret"))
        #expect(!error.logMessage.contains("example.com"))
    }

    @Test func test_classification_when_status_and_body_vary_then_preserves_api_errors() {
        // Given
        let cases: [(Int, String, UnexpectedStoreResponseError.Kind?)] = [
            (200, "<html>Blocked</html>", .unexpectedContent), (200, "", .unexpectedContent),
            (200, "{broken", .unexpectedContent), (200, "{}", nil),
            (500, "{\"code\":\"critical_error\"}", .unacceptableStatusCode), (502, "", .unacceptableStatusCode),
            (429, "", .unacceptableStatusCode), (429, "Too many requests", .unacceptableStatusCode),
            (403, "<html>Blocked</html>", .unacceptableStatusCode), (401, "Unauthorized", nil),
            (404, "{\"code\":\"rest_no_route\"}", nil)
        ]
        for (status, body, expected) in cases {
            // When / Then
            #expect(UnexpectedResponseClassifier.classify(data: Data(body.utf8), status: status, contentType: nil) == expected)
        }
    }

    @Test func test_error_when_response_contains_private_text_then_logs_metadata_only() {
        // Given
        let bodies = [
            "<div hidden>private-secret</div>",
            "<input hidden title=\"a > b\" value=\"private-nonce\">",
            "<div style=\"display:none\">private-hidden</div>",
            "{\"code\":\"critical_error\",\"message\":\"private-message\"}"
        ]
        for body in bodies {
            // When
            let policy = UnexpectedResponseRequest(original: RESTRequest(siteURL: "https://example.com", method: .get, path: ""))
            let error = policy.responseError(data: Data(body.utf8), status: 500,
                                             contentType: "text/html; charset=utf-8", tunneled: false) as? UnexpectedStoreResponseError
            // Then
            #expect(error?.diagnostics?.contentType == "text/html")
            #expect(error?.logMessage.contains("private-") == false)
            #expect(error?.logMessage.contains("excerpt") == false)
        }
    }

    @Test func test_error_when_described_then_diagnostics_do_not_leak() {
        // Given
        let error = UnexpectedStoreResponseError(kind: .unexpectedContent, statusCode: 202,
                                                contentType: "text/html", request: nil)
        // When / Then
        #expect(!error.logMessage.contains("private-sentinel"))
        #expect(!String(describing: error).contains("private-sentinel"))
        #expect(!String(reflecting: error).contains("private-sentinel"))
        #expect(!String(describing: (error as NSError).userInfo).contains("private-sentinel"))
    }

    @Test func test_tunnel_when_outer_error_has_no_store_body_then_does_not_attribute_it_to_store() {
        // Given / When / Then
        #expect(UnexpectedResponseClassifier.tunnelResponse(in: Data("{\"status\":500}".utf8)) == nil)
        let body = "{\"data\":{\"status\":403,\"raw_body\":\"<html>Blocked</html>\"}}"
        let response = UnexpectedResponseClassifier.tunnelResponse(in: Data(body.utf8))
        #expect(response?.status == 403)
        #expect(response?.data == Data("<html>Blocked</html>".utf8))
        let nested = Data("{\"status\":\"503\",\"body\":{\"data\":{\"raw_body\":\"Unavailable\"}}}".utf8)
        #expect(UnexpectedResponseClassifier.tunnelResponse(in: nested)?.status == 503)
    }
}
