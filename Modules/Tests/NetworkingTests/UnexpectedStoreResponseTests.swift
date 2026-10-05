import Foundation
import Testing
@testable import NetworkingCore

struct UnexpectedStoreResponseTests {
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

    @Test func test_excerpt_when_html_contains_private_regions_then_only_sanitized_visible_text_remains() {
        // Given
        let body = """
        <html><head><title>Blocked</title><script>secretScript</script></head>
        <body><!-- secretComment --><input value="secretInput"><textarea>secretTextarea</textarea>
        <p>Contact admin@example.com. IP 203.0.113.7. password=secretPassword token=secretToken</p></body></html>
        """
        // When
        let excerpt = UnexpectedResponseExcerpt.make(body) ?? ""
        // Then
        #expect(excerpt.contains("Blocked"))
        #expect(excerpt.contains("[email]"))
        #expect(excerpt.contains("[ip]"))
        #expect(!excerpt.contains("secret"))
    }

    @Test func test_excerpt_when_json_or_debug_prefix_then_omits_store_payload() {
        // Given / When / Then
        #expect(UnexpectedResponseExcerpt.make("{\"orders\":[{\"email\":\"private\"}]}") == nil)
        #expect(UnexpectedResponseExcerpt.make("[1,2,3]") == nil)
        #expect(UnexpectedResponseExcerpt.make("Debug: /orders\n{\"orders\":[1]}") == "Debug: /orders")
        let apiError = "{\"code\":\"critical_error\",\"message\":\"Failed\",\"data\":\"private\"}"
        #expect(UnexpectedResponseExcerpt.make(apiError) == "critical_error | Failed")
        #expect(UnexpectedResponseExcerpt.make(" ") == nil)
    }

    @Test func test_excerpt_when_long_then_redacts_before_truncating() {
        // Given
        let body = "password=" + String(repeating: "x", count: 500) + " " + String(repeating: "visible ", count: 100)
        // When
        let excerpt = UnexpectedResponseExcerpt.make(body) ?? ""
        // Then
        #expect(excerpt.count == 300)
        #expect(excerpt.hasSuffix("…"))
        #expect(!excerpt.contains("xxx"))
    }

    @Test func test_error_when_described_then_diagnostics_do_not_leak() {
        // Given
        let error = UnexpectedStoreResponseError(kind: .unexpectedContent, statusCode: 202,
                                                data: Data("private-sentinel".utf8), contentType: "text/html", request: nil)
        // When / Then
        #expect(error.diagnostics?.excerpt == "private-sentinel")
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
    }
}
