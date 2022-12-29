import Foundation
import XCTest
import WordPressShared
@testable import Networking

/// AuthenticatedRequest Unit Tests
///
final class AuthenticatedRequestTests: XCTestCase {

    /// Sample Unauthenticated Request
    ///
    private var unauthenticatedRequest: URLRequest!

    /// Sample Credentials
    ///
    private let credentials = Credentials(username: "username", authToken: "yosemite", siteAddress: "https://wordpress.com")

    /// Sample Application Password
    ///
    private let applicationPassword = ApplicationPassword(wpOrgUsername: "username", password: Secret("password"))

    override func setUp() {
        super.setUp()

        unauthenticatedRequest = try! URLRequest(url: "www.automattic.com", method: .get)
    }

    override func tearDown() {
        unauthenticatedRequest = nil

        super.tearDown()
    }

    // MARK: WPCOM Credentials

    /// Verifies that the Bearer Token is injected, as part of the HTTP Headers.
    ///
    func test_bearer_token_is_injected_as_request_header_when_authenticated_using_WPCOM_token() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        guard case let .wpcom(_, authToken, _) = credentials else {
            XCTFail("Missing credentials.")
            return
        }

        let authenticated = AuthenticatedRequest(authToken: authToken, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = output.allHTTPHeaderFields?["Authorization"]
        let expected = "Bearer \(authToken)"
        XCTAssertEqual(generated, expected)
    }

    /// Verifies that the User Agent is injected as part of the HTTP Headers.
    ///
    func test_user_agent_is_injected_as_request_header_when_authenticated_using_WPCOM_token() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        guard case let .wpcom(_, authToken, _) = credentials else {
            XCTFail("Missing credentials.")
            return
        }

        let authenticated = AuthenticatedRequest(authToken: authToken, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = output.allHTTPHeaderFields?["User-Agent"]
        XCTAssertEqual(generated, UserAgent.defaultUserAgent)
    }

    /// Verifies that the `Accept` header is injected, as part of the HTTP Headers.
    ///
    func test_accept_is_injected_as_request_header_when_authenticated_using_WPCOM_token() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        guard case let .wpcom(_, authToken, _) = credentials else {
            XCTFail("Missing credentials.")
            return
        }

        let authenticated = AuthenticatedRequest(authToken: authToken, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = output.allHTTPHeaderFields?["Accept"]
        let expected = "application/json"
        XCTAssertEqual(generated, expected)
    }

    // MARK: Application password

    /// Verifies that Basic authorization string is injected, as part of the HTTP Headers.
    ///
    func test_basic_is_injected_as_request_header_when_authenticated_using_application_password() throws {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        let authenticated = AuthenticatedRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = try XCTUnwrap(output.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(generated.hasPrefix("Basic"))
    }

    /// Verifies that the User Agent is injected as part of the HTTP Headers.
    ///
    func test_user_agent_is_injected_as_request_header_when_authenticated_using_application_password() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])
        let authenticated = AuthenticatedRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = output.allHTTPHeaderFields?["User-Agent"]
        XCTAssertEqual(generated, UserAgent.defaultUserAgent)
    }

    /// Verifies that the `Accept` header is injected, as part of the HTTP Headers.
    ///
    func test_accept_is_injected_as_request_header_when_authenticated_using_application_password() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])
        let authenticated = AuthenticatedRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = output.allHTTPHeaderFields?["Accept"]
        let expected = "application/json"
        XCTAssertEqual(generated, expected)
    }

    /// Verifies that handling cookies is turned off
    ///
    func test_httpShouldHandleCookies_is_false_when_authenticated_using_application_password() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])
        let authenticated = AuthenticatedRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        XCTAssertFalse(output.httpShouldHandleCookies)
    }
}
