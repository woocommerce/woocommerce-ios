import Foundation
import Testing
@testable import Networking
@testable import Yosemite

struct DefaultRetryErrorEvaluatorTests {
    @Test(arguments: [
        URLError(.timedOut),
        URLError(.networkConnectionLost),
        URLError(.notConnectedToInternet),
        URLError(.cannotConnectToHost),
        URLError(.cancelled)
    ])
    func it_retries_url_errors(_ error: URLError) {
        // Given
        let sut = DefaultRetryErrorEvaluator()

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(shouldRetry == true)
    }

    @Test(arguments: [
        NetworkError.unacceptableStatusCode(statusCode: 500, response: nil),
        NetworkError.unacceptableStatusCode(statusCode: 503, response: nil),
        NetworkError.unacceptableStatusCode(statusCode: 429, response: nil),
        NetworkError.unacceptableStatusCode(statusCode: 401, response: nil),
        NetworkError.unacceptableStatusCode(statusCode: 403, response: nil),
        NetworkError.unacceptableStatusCode(statusCode: 404, response: nil),
        NetworkError.unacceptableStatusCode(statusCode: 400, response: nil)
    ])
    func it_retries_network_errors(_ error: NetworkError) {
        // Given
        let sut = DefaultRetryErrorEvaluator()

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(shouldRetry == true)
    }

    @Test func it_does_not_retry_invalid_cookie_nonce_error() {
        // Given
        let sut = DefaultRetryErrorEvaluator()
        let error = NetworkError.invalidCookieNonce

        // When
        let shouldRetry = sut.shouldRetry(error)

        // Then
        #expect(shouldRetry == false)
    }
}
