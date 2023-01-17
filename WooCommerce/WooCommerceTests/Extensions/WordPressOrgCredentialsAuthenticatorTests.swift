import XCTest
import WordPressAuthenticator
@testable import WooCommerce

final class WordPressOrgCredentialsAuthenticatorTests: XCTestCase {

    private let username = "test"
    private let password = "pwd"
    private let xmlrpc = "https://test.com/xmlrpc.php"
    private let options: [AnyHashable: Any] = [
        "login_url": ["value": "http://test.com/wp-login.php"],
        "admin_url": ["value": "https://test.com/wp-admin"],
        "software_version": ["value": "5.3.1"]
    ]

    func test_loginURL_is_correct() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        assertEqual(credentials.loginURL, "http://test.com/wp-login.php")
    }

    func test_adminURL_is_correct() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // Then
        assertEqual(credentials.adminURL, "https://test.com/wp-admin")
    }

    func test_configuration_is_created_correctly() {
        // Given
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)

        // When
        let configuration = credentials.makeCookieNonceAuthenticatorConfig()

        // Then
        XCTAssertNotNil(configuration)
    }

}
