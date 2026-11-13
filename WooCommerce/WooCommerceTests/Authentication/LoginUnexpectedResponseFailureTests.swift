import Foundation
import Testing
import Yosemite
@testable import WooCommerce

struct LoginUnexpectedResponseFailureTests {
    @Test(arguments: [LoginUnexpectedResponseFailure.Step.appPasswordGeneration, .userRoleCheck, .wooPluginCheck, .appPasswordAuthorizationURL])
    func test_failure_when_api_response_is_wrapped_then_preserves_sanitized_diagnostics(step: LoginUnexpectedResponseFailure.Step) throws {
        // Given
        let request = URLRequest(url: try #require(URL(string: "https://example.com/wp-json/?token=private")))
        let response = UnexpectedStoreResponseError(kind: .unacceptableStatusCode, statusCode: 500,
                                                   data: Data("<html>Blocked token=private-token</html>".utf8),
                                                   contentType: "text/html", request: request)
        let wrapped = RoleEligibilityError.unknown(error: response)

        // When
        let failure = try #require(LoginUnexpectedResponseFailure(error: wrapped, step: step))

        // Then
        #expect(failure.step == step)
        #expect(failure.statusCode == 500)
        #expect(failure.diagnostics == response.diagnostics)
        #expect(!String(reflecting: failure).contains("Blocked"))
        let event = WooAnalyticsEvent.Login.unexpectedResponseShown(failure: failure, loginFlow: .siteCredentials)
        #expect(event.properties as? [String: String] == [
            "step": step.rawValue, "login_flow": "site_credentials", "failure_kind": "unacceptable_status_code"
        ])
    }
}
