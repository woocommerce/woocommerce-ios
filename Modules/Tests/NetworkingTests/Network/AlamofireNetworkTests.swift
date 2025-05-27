import Alamofire
import Combine
import XCTest
@testable import Networking

/// AlamofireNetwork Tests
///
final class AlamofireNetworkTests: XCTestCase {
    private var responseDataSubscription: AnyCancellable?

    // MARK: - `responseData` with data and error in the callback

    func test_responseData_completion_block_returns_NetworkError_unacceptableStatusCode_when_status_code_is_invalid() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "http_request_failed"], statusCode: 401, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let error = waitFor { promise in
            network.responseData(for: request) { data, error in
                promise(error)
            }
        }

        // Then
        let responseData = try JSONSerialization.data(withJSONObject: ["error": "http_request_failed"])
        assertEqual(NetworkError.unacceptableStatusCode(statusCode: 401, response: responseData), error as? NetworkError)
    }

    func test_responseData_completion_block_returns_NetworkError_notFound_when_status_code_is_404() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "not_found"], statusCode: 404, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let error = waitFor { promise in
            network.responseData(for: request) { data, error in
                promise(error)
            }
        }

        // Then
        let responseData = try JSONSerialization.data(withJSONObject: ["error": "not_found"])
        assertEqual(NetworkError.notFound(response: responseData), error as? NetworkError)
    }

    func test_responseData_completion_block_returns_nil_error_when_status_code_is_200() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "http_request_failed"], statusCode: 200, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let error = waitFor { promise in
            network.responseData(for: request) { data, error in
                promise(error)
            }
        }

        // Then
        XCTAssertNil(error)
    }

    // MARK: - `responseData` with `Result` in the callback

    func test_responseData_completion_result_returns_NetworkError_unacceptableStatusCode_when_status_code_is_invalid() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "http_request_failed"], statusCode: 500, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let result = waitFor { promise in
            network.responseData(for: request) { result in
                promise(result)
            }
        }

        // Then
        let responseData = try JSONSerialization.data(withJSONObject: ["error": "http_request_failed"])
        assertEqual(NetworkError.unacceptableStatusCode(statusCode: 500, response: responseData), result.failure as? NetworkError)
    }

    func test_responseData_completion_result_returns_success_when_status_code_is_200() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "http_request_failed"], statusCode: 200, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let result = waitFor { promise in
            network.responseData(for: request) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }

    // MARK: - `responseDataPublisher`

    func test_responseDataPublisher_returns_NetworkError_unacceptableStatusCode_when_status_code_is_invalid() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "http_request_failed"], statusCode: 500, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let result = waitFor { promise in
            self.responseDataSubscription = network.responseDataPublisher(for: request)
                .sink { result in
                    promise(result)
                }
        }

        // Then
        let responseData = try JSONSerialization.data(withJSONObject: ["error": "http_request_failed"])
        assertEqual(NetworkError.unacceptableStatusCode(statusCode: 500, response: responseData), result.failure as? NetworkError)
    }

    func test_responseDataPublisher_returns_success_when_status_code_is_200() throws {
        // Given
        let request = JetpackRequest(wooApiVersion: .mark1,
                                     method: .get,
                                     siteID: 1,
                                     path: "test")
        let urlRequest = try XCTUnwrap(try? request.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "http_request_failed"], statusCode: 200, for: urlRequest)

        // When
        let network = AlamofireNetwork(credentials: nil, sessionManager: createSessionWithMockURLProtocol())
        let result = waitFor { promise in
            self.responseDataSubscription = network.responseDataPublisher(for: request)
                .sink { result in
                    promise(result)
                }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
    }
}

private extension AlamofireNetworkTests {
    func createSessionWithMockURLProtocol() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        return Session(configuration: configuration)
    }
}
