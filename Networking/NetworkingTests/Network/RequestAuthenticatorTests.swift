import XCTest
import Alamofire
@testable import Networking

final class RequestAuthenticatorTests: XCTestCase {

    func test_authenticateRequest_returns_unauthenticated_request_for_non_REST_request_without_WPCOM_credentials() {
        // Given
        let authenticator = RequestAuthenticator(credentials: nil)
        let request = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test")

        // When
        var result: URLRequestConvertible?
        authenticator.authenticateRequest(request) { updatedRequest in
            result = updatedRequest
        }

        // Then
        XCTAssertTrue(result is UnauthenticatedRequest)
    }

    func test_authenticatedRequest_returns_authenticated_request_for_non_REST_request_with_WPCOM_credentials() {
        // Given
        let credentials = Credentials(authToken: "secret")
        let authenticator = RequestAuthenticator(credentials: credentials)
        let request = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test")

        // When
        var result: URLRequestConvertible?
        authenticator.authenticateRequest(request) { updatedRequest in
            result = updatedRequest
        }

        // Then
        XCTAssertTrue(result is AuthenticatedRequest)
    }

    func test_authenticatedRequest_returns_REST_request_with_authorization_header_if_application_password_is_available() throws {
        // Given
        let credentials = Credentials(authToken: "secret")
        let applicationPassword = ApplicationPassword(wpOrgUsername: "admin", password: .init("supersecret"))
        let authenticator = RequestAuthenticator(credentials: credentials)
        let useCase = MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword)
        let fallbackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test")
        let restRequest = RESTRequest(siteURL: "https://test.com", method: .get, path: "/test", fallbackRequest: fallbackRequest)

        // When
        var result: URLRequestConvertible?
        authenticator.updateApplicationPasswordHandler(with: useCase)
        waitForExpectation { expectation in
            authenticator.authenticateRequest(restRequest) { updatedRequest in
                result = updatedRequest
                expectation.fulfill()
            }
        }

        // Then
        let request = try XCTUnwrap(result as? URLRequest)
        let expectedURL = "https://test.com/test"
        assertEqual(expectedURL, request.url?.absoluteString)
        let authorizationValue = try XCTUnwrap(request.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Basic"))
    }

    func test_authenticatedRequest_returns_REST_request_with_authorization_header_if_application_password_generation_succeeds() throws {
        // Given
        let credentials = Credentials(authToken: "secret")
        let applicationPassword = ApplicationPassword(wpOrgUsername: "admin", password: .init("supersecret"))
        let authenticator = RequestAuthenticator(credentials: credentials)
        let useCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let fallbackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test")
        let restRequest = RESTRequest(siteURL: "https://test.com", method: .get, path: "/test", fallbackRequest: fallbackRequest)

        // When
        var result: URLRequestConvertible?
        authenticator.updateApplicationPasswordHandler(with: useCase)
        waitForExpectation { expectation in
            authenticator.authenticateRequest(restRequest) { updatedRequest in
                result = updatedRequest
                expectation.fulfill()
            }
        }

        // Then
        let request = try XCTUnwrap(result as? URLRequest)
        let expectedURL = "https://test.com/test"
        assertEqual(expectedURL, request.url?.absoluteString)
        let authorizationValue = try XCTUnwrap(request.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Basic"))
    }

    func test_authenticatedRequest_returns_fallback_request_if_generating_application_password_fails_for_REST_request() {
        // Given
        let credentials = Credentials(authToken: "secret")
        let authenticator = RequestAuthenticator(credentials: credentials)
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout)
        let fallbackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test")
        let restRequest = RESTRequest(siteURL: "https://test.com", method: .get, path: "/test", fallbackRequest: fallbackRequest)

        // When
        var result: URLRequestConvertible?
        authenticator.updateApplicationPasswordHandler(with: useCase)
        waitForExpectation { expectation in
            authenticator.authenticateRequest(restRequest) { updatedRequest in
                result = updatedRequest
                expectation.fulfill()
            }
        }

        // Then
        XCTAssertTrue(result is AuthenticatedRequest)
        let expectedURL = "https://public-api.wordpress.com/rest/v1.1/jetpack-blogs/123/rest-api/?json=true&path=/wc/v1/test%26_method%3Dget"
        assertEqual(expectedURL, result?.urlRequest?.url?.absoluteString)
    }
}

/// MOCK: application password use case
///
private final class MockApplicationPasswordUseCase: ApplicationPasswordUseCase {
    let mockApplicationPassword: ApplicationPassword?
    let mockGeneratedPassword: ApplicationPassword?
    let mockGenerationError: Error?
    let mockDeletionError: Error?
    init(mockApplicationPassword: ApplicationPassword? = nil,
         mockGeneratedPassword: ApplicationPassword? = nil,
         mockGenerationError: Error? = nil,
         mockDeletionError: Error? = nil) {
        self.mockApplicationPassword = mockApplicationPassword
        self.mockGeneratedPassword = mockGeneratedPassword
        self.mockGenerationError = mockGenerationError
        self.mockDeletionError = mockDeletionError
    }

    var applicationPassword: Networking.ApplicationPassword? {
        mockApplicationPassword
    }

    func generateNewPassword() async throws -> Networking.ApplicationPassword {
        if let mockGeneratedPassword {
            return mockGeneratedPassword
        }
        throw mockGenerationError ?? NetworkError.notFound
    }

    func deletePassword() async throws {
        throw mockDeletionError ?? NetworkError.notFound
    }
}
