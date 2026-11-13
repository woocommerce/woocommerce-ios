import Testing
@testable import WordPressAuthenticator

struct AuthenticationFailureTests {

    @Test
    func test_supported_auth_types_when_response_lists_methods_then_preserves_order_and_unknown_values() {
        // Given
        let methods = ["backup", "webauthn", "future_method"]
        let failure = makeFailure(supportedAuthTypes: methods)

        // When / Then
        #expect(failure.supportedAuthTypes == methods)
    }

    @Test
    func test_supported_auth_types_when_response_has_no_method_list_then_returns_empty_list() {
        // Given
        let failure = makeFailure(supportedAuthTypes: nil)

        // When / Then
        #expect(failure.supportedAuthTypes.isEmpty)
    }

    private func makeFailure(supportedAuthTypes: [String]?) -> AuthenticationFailure {
        var response: [String: AnyObject] = ["error": "needs_2fa" as AnyObject]
        if let supportedAuthTypes {
            response["two_step_supported_auth_types"] = supportedAuthTypes as AnyObject
        }
        return AuthenticationFailure(apiJSONResponse: response)
    }
}
