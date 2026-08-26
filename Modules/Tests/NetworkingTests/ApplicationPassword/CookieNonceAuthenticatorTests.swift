import Alamofire
import TestKit
import XCTest
@testable import Networking
@testable import NetworkingCore

final class CookieNonceAuthenticatorTests: XCTestCase {

    private let loginURL = URL(string: "https://example.com/wp-login.php")!
    private let adminURL = URL(string: "https://example.com/wp-admin/")!
    private let apiRequest = URLRequest(url: URL(string: "https://example.com/wp-json/")!)
    private let sampleUser = "user123"
    private let samplePassword = "password *+/$&=2+é"

    func test_cookie_nonce_authenticator_encode_parameters_correctly() throws {
        // Given
        let config = CookieNonceAuthenticatorConfiguration(username: sampleUser,
                                                           password: samplePassword,
                                                           loginURL: loginURL,
                                                           adminURL: adminURL)
        let authenticator = CookieNonceAuthenticator(configuration: config)


        let generatedBodyAsData = try XCTUnwrap(authenticator.authenticatedRequest().urlRequest?.httpBody)
        let generatedBodyAsString = try XCTUnwrap(String(data: generatedBodyAsData, encoding: .utf8))
        let generatedBodyParameters = generatedBodyAsString.split(separator: Character("&"))

        // When
        /// Expected parameters with encoded data
        ///
        let expectedParameters = ["log": "user123", "pwd": "password%20*%2B/$%26%3D2%2B%C3%A9", "rememberme": "true"]

        // Then
        /// Note: As of iOS 12 the parameters were being serialized at random positions. That's *why* this test is a bit extra complex!
        ///
        for parameter in generatedBodyParameters {
            let components = parameter.split(separator: Character("="))
            let key = String(components[0])
            let value = String(components[1])

            XCTAssertEqual(value, expectedParameters[key])
        }
    }

    // MARK: - Login sequence failure handling (WOOMOB-3866)

    func test_request_when_login_POST_fails_with_401_then_request_completes_with_original_error() throws {
        // Given
        // A host that responds with HTTP 401 to the wp-login.php POST
        // (instead of the standard WordPress 200 + re-rendered login form).
        let session = makeSessionWithMockURLProtocol(interceptor: makeAuthenticator())
        MockURLProtocol.Mocks.mockResponse(["error": "unauthorized"], statusCode: 401, for: apiRequest)
        MockURLProtocol.Mocks.mockResponse(["error": "captcha_required"], statusCode: 401, for: URLRequest(url: loginURL))

        // When
        let error: Error? = waitFor { promise in
            session.request(self.apiRequest)
                .validate()
                .response { response in
                    promise(response.error)
                }
        }

        // Then
        let afError = try XCTUnwrap(error as? AFError)
        guard case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = afError else {
            return XCTFail("Expected a 401 validation error, got \(afError)")
        }
    }

    func test_request_when_login_sequence_previously_failed_with_unexpected_error_then_subsequent_request_completes() throws {
        // Given
        // A first request has already gone through a login sequence whose wp-login.php POST
        // failed with an unexpected 401. Before the fix, this left the authenticator stuck in
        // the authenticating state, so any subsequent 401 request would hang forever.
        let session = makeSessionWithMockURLProtocol(interceptor: makeAuthenticator())
        MockURLProtocol.Mocks.mockResponse(["error": "unauthorized"], statusCode: 401, for: apiRequest)
        MockURLProtocol.Mocks.mockResponse(["error": "captcha_required"], statusCode: 401, for: URLRequest(url: loginURL))
        _ = waitFor { promise in
            session.request(self.apiRequest)
                .validate()
                .response { response in
                    promise(response.error)
                }
        }

        // When
        let error: Error? = waitFor { promise in
            session.request(self.apiRequest)
                .validate()
                .response { response in
                    promise(response.error)
                }
        }

        // Then
        let afError = try XCTUnwrap(error as? AFError)
        guard case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = afError else {
            return XCTFail("Expected a 401 validation error, got \(afError)")
        }
    }
}

private extension CookieNonceAuthenticatorTests {
    func makeAuthenticator() -> CookieNonceAuthenticator {
        let config = CookieNonceAuthenticatorConfiguration(username: sampleUser,
                                                           password: samplePassword,
                                                           loginURL: loginURL,
                                                           adminURL: adminURL)
        return CookieNonceAuthenticator(configuration: config)
    }

    func makeSessionWithMockURLProtocol(interceptor: RequestInterceptor) -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        return Session(configuration: configuration, interceptor: interceptor)
    }
}
