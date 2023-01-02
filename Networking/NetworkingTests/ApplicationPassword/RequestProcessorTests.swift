import XCTest
@testable import Networking

/// RequestProcessor Unit Tests
///
final class RequestProcessorTests: XCTestCase {
    func test_adapt_authenticates_the_urlrequest() throws {
        // Given
        let mockRequestAuthenticator = MockRequestAuthenticator()
        let sut = RequestProcessor(requestAuthenticator: mockRequestAuthenticator)
        let urlRequest = URLRequest(url: URL(string: "https://test.com/")!)

        // When
        let _ = try sut.adapt(urlRequest)

        // Then
        XCTAssertTrue(mockRequestAuthenticator.authenticateCalled)
    }
}

private class MockRequestAuthenticator: RequestAuthenticator {
    private(set) var authenticateCalled = false

    var credentials: Networking.Credentials? = nil

    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        authenticateCalled = true
        return urlRequest
    }

    func generateApplicationPassword() async throws {
        // Do nothing
    }

    func shouldRetry(_ urlRequest: URLRequest) -> Bool {
        true
    }
}
