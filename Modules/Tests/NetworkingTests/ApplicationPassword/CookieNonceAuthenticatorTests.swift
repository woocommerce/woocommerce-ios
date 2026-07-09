import XCTest
@testable import Networking
@testable import NetworkingCore
@testable import Alamofire

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

    /// Regression test: when the login sequence aborts with an uncaught error (e.g. the nonce
    /// retrieval returns HTTP 400, as a misconfigured wp-env/Tailscale site does), the authenticator
    /// must reset its internal state so a subsequent 401 can start a fresh login sequence. Previously
    /// the `isAuthenticating` flag was never cleared, so every later retry was enqueued but never run,
    /// leaving requests hanging forever.
    ///
    func test_retry_when_login_sequence_aborts_with_uncaught_error_then_a_subsequent_retry_still_completes() {
        // Given
        let config = CookieNonceAuthenticatorConfiguration(username: sampleUser,
                                                           password: samplePassword,
                                                           loginURL: loginURL,
                                                           adminURL: adminURL)
        let authenticator = CookieNonceAuthenticator(configuration: config)

        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [StubLoginNonceURLProtocol.self]
        let session = Alamofire.Session(configuration: configuration)

        let unauthorizedError = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))

        // When
        /// The first retry drives a full login sequence. `wp-login.php` succeeds but the nonce fetch
        /// returns 400, which surfaces as an uncaught `AFError` inside the login sequence.
        ///
        let firstResult: RetryResult = waitFor { promise in
            authenticator.retry(self.makeRequest(for: session), for: session, dueTo: unauthorizedError) { result in
                promise(result)
            }
        }

        // Then
        /// The first request fails cleanly without retrying.
        ///
        XCTAssertFalse(firstResult.retryRequired)

        // When
        /// A subsequent retry must still invoke its completion handler. Before the fix this call would
        /// hang because the authenticator was stuck in its `isAuthenticating` state.
        ///
        let secondRetryCompleted = expectation(description: "Second retry completion handler is invoked")
        authenticator.retry(makeRequest(for: session), for: session, dueTo: unauthorizedError) { _ in
            secondRetryCompleted.fulfill()
        }

        // Then
        wait(for: [secondRetryCompleted], timeout: Constants.expectationTimeout)
    }
}

// MARK: - Helpers
//
private extension CookieNonceAuthenticatorTests {
    enum Constants {
        static let expectationTimeout: TimeInterval = 10
    }

    /// Builds a retriable request whose URL differs from the login URL so it passes the retrier's guards.
    ///
    func makeRequest(for session: Alamofire.Session) -> StubDataRequest {
        StubDataRequest(convertible: apiRequest,
                        underlyingQueue: .global(),
                        serializationQueue: .global(),
                        eventMonitor: nil,
                        interceptor: nil,
                        delegate: session)
    }
}

/// A `DataRequest` whose `retryCount` and `request` can be controlled for testing the retrier.
///
private final class StubDataRequest: Alamofire.DataRequest, @unchecked Sendable {
    override var retryCount: Int {
        0
    }

    override var request: URLRequest? {
        convertible.urlRequest
    }
}

/// Stubs the two requests the cookie-nonce login sequence makes: `wp-login.php` succeeds, but the
/// `admin-ajax.php?action=rest-nonce` fetch returns the unauthenticated `400 "0"` response a real
/// WordPress site returns when the login cookie did not establish a session.
///
private final class StubLoginNonceURLProtocol: URLProtocol {
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let url = request.url else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        let isLoginRequest = url.path.hasSuffix("wp-login.php")
        let statusCode = isLoginRequest ? 200 : 400
        let body = isLoginRequest ? Data() : Data("0".utf8)

        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocolDidFinishLoading(self)
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: body)
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
