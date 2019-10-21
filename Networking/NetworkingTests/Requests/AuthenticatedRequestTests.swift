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
    func testBearerTokenIsInjectedAsRequestHeader() {
        XCTAssertEqual(unauthenticatedRequest.allHTTPHeaderFields, [:])

        let authenticated = AuthenticatedRequest(credentials: credentials, request: unauthenticatedRequest)
        let output = try! authenticated.asURLRequest()

        let generated = output.allHTTPHeaderFields?["Authorization"]
        let expected = "Bearer \(credentials.authToken)"
        XCTAssertEqual(generated, expected)
    }

    /// Verifies that the User Agent is injected as part of the HTTP Headers.
    ///
    func testUserAgentIsInjectedAsRequestHeader() {
        let authenticated = AuthenticatedRequest(credentials: credentials, request: unauthenticatedRequest)
        let output = try! authenticated.asURLRequest()

        let generated = output.allHTTPHeaderFields?["User-Agent"]
        XCTAssertEqual(generated, Settings.userAgent)
    }
}
