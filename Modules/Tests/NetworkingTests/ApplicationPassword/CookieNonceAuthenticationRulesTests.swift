import Foundation
import Testing
@testable import NetworkingCore

struct CookieNonceAuthenticationRulesTests {
    typealias Failure = CookieNonceAuthenticationFailure
    typealias Stage = CookieNonceAuthenticationResponseStage

    @Test(arguments: responseCases)
    func test_response_classification_matches_shared_trace(_ trace: ResponseTrace) {
        // Given
        let response = trace

        // When
        let failure = CookieNonceAuthenticationRules.failure(
            statusCode: response.statusCode,
            authenticateHeader: response.authenticate,
            locationHeader: response.location,
            stage: response.stage
        )

        // Then
        #expect(failure == response.expectedFailure)
    }

    @Test func test_basic_authentication_requires_basic_challenge_scheme() {
        // Given
        let misleadingHeader = "Digest realm=\"basic users\""
        let mixedHeader = "Bearer realm=\"api\", Basic realm=\"store\""

        // When
        let misleadingResult = CookieNonceAuthenticationRules.containsBasicAuthentication(
            statusCode: 401,
            authenticateHeader: misleadingHeader
        )
        let mixedResult = CookieNonceAuthenticationRules.containsBasicAuthentication(
            statusCode: 401,
            authenticateHeader: mixedHeader
        )

        // Then
        #expect(misleadingResult == false)
        #expect(mixedResult)
    }

    @Test func test_basic_authentication_ignores_decoys_inside_quoted_digest_realm() {
        // Given
        let quotedDecoyHeader = "Digest realm=\"store, Basic realm=decoy\""
        let escapedQuoteDecoyHeader = "Digest realm=\"store\\\", Basic realm=decoy\""

        // When
        let quotedDecoyResult = CookieNonceAuthenticationRules.containsBasicAuthentication(
            statusCode: 401,
            authenticateHeader: quotedDecoyHeader
        )
        let escapedQuoteDecoyResult = CookieNonceAuthenticationRules.containsBasicAuthentication(
            statusCode: 401,
            authenticateHeader: escapedQuoteDecoyHeader
        )

        // Then
        #expect(quotedDecoyResult == false)
        #expect(escapedQuoteDecoyResult == false)
    }

    @Test func test_credential_body_encodes_reserved_characters_and_policy_nonce_url() throws {
        // Given
        let nonceURL = try #require(URL(string: "https://example.com/hidden-admin/admin-ajax.php?action=rest-nonce"))

        // When
        let body = CookieNonceAuthenticationRules.credentialBody(
            username: "user+name",
            password: "password *+/$&=2+é",
            redirectTo: nonceURL
        )
        let value = try #require(body.flatMap { String(data: $0, encoding: .utf8) })

        // Then
        #expect(value.contains("log=user%2Bname"))
        #expect(value.contains("pwd=password%20*%2B/$%26%3D2%2B%C3%A9"))
        #expect(value.contains("rememberme=true"))
        #expect(value.contains("redirect_to=https://example.com/hidden-admin/admin-ajax.php?action%3Drest-nonce"))
    }

    @Test(arguments: ["ab", "ABC123", "0a9Z"])
    func test_valid_nonce_is_returned_unchanged(_ value: String) {
        // Given
        let data = Data(value.utf8)

        // When
        let nonce = CookieNonceAuthenticationRules.validatedNonce(from: data)

        // Then
        #expect(nonce == value)
    }

    @Test(arguments: ["", "a", "a-b", "nonce\n", "é2"])
    func test_mutated_nonce_is_rejected(_ value: String) {
        // Given
        let data = Data(value.utf8)

        // When
        let nonce = CookieNonceAuthenticationRules.validatedNonce(from: data)

        // Then
        #expect(nonce == nil)
    }

    @Test func test_credential_failure_preserves_rendered_server_error_message() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://example.com"))
        )
        let html = "<div id=\"login_error\">Incorrect password</div>"

        // When
        let failure = CookieNonceAuthenticationRules.credentialFailure(
            in: html,
            endpoints: endpoints
        )

        // Then
        #expect(failure == .loginFailed(message: "Incorrect password"))
    }

    @Test func test_credential_failure_requires_wordpress_shake_marker_for_invalid_credentials() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://example.com"))
        )
        let html = "<div id=\"login_error\">Incorrect password</div>" +
            "<script>document.querySelector('form').classList.add('shake')</script>"

        // When
        let failure = CookieNonceAuthenticationRules.credentialFailure(in: html, endpoints: endpoints)

        // Then
        #expect(failure == .invalidCredentials)
    }

    @Test func test_credential_failure_rejects_captcha_even_with_shake_marker() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: #require(URL(string: "https://example.com"))
        )
        let html = "<div id=\"login_error\">Complete the CAPTCHA</div>" +
            "<script>document.querySelector('form').classList.add('shake')</script>"

        // When
        let failure = CookieNonceAuthenticationRules.credentialFailure(in: html, endpoints: endpoints)

        // Then
        #expect(failure == .invalidResponse)
    }
}

extension CookieNonceAuthenticationRulesTests {
    struct ResponseTrace: CustomTestStringConvertible, Sendable {
        let statusCode: Int
        let authenticate: String?
        let location: String?
        let stage: Stage
        let expectedFailure: Failure?

        var testDescription: String {
            "\(stage)-\(statusCode)-\(expectedFailure.map(String.init(describing:)) ?? "accepted")"
        }
    }

    static let responseCases = [
        ResponseTrace(statusCode: 200, authenticate: nil, location: nil, stage: .preflight, expectedFailure: nil),
        ResponseTrace(statusCode: 302, authenticate: nil, location: "/login", stage: .preflight, expectedFailure: nil),
        ResponseTrace(statusCode: 302, authenticate: nil, location: nil, stage: .preflight, expectedFailure: .invalidResponse),
        ResponseTrace(statusCode: 302, authenticate: nil, location: "/admin/", stage: .credentials, expectedFailure: nil),
        ResponseTrace(statusCode: 302, authenticate: nil, location: "/login", stage: .dashboard, expectedFailure: nil),
        ResponseTrace(statusCode: 302, authenticate: nil, location: "/nonce", stage: .nonce, expectedFailure: .invalidResponse),
        ResponseTrace(statusCode: 401, authenticate: "Basic realm=\"store\"", location: nil, stage: .preflight, expectedFailure: .basicAuthenticationRequired),
        ResponseTrace(statusCode: 404, authenticate: nil, location: nil, stage: .preflight, expectedFailure: .inaccessibleLoginPage),
        ResponseTrace(statusCode: 404, authenticate: nil, location: nil, stage: .credentials, expectedFailure: .unacceptableStatusCode(404)),
        ResponseTrace(statusCode: 404, authenticate: nil, location: nil, stage: .nonce, expectedFailure: .inaccessibleAdminPage),
        ResponseTrace(statusCode: 410, authenticate: nil, location: nil, stage: .preflight, expectedFailure: .inaccessibleLoginPage),
        ResponseTrace(statusCode: 410, authenticate: nil, location: nil, stage: .credentials, expectedFailure: .unacceptableStatusCode(410)),
        ResponseTrace(statusCode: 410, authenticate: nil, location: nil, stage: .dashboard, expectedFailure: .inaccessibleAdminPage),
        ResponseTrace(statusCode: 429, authenticate: nil, location: nil, stage: .nonce, expectedFailure: .unacceptableStatusCode(429))
    ]
}
