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
        #expect(error?.diagnostics?.excerpt == "Blocked")
    }

    @Test(arguments: [200, 400, 500, 503])
    func test_policy_when_tunnel_raw_body_has_no_inner_status_then_does_not_classify(transportStatus: Int) throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: 123, path: "")
        let policy = UnexpectedResponseRequest(original: request)
        let payload = """
        {"error":"no_response_body","message":"Server could not read response.",
         "data":{"raw_body":"<html>Store temporarily blocked</html>"}}
        """
        let object = try JSONSerialization.jsonObject(with: Data(payload.utf8))
        let envelopes: [Data] = [
            Data(payload.utf8),
            try JSONSerialization.data(withJSONObject: ["body": payload]),
            try JSONSerialization.data(withJSONObject: ["body": object]),
            try JSONSerialization.data(withJSONObject: ["status": 503, "body": payload]),
            try JSONSerialization.data(withJSONObject: ["status": "503", "body": object])
        ]

        for envelope in envelopes {
            // When
            let error = policy.responseError(data: envelope, status: transportStatus, tunneled: true)

            // Then
            #expect(error == nil)
        }
    }

    @Test(arguments: [200, 503])
    func test_policy_when_tunnel_raw_body_has_inner_status_then_uses_store_status(storeStatus: Int) throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: 123, path: "")
        let policy = UnexpectedResponseRequest(original: request)
        let payload = """
        {"error":"no_response_body","message":"Server could not read response.",
         "data":{"status":\(storeStatus),
                 "raw_body":"<html><div hidden>private-sentinel</div><p>Store temporarily blocked token=private-token</p></html>"}}
        """
        let envelopes: [Data] = [
            Data(payload.utf8),
            try JSONSerialization.data(withJSONObject: ["status": 500, "body": payload]),
            try JSONSerialization.data(withJSONObject: ["status": 500, "body": JSONSerialization.jsonObject(with: Data(payload.utf8))])
        ]

        for envelope in envelopes {
            // When
            let error = try #require(policy.responseError(data: envelope, status: 500, tunneled: true) as? UnexpectedStoreResponseError)

            // Then
            #expect(error.kind == (storeStatus == 200 ? .unexpectedContent : .unacceptableStatusCode))
            #expect(error.statusCode == storeStatus)
            #expect(error.diagnostics?.request == "GET /")
            #expect(error.diagnostics?.excerpt == "Store temporarily blocked token=[redacted]")
            #expect(!error.logMessage.contains("private-sentinel"))
            #expect(!error.logMessage.contains("private-token"))
        }
    }

    @Test func test_policy_when_tunnel_transport_fails_without_store_body_then_does_not_classify() {
        // Given
        let request = JetpackRequest(wooApiVersion: .none, method: .get, siteID: 123, path: "")
        let policy = UnexpectedResponseRequest(original: request)
        let envelopes = [
            "{\"error\":\"no_response_body\"}",
            "{\"error\":\"no_response_body\",\"data\":{\"raw_body\":\"\"}}",
            "{\"error\":\"no_response_body\",\"data\":{\"raw_body\":\"  \"}}"
        ]

        for envelope in envelopes {
            // When
            let error = policy.responseError(data: Data(envelope.utf8), status: 503, tunneled: true)

            // Then
            #expect(error == nil)
        }
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

    @Test func test_error_when_response_contains_hidden_text_then_logs_only_visible_excerpt() {
        // Given
        let bodies = [
            "<div hidden>private-secret</div><p>Blocked</p>",
            "<input hidden title=\"a > b\" value=\"private-nonce\"><p>Blocked</p>",
            "<div style=\"display:none\">private-hidden</div><p>Blocked</p>"
        ]
        for body in bodies {
            // When
            let policy = UnexpectedResponseRequest(original: RESTRequest(siteURL: "https://example.com", method: .get, path: ""))
            let error = policy.responseError(data: Data(body.utf8), status: 500,
                                             contentType: "text/html; charset=utf-8", tunneled: false) as? UnexpectedStoreResponseError
            // Then
            #expect(error?.diagnostics?.contentType == "text/html")
            #expect(error?.logMessage.contains("private-") == false)
            #expect(error?.diagnostics?.excerpt == "Blocked")
            #expect(error?.logMessage.contains("excerpt=Blocked") == true)
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
        #expect(UnexpectedResponseExcerpt.make("Authorization: Basic private-token") == "Authorization: [redacted]")
        #expect(UnexpectedResponseExcerpt.make("abcd efgh ijkl mnop qrst uvwx") == "[redacted]")
    }

    @Test func test_excerpt_when_wordpress_error_has_styles_then_preserves_message_and_omits_private_regions() {
        // Given
        let body = """
        <html><head><title>WordPress › Error</title>
        <style>body { color: red; } /* private-style */</style>
        <script>const data = {secret: "private-script"};</script></head>
        <body><!-- {private-comment} --><p>There has been a critical error on this website.</p></body></html>
        {"orders":[{"secret":"private-payload"}]}
        """
        // When
        let excerpt = UnexpectedResponseExcerpt.make(body) ?? ""
        // Then
        #expect(excerpt.contains("WordPress › Error"))
        #expect(excerpt.contains("There has been a critical error on this website."))
        #expect(!excerpt.contains("private-"))
        #expect(!excerpt.contains("color: red"))
        #expect(!excerpt.contains("orders"))
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

    @Test(arguments: [
        "<div hidden><span>private-hidden</span></div>",
        "<div hidden><div>private-a</div><div>private-b</div>private-c</div>",
        "<p hidden><p>private-hidden</p>private-tail</p>",
        "<li hidden><li>private-hidden</li>private-tail</li>",
        "<div HIDDEN=\"false\">private-hidden</div>",
        "<div aria-hidden=\"true\">private-hidden</div>",
        "<div style=\"color:red; DISPLAY : none !important;\">private-hidden</div>",
        "<div style=\"visibility: hidden\">private-hidden</div>",
        "<svg><title>private-title</title><text>private-hidden</text></svg>",
        "<template><p>private-hidden</p></template>",
        "<noscript>private-hidden</noscript>"
    ])
    func test_excerpt_when_element_is_hidden_then_omits_its_entire_subtree(hidden: String) {
        // Given
        let body = "<html><head><title>Blocked</title></head><body>\(hidden)<p>Enable cookies to continue</p></body></html>"

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body)

        // Then
        #expect(excerpt == "Blocked | Enable cookies to continue")
    }

    @Test(arguments: [
        "<input hidden title=\"a > b\" value=\"private-nonce\">",
        "<input title='a > b' value='private-password'>",
        "<a title=\"a > b private-attribute\">Visible</a>",
        "<div hidden title='a > b'><p>private-hidden</p></div>"
    ])
    func test_excerpt_when_attribute_contains_greater_than_then_does_not_include_attribute_text(tag: String) {
        // Given
        let body = "<p>Blocked</p>\(tag)<p>Try again</p>"

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body) ?? ""

        // Then
        #expect(excerpt.hasPrefix("Blocked"))
        #expect(excerpt.hasSuffix("Try again"))
        #expect(!excerpt.contains("private-"))
        #expect(!excerpt.contains("a > b"))
    }

    @Test(arguments: [
        "<input value=\"private-nonce",
        "<input title='a > b' value='private-nonce",
        "<a title=\"private-attribute > private-tail",
        "<div hidden><div>private-hidden</div><p>private-tail",
        "<div style='display:none'><div>private-hidden</div><p>private-tail",
        "<p hidden>private-hidden<p>private-tail",
        "<li style='visibility:hidden'>private-hidden<li>private-tail"
    ])
    func test_excerpt_when_markup_is_unterminated_then_omits_private_tail(markup: String) {
        // Given
        let body = "<p>Blocked</p>\(markup)"

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body)

        // Then
        #expect(excerpt == "Blocked")
    }

    @Test func test_excerpt_when_attributes_only_mention_hidden_then_preserves_visible_text() {
        // Given
        let body = """
        <p data-state="hidden" title="hidden style='display:none'">Shown</p>
        <p style="--hidden: true; display:block">Also shown</p>
        <input type="hidden" name="_wpnonce" value="private-nonce"><p>End</p>
        """

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body)

        // Then
        #expect(excerpt == "Shown Also shown End")
    }

    @Test func test_excerpt_when_script_or_comment_contains_hidden_markup_then_preserves_following_text() {
        // Given
        let body = """
        <script>const markup = "<p hidden>private-script";</script>
        <!-- <div hidden>private-comment -->
        <div hidden><script>const markup = "<div>private-script";</script>private-hidden</div>
        <p>Shown</p><p>2 &lt; 3 and 4 &gt; 3</p>
        """

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body)

        // Then
        #expect(excerpt == "Shown 2 < 3 and 4 > 3")
    }

    @Test func test_excerpt_when_json_error_message_has_unclosed_hidden_element_then_omits_private_tail() throws {
        // Given
        let data = try JSONSerialization.data(withJSONObject: [
            "code": "blocked",
            "message": "<p>Contact support</p><p hidden>private-hidden<p>private-tail"
        ])
        let body = try #require(String(data: data, encoding: .utf8))

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body)

        // Then
        #expect(excerpt == "blocked | Contact support")
    }

    @Test func test_excerpt_when_headers_and_secret_fields_are_present_then_masks_values() {
        // Given
        let body = """
        <p>Contact admin&#64;example.com. IP 203.0.113.7 or 2001:db8::1</p>
        <p>password=private-password token=private-token api_key=private-key consumer_secret=private-secret</p>
        <p>refresh_token=private-refresh cookie=private-cookie</p>
        <pre>Authorization: Bearer private-bearer
        Set-Cookie: private-session</pre>
        """

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body) ?? ""

        // Then
        #expect(excerpt.contains("[email]"))
        #expect(excerpt.contains("[ip]"))
        #expect(excerpt.contains("[redacted]"))
        #expect(!excerpt.contains("private-"))
        #expect(!excerpt.contains("example.com"))
        #expect(!excerpt.contains("203.0.113.7"))
        #expect(!excerpt.contains("2001:db8::1"))
    }

    @Test func test_excerpt_when_email_crosses_cut_point_then_masks_before_truncation() {
        // Given
        let body = String(repeating: "Visible ", count: 36) + "admin@example.com " + String(repeating: "text ", count: 50)

        // When
        let excerpt = UnexpectedResponseExcerpt.make(body) ?? ""

        // Then
        #expect(excerpt.count == 300)
        #expect(excerpt.hasSuffix("…"))
        #expect(!excerpt.contains("admin"))
        #expect(!excerpt.contains("example.com"))
    }

    @Test func test_excerpt_when_title_repeats_or_markup_is_unclosed_then_keeps_only_readable_text() {
        // Given / When / Then
        #expect(UnexpectedResponseExcerpt.make("<title>Blocked</title><p>Blocked by firewall</p>") == "Blocked by firewall")
        #expect(UnexpectedResponseExcerpt.make("<p>Blocked</p><script>private-script") == "Blocked")
        #expect(UnexpectedResponseExcerpt.make("<p>Blocked</p><div hidden>private-hidden") == "Blocked")
        #expect(UnexpectedResponseExcerpt.make("<!-- private-comment -->") == nil)
        #expect(UnexpectedResponseExcerpt.make("<input hidden title=\"a > b\" value=\"private-nonce\">") == nil)
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
        let nested = Data("{\"status\":\"503\",\"body\":{\"data\":{\"raw_body\":\"Unavailable\"}}}".utf8)
        #expect(UnexpectedResponseClassifier.tunnelResponse(in: nested) == nil)
    }
}
