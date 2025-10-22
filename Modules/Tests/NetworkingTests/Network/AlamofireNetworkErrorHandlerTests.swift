import XCTest
import Alamofire
@testable import NetworkingCore

/// Tests for AlamofireNetworkErrorHandler to verify thread safety and functionality
final class AlamofireNetworkErrorHandlerTests: XCTestCase {
    private var userDefaults: UserDefaults!
    private var errorHandler: AlamofireNetworkErrorHandler!
    private var notificationCenter: NotificationCenter!

    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)
        notificationCenter = NotificationCenter()
        errorHandler = AlamofireNetworkErrorHandler(credentials: createWPComCredentials(), userDefaults: userDefaults, notificationCenter: notificationCenter)
    }

    override func tearDown() {
        userDefaults = nil
        errorHandler = nil
        notificationCenter = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func test_prepareAppPasswordSupport_removes_failure_count_for_site() {
        // Given
        let siteID: Int64 = 123

        // Simulate adding some failures first
        simulateFailureCount(5, for: siteID)

        // When
        errorHandler.prepareAppPasswordSupport(for: siteID)

        // Then - should not flag site as unsupported even after more failures
        simulateFailureCount(5, for: siteID) // Would normally reach threshold
        XCTAssertFalse(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_shouldRetryJetpackRequest_returns_false_for_nil_credentials() {
        // Given
        let errorHandlerWithNilCredentials = AlamofireNetworkErrorHandler(credentials: nil, userDefaults: userDefaults, notificationCenter: notificationCenter)
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
        let errorHandlerWithWporg = AlamofireNetworkErrorHandler(credentials: wporgCredentials, userDefaults: userDefaults, notificationCenter: notificationCenter)
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
            AFError.requestRetryFailed(
                retryError: createNetworkError(),
                originalError: AFError.requestAdaptationFailed(error: NSError(domain: "test", code: 0))
            ),
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
        errorHandler.flagSiteAsUnsupported(for: siteID, flow: .apiRequest, cause: .majorError, error: NetworkError.notFound(response: nil))

        // Then
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_flagSiteAsUnsupported_appends_to_existing_list() {
        // Given
        let existingSiteID: Int64 = 789
        let newSiteID: Int64 = 456
        userDefaults.applicationPasswordUnsupportedList = [String(existingSiteID): Date()]

        // When
        errorHandler.flagSiteAsUnsupported(for: newSiteID, flow: .apiRequest, cause: .majorError, error: NetworkError.notFound(response: nil))

        // Then
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(existingSiteID)))
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(newSiteID)))
    }

    // MARK: - Notification Tests

    func test_prepareAppPasswordSupport_posts_eligible_notification() {
        // Given
        let siteID: Int64 = 123
        var receivedNotifications: [Notification] = []

        let observer = notificationCenter.addObserver(
            forName: .JetpackSiteEligibleForAppPasswordSupport,
            object: nil,
            queue: nil
        ) { notification in
            receivedNotifications.append(notification)
        }

        // When
        errorHandler.prepareAppPasswordSupport(for: siteID)

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        XCTAssertEqual(receivedNotifications.first?.name, .JetpackSiteEligibleForAppPasswordSupport)
        XCTAssertEqual(receivedNotifications.first?.object as? Int64, siteID)

        notificationCenter.removeObserver(observer)
    }

    func test_flagSiteAsUnsupported_posts_flagged_notification_with_properties() {
        // Given
        let siteID: Int64 = 456
        let error = NetworkError.unacceptableStatusCode(statusCode: 401, response: Data())
        var receivedNotifications: [Notification] = []

        let observer = notificationCenter.addObserver(
            forName: .JetpackSiteFlaggedUnsupportedForApplicationPassword,
            object: nil,
            queue: nil
        ) { notification in
            receivedNotifications.append(notification)
        }

        // When
        errorHandler.flagSiteAsUnsupported(for: siteID, flow: .apiRequest, cause: .majorError, error: error)

        // Then
        XCTAssertEqual(receivedNotifications.count, 1)
        XCTAssertEqual(receivedNotifications.first?.name, .JetpackSiteFlaggedUnsupportedForApplicationPassword)

        guard let tracksProperties = receivedNotifications.first?.object as? [String: Any] else {
            XCTFail("Expected tracks properties dictionary")
            return
        }

        XCTAssertEqual(tracksProperties["flow"] as? String, "api_request")
        XCTAssertEqual(tracksProperties["cause"] as? String, "major_error")
        XCTAssertEqual(tracksProperties["http_status_code"] as? Int, 401)
        XCTAssertNotNil(tracksProperties["api_error_code"])

        notificationCenter.removeObserver(observer)
    }

    // MARK: - Thread Safety Tests

    func test_concurrent_prepareAppPasswordSupport_operations_are_thread_safe() {
        let expectation = XCTestExpectation(description: "All reset operations complete")
        let operationCount = 3
        let siteIDs = Array(1...3).map { Int64($0) }

        expectation.expectedFulfillmentCount = operationCount

        // When - perform many concurrent reset operations
        for i in 0..<operationCount {
            DispatchQueue.global().async {
                let siteID = siteIDs[i % siteIDs.count]
                self.errorHandler.prepareAppPasswordSupport(for: siteID)
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
                self.errorHandler.flagSiteAsUnsupported(for: Int64(i), flow: .apiRequest, cause: .majorError, error: NetworkError.notFound(response: nil))
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
                    self.errorHandler.prepareAppPasswordSupport(for: siteID)
                case 1:
                    self.errorHandler.flagSiteAsUnsupported(for: siteID, flow: .apiRequest, cause: .majorError, error: NetworkError.notFound(response: nil))
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

    // MARK: - siteFlaggedAsUnsupported Tests

    func test_siteFlaggedAsUnsupported_returns_false_when_site_not_in_list() {
        // Given
        let siteID: Int64 = 123
        let unsupportedList: [String: Date] = [:]

        // When
        let isFlagged = errorHandler.siteFlaggedAsUnsupported(siteID: siteID, unsupportedList: unsupportedList)

        // Then
        XCTAssertFalse(isFlagged)
    }

    func test_siteFlaggedAsUnsupported_returns_false_when_timestamp_string_invalid() {
        // Given
        let siteID: Int64 = 123
        let unsupportedList: [String: Date] = [String(siteID): Date(timeIntervalSince1970: 0)]

        // When
        let isFlagged = errorHandler.siteFlaggedAsUnsupported(siteID: siteID, unsupportedList: unsupportedList)

        // Then
        XCTAssertFalse(isFlagged)
    }

    func test_siteFlaggedAsUnsupported_returns_true_when_flag_is_recent() {
        // Given
        let siteID: Int64 = 123
        let recentDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - (60 * 60)) // 1 hour ago
        let unsupportedList: [String: Date] = [String(siteID): recentDate]

        // When
        let isFlagged = errorHandler.siteFlaggedAsUnsupported(siteID: siteID, unsupportedList: unsupportedList)

        // Then
        XCTAssertTrue(isFlagged)
    }

    func test_siteFlaggedAsUnsupported_returns_false_and_clears_flag_when_expired() {
        // Given
        let siteID: Int64 = 123
        let expiredDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - (60 * 60 * 24 * 15)) // 15 days ago (expired)
        userDefaults.applicationPasswordUnsupportedList = [String(siteID): expiredDate]

        // When
        let isFlagged = errorHandler.siteFlaggedAsUnsupported(siteID: siteID, unsupportedList: userDefaults.applicationPasswordUnsupportedList)

        // Then
        XCTAssertFalse(isFlagged)
        // Verify the flag was cleared from UserDefaults
        XCTAssertFalse(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_siteFlaggedAsUnsupported_returns_true_for_flag_at_boundary_time() {
        // Given
        let siteID: Int64 = 123
        let boundaryDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - (60 * 60 * 24 * 7 - 1)) // Just under 7 days ago
        let unsupportedList: [String: Date] = [String(siteID): boundaryDate]

        // When
        let isFlagged = errorHandler.siteFlaggedAsUnsupported(siteID: siteID, unsupportedList: unsupportedList)

        // Then
        XCTAssertTrue(isFlagged)
    }

    func test_siteFlaggedAsUnsupported_returns_false_for_flag_just_over_boundary() {
        // Given
        let siteID: Int64 = 123
        let expiredDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - (60 * 60 * 24 * 14 + 1)) // Just over 7 days ago
        userDefaults.applicationPasswordUnsupportedList = [String(siteID): expiredDate]

        // When
        let isFlagged = errorHandler.siteFlaggedAsUnsupported(siteID: siteID, unsupportedList: userDefaults.applicationPasswordUnsupportedList)

        // Then
        XCTAssertFalse(isFlagged)
        // Verify the flag was cleared from UserDefaults
        XCTAssertFalse(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_siteFlaggedAsUnsupported_handles_multiple_sites_correctly() {
        // Given
        let siteID1: Int64 = 123
        let siteID2: Int64 = 456
        let siteID3: Int64 = 789
        let recentDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - (60 * 60)) // 1 hour ago
        let expiredDate = Date(timeIntervalSince1970: Date().timeIntervalSince1970 - (60 * 60 * 24 * 15)) // 15 days ago

        userDefaults.applicationPasswordUnsupportedList = [
            String(siteID1): recentDate,
            String(siteID2): expiredDate,
            String(siteID3): recentDate
        ]

        // When & Then
        let list = userDefaults.applicationPasswordUnsupportedList
        XCTAssertTrue(errorHandler.siteFlaggedAsUnsupported(siteID: siteID1, unsupportedList: list))
        XCTAssertFalse(errorHandler.siteFlaggedAsUnsupported(siteID: siteID2, unsupportedList: userDefaults.applicationPasswordUnsupportedList))
        XCTAssertTrue(errorHandler.siteFlaggedAsUnsupported(siteID: siteID3, unsupportedList: userDefaults.applicationPasswordUnsupportedList))

        // Verify expired flag was cleared but others remain
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID1)))
        XCTAssertFalse(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID2)))
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID3)))
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
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
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
        XCTAssertTrue(userDefaults.applicationPasswordUnsupportedList.keys.contains(String(siteID)))
    }

    func test_concurrent_flagSiteAsUnsupportedForAppPasswordIfNeeded_no_race_condition() {
        // Given - test for the race condition fix where multiple threads
        // try to remove the same item simultaneously
        let expectation = XCTestExpectation(description: "All concurrent flag operations complete without crash")
        let threadCount = 50
        let siteID: Int64 = 999
        let jetpackRequest = createJetpackRequest(siteID: siteID)
        let restRequest = createRESTRequest()
        let error = createNetworkError()

        expectation.expectedFulfillmentCount = threadCount

        // Add a single request to the retry list
        _ = errorHandler.shouldRetryJetpackRequest(
            originalRequest: jetpackRequest,
            convertedRequest: restRequest,
            failure: error
        )

        // When - multiple threads concurrently try to flag and remove the SAME item
        // This would cause a race condition in the old code where:
        // 1. Thread A reads the array, finds index 0
        // 2. Thread B reads the array, finds index 0
        // 3. Thread A removes at index 0 (succeeds)
        // 4. Thread B tries to remove at index 0 (crashes - array is now empty)
        let group = DispatchGroup()
        for _ in 0..<threadCount {
            group.enter()
            DispatchQueue.global().async {
                // All threads try to remove the same request concurrently
                self.errorHandler.flagSiteAsUnsupportedForAppPasswordIfNeeded(
                    originalRequest: jetpackRequest,
                    failure: nil
                )
                group.leave()
                expectation.fulfill()
            }
        }

        // Wait for all threads to complete
        group.wait()

        // Then - no crashes should occur (especially no EXC_BREAKPOINT from array index out of bounds)
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Deadlock Regression Test

    func test_no_deadlock_when_kvo_observer_triggers_during_flagSiteAsUnsupported() {
        // This test reproduces the exact deadlock scenario from the production crash:
        // 1. flagSiteAsUnsupported writes to UserDefaults
        // 2. UserDefaults triggers KVO notification synchronously
        // 3. KVO observer calls prepareAppPasswordSupport
        // 4. prepareAppPasswordSupport accesses appPasswordFailures
        //
        // BEFORE FIX: This would deadlock because:
        // - flagSiteAsUnsupported used queue.sync(flags: .barrier) around UserDefaults write
        // - KVO fired synchronously during the barrier
        // - prepareAppPasswordSupport tried queue.sync while barrier was still active
        //
        // AFTER FIX: No deadlock because:
        // - flagSiteAsUnsupported uses userDefaultsQueue.async for UserDefaults write
        // - KVO fires on userDefaultsQueue, not the main queue
        // - prepareAppPasswordSupport can safely use queue.sync on the main queue

        // Given - Set up KVO observer to simulate the production scenario
        let siteID: Int64 = 12345
        let kvoTriggered = XCTestExpectation(description: "KVO observer triggered")
        let preparePasswordSupportCalled = XCTestExpectation(description: "prepareAppPasswordSupport called from KVO")
        let operationCompleted = XCTestExpectation(description: "Operation completed without deadlock")

        var kvoObservation: NSKeyValueObservation?
        kvoObservation = userDefaults.observe(\.applicationPasswordUnsupportedList, options: [.new]) { [weak self] _, _ in
            kvoTriggered.fulfill()

            // Simulate what happens in production:
            // AlamofireNetwork.observeSelectedSite gets triggered by KVO
            // and calls prepareAppPasswordSupport
            self?.errorHandler.prepareAppPasswordSupport(for: siteID)
            preparePasswordSupportCalled.fulfill()
        }

        // When - Trigger the scenario that caused the deadlock
        DispatchQueue.global().async {
            // This will write to UserDefaults, triggering KVO
            self.errorHandler.flagSiteAsUnsupported(
                for: siteID,
                flow: .apiRequest,
                cause: .majorError,
                error: NetworkError.notFound(response: nil)
            )
            operationCompleted.fulfill()
        }

        // Then - All expectations should complete without timing out (no deadlock)
        // The timeout of 2 seconds is generous - if there's a deadlock, this will timeout
        let result = XCTWaiter.wait(
            for: [kvoTriggered, preparePasswordSupportCalled, operationCompleted],
            timeout: 2.0,
            enforceOrder: false
        )

        XCTAssertEqual(result, .completed, "Test should complete without deadlock. If this times out, the deadlock bug has returned!")

        // Cleanup
        kvoObservation?.invalidate()
    }

    func test_no_deadlock_with_concurrent_kvo_observers_and_flag_operations() {
        // This test creates even more stress by having multiple KVO observers
        // and concurrent flag operations to ensure the fix is robust

        let completionExpectation = XCTestExpectation(description: "All operations complete")
        completionExpectation.expectedFulfillmentCount = 10 // 10 flag operations

        var observations: [NSKeyValueObservation] = []

        // Set up multiple KVO observers (simulating multiple parts of the app observing)
        for i in 1...3 {
            let observation = userDefaults.observe(\.applicationPasswordUnsupportedList, options: [.new]) { [weak self] _, _ in
                let siteID = Int64(1000 + i)
                // Each observer tries to access the error handler
                self?.errorHandler.prepareAppPasswordSupport(for: siteID)
            }
            observations.append(observation)
        }

        // When - Perform multiple concurrent operations that trigger KVO
        for i in 0..<10 {
            DispatchQueue.global().async {
                let siteID = Int64(i)
                self.errorHandler.flagSiteAsUnsupported(
                    for: siteID,
                    flow: .apiRequest,
                    cause: .majorError,
                    error: NetworkError.notFound(response: nil)
                )
                completionExpectation.fulfill()
            }
        }

        // Then - Should complete without deadlock
        let result = XCTWaiter.wait(for: [completionExpectation], timeout: 3.0)
        XCTAssertEqual(result, .completed, "Concurrent operations with multiple KVO observers should not deadlock")

        // Cleanup
        observations.forEach { $0.invalidate() }
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
