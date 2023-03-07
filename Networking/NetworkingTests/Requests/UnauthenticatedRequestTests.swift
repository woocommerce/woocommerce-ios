import Foundation
import XCTest
@testable import Networking

/// `UnauthenticatedRequest` Unit Tests
final class UnauthenticatedRequestTests: XCTestCase {
    /// Sample Unauthenticated Request
    private let unauthenticatedRequest = try! URLRequest(url: "www.automattic.com", method: .get)

    /// Verifies that the user-agent is injected as part of the HTTP Headers.
    func test_user_agent_is_injected_as_request_header() throws {
        // Given
        let request = UnauthenticatedRequest(request: unauthenticatedRequest)

        // When
        let urlRequest = request.asURLRequest()

        // Then
        let userAgentHeader = urlRequest.allHTTPHeaderFields?["User-Agent"]
        XCTAssertEqual(userAgentHeader, UserAgent.defaultUserAgent)
    }

    /// Verifies that the `Accept` header is injected, as part of the HTTP Headers.
    func test_accept_is_injected_as_request_header() {
        // Given
        let request = UnauthenticatedRequest(request: unauthenticatedRequest)

        // When
        let urlRequest = request.asURLRequest()

        // Then
        let acceptHeader = urlRequest.allHTTPHeaderFields?["Accept"]
        XCTAssertEqual(acceptHeader, "application/json")
    }
}
