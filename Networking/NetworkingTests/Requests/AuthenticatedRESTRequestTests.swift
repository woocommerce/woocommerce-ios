import Foundation
import XCTest
@testable import Networking

/// AuthenticatedRESTRequest Unit Tests
///
final class AuthenticatedRESTRequestTests: XCTestCase {

    /// Sample Unauthenticated Request
    ///
    private var unauthenticatedRequest: URLRequest!

    /// Sample Application Password
    ///
    private let applicationPassword = ApplicationPassword(wpOrgUsername: "username",
                                                          password: .init("password"),
                                                          uuid: "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e",
                                                          appID: "")

    override func setUp() {
        super.setUp()

        unauthenticatedRequest = try! URLRequest(url: "www.automattic.com", method: .get)
    }

    override func tearDown() {
        unauthenticatedRequest = nil

        super.tearDown()
    }

    /// Verifies that Basic authorization string is injected, as part of the HTTP Headers.
    ///
    func test_basic_is_injected_as_request_header_when_authenticated_using_application_password() throws {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        let authenticated = AuthenticatedRESTRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

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
        let authenticated = AuthenticatedRESTRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

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
        let authenticated = AuthenticatedRESTRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

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
        let authenticated = AuthenticatedRESTRequest(applicationPassword: applicationPassword, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        XCTAssertFalse(output.httpShouldHandleCookies)
    }
}
