import Alamofire
import Combine
import XCTest
@testable import Networking
@testable import NetworkingCore

/// AlamofireNetwork Tests
///
final class AlamofireNetworkTests: XCTestCase {
    private var responseDataSubscription: AnyCancellable?
    private var userDefaults: UserDefaults!
    private let userDefaultsKey = "alamofireNetworkTestsKey"

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)
    }

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

    // MARK: - `didFailToAuthenticateRequestWithAppPassword`

    func test_didFailToAuthenticateRequestWithAppPassword_notSupported_adds_siteID_to_unsupported_list() {
        // Given
        let siteID: Int64 = 123
        let network = AlamofireNetwork(credentials: nil, userDefaults: userDefaults)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        // When
        network.didFailToAuthenticateRequestWithAppPassword(siteID: siteID, reason: .notSupported)

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [siteID])
    }

    func test_didFailToAuthenticateRequestWithAppPassword_notSupported_appends_to_existing_unsupported_list() {
        // Given
        let existingSiteID: Int64 = 456
        let newSiteID: Int64 = 123
        userDefaults.applicationPasswordUnsupportedList = [existingSiteID]
        let network = AlamofireNetwork(credentials: nil, userDefaults: userDefaults)

        // When
        network.didFailToAuthenticateRequestWithAppPassword(siteID: newSiteID, reason: .notSupported)

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [existingSiteID, newSiteID])
    }

    func test_didFailToAuthenticateRequestWithAppPassword_unknown_below_threshold_does_not_add_to_unsupported_list() {
        // Given
        let siteID: Int64 = 123
        let network = AlamofireNetwork(credentials: nil, userDefaults: userDefaults)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        // When - Call 9 times (below threshold of 10)
        for _ in 1...9 {
            network.didFailToAuthenticateRequestWithAppPassword(siteID: siteID, reason: .unknown)
        }

        // Then
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)
    }

    func test_didFailToAuthenticateRequestWithAppPassword_unknown_at_threshold_adds_siteID_to_unsupported_list() {
        // Given
        let siteID: Int64 = 123
        let network = AlamofireNetwork(credentials: nil, userDefaults: userDefaults)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        // When - Call exactly 10 times (threshold)
        for _ in 1...10 {
            network.didFailToAuthenticateRequestWithAppPassword(siteID: siteID, reason: .unknown)
        }

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [siteID])
    }

    func test_didFailToAuthenticateRequestWithAppPassword_unknown_multiple_sites_tracks_separately() {
        // Given
        let siteID1: Int64 = 123
        let siteID2: Int64 = 456
        let network = AlamofireNetwork(credentials: nil, userDefaults: userDefaults)

        // When - Call site1 5 times, site2 10 times
        for _ in 1...5 {
            network.didFailToAuthenticateRequestWithAppPassword(siteID: siteID1, reason: .unknown)
        }
        for _ in 1...10 {
            network.didFailToAuthenticateRequestWithAppPassword(siteID: siteID2, reason: .unknown)
        }

        // Then - Only site2 should be in unsupported list
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [siteID2])
    }
}

private extension AlamofireNetworkTests {
    func createSessionWithMockURLProtocol() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        return Session(configuration: configuration)
    }
}
