import XCTest
import Alamofire
@testable import NetworkingCore

/// Tests for AlamofireNetworkErrorHandler to verify thread safety and functionality
final class AlamofireNetworkErrorHandlerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var errorHandler: AlamofireNetworkErrorHandler!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)
        errorHandler = AlamofireNetworkErrorHandler(credentials: createWPComCredentials(), userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults = nil
        errorHandler = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func test_resetFailureCount_removes_failure_count_for_site() {
        // Given
        let siteID: Int64 = 123

        // Simulate adding some failures first
        simulateFailureCount(5, for: siteID)

        // When
        errorHandler.resetFailureCount(for: siteID)

        // Then - should not flag site as unsupported even after more failures
        simulateFailureCount(5, for: siteID) // Would normally reach threshold
        XCTAssertFalse(userDefaults.applicationPasswordUnsupportedList.contains(siteID))
    }

    func test_shouldRetryJetpackRequest_returns_false_for_nil_credentials() {
        // Given
        let errorHandlerWithNilCredentials = AlamofireNetworkErrorHandler(credentials: nil, userDefaults: userDefaults)
        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()
        let error = createNetworkError()

        // When
        let shouldRetry = errorHandlerWithNilCredentials.shouldRetryJetpackRequest(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: error
        )

        // Then
        XCTAssertFalse(shouldRetry)
    }

    func test_shouldRetryJetpackRequest_returns_false_for_non_wpcom_credentials() {
        // Given
        let wporgCredentials = Credentials.wporg(username: "user", password: "pass", siteAddress: "https://example.com")
        let errorHandlerWithWporg = AlamofireNetworkErrorHandler(credentials: wporgCredentials, userDefaults: userDefaults)
        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()
        let error = createNetworkError()

        // When
        let shouldRetry = errorHandlerWithWporg.shouldRetryJetpackRequest(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: error
        )

        // Then
        XCTAssertFalse(shouldRetry)
    }

    func test_shouldRetryJetpackRequest_returns_true_for_expected_errors() {
        // Given
        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()

        let testCases: [Error] = [
            AFError.requestAdaptationFailed(error: NSError(domain: "test", code: 1)),
            createNetworkError()
        ]

        for error in testCases {
            // When
            let shouldRetry = errorHandler.shouldRetryJetpackRequest(
                originalRequest: jetpackRequest,
                convertedRequest: restRequest,
                failure: error
            )

            // Then
            XCTAssertTrue(shouldRetry, "Should retry for error: \(error)")
        }
    }

    func test_shouldRetryJetpackRequest_returns_false_for_unexpected_errors() {
        // Given
        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()
        let unexpectedError = NSError(domain: "UnexpectedDomain", code: 999)

        // When
        let shouldRetry = errorHandler.shouldRetryJetpackRequest(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: unexpectedError
        )

        // Then
        XCTAssertFalse(shouldRetry)
    }

    func test_flagSiteAsUnsupported_adds_site_to_unsupported_list() {
        // Given
        let siteID: Int64 = 456
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.isEmpty)

        // When
        errorHandler.flagSiteAsUnsupported(for: siteID)

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [siteID])
    }

    func test_flagSiteAsUnsupported_appends_to_existing_list() {
        // Given
        let existingSiteID: Int64 = 789
        let newSiteID: Int64 = 456
        userDefaults.applicationPasswordUnsupportedList = [existingSiteID]

        // When
        errorHandler.flagSiteAsUnsupported(for: newSiteID)

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [existingSiteID, newSiteID])
    }

    // MARK: - Thread Safety Tests

    func test_concurrent_resetFailureCount_operations_are_thread_safe() {
        let expectation = XCTestExpectation(description: "All reset operations complete")
        let operationCount = 3
        let siteIDs = Array(1...3).map { Int64($0) }

        expectation.expectedFulfillmentCount = operationCount

        // When - perform many concurrent reset operations
        for i in 0..<operationCount {
            DispatchQueue.global().async {
                let siteID = siteIDs[i % siteIDs.count]
                self.errorHandler.resetFailureCount(for: siteID)
                expectation.fulfill()
            }
        }

        // Then - no crashes should occur
        wait(for: [expectation], timeout: 3.0)
    }

    func test_concurrent_shouldRetryJetpackRequest_operations_are_thread_safe() {
        let expectation = XCTestExpectation(description: "All retry checks complete")
        let operationCount = 3
        expectation.expectedFulfillmentCount = operationCount

        // When - perform many concurrent retry checks
        for i in 0..<operationCount {
            DispatchQueue.global().async {
                let jetpackRequest = self.createJetpackRequest(siteID: Int64(i))
                let restRequest = self.createRESTRequest()
                let error = self.createNetworkError()

                _ = self.errorHandler.shouldRetryJetpackRequest(
                    originalRequest: jetpackRequest,
                    convertedRequest: restRequest,
                    failure: error
                )
                expectation.fulfill()
            }
        }

        // Then - no crashes should occur
        wait(for: [expectation], timeout: 3.0)
    }

    func test_concurrent_flagSiteAsUnsupported_operations_are_thread_safe() {
        let expectation = XCTestExpectation(description: "All flag operations complete")
        let operationCount = 3
        expectation.expectedFulfillmentCount = operationCount

        // When - perform many concurrent flag operations
        for i in 0..<operationCount {
            DispatchQueue.global().async {
                self.errorHandler.flagSiteAsUnsupported(for: Int64(i))
                expectation.fulfill()
            }
        }

        // Then - no crashes should occur and all sites should be flagged
        wait(for: [expectation], timeout: 3.0)

        // Verify all sites were added (though order may vary due to concurrency)
        let unsupportedList = userDefaults.applicationPasswordUnsupportedList
        XCTAssertEqual(unsupportedList.count, operationCount)
    }

    func test_concurrent_mixed_operations_are_thread_safe() {
        let expectation = XCTestExpectation(description: "All mixed operations complete")
        let operationCount = 10
        expectation.expectedFulfillmentCount = operationCount

        // When - perform mixed concurrent operations
        for i in 0..<operationCount {
            DispatchQueue.global().async {
                let siteID = Int64(i % 10)

                switch i % 3 {
                case 0:
                    self.errorHandler.resetFailureCount(for: siteID)
                case 1:
                    self.errorHandler.flagSiteAsUnsupported(for: siteID)
                case 2:
                    let jetpackRequest = self.createJetpackRequest(siteID: siteID)
                    let restRequest = self.createRESTRequest()
                    let error = self.createNetworkError()
                    _ = self.errorHandler.shouldRetryJetpackRequest(
                        originalRequest: jetpackRequest,
                        convertedRequest: restRequest,
                        failure: error
                    )
                default:
                    break
                }
                expectation.fulfill()
            }
        }

        // Then - no crashes should occur
        wait(for: [expectation], timeout: 5.0)
    }

    func test_isRequestRetried_with_concurrent_retry_additions() {
        let expectation = XCTestExpectation(description: "All operations complete")
        let operationCount = 5
        expectation.expectedFulfillmentCount = operationCount * 2 // retry + check operations

        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()
        let error = createNetworkError()

        // When - concurrently add retries and check if request is retried
        for _ in 0..<operationCount {
            DispatchQueue.global().async {
                // Add retry
                _ = self.errorHandler.shouldRetryJetpackRequest(
                    originalRequest: jetpackRequest,
                    convertedRequest: restRequest,
                    failure: error
                )
                expectation.fulfill()
            }

            DispatchQueue.global().async {
                // Check if retried
                _ = self.errorHandler.isRequestRetried(jetpackRequest)
                expectation.fulfill()
            }
        }

        // Then - no crashes should occur
        wait(for: [expectation], timeout: 3.0)
    }

    // MARK: - Integration Tests

    func test_handleFailureForDirectRequestIfNeeded_calls_correct_callbacks() {
        // Given
        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()
        let error = createNetworkError()

        var retryCallbackCalled = false
        var completionCallbackCalled = false

        // When
        errorHandler.handleFailureForDirectRequestIfNeeded(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: error,
            onRetry: {
                retryCallbackCalled = true
            },
            onCompletion: {
                completionCallbackCalled = true
            }
        )

        // Then - should call retry callback for expected error
        XCTAssertTrue(retryCallbackCalled)
        XCTAssertFalse(completionCallbackCalled)
    }

    func test_handleFailureForDirectRequestIfNeeded_calls_completion_for_non_retryable_error() {
        // Given
        let jetpackRequest = createJetpackRequest(siteID: 123)
        let restRequest = createRESTRequest()
        let unexpectedError = NSError(domain: "UnexpectedDomain", code: 999)

        var retryCallbackCalled = false
        var completionCallbackCalled = false

        // When
        errorHandler.handleFailureForDirectRequestIfNeeded(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: unexpectedError,
            onRetry: {
                retryCallbackCalled = true
            },
            onCompletion: {
                completionCallbackCalled = true
            }
        )

        // Then - should call completion callback for unexpected error
        XCTAssertFalse(retryCallbackCalled)
        XCTAssertTrue(completionCallbackCalled)
    }

    // MARK: - Error Handling Tests

    func test_flagSiteAsUnsupportedForAppPasswordIfNeeded_handles_401_error() {
        // Given
        let siteID: Int64 = 123
        let jetpackRequest = createJetpackRequest(siteID: siteID)
        let restRequest = createRESTRequest()
        let error401 = NetworkError.unacceptableStatusCode(statusCode: 401, response: Data())

        // Add request to retried list first
        _ = errorHandler.shouldRetryJetpackRequest(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: error401
        )

        // When - simulate successful retry
        errorHandler.flagSiteAsUnsupportedForAppPasswordIfNeeded(
            originalRequest: jetpackRequest,
            failure: nil
        )

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [siteID])
    }

    func test_flagSiteAsUnsupportedForAppPasswordIfNeeded_handles_disabled_error_codes() {
        // Given
        let siteID: Int64 = 456
        let jetpackRequest = createJetpackRequest(siteID: siteID)
        let restRequest = createRESTRequest()

        let disabledError = NetworkError.unacceptableStatusCode(
            statusCode: 400,
            response: try! JSONSerialization.data(withJSONObject: [
                "code": "application_passwords_disabled",
                "message": "Application passwords are disabled"
            ])
        )

        // Add request to retried list first
        _ = errorHandler.shouldRetryJetpackRequest(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: disabledError
        )

        // When - simulate successful retry
        errorHandler.flagSiteAsUnsupportedForAppPasswordIfNeeded(
            originalRequest: jetpackRequest,
            failure: nil
        )

        // Then
        XCTAssertEqual(userDefaults.applicationPasswordUnsupportedList, [siteID])
    }
}

