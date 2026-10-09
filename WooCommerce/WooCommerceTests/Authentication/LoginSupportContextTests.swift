import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct LoginSupportContextTests {
    @Test func test_context_when_site_contains_private_url_parts_then_keeps_only_site_address() throws {
        // Given
        let context = LoginSupportContext(failure: .init(stage: .preflight), flow: .siteCredentials,
                                          siteURL: "https://user:secret@example.com/store?token=private#fragment")

        // When
        let message = context.initialMessage

        // Then
        #expect(context.siteURL == "https://example.com/store")
        #expect(message.contains("Site: https://example.com/store"))
        #expect(message.contains("HTTP status: Unknown"))
        #expect(!message.contains("secret"))
        #expect(!message.contains("private"))
        #expect(!message.contains("Response excerpt"))
    }

    @Test(arguments: [LoginUnexpectedResponseFailure.LoginFlow.siteCredentials, .appPassword, .storePicker])
    func test_message_when_diagnostics_exist_then_includes_sanitized_failure_details(flow: LoginUnexpectedResponseFailure.LoginFlow) throws {
        // Given
        var request = URLRequest(url: try #require(URL(string: "https://example.com/wp-json/wp/v2/users/me?token=private")))
        request.httpMethod = "GET"
        let error = UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 500,
                                                data: Data("<html>Blocked password=secret-marker</html>".utf8),
                                                contentType: "text/html", request: request)
        let failure = try #require(LoginUnexpectedResponseFailure(error: error, step: .userRoleCheck))
        let context = LoginSupportContext(failure: failure, flow: flow, siteURL: "https://example.com")

        // When
        let message = context.initialMessage

        // Then
        #expect(message.contains("Login step: user_role_check"))
        #expect(message.contains("Login flow: " + flow.rawValue))
        #expect(message.contains("Failure kind: unacceptable_status_code"))
        #expect(message.contains("HTTP status: 500"))
        #expect(message.contains("Request: GET /wp-json/wp/v2/users/me"))
        #expect(message.contains("Content type: text/html"))
        #expect(message.contains("Response excerpt: Blocked password=[redacted]"))
        #expect(!message.contains("secret-marker"))
        #expect(!message.contains("?token"))
    }
}
