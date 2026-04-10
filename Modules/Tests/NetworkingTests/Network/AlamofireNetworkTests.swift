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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())
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

    func test_didFailToAuthenticateRequestWithAppPassword_adds_siteID_to_unsupported_list() {
        // Given
        let siteID: Int64 = 123
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, userDefaults: userDefaults)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        // When
        network.didFailToAuthenticateRequestWithAppPassword(siteID: siteID, error: NetworkError.notFound(response: nil))

        // Then
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_didFailToAuthenticateRequestWithAppPassword_appends_to_existing_unsupported_list() {
        // Given
        let existingSiteID: Int64 = 456
        let newSiteID: Int64 = 123
        userDefaults.applicationPasswordUnsupportedList = [String(existingSiteID): Date()]
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, userDefaults: userDefaults)

        // When
        network.didFailToAuthenticateRequestWithAppPassword(siteID: newSiteID, error: NetworkError.notFound(response: nil))

        // Then
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(existingSiteID)))
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(newSiteID)))
    }

    // MARK: - Session Initialization Tests

    func test_concurrent_requests_do_not_fail_with_sessionDeinitialized_error() async throws {
        // Given
        let url = try XCTUnwrap(URL(string: "http://localhost:991929281"))
        let request = URLRequest(url: url, timeoutInterval: 0.001)
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil)

        // When
        async let request1 = network.responseDataAndHeaders(for: request)
        async let request2 = network.responseDataAndHeaders(for: request)
        async let request3 = network.responseDataAndHeaders(for: request)

        do {
            _ = try await [request1, request2, request3]
            XCTFail("Requests should fail")
        } catch Alamofire.AFError.sessionDeinitialized {
            XCTFail("Requests should not fail with sessionDeinitialized error")
        } catch {
            // Then
            XCTAssertTrue(true)
        }
    }

    // MARK: - Retry Logic Tests

    func test_responseData_with_completion_retries_direct_request_when_converted_request_fails() throws {
        // Given
        let siteID: Int64 = 123
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "products")
        let restRequest = createRESTRequest(path: "products")
        let network = createNetworkWithSelectedSite(siteID: siteID)

        try setupMockForDirectRequestFailure(jetpackRequest: jetpackRequest,
                                             restRequest: restRequest,
                                             failureStatusCode: 401,
                                             failureResponse: ["error": "unauthorized"])

        // When
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        let responseDict = try JSONSerialization.jsonObject(with: result.0!, options: []) as? [String: String]
        XCTAssertEqual(responseDict?["success"], "data")
    }

    func test_responseData_with_result_retries_direct_request_when_converted_request_fails() throws {
        // Given
        let siteID: Int64 = 456
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "orders")
        let restRequest = createRESTRequest(path: "orders")
        let network = createNetworkWithSelectedSite(siteID: siteID)

        try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                             restRequest: restRequest,
                                                             failureStatusCode: 403,
                                                             failureResponse: ["error": "forbidden"],
                                                             successResponse: ["success": "orders"])

        // When
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { result in
                promise(result)
            }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let data = try XCTUnwrap(result.get())
        let responseDict = try JSONSerialization.jsonObject(with: data, options: []) as? [String: String]
        XCTAssertEqual(responseDict?["success"], "orders")
    }

    func test_responseData_flags_site_as_unsupported_when_jetpack_retry_succeeds_after_401_failure() throws {
        // Given
        let siteID: Int64 = 789
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "customers")
        let restRequest = createRESTRequest(path: "customers")
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                             restRequest: restRequest,
                                                             failureStatusCode: 401,
                                                             failureResponse: ["error": "unauthorized"],
                                                             successResponse: ["success": "customers"])

        // When
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_responseDataAndHeaders_retries_direct_request_when_converted_request_fails() async throws {
        // Given
        let siteID: Int64 = 101
        let testParameters = ["name": "Test Product"]
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "products", method: .post, parameters: testParameters)
        let restRequest = createRESTRequest(path: "products", method: .post, parameters: testParameters)
        let network = createNetworkWithSelectedSite(siteID: siteID)

        try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                             restRequest: restRequest,
                                                             failureStatusCode: 429,
                                                             failureResponse: ["error": "rate_limited"],
                                                             successResponse: ["product": "created"])

        // When
        let result = try await network.responseDataAndHeaders(for: jetpackRequest)

        // Then
        let responseDict = try JSONSerialization.jsonObject(with: result.0, options: []) as? [String: String]
        XCTAssertEqual(responseDict?["product"], "created")
    }

    func test_responseDataAndHeaders_flags_site_as_unsupported_when_jetpack_retry_succeeds_after_403_failure() async throws {
        // Given
        let siteID: Int64 = 202
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "reports")
        let restRequest = createRESTRequest(path: "reports")
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                             restRequest: restRequest,
                                                             failureStatusCode: 403,
                                                             failureResponse: ["error": "forbidden"],
                                                             successResponse: ["reports": "data"])

        // When
        let result = try await network.responseDataAndHeaders(for: jetpackRequest)

        // Then
        let responseDict = try JSONSerialization.jsonObject(with: result.0, options: []) as? [String: String]
        XCTAssertEqual(responseDict?["reports"], "data")
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_responseDataPublisher_retries_direct_request_when_converted_request_fails() {
        // Given
        let siteID: Int64 = 303
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "settings")
        let restRequest = createRESTRequest(path: "settings")
        let network = createNetworkWithSelectedSite(siteID: siteID)

        try! setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                              restRequest: restRequest,
                                                              failureStatusCode: 500,
                                                              failureResponse: ["error": "server_error"],
                                                              successResponse: ["settings": "values"])

        // When
        let result = waitFor { promise in
            self.responseDataSubscription = network.responseDataPublisher(for: jetpackRequest)
                .sink { result in
                    promise(result)
                }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        let data = try! result.get()
        let responseDict = try! JSONSerialization.jsonObject(with: data, options: []) as! [String: String]
        XCTAssertEqual(responseDict["settings"], "values")
    }

    func test_responseDataPublisher_flags_site_as_unsupported_when_jetpack_retry_succeeds_after_429_failure() {
        // Given
        let siteID: Int64 = 404
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "stats")
        let restRequest = createRESTRequest(path: "stats")
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        try! setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                              restRequest: restRequest,
                                                              failureStatusCode: 429,
                                                              failureResponse: ["error": "rate_limited"],
                                                              successResponse: ["stats": "data"])

        // When
        let result = waitFor { promise in
            self.responseDataSubscription = network.responseDataPublisher(for: jetpackRequest)
                .sink { result in
                    promise(result)
                }
        }

        // Then
        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_uploadMultipartFormData_retries_direct_request_when_converted_request_fails() {
        // Given
        let siteID: Int64 = 505
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "media", method: .post)
        let restRequest = createRESTRequest(path: "media", method: .post)
        let network = createNetworkWithSelectedSite(siteID: siteID)

        try! setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                              restRequest: restRequest,
                                                              failureStatusCode: 400,
                                                              failureResponse: ["error": "upload_failed"],
                                                              successResponse: ["media": "uploaded"])

        // When
        let result = waitFor { promise in
            network.uploadMultipartFormData(multipartFormData: { formData in
                let testData = "test data".data(using: .utf8)!
                formData.append(testData, withName: "file")
            }, to: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        let responseDict = try! JSONSerialization.jsonObject(with: result.0!, options: []) as! [String: String]
        XCTAssertEqual(responseDict["media"], "uploaded")
    }

    func test_uploadMultipartFormData_flags_site_as_unsupported_when_jetpack_retry_succeeds_after_failure() {
        // Given
        let siteID: Int64 = 606
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "media", method: .post)
        let restRequest = createRESTRequest(path: "media", method: .post)
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        try! setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                              restRequest: restRequest,
                                                              failureStatusCode: 401,
                                                              failureResponse: ["error": "unauthorized"],
                                                              successResponse: ["upload": "success"])

        // When
        let result = waitFor { promise in
            network.uploadMultipartFormData(multipartFormData: { formData in
                let imageData = "fake image data".data(using: .utf8)!
                formData.append(imageData, withName: "image")
            }, to: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    // MARK: - Application Password Error Code Tests

    func test_responseData_flags_site_as_unsupported_when_jetpack_retry_succeeds_after_application_passwords_disabled_error() throws {
        // Given
        let siteID: Int64 = 707
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "plugins")
        let restRequest = createRESTRequest(path: "plugins")
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                             restRequest: restRequest,
                                                             failureStatusCode: 400,
                                                             failureResponse: [
                                                                "code": "application_passwords_disabled",
                                                                "message": "Application passwords are disabled"
                                                             ],
                                                             successResponse: ["plugins": "list"])

        // When
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_responseData_increments_failure_count_when_jetpack_retry_succeeds_after_unknown_error() throws {
        // Given
        let siteID: Int64 = 808
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "system_status")
        let restRequest = createRESTRequest(path: "system_status")
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                             restRequest: restRequest,
                                                             failureStatusCode: 400,
                                                             failureResponse: [
                                                                "code": "unknown_error",
                                                                "message": "Some unknown error"
                                                             ],
                                                             successResponse: ["status": "ok"])

        // When - Call once, should not flag site yet
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then
        XCTAssertNil(result.1)
        XCTAssertNotNil(result.0)
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)
    }

    func test_responseData_flags_site_as_unsupported_when_unknown_error_threshold_reached() throws {
        // Given
        let siteID: Int64 = 909
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        // When - Call 10 times to reach threshold
        for i in 1...10 {
            let jetpackRequest = createJetpackRequest(siteID: siteID, path: "test_\(i)")
            let restRequest = createRESTRequest(path: "test_\(i)")

            try setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: jetpackRequest,
                                                                 restRequest: restRequest,
                                                                 failureStatusCode: 400,
                                                                 failureResponse: [
                                                                    "code": "random_error",
                                                                    "message": "Random error \(i)"
                                                                 ],
                                                                 successResponse: ["result": "success_\(i)"])

            let result = waitFor { promise in
                network.responseData(for: jetpackRequest) { data, error in
                    promise((data, error))
                }
            }

            XCTAssertNil(result.1)
            XCTAssertNotNil(result.0)
        }

        // Then
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_responseData_does_not_retry_when_jetpack_request_not_available_as_rest() throws {
        // Given
        let siteID: Int64 = 111
        let jetpackRequest = JetpackRequest(wooApiVersion: .mark3,
                                            method: .get,
                                            siteID: siteID,
                                            path: "test",
                                            availableAsRESTRequest: false)
        let network = createNetworkWithSelectedSite(siteID: siteID, userDefaults: userDefaults)

        // Mock Jetpack request to fail
        let jetpackUrlRequest = try XCTUnwrap(try? jetpackRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "failed"], statusCode: 400, for: jetpackUrlRequest)

        // When
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then - Should return error without retrying
        XCTAssertNotNil(result.1)
        let networkError = result.1 as? NetworkError
        XCTAssertEqual(networkError?.errorCode, "failed")
    }

    func test_responseData_does_not_retry_when_credentials_not_wpcom() throws {
        // Given
        let siteID: Int64 = 333
        let restRequest = createRESTRequest(path: "test")
        let wporgCredentials = Credentials.wporg(username: "user", password: "pass", siteAddress: "https://example.com")
        let network = createNetworkWithSelectedSite(siteID: siteID, credentials: wporgCredentials, userDefaults: userDefaults)

        // Mock Jetpack request to fail
        let urlRequest = try XCTUnwrap(try? restRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "failed"], statusCode: 400, for: urlRequest)

        // When
        let result = waitFor { promise in
            network.responseData(for: restRequest) { data, error in
                promise((data, error))
            }
        }

        // Then - Should return error without retrying
        XCTAssertNotNil(result.1)
        let networkError = result.1 as? NetworkError
        XCTAssertEqual(networkError?.errorCode, "failed")
    }

    func test_responseData_does_not_retry_when_no_selected_site_injected() throws {
        // Given
        let siteID: Int64 = 333
        let jetpackRequest = createJetpackRequest(siteID: siteID, path: "test")
        let wpcomCredentials = createWPComCredentials()
        let network = AlamofireNetwork(credentials: wpcomCredentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol())

        // Mock Jetpack request to fail
        let jetpackUrlRequest = try XCTUnwrap(try? jetpackRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["error": "failed"], statusCode: 400, for: jetpackUrlRequest)

        // When
        let result = waitFor { promise in
            network.responseData(for: jetpackRequest) { data, error in
                promise((data, error))
            }
        }

        // Then - Should return error without retrying since no selected site means no request conversion
        XCTAssertNotNil(result.1)
        let networkError = result.1 as? NetworkError
        XCTAssertEqual(networkError?.errorCode, "failed")
    }

    // MARK: - Discovery Logic Tests

    func test_discovery_is_triggered_with_siteAddress_for_wporg_credentials() async {
        // Given
        let siteAddress = "https://wporg-site.example.com"
        let credentials = Credentials.wporg(username: "user", password: "pass", siteAddress: siteAddress)
        let expectation = expectation(description: "Discovery called")
        var discoveredURL: String?

        // When
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol(),
                                       discoveryHandler: { siteURL in
                                           discoveredURL = siteURL
                                           expectation.fulfill()
                                       })
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(discoveredURL, siteAddress)
        _ = network
    }

    func test_discovery_is_triggered_with_siteAddress_for_applicationPassword_credentials() async {
        // Given
        let siteAddress = "https://apppw-site.example.com"
        let credentials = Credentials.applicationPassword(username: "user", password: "pass", siteAddress: siteAddress)
        let expectation = expectation(description: "Discovery called")
        var discoveredURL: String?

        // When
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol(),
                                       discoveryHandler: { siteURL in
                                           discoveredURL = siteURL
                                           expectation.fulfill()
                                       })
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(discoveredURL, siteAddress)
    }

    func test_discovery_is_triggered_with_siteAddress_for_wpcom_credentials() async {
        // Given
        let siteAddress = "https://wpcom-site.example.com"
        let credentials = Credentials.wpcom(username: "user", authToken: "token", siteAddress: siteAddress)
        let expectation = expectation(description: "Discovery called")
        var discoveredURL: String?

        // When
        let network = AlamofireNetwork(credentials: credentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol(),
                                       discoveryHandler: { siteURL in
                                           discoveredURL = siteURL
                                           expectation.fulfill()
                                       })
        await fulfillment(of: [expectation], timeout: 1.0)

        // Then
        XCTAssertEqual(discoveredURL, siteAddress)
    }

    func test_discovery_is_not_triggered_when_credentials_are_nil() async {
        // Given
        let expectation = expectation(description: "Discovery should not be called")
        expectation.isInverted = true

        // When
        let network = AlamofireNetwork(credentials: nil,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol(),
                                       discoveryHandler: { _ in expectation.fulfill() })
        await fulfillment(of: [expectation], timeout: 0.1)

        // Then — expectation is inverted; reaching here means the handler was never called
        _ = network
    }

    // MARK: - Authentication Mode Tests

    func test_authenticationMode_is_appPasswords_for_wporg_credentials() {
        // Given
        let wporgCredentials = Credentials.wporg(username: "user", password: "pass", siteAddress: "https://example.com")

        // When
        let network = AlamofireNetwork(credentials: wporgCredentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol())

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should be set")
        DispatchQueue.main.async {
            XCTAssertEqual(network.authenticationMode, .appPasswords)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_is_appPasswords_for_applicationPassword_credentials() {
        // Given
        let appPasswordCredentials = Credentials.applicationPassword(username: "user", password: "pass", siteAddress: "https://example.com")

        // When
        let network = AlamofireNetwork(credentials: appPasswordCredentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol())

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should be set")
        DispatchQueue.main.async {
            XCTAssertEqual(network.authenticationMode, .appPasswords)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_is_jetpackTunnel_for_wpcom_credentials() {
        // Given
        let wpcomCredentials = createWPComCredentials()

        // When
        let network = AlamofireNetwork(credentials: wpcomCredentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol())

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should be set")
        DispatchQueue.main.async {
            XCTAssertEqual(network.authenticationMode, .jetpackTunnel)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_is_nil_for_no_credentials() {
        // When
        let network = AlamofireNetwork(credentials: nil, selectedSite: nil, appPasswordSupportState: nil, sessionManager: createSessionWithMockURLProtocol())

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should be set")
        DispatchQueue.main.async {
            XCTAssertNil(network.authenticationMode)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_changes_to_appPasswordsWithJetpack_when_app_password_switching_enabled() {
        // Given
        let siteID: Int64 = 123
        let wpcomCredentials = createWPComCredentials()
        let appPasswordSupportStream = CurrentValueSubject<Bool, Never>(false)
        let network = createNetworkWithSelectedSite(
            siteID: siteID,
            credentials: wpcomCredentials,
            userDefaults: userDefaults,
            appPasswordSupport: appPasswordSupportStream.eraseToAnyPublisher()
        )

        // When - Enable app password switching
        appPasswordSupportStream.send(true)

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should change")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(network.authenticationMode, .appPasswordsWithJetpack)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_reverts_to_jetpackTunnel_when_app_password_switching_disabled() {
        // Given
        let siteID: Int64 = 456
        let wpcomCredentials = createWPComCredentials()
        let appPasswordSupportStream = CurrentValueSubject<Bool, Never>(false)
        let network = createNetworkWithSelectedSite(
            siteID: siteID,
            credentials: wpcomCredentials,
            userDefaults: userDefaults,
            appPasswordSupport: appPasswordSupportStream.eraseToAnyPublisher()
        )

        // When - Enable then disable app password switching
        appPasswordSupportStream.send(true)
        appPasswordSupportStream.send(false)

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should revert")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(network.authenticationMode, .jetpackTunnel)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_remains_jetpackTunnel_when_site_flagged_as_unsupported() {
        // Given
        let siteID: Int64 = 789
        let wpcomCredentials = createWPComCredentials()
        let appPasswordSupportStream = CurrentValueSubject<Bool, Never>(false)
        userDefaults.applicationPasswordUnsupportedList = [String(siteID): Date()]
        let network = createNetworkWithSelectedSite(
            siteID: siteID,
            credentials: wpcomCredentials,
            userDefaults: userDefaults,
            appPasswordSupport: appPasswordSupportStream.eraseToAnyPublisher()
        )

        // When - Enable app password switching for an unsupported site
        appPasswordSupportStream.send(true)

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should remain jetpackTunnel")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(network.authenticationMode, .jetpackTunnel)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }

    func test_authenticationMode_does_not_change_for_non_wpcom_credentials() {
        // Given
        let wporgCredentials = Credentials.wporg(username: "user", password: "pass", siteAddress: "https://example.com")
        let network = AlamofireNetwork(credentials: wporgCredentials,
                                       selectedSite: nil,
                                       appPasswordSupportState: nil,
                                       sessionManager: createSessionWithMockURLProtocol())

        // Then
        let expectation = XCTestExpectation(description: "Authentication mode should remain unchanged")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            XCTAssertEqual(network.authenticationMode, .appPasswords)
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
}

private extension AlamofireNetworkTests {
    func createSessionWithMockURLProtocol() -> Session {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self]
        return Session(configuration: configuration)
    }

    func createJetpackRequest(siteID: Int64, path: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil) -> JetpackRequest {
        return JetpackRequest(wooApiVersion: .mark3,
                             method: method,
                             siteID: siteID,
                             path: path,
                             parameters: parameters,
                             availableAsRESTRequest: true)
    }

    func createRESTRequest(path: String, method: HTTPMethod = .get, parameters: [String: Any]? = nil) -> RESTRequest {
        return RESTRequest(siteURL: "https://example.com",
                          wooApiVersion: .mark3,
                          method: method,
                          path: path,
                          parameters: parameters)
    }

    func createWPComCredentials() -> Credentials {
        return Credentials.wpcom(username: "user", authToken: "token", siteAddress: "https://example.com")
    }

    func createSelectedSitePublisher(siteID: Int64) -> AnyPublisher<JetpackSite?, Never> {
        let site = JetpackSite(siteID: siteID, siteAddress: "https://example.com", applicationPasswordAvailable: true)
        return Just(site).eraseToAnyPublisher()
    }

    func createNetworkWithSelectedSite(
        siteID: Int64,
        credentials: Credentials? = nil,
        userDefaults: UserDefaults? = nil,
        appPasswordSupport: AnyPublisher<Bool, Never> = Just(true).eraseToAnyPublisher()
    ) -> AlamofireNetwork {
        let networkCredentials = credentials ?? createWPComCredentials()
        let selectedSite = createSelectedSitePublisher(siteID: siteID)
        let network = AlamofireNetwork(
            credentials: networkCredentials,
            selectedSite: selectedSite,
            appPasswordSupportState: appPasswordSupport,
            userDefaults: userDefaults ?? .standard,
            sessionManager: createSessionWithMockURLProtocol()
        )
        return network
    }

    func setupMockForDirectRequestFailure(jetpackRequest: JetpackRequest,
                                          restRequest: RESTRequest,
                                          failureStatusCode: Int,
                                          failureResponse: AnyCodable = ["error": "failed"]) throws {
        // Mock REST request to fail
        let restUrlRequest = try XCTUnwrap(try? restRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(failureResponse, statusCode: failureStatusCode, for: restUrlRequest)

        // Mock Jetpack request to succeed
        let jetpackUrlRequest = try XCTUnwrap(try? jetpackRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(["success": "data"], statusCode: 200, for: jetpackUrlRequest)
    }

    func setupMockForDirectRequestFailureWithRetrySuccess(jetpackRequest: JetpackRequest,
                                                          restRequest: RESTRequest,
                                                          failureStatusCode: Int,
                                                          failureResponse: AnyCodable = ["error": "failed"],
                                                          successResponse: AnyCodable) throws {
        // Mock REST request to fail
        let restUrlRequest = try XCTUnwrap(try? restRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(failureResponse, statusCode: failureStatusCode, for: restUrlRequest)

        // Mock Jetpack request to succeed with custom response
        let jetpackUrlRequest = try XCTUnwrap(try? jetpackRequest.asURLRequest())
        MockURLProtocol.Mocks.mockResponse(successResponse, statusCode: 200, for: jetpackUrlRequest)
    }
}
