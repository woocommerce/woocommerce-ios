import Foundation
import XCTest
@testable import Networking


/// AuthenticatedRequest Unit Tests
///
class AuthenticatedRequestTests: XCTestCase {

    /// Sample Unauthenticated Request
    ///
    private let unauthenticatedRequest = try! URLRequest(url: "www.automattic.com", method: .get)

    /// Sample Credentials
    ///
    private let credentials = Credentials(username: "username", authToken: "yosemite", siteAddress: "https://wordpress.com")


    /// Verifies that the Bearer Token is injected, as part of the HTTP Headers.
    ///
    func test_bearer_token_is_injected_as_request_header() throws {
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        let authenticated = AuthenticatedRequest(credentials: credentials, request: unauthenticatedRequest)
        let output = try! authenticated.asURLRequest()

        let authToken = try XCTUnwrap(credentials.authToken)

        let generated = output.allHTTPHeaderFields?["Authorization"]
        let expected = "Bearer \(authToken)"
        XCTAssertEqual(generated, expected)
    }

    /// Verifies that the User Agent is injected as part of the HTTP Headers.
    ///
    func test_user_agent_is_injected_as_request_header() {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: unauthenticatedRequest)
        let output = try! authenticated.asURLRequest()

        let generated = output.allHTTPHeaderFields?["User-Agent"]
        XCTAssertEqual(generated, UserAgent.defaultUserAgent)
    }
}
