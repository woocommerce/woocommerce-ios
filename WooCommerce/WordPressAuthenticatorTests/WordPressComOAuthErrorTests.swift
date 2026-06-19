import Testing
@testable import WordPressAuthenticator

/// Tests for `WordPressComOAuthError.loginErrorMessage`, which decides the user-facing copy for a
/// failed WordPress.com password sign-in.
///
/// Regression coverage for WOOMOB-3205: a blocked WordPress.com account returns an `invalid_request`
/// failure whose message mentions "reset your password". The old code matched the substring "password"
/// and replaced *any* such message with a generic incorrect-password copy, hiding the real reason. The
/// fix surfaces the backend `error_description` verbatim instead of inferring the reason from its text.
struct WordPressComOAuthErrorTests {

    @Test func test_loginErrorMessage_when_account_is_blocked_then_shows_backend_message() {
        // Given the exact response WordPress.com returns for a blocked account (see GitHub issue #3892)
        let blockedMessage = "Your account has been blocked as a security precaution. To continue, you must reset your password."
        let error = makeError(code: "invalid_request", description: blockedMessage)

        // When / Then the backend guidance is surfaced verbatim
        #expect(error.loginErrorMessage == blockedMessage)
    }

    @Test func test_loginErrorMessage_when_wrong_password_then_shows_backend_message() {
        // Given the canonical wrong-credentials response
        let wrongCredentials = "Incorrect username or password."
        let error = makeError(code: "invalid_request", description: wrongCredentials)

        // When / Then it is shown verbatim (we no longer infer "wrong password" from the text)
        #expect(error.loginErrorMessage == wrongCredentials)
    }

    @Test func test_loginErrorMessage_when_login_limit_exceeded_then_shows_backend_message() {
        // Given a different invalid_request reason (rate limiting)
        let limitMessage = "You can't log in to this account because too many failed login attempts have been detected."
        let error = makeError(code: "invalid_request", description: limitMessage)

        // When / Then the backend message is surfaced verbatim
        #expect(error.loginErrorMessage == limitMessage)
    }

    @Test func test_loginErrorMessage_when_no_description_then_falls_back_to_localized_description() {
        // Given an invalid_request with no error_description
        let error = makeError(code: "invalid_request", description: nil)

        // When / Then it falls back to the standard error description (not a credential-specific guess)
        #expect(error.loginErrorMessage == error.localizedDescription)
    }

    @Test func test_loginErrorMessage_when_empty_description_then_falls_back_to_localized_description() {
        // Given an invalid_request with an empty error_description
        let error = makeError(code: "invalid_request", description: "")

        // When / Then it falls back to the standard error description rather than an empty string
        #expect(error.loginErrorMessage == error.localizedDescription)
    }
}

private extension WordPressComOAuthErrorTests {
    func makeError(code: String, description: String?) -> WordPressComOAuthError {
        var json: [String: AnyObject] = ["error": code as AnyObject]
        if let description {
            json["error_description"] = description as AnyObject
        }
        return .endpointError(AuthenticationFailure(apiJSONResponse: json))
    }
}