// MARK: - Helper Methods
private extension AlamofireNetworkErrorHandlerTests {
    func createWPComCredentials() -> Credentials {
        return Credentials.wpcom(username: "test", authToken: "token", siteAddress: "https://example.com")
    }

    func createJetpackRequest(siteID: Int64) -> JetpackRequest {
        return JetpackRequest(
            wooApiVersion: .mark3,
            method: .get,
            siteID: siteID,
            path: "test",
            availableAsRESTRequest: true
        )
    }

    func createRESTRequest() -> RESTRequest {
        return RESTRequest(
            siteURL: "https://example.com",
            wooApiVersion: .mark3,
            method: .get,
            path: "test"
        )
    }

    func createNetworkError() -> NetworkError {
        return NetworkError.unacceptableStatusCode(statusCode: 500, response: Data())
    }

    func simulateFailureCount(_ count: Int, for siteID: Int64) {
        // Simulate multiple failures to reach the count
        for _ in 0..<count {
            let jetpackRequest = createJetpackRequest(siteID: siteID)
            let restRequest = createRESTRequest()
            let error = createNetworkError()

            // Add to retried list
            _ = errorHandler.shouldRetryJetpackRequest(
                originalRequest: jetpackRequest,
                convertedRequest: restRequest,
                failure: error
            )

            // Simulate successful retry (which triggers increment)
            errorHandler.flagSiteAsUnsupportedForAppPasswordIfNeeded(
                originalRequest: jetpackRequest,
                failure: nil
            )
        }
    }
}
