import XCTest
import Alamofire
@testable import Networking

final class RequestAuthenticatorTests: XCTestCase {

    func test_authenticateRequest_returns_unauthenticated_request_for_non_REST_request_without_WPCOM_credentials() {
        // Given
        let authenticator = RequestAuthenticator(credentials: nil)
        let request = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        var updatedRequest: URLRequestConvertible?
        authenticator.authenticateRequest(request) { result in
            updatedRequest = try? result.get()
        }

        // Then
        XCTAssertTrue(updatedRequest is UnauthenticatedRequest)
    }

    func test_authenticatedRequest_returns_authenticated_request_for_non_REST_request_with_WPCOM_credentials() {
        // Given
        let credentials = Credentials(authToken: "secret")
        let authenticator = RequestAuthenticator(credentials: credentials)
        let request = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        var updatedRequest: URLRequestConvertible?
        authenticator.authenticateRequest(request) { result in
            updatedRequest = try? result.get()
        }

        // Then
        XCTAssertTrue(updatedRequest is AuthenticatedRequest)
    }

    func test_authenticatedRequest_returns_REST_request_with_authorization_header_if_application_password_is_available() throws {
        // Given
        let credentials = Credentials(authToken: "secret")
        let applicationPassword = ApplicationPassword(wpOrgUsername: "admin", password: .init("supersecret"))
        let authenticator = RequestAuthenticator(credentials: credentials)
        let useCase = MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        var updatedRequest: URLRequestConvertible?
        authenticator.updateApplicationPasswordHandler(with: useCase)
        waitForExpectation { expectation in
            authenticator.authenticateRequest(jetpackRequest) { result in
                updatedRequest = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        let request = try XCTUnwrap(updatedRequest as? URLRequest)
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
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        var updatedRequest: URLRequestConvertible?
        authenticator.updateApplicationPasswordHandler(with: useCase)
        waitForExpectation { expectation in
            authenticator.authenticateRequest(jetpackRequest) { result in
                updatedRequest = try? result.get()
                expectation.fulfill()
            }
        }

        // Then
        let request = try XCTUnwrap(updatedRequest as? URLRequest)
        let expectedURL = "https://test.com/test"
        assertEqual(expectedURL, request.url?.absoluteString)
        let authorizationValue = try XCTUnwrap(request.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Basic"))
    }

    func test_authenticatedRequest_returns_error_if_generating_application_password_fails_for_REST_request() throws {
        // Given
        let credentials = Credentials(authToken: "secret")
        let authenticator = RequestAuthenticator(credentials: credentials)
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: true)

        // When
        var error: Error?
        authenticator.updateApplicationPasswordHandler(with: useCase)
        waitForExpectation { expectation in
            authenticator.authenticateRequest(jetpackRequest) { result in
                error = result.failure
                expectation.fulfill()
            }
        }

        // Then
        let networkError = try XCTUnwrap(error as? NetworkError)
        XCTAssertEqual(networkError, NetworkError.timeout)
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
