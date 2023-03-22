import XCTest
import Alamofire
@testable import Networking

final class DefaultRequestAuthenticatorTests: XCTestCase {

    /// Sample Application Password
    ///
    private let applicationPassword = ApplicationPassword(wpOrgUsername: "username", password: .init("password"), uuid: "8ef68e6b-4670-4cfd-8ca0-456e616bcd5e")

    func test_authenticateRequest_returns_unauthenticated_request_for_non_REST_request_without_WPCOM_credentials() throws {
        // Given
        let authenticator = DefaultRequestAuthenticator(credentials: nil)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        let request = try jetpackRequest.asURLRequest()
        let updatedRequest = try authenticator.authenticate(request)

        // Then
        XCTAssertNil(updatedRequest.allHTTPHeaderFields?["Authorization"])
    }

    func test_authenticatedRequest_returns_authenticated_request_for_non_REST_request_with_WPCOM_credentials() throws {
        // Given
        let credentials = Credentials(authToken: "secret")
        let authenticator = DefaultRequestAuthenticator(credentials: credentials)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        let request = try jetpackRequest.asURLRequest()
        let updatedRequest = try authenticator.authenticate(request)

        // Then
        let authorizationValue = try XCTUnwrap(updatedRequest.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Bearer"))
    }

    func test_authenticatedRequest_returns_REST_request_with_authorization_header_if_application_password_is_available() throws {
        // Given
        let siteURL = "https://test.com/"
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: siteURL)
        let useCase = MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword)
        let authenticator = DefaultRequestAuthenticator(credentials: credentials, applicationPasswordUseCase: useCase)
        let wooAPIVersion = WooAPIVersion.mark1
        let basePath = RESTRequest.Settings.basePath
        let restRequest = RESTRequest(siteURL: siteURL, wooApiVersion: wooAPIVersion, method: .get, path: "test")

        // When
        let request = try restRequest.asURLRequest()
        let updatedRequest = try authenticator.authenticate(request)

        // Then
        let expectedURL = "https://test.com/\(basePath)\(wooAPIVersion.path)test"
        assertEqual(expectedURL, updatedRequest.url?.absoluteString)
        let authorizationValue = try XCTUnwrap(updatedRequest.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Basic"))
    }

    func test_authenticatedRequest_returns_REST_request_with_authorization_header_if_authenticated_with_application_password() throws {
        // Given
        let siteURL = "https://test.com/"
        let credentials: Credentials = .applicationPassword(username: "admin", password: "supersecret", siteAddress: siteURL)
        let useCase = MockApplicationPasswordUseCase(mockApplicationPassword: applicationPassword)
        let authenticator = DefaultRequestAuthenticator(credentials: credentials, applicationPasswordUseCase: useCase)
        let wooAPIVersion = WooAPIVersion.mark1
        let basePath = RESTRequest.Settings.basePath
        let restRequest = RESTRequest(siteURL: siteURL, wooApiVersion: wooAPIVersion, method: .get, path: "test")

        // When
        let request = try restRequest.asURLRequest()
        let updatedRequest = try authenticator.authenticate(request)

        // Then
        let expectedURL = "https://test.com/\(basePath)\(wooAPIVersion.path)test"
        assertEqual(expectedURL, updatedRequest.url?.absoluteString)
        let authorizationValue = try XCTUnwrap(updatedRequest.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Basic"))
    }

    func test_authenticatedRequest_returns_REST_request_with_authorization_header_if_application_password_generation_succeeds() async throws {
        // Given
        let siteURL = "https://test.com/"
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: siteURL)
        let useCase = MockApplicationPasswordUseCase(mockGeneratedPassword: applicationPassword)
        let authenticator = DefaultRequestAuthenticator(credentials: credentials, applicationPasswordUseCase: useCase)
        let wooAPIVersion = WooAPIVersion.mark1
        let basePath = RESTRequest.Settings.basePath
        let restRequest = RESTRequest(siteURL: siteURL, wooApiVersion: wooAPIVersion, method: .get, path: "test")

        // When
        let request = try restRequest.asURLRequest()

        do {
            let _ = try authenticator.authenticate(request)
        } catch RequestAuthenticatorError.applicationPasswordNotAvailable {
            try await authenticator.generateApplicationPassword()
        }

        let updatedRequest = try authenticator.authenticate(request)

        // Then
        let expectedURL = "https://test.com/\(basePath)\(wooAPIVersion.path)test"
        assertEqual(expectedURL, updatedRequest.url?.absoluteString)
        let authorizationValue = try XCTUnwrap(updatedRequest.allHTTPHeaderFields?["Authorization"])
        XCTAssertTrue(authorizationValue.hasPrefix("Basic"))
    }

    func test_authenticatedRequest_returns_error_if_generating_application_password_fails_for_REST_request() async throws {
        // Given
        let siteURL = "https://test.com/"
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: siteURL)
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout)
        let authenticator = DefaultRequestAuthenticator(credentials: credentials, applicationPasswordUseCase: useCase)
        let wooAPIVersion = WooAPIVersion.mark1
        let restRequest = RESTRequest(siteURL: siteURL, wooApiVersion: wooAPIVersion, method: .get, path: "test")

        let exp = expectation(description: "Failed with `NetworkError.timeout` error")

        // When
        let request = try restRequest.asURLRequest()
        do {
            let _ = try authenticator.authenticate(request)
        } catch RequestAuthenticatorError.applicationPasswordNotAvailable {
            // Then
            do {
                try await authenticator.generateApplicationPassword()
                let _ = try authenticator.authenticate(request)
            } catch NetworkError.timeout {
                exp.fulfill()
            }
        }
        await waitForExpectations(timeout: Constants.expectationTimeout, handler: nil)
    }

    func test_shouldRetry_returns_true_for_REST_request() throws {
        // Given
        let siteURL = "https://test.com/"
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: siteURL)
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout)
        let authenticator = DefaultRequestAuthenticator(credentials: credentials, applicationPasswordUseCase: useCase)
        let wooAPIVersion = WooAPIVersion.mark1
        let restRequest = RESTRequest(siteURL: siteURL, wooApiVersion: wooAPIVersion, method: .get, path: "test")

        // When
        let request = try restRequest.asURLRequest()

        // Then
        XCTAssertTrue(authenticator.shouldRetry(request))
    }

    func test_shouldRetry_returns_true_for_non_REST_request() throws {
        // Given
        let siteURL = "https://test.com/"
        let credentials: Credentials = .wporg(username: "admin", password: "supersecret", siteAddress: siteURL)
        let useCase = MockApplicationPasswordUseCase(mockGenerationError: NetworkError.timeout)
        let authenticator = DefaultRequestAuthenticator(credentials: credentials, applicationPasswordUseCase: useCase)
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark1, method: .get, siteID: 123, path: "test", availableAsRESTRequest: false)

        // When
        let request = try jetpackRequest.asURLRequest()

        // Then
        XCTAssertFalse(authenticator.shouldRetry(request))
    }
}

/// MOCK: application password use case
///
private final class MockApplicationPasswordUseCase: ApplicationPasswordUseCase {
    var mockApplicationPassword: ApplicationPassword?
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
            // Store the newly generated password
            mockApplicationPassword = mockGeneratedPassword
            return mockGeneratedPassword
        }
        throw mockGenerationError ?? NetworkError.notFound
    }

    func deletePassword() async throws {
        throw mockDeletionError ?? NetworkError.notFound
    }
}
