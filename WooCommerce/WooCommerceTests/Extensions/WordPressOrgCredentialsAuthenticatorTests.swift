import XCTest
import WebKit
import WordPressAuthenticator
@testable import WooCommerce

@MainActor
final class WordPressOrgCredentialsAuthenticatorTests: XCTestCase {

    private let username = "test"
    private let password = "pwd"
    private let xmlrpc = "https://test.com/xmlrpc.php"
    private let options: [AnyHashable: Any] = [
        "login_url": ["value": "https://test.com/wp-login.php"],
        "admin_url": ["value": "https://test.com/wp-admin"],
        "software_version": ["value": "5.3.1"]
    ]

    func test_loginURL_is_correct() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        assertEqual(credentials.loginURL, "https://test.com/wp-login.php")
    }

    func test_adminURL_is_correct() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        assertEqual(credentials.adminURL, "https://test.com/wp-admin")
    }

    func test_authentication_endpoints_reject_https_to_http_downgrade() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": "http://test.com/wp-login.php"],
            "admin_url": ["value": "https://test.com/wp-admin"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertNil(credentials.authenticationEndpoints)
    }

    func test_default_endpoints_normalize_trailing_slash_without_double_slashes() {
        // Given
        let credentials = WordPressOrgCredentials(
            username: username,
            password: password,
            xmlrpc: "https://test.com//xmlrpc.php",
            options: [:]
        )

        // Then
        XCTAssertEqual(credentials.authenticationEndpoints?.loginEntryURL.absoluteString, "https://test.com/wp-login.php")
        XCTAssertEqual(credentials.authenticationEndpoints?.adminBaseURL.absoluteString, "https://test.com/wp-admin/")
        XCTAssertEqual(credentials.loginURL, "https://test.com/wp-login.php")
        XCTAssertEqual(credentials.adminURL, "https://test.com/wp-admin")
    }

    func test_web_view_authentication_default_redirect_has_exactly_one_admin_path_separator() throws {
        // Given
        let credentials = WordPressOrgCredentials(
            username: username,
            password: password,
            xmlrpc: "https://test.com//xmlrpc.php",
            options: [:]
        )

        // When
        let request = try WKWebView().authenticateForWPOrg(with: credentials)
        let body = try XCTUnwrap(request.httpBody)
        let encodedParameters = try XCTUnwrap(String(data: body, encoding: .utf8))
        var components = URLComponents()
        components.percentEncodedQuery = encodedParameters
        let redirectURL = components.queryItems?.first(where: { $0.name == "redirect_to" })?.value

        // Then
        XCTAssertEqual(redirectURL, "https://test.com/wp-admin/admin-ajax.php?action=rest-nonce")
        XCTAssertFalse(redirectURL?.contains("/wp-admin//admin-ajax.php") == true)
    }

    func test_authentication_endpoints_accept_custom_same_site_options() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": "https://test.com/custom-entry"],
            "admin_url": ["value": "https://test.com/private-admin"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertEqual(credentials.authenticationEndpoints?.loginEntryURL.absoluteString, "https://test.com/custom-entry")
        XCTAssertEqual(credentials.authenticationEndpoints?.adminBaseURL.absoluteString, "https://test.com/private-admin/")
    }

    func test_authentication_endpoints_reject_cross_origin_option() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": "https://attacker.example/wp-login.php"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertNil(credentials.authenticationEndpoints)
    }

    func test_authentication_endpoints_reject_malformed_option_string() {
        // Given
        let options: [AnyHashable: Any] = [
            "login_url": ["value": ":// malformed"]
        ]
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        XCTAssertNil(credentials.authenticationEndpoints)
    }
}
