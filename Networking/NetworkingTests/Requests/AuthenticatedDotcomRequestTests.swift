import Foundation
import XCTest
import WordPressShared
@testable import Networking

/// AuthenticatedDotcomRequest Unit Tests
///
final class AuthenticatedDotcomRequestTests: XCTestCase {

    /// Sample Unauthenticated Request
    ///
    private var unauthenticatedRequest: URLRequest!

    /// Sample Credentials
    ///
    private let credentials = Credentials(username: "username", authToken: "yosemite", siteAddress: "https://wordpress.com")

    override func setUp() {
        super.setUp()

        unauthenticatedRequest = try! URLRequest(url: "www.automattic.com", method: .get)
    }

    override func tearDown() {
        unauthenticatedRequest = nil

        super.tearDown()
    }

    /// Verifies that the Bearer Token is injected, as part of the HTTP Headers.
    ///
    func test_bearer_token_is_injected_as_request_header_when_authenticated_using_WPCOM_token() {
        // Given
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        guard case let .wpcom(_, authToken, _) = credentials else {
            XCTFail("Missing credentials.")
            return
        }

        let authenticated = AuthenticatedDotcomRequest(authToken: authToken, request: unauthenticatedRequest)

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

        let authenticated = AuthenticatedDotcomRequest(authToken: authToken, request: unauthenticatedRequest)

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

        let authenticated = AuthenticatedDotcomRequest(authToken: authToken, request: unauthenticatedRequest)

        // When
        let output = authenticated.asURLRequest()

        // Then
        let generated = output.allHTTPHeaderFields?["Accept"]
        let expected = "application/json"
        XCTAssertEqual(generated, expected)
    }
}
