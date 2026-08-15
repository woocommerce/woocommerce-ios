import Foundation
import Testing
@testable import NetworkingCore

struct CookieNonceAuthenticationEndpointsTests {
    typealias ValidationError = CookieNonceAuthenticationEndpoints.ValidationError

    @Test func test_configured_endpoints_are_canonically_normalized() throws {
        // Given
        let siteURL = try url("HTTPS://EXAMPLE.COM:443/shop///#identity")
        let loginEntryURL = try url("https://example.com/shop/secret-login?key=value#form")
        let adminBaseURL = try url("https://example.com/shop/secret-admin/INDEX.PHP//#admin")

        // When
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: siteURL,
            loginEntryURL: loginEntryURL,
            adminBaseURL: adminBaseURL
        )

        // Then
        #expect(endpoints.siteURL.absoluteString == "https://example.com/shop")
        #expect(endpoints.loginEntryURL.absoluteString == "https://example.com/shop/secret-login?key=value")
        #expect(endpoints.adminBaseURL.absoluteString == "https://example.com/shop/secret-admin/")
    }

    @Test func test_percent_encoded_path_identity_is_preserved_during_normalization() throws {
        // Given
        let siteURL = try url("https://example.com/store%2Fbranch/")
        let adminBaseURL = try url("https://example.com/hidden%2Findex.php/")

        // When
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: siteURL, adminBaseURL: adminBaseURL)

        // Then
        #expect(endpoints.siteURL.absoluteString == "https://example.com/store%2Fbranch")
        #expect(endpoints.loginEntryURL.absoluteString == "https://example.com/store%2Fbranch/wp-login.php")
        #expect(endpoints.adminBaseURL.absoluteString == "https://example.com/hidden%2Findex.php/")
    }

    @Test func test_default_endpoints_preserve_the_canonical_subdirectory() throws {
        // Given
        let siteURL = try url("https://example.com/store/")

        // When
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: siteURL)

        // Then
        #expect(endpoints.siteURL.absoluteString == "https://example.com/store")
        #expect(endpoints.loginEntryURL.absoluteString == "https://example.com/store/wp-login.php")
        #expect(endpoints.adminBaseURL.absoluteString == "https://example.com/store/wp-admin/")
        #expect(try endpoints.nonceURL().absoluteString == "https://example.com/store/wp-admin/admin-ajax.php?action=rest-nonce")
    }

    @Test(arguments: [
        ("ftp://example.com", "https://example.com/login", "https://example.com/admin/", ValidationError.unsupportedScheme),
        ("https://user:secret@example.com", "https://example.com/login", "https://example.com/admin/", .userInfoNotAllowed),
        ("https://example.com?identity=other", "https://example.com/login", "https://example.com/admin/", .queryNotAllowed),
        ("https://example.com", "https://other.example/login", "https://example.com/admin/", .originMismatch),
        ("https://example.com", "https://user:secret@example.com/login", "https://example.com/admin/", .userInfoNotAllowed),
        ("https://example.com", "http://example.com/login", "https://example.com/admin/", .originMismatch),
        ("https://example.com", "https://example.com:8443/login", "https://example.com/admin/", .originMismatch),
        ("https://example.com", "https://example.com/login", "https://other.example/admin/", .originMismatch),
        ("https://example.com", "https://example.com/login", "https://example.com/admin/?redirect=1", .queryNotAllowed)
    ])
    func test_unsafe_configured_endpoint_is_rejected(
        site: String,
        login: String,
        admin: String,
        expectedError: ValidationError
    ) throws {
        // Given
        let siteURL = try url(site)
        let loginEntryURL = try url(login)
        let adminBaseURL = try url(admin)

        // When
        let error = validationError {
            try CookieNonceAuthenticationEndpoints(
                siteURL: siteURL,
                loginEntryURL: loginEntryURL,
                adminBaseURL: adminBaseURL
            )
        }

        // Then
        #expect(error == expectedError)
    }

    @Test func test_relative_url_with_base_is_not_intrinsically_absolute() throws {
        // Given
        let baseURL = try url("https://example.com/root/")
        let relativeURL = try #require(URL(string: "login", relativeTo: baseURL))
        let siteURL = try url("https://example.com")

        // When
        let siteError = validationError { try CookieNonceAuthenticationEndpoints(siteURL: relativeURL) }
        let loginError = validationError {
            try CookieNonceAuthenticationEndpoints(siteURL: siteURL, loginEntryURL: relativeURL)
        }

        // Then
        #expect(relativeURL.baseURL == baseURL)
        #expect(siteError == .unsupportedScheme)
        #expect(loginError == .unsupportedScheme)
    }

    @Test func test_default_effective_ports_are_equivalent_and_removed() throws {
        // Given
        let siteURL = try url("https://example.com:443/")
        let loginEntryURL = try url("https://EXAMPLE.COM/login")

        // When
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: siteURL, loginEntryURL: loginEntryURL)

        // Then
        #expect(endpoints.siteURL.absoluteString == "https://example.com")
        #expect(endpoints.loginEntryURL.absoluteString == "https://example.com/login")
    }

    @Test func test_http_to_https_promotion_is_limited_to_default_effective_ports() throws {
        // Given
        let secureLogin = try url("https://example.com:443/login")
        let defaultSite = try url("http://example.com:80")
        let customPortSite = try url("http://example.com:8080")

        // When
        let promoted = try CookieNonceAuthenticationEndpoints(siteURL: defaultSite, loginEntryURL: secureLogin)
        let error = validationError {
            try CookieNonceAuthenticationEndpoints(siteURL: customPortSite, loginEntryURL: secureLogin)
        }

        // Then
        #expect(promoted.loginEntryURL.absoluteString == "https://example.com/login")
        #expect(try promoted.derivedAdminBaseURL().absoluteString == "https://example.com/wp-admin/")
        #expect(error == .originMismatch)
    }

    @Test func test_untrusted_final_login_url_cannot_influence_admin_promotion() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("http://example.com"))
        let attackerURL = try url("https://attacker.example/login")

        // When
        let error = validationError { try endpoints.derivedAdminBaseURL(afterLoginAt: attackerURL) }

        // Then
        #expect(error == .originMismatch)
        #expect(endpoints.adminBaseURL.absoluteString == "http://example.com/wp-admin/")
    }

    @Test func test_https_login_entry_cannot_finish_at_http_when_deriving_admin_base() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: url("http://example.com"),
            loginEntryURL: url("https://example.com/wp-login.php")
        )
        let finalLoginURL = try url("http://example.com/wp-login.php")

        // When
        let error = validationError { try endpoints.derivedAdminBaseURL(afterLoginAt: finalLoginURL) }

        // Then
        #expect(error == .insecureDowngrade)
    }

    @Test func test_redirect_location_is_resolved_relative_to_the_previous_url() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com/store"))
        let previousURL = try url("https://example.com/store/login/step")

        // When
        let redirectURL = try endpoints.resolveRedirect(location: " ../finish?flow=login#ignored ", from: previousURL)

        // Then
        #expect(redirectURL.absoluteString == "https://example.com/store/finish?flow=login")
    }

    @Test(arguments: [
        ("//attacker.example/collect", ValidationError.originMismatch),
        ("https://user:secret@example.com/collect", .userInfoNotAllowed),
        ("https://example.com:8443/collect", .originMismatch),
        ("ftp://example.com/collect", .unsupportedScheme)
    ])
    func test_unsafe_redirect_location_is_rejected(location: String, expectedError: ValidationError) throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let previousURL = try url("https://example.com/login")

        // When
        let error = validationError { try endpoints.resolveRedirect(location: location, from: previousURL) }

        // Then
        #expect(error == expectedError)
    }

    @Test func test_https_redirect_cannot_downgrade_to_http() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("http://example.com"))
        let previousURL = try url("https://example.com/login")

        // When
        let error = validationError {
            try endpoints.resolveRedirect(location: "http://example.com/login", from: previousURL)
        }

        // Then
        #expect(error == .insecureDowngrade)
    }

    @Test(arguments: [
        "https://example.com/private-admin/",
        "https://example.com/private-admin",
        "https://example.com/private-admin/index.php",
        "https://example.com/private-admin/admin-ajax.php?action=rest-nonce",
        "https://example.com/hidden-admin/admin-ajax.php?action=rest-nonce"
    ])
    func test_expected_credential_redirect_accepts_exact_configured_admin_or_structural_nonce(location: String) throws {
        // Given
        let submissionURL = try url("https://example.com/custom-submit")
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: url("https://example.com"),
            loginEntryURL: submissionURL,
            adminBaseURL: url("https://example.com/private-admin/")
        )

        // When
        let isExpected = endpoints.isExpectedCredentialRedirect(
            location: location,
            from: submissionURL,
            afterLoginAt: submissionURL
        )

        // Then
        #expect(isExpected)
    }

    @Test(arguments: [
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://attacker.example/private-admin/"
        ),
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://user:secret@example.com/private-admin/"
        ),
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://example.com:8443/private-admin/"
        ),
        (
            "http://example.com",
            "http://example.com/private-admin/",
            "https://example.com/custom-submit",
            "http://example.com/private-admin/"
        ),
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://example.com/private-admin/?page=dashboard"
        ),
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://example.com/other-admin/"
        ),
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://example.com/private-admin/admin-ajax.php?action=rest-nonce&extra=1"
        ),
        (
            "https://example.com",
            "https://example.com/private-admin/",
            "https://example.com/custom-submit",
            "https://example.com/hidden-admin/admin-ajax.php?action=wrong-action"
        )
    ])
    func test_expected_credential_redirect_rejects_unsafe_or_inexact_destination(
        site: String,
        admin: String,
        login: String,
        location: String
    ) throws {
        // Given
        let submissionURL = try url(login)
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: url(site),
            loginEntryURL: submissionURL,
            adminBaseURL: url(admin)
        )

        // When
        let isExpected = endpoints.isExpectedCredentialRedirect(
            location: location,
            from: submissionURL,
            afterLoginAt: submissionURL
        )

        // Then
        #expect(isExpected == false)
    }

    @Test func test_form_action_is_transaction_local_and_does_not_replace_the_login_entry() throws {
        // Given
        let entryURL = try url("https://example.com/custom-entry?durable=1")
        let documentURL = try url("https://example.com/login/final-page")
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"), loginEntryURL: entryURL)

        // When
        let submissionURL = try endpoints.resolveFormAction("../authenticate?transaction=1#ignored", documentURL: documentURL)

        // Then
        #expect(submissionURL.absoluteString == "https://example.com/authenticate?transaction=1")
        #expect(endpoints.loginEntryURL == entryURL)
    }

    @Test func test_empty_form_action_uses_the_final_document_url() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let documentURL = try url("https://example.com/final-login?attempt=1#ignored")

        // When
        let submissionURL = try endpoints.resolveFormAction("   ", documentURL: documentURL)

        // Then
        #expect(submissionURL.absoluteString == "https://example.com/final-login?attempt=1")
    }

    @Test(arguments: [
        ("https://example.com", "https://example.com/login", "https://attacker.example/collect", ValidationError.originMismatch),
        ("https://example.com", "https://example.com/login", "https://user:secret@example.com/collect", .userInfoNotAllowed),
        ("http://example.com", "https://example.com/login", "http://example.com/collect", .insecureDowngrade),
        ("https://example.com", "https://example.com/login", "https://example.com:8443/collect", .originMismatch)
    ])
    func test_eligible_form_with_unsafe_action_never_returns_submission_url(
        site: String,
        document: String,
        action: String,
        expectedError: ValidationError
    ) throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url(site))
        let html = loginForm(action: action)
        let documentURL = try url(document)

        // When
        let error = validationError {
            try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: documentURL)
        }

        // Then
        #expect(error == expectedError)
    }

    @Test func test_admin_and_nonce_destinations_are_derived_and_matched_exactly() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(
            siteURL: url("http://example.com"),
            adminBaseURL: url("http://example.com/hidden-admin/index.php")
        )
        let secureLogin = try endpoints.resolveRedirect(
            location: "https://example.com/custom-login",
            from: url("http://example.com/wp-login.php")
        )
        let adminURL = try url("https://example.com/hidden-admin/")
        let nonceURL = try url("https://example.com/hidden-admin/admin-ajax.php?action=rest-nonce")

        // When
        let derivedAdminURL = try endpoints.derivedAdminBaseURL(afterLoginAt: secureLogin)
        let derivedNonceURL = try endpoints.nonceURL(afterLoginAt: secureLogin)

        // Then
        #expect(derivedAdminURL == adminURL)
        #expect(derivedNonceURL == nonceURL)
        #expect(endpoints.isExpectedAdminBaseURL(adminURL, afterLoginAt: secureLogin))
        #expect(endpoints.isExpectedNonceURL(nonceURL, afterLoginAt: secureLogin))
    }

    @Test func test_nonce_classifier_accepts_exact_same_site_endpoint_at_another_admin_path() throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let recoveredNonceURL = try url("https://example.com/custom-admin/admin-ajax.php?action=rest-nonce")

        // When
        let isNonceEndpoint = endpoints.isNonceEndpoint(recoveredNonceURL)
        let isConfiguredNonceEndpoint = endpoints.isExpectedNonceURL(recoveredNonceURL)

        // Then
        #expect(isNonceEndpoint)
        #expect(isConfiguredNonceEndpoint == false)
    }

    @Test(arguments: [
        "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce&extra=1",
        "https://example.com/wp-admin/admin-ajax.php?action=rest%2Dnonce",
        "https://example.com/wp-admin/admin-ajax.php?action=rest-nonce#fragment",
        "https://example.com/wp-admin/admin-ajax.php/?action=rest-nonce",
        "https://example.com/wp-admin/not-admin-ajax.php?action=rest-nonce",
        "https://attacker.example/wp-admin/admin-ajax.php?action=rest-nonce"
    ])
    func test_mutated_nonce_endpoint_is_not_recognized(_ candidate: String) throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let candidateURL = try url(candidate)

        // When
        let isNonceEndpoint = endpoints.isNonceEndpoint(candidateURL)

        // Then
        #expect(isNonceEndpoint == false)
        #expect(endpoints.isExpectedNonceURL(candidateURL) == false)
    }

    @Test(arguments: [
        "https://example.com/wp-admin/?page=dashboard",
        "https://example.com/wp-admin/#fragment",
        "https://example.com/other-admin/",
        "https://attacker.example/wp-admin/"
    ])
    func test_mutated_admin_destination_does_not_match(_ candidate: String) throws {
        // Given
        let endpoints = try CookieNonceAuthenticationEndpoints(siteURL: url("https://example.com"))
        let candidateURL = try url(candidate)

        // When
        let isExpected = endpoints.isExpectedAdminBaseURL(candidateURL)

        // Then
        #expect(isExpected == false)
    }

    @Test func test_redirect_limit_matches_android() {
        // Given
        let androidRedirectLimit = 3

        // When
        let redirectLimit = CookieNonceAuthenticationEndpoints.maximumRedirectCount

        // Then
        #expect(redirectLimit == androidRedirectLimit)
    }
}

private extension CookieNonceAuthenticationEndpointsTests {
    func url(_ value: String) throws -> URL {
        try #require(URL(string: value))
    }

    func validationError<T>(from operation: () throws -> T) -> ValidationError? {
        do {
            _ = try operation()
            return nil
        } catch let error as ValidationError {
            return error
        } catch {
            Issue.record("Unexpected error: \(error)")
            return nil
        }
    }

    func loginForm(action: String) -> String {
        "<form id=\"loginform\" name=\"loginform\" method=\"post\" action=\"\(action)\">" +
            "<input name=\"log\" id=\"user_login\" type=\"text\">" +
            "<input name=\"pwd\" id=\"user_pass\" type=\"password\"></form>"
    }
}
