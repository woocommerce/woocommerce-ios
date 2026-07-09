import XCTest
@testable import Networking
@testable import NetworkingCore
@testable import Alamofire

/// RequestProcessor Unit Tests
///
final class RequestProcessorTests: XCTestCase {
    private var mockRequestAuthenticator: MockRequestAuthenticator!
    private var sut: RequestProcessor!
    private var session: Alamofire.Session!
    private var mockNotificationCenter: MockNotificationCenter!

    private let url = URL(string: "https://test.com/")!

    override func setUp() {
        super.setUp()

        session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        mockRequestAuthenticator = MockRequestAuthenticator()
        mockNotificationCenter = MockNotificationCenter()
        sut = RequestProcessor(requestAuthenticator: mockRequestAuthenticator,
                               notificationCenter: mockNotificationCenter)
    }

    override func tearDown() {
        sut = nil
        mockRequestAuthenticator = nil
        session = nil
        mockNotificationCenter = nil

        super.tearDown()
    }

    // MARK: Request Authentication
    //
    func test_adapt_authenticates_the_urlrequest() throws {
        // Given
        let urlRequest = URLRequest(url: url)

        // When
        waitFor { done in
            self.sut.adapt(urlRequest, for: .default) { _ in
                done(())
            }
        }

        // Then
        XCTAssertTrue(mockRequestAuthenticator.authenticateCalled)
    }

    // MARK: Retry count
    //
    func test_request_with_zero_retryCount_is_scheduled_for_retry() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        request.fakeRetryCount = 0
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry.retryRequired)
    }

    func test_request_with_non_zero_retryCount_is_not_scheduled_for_retry() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        request.fakeRetryCount = 1
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
    }

    // MARK: `shouldRetry` from RequestAuthenticator
    //
    func test_request_is_scheduled_for_retry_when_request_authenticator_shouldRetry_returns_true() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        mockRequestAuthenticator.mockedShouldRetryValue = true
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry.retryRequired)
    }

    func test_request_is_not_scheduled_for_retry_when_request_authenticator_shouldRetry_returns_false() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        mockRequestAuthenticator.mockedShouldRetryValue = false
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
    }

    // MARK: Error type
    //
    func test_request_is_scheduled_for_retry_when_applicationPasswordNotAvailable_error_occurs() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry.retryRequired)
    }

    func test_request_is_scheduled_for_retry_when_requestAdaptationFailed_error_occurs() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = AFError.requestAdaptationFailed(error: RequestAuthenticatorError.applicationPasswordNotAvailable)
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry.retryRequired)
    }

    func test_request_is_scheduled_for_retry_when_401_error_occurs() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry.retryRequired)
    }

    func test_request_is_not_scheduled_for_retry_when_irrelavant_error_occurs() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = AFError.invalidURL(url: url)
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
    }

    // MARK: Generate application password
    //
    func test_application_password_is_generated_upon_retrying_a_request() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { _ in
                promise(())
            }
        }

        // Then
        XCTAssertTrue(mockRequestAuthenticator.generateApplicationPasswordCalled)
    }

    func test_application_password_is_not_generated_when_a_request_is_not_eligible_for_retry() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        mockRequestAuthenticator.mockedShouldRetryValue = false
        waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.retry(request, for: session, dueTo: error) { _ in
                promise(())
            }
        }

        // Then
        XCTAssertFalse(mockRequestAuthenticator.generateApplicationPasswordCalled)
    }

    // MARK: Validate application password
    //
    func test_application_password_is_validated_when_generation_is_not_available() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        mockRequestAuthenticator.mockedCanGenerateApplicationPassword = false
        mockRequestAuthenticator.mockedCanValidateApplicationPassword = true
        mockRequestAuthenticator.mockApplicationPasswordValidationResult = .valid

        // When
        let shouldRetry = waitFor { promise in
            let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        XCTAssertTrue(mockRequestAuthenticator.validateApplicationPasswordCalled)
        XCTAssertFalse(mockRequestAuthenticator.generateApplicationPasswordCalled)
        XCTAssertNil(mockNotificationCenter.notificationName)
    }

    func test_application_password_invalidation_notification_is_posted_when_validation_finds_invalid_password() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let validationError = NetworkError.unacceptableStatusCode(statusCode: 401)
        mockRequestAuthenticator.mockedCanGenerateApplicationPassword = false
        mockRequestAuthenticator.mockedCanValidateApplicationPassword = true
        mockRequestAuthenticator.mockApplicationPasswordValidationResult = .invalid(validationError)

        // When
        let shouldRetry = waitFor { promise in
            let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        XCTAssertTrue(mockRequestAuthenticator.validateApplicationPasswordCalled)
        XCTAssertEqual(mockNotificationCenter.notificationName, .ApplicationPasswordInvalidated)
        XCTAssertEqual(mockNotificationCenter.notificationObject as? NetworkError, validationError)
    }

    func test_application_password_invalidation_notification_is_not_posted_when_validation_fails_with_network_error() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        mockRequestAuthenticator.mockedCanGenerateApplicationPassword = false
        mockRequestAuthenticator.mockedCanValidateApplicationPassword = true
        mockRequestAuthenticator.mockErrorWhileValidatingPassword = NetworkError.timeout()

        // When
        let shouldRetry = waitFor { promise in
            let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        XCTAssertTrue(mockRequestAuthenticator.validateApplicationPasswordCalled)
        XCTAssertNil(mockNotificationCenter.notificationName)
    }

    @MainActor
    func test_concurrent_requests_share_single_application_password_validation() async throws {
        // Given
        mockRequestAuthenticator.mockedCanGenerateApplicationPassword = false
        mockRequestAuthenticator.mockedCanValidateApplicationPassword = true
        mockRequestAuthenticator.mockApplicationPasswordValidationResult = .valid
        mockRequestAuthenticator.mockValidationDelayNanoseconds = 100_000_000

        let completionExpectation = expectation(description: "All retry completions are called")
        completionExpectation.expectedFulfillmentCount = 3
        var retryResults: [RetryResult] = []

        // When
        for _ in 0..<3 {
            let request = try mockRequest()
            let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
            sut.retry(request, for: session, dueTo: error) { result in
                retryResults.append(result)
                completionExpectation.fulfill()
            }
        }

        await fulfillment(of: [completionExpectation], timeout: 2)

        // Then
        XCTAssertEqual(mockRequestAuthenticator.validateApplicationPasswordCallCount, 1)
        XCTAssertEqual(retryResults.count, 3)
        XCTAssertTrue(retryResults.allSatisfy { $0.retryRequired == false })
    }

    // MARK: Notification center
    //
    func test_notification_is_posted_when_application_password_generation_is_successful() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { _ in
                promise(())
            }
        }

        // Then
        waitUntil {
            self.mockNotificationCenter.notificationName == .ApplicationPasswordsNewPasswordCreated
        }
    }

    func test_notification_is_posted_when_application_password_generation_fails() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = ApplicationPasswordUseCaseError.applicationPasswordsDisabled

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { _ in
                promise(())
            }
        }

        // Then
        waitUntil {
            self.mockNotificationCenter.notificationName == .ApplicationPasswordsGenerationFailed
        }
    }

    func test_posted_notification_holds_expected_error_when_application_password_generation_fails() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let applicationPasswordGenerationError = ApplicationPasswordUseCaseError.applicationPasswordsDisabled
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = applicationPasswordGenerationError

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { _ in
                promise(())
            }
        }

        // Then
        waitUntil {
            (self.mockNotificationCenter.notificationObject as? ApplicationPasswordUseCaseError) == applicationPasswordGenerationError
        }
    }

    // MARK: Error handling when isAuthenticatedWithWPCom is true

    func test_delegate_called_when_404_error_occurs_with_wpcom_authentication() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let wpcomCredentials = Networking.Credentials.wpcom(username: "test", authToken: "token", siteAddress: "test.com")
        let mockDelegate = MockRequestProcessorDelegate()

        mockRequestAuthenticator.credentials = wpcomCredentials
        mockRequestAuthenticator.jetpackSiteID = 123
        sut.updateAuthenticator(mockRequestAuthenticator)
        sut.delegate = mockDelegate

        let notFound404Error = NetworkError.notFound(response: nil)
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = notFound404Error

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        waitUntil {
            mockDelegate.didFailToAuthenticateRequestForSiteID == 123
        }
    }

    func test_delegate_called_when_application_password_disabled() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let wpcomCredentials = Networking.Credentials.wpcom(username: "test", authToken: "token", siteAddress: "test.com")
        let mockDelegate = MockRequestProcessorDelegate()

        mockRequestAuthenticator.credentials = wpcomCredentials
        mockRequestAuthenticator.jetpackSiteID = 123
        sut.updateAuthenticator(mockRequestAuthenticator)
        sut.delegate = mockDelegate

        let response = ["error": "application_passwords_disabled"]
        let data = try JSONEncoder().encode(response)
        let notSupportedError = NetworkError.unacceptableStatusCode(statusCode: 501, response: data)
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = notSupportedError

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        waitUntil {
            mockDelegate.didFailToAuthenticateRequestForSiteID == 123
        }
    }

    func test_delegate_called_when_application_password_disabled_for_user() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let wpcomCredentials = Networking.Credentials.wpcom(username: "test", authToken: "token", siteAddress: "test.com")
        let mockDelegate = MockRequestProcessorDelegate()

        mockRequestAuthenticator.credentials = wpcomCredentials
        mockRequestAuthenticator.jetpackSiteID = 123
        sut.updateAuthenticator(mockRequestAuthenticator)
        sut.delegate = mockDelegate

        let response = ["error": "application_passwords_disabled_for_user"]
        let data = try JSONEncoder().encode(response)
        let notSupportedError = NetworkError.unacceptableStatusCode(statusCode: 501, response: data)
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = notSupportedError

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        waitUntil {
            mockDelegate.didFailToAuthenticateRequestForSiteID == 123
        }
    }

    func test_request_not_retried_when_other_error_occurs_with_wpcom_authentication() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let wpcomCredentials = Networking.Credentials.wpcom(username: "test", authToken: "token", siteAddress: "test.com")
        let mockDelegate = MockRequestProcessorDelegate()

        mockRequestAuthenticator.credentials = wpcomCredentials
        mockRequestAuthenticator.jetpackSiteID = 123
        sut.updateAuthenticator(mockRequestAuthenticator)
        sut.delegate = mockDelegate

        let genericError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = genericError

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry.retryRequired)
        XCTAssertFalse(mockRequestAuthenticator.deleteApplicationPasswordCalled)
    }

    func test_request_not_retried_when_password_deletion_fails_after_409_error_with_wpcom_authentication() throws {
        // Given
        let session = Alamofire.Session(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()
        let wpcomCredentials = Networking.Credentials.wpcom(username: "test", authToken: "token", siteAddress: "test.com")

        mockRequestAuthenticator.credentials = wpcomCredentials
        mockRequestAuthenticator.jetpackSiteID = 123
        sut.updateAuthenticator(mockRequestAuthenticator)

        let conflict409Error = NetworkError.unacceptableStatusCode(statusCode: 409, response: nil)
        let deletionError = NSError(domain: "TestError", code: 500, userInfo: nil)
        mockRequestAuthenticator.mockErrorWhileGeneratingPassword = conflict409Error
        mockRequestAuthenticator.mockErrorWhileDeletingPassword = deletionError

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(mockRequestAuthenticator.deleteApplicationPasswordCalled)
        XCTAssertFalse(shouldRetry.retryRequired)
    }

    /// Simulates race condition of concurrent `delegate` reads and writes from different threads.
    /// Verifies the synchronized implementation does not crash. Best run with Thread Sanitizer enabled.
    func test_concurrent_delegate_access_does_not_trigger_race_condition() {
        // Given
        let sut = RequestProcessor(
            requestAuthenticator: MockRequestAuthenticator(),
            notificationCenter: MockNotificationCenter()
        )
        let iterations = 20000
        let queue = DispatchQueue(
            label: "com.woocommerce.tests.requestProcessor.delegate-race",
            qos: .userInitiated,
            attributes: .concurrent
        )
        let group = DispatchGroup()
        let delegates = (0..<iterations / 2).map { _ in MockRequestProcessorDelegate() }

        // When
        for index in 0..<iterations {
            queue.async(group: group) {
                if index.isMultiple(of: 2) {
                    sut.delegate = delegates[index / 2]
                } else {
                    _ = sut.delegate
                }
            }
        }

        // Then
        let result = group.wait(timeout: .now() + 20)
        XCTAssertEqual(result, .success)
    }

    /// Simulates race condition of multiple `updateAuthenticator` calls from different threads
    /// Should cause a crash on old/non-synchronized `RequestProcessor` implementatoin
    /// Should work fine on synchronized version of `RequestProcessor`
    func test_concurrent_authenticator_updates_does_not_trigger_race_condition() throws {
        let credentials = Networking.Credentials.wpcom(
            username: "initial",
            authToken: UUID().uuidString,
            siteAddress: "https://example.com"
        )
        let authenticator = DefaultRequestAuthenticator(credentials: credentials)
        let sut = RequestProcessor(
            requestAuthenticator: authenticator,
            notificationCenter: MockNotificationCenter()
        )

        let request = URLRequest(url: url)
        let iterations = 20000
        let queue = DispatchQueue(
            label: "com.woocommerce.tests.requestProcessor.race",
            qos: .userInitiated,
            attributes: .concurrent
        )
        let group = DispatchGroup()

        for index in 0..<iterations {
            queue.async(group: group) {
                if index.isMultiple(of: 2) {
                    let credentials = Networking.Credentials.wpcom(
                        username: "user-\(index)",
                        authToken: UUID().uuidString,
                        siteAddress: "https://example.com"
                    )
                    let authenticator = DefaultRequestAuthenticator(credentials: credentials)
                    sut.updateAuthenticator(authenticator)
                } else {
                    sut.adapt(request, for: .default) { _ in }
                }
            }
        }

        let result = group.wait(timeout: .now() + 20)
        XCTAssertEqual(result, .success)
    }
}

// MARK: Helpers
//
private extension RequestProcessorTests {
    func mockRequest() throws -> MockRequest {
        let urlRequest = URLRequest(url: URL(string: "https://test.com/")!)
        return MockRequest(
            convertible: urlRequest,
            underlyingQueue: .global(),
            serializationQueue: .global(),
            eventMonitor: nil,
            interceptor: nil,
            delegate: session
        )
    }
}

private class MockRequestAuthenticator: RequestAuthenticator {
    var mockedShouldRetryValue: Bool?
    var mockedCanGenerateApplicationPassword = true
    var mockedCanValidateApplicationPassword = false

    private(set) var authenticateCalled = false
    private(set) var generateApplicationPasswordCalled = false
    private(set) var deleteApplicationPasswordCalled = false
    private(set) var validateApplicationPasswordCallCount = 0

    var validateApplicationPasswordCalled: Bool {
        validateApplicationPasswordCallCount > 0
    }

    var credentials: Networking.Credentials? = nil
    var jetpackSiteID: Int64?

    var mockErrorWhileGeneratingPassword: Error?
    var mockErrorWhileDeletingPassword: Error?
    var mockErrorWhileValidatingPassword: Error?
    var mockApplicationPasswordValidationResult: ApplicationPasswordValidationResult = .valid
    var mockValidationDelayNanoseconds: UInt64?

    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        authenticateCalled = true
        return urlRequest
    }

    func canGenerateApplicationPassword() -> Bool {
        return mockedCanGenerateApplicationPassword
    }

    func generateApplicationPassword() async throws {
        generateApplicationPasswordCalled = true
        if let mockErrorWhileGeneratingPassword {
            throw mockErrorWhileGeneratingPassword
        }
    }

    func canValidateApplicationPassword() -> Bool {
        mockedCanValidateApplicationPassword
    }

    func validateApplicationPassword() async throws -> ApplicationPasswordValidationResult {
        validateApplicationPasswordCallCount += 1
        if let mockValidationDelayNanoseconds {
            try? await Task.sleep(nanoseconds: mockValidationDelayNanoseconds)
        }
        if let mockErrorWhileValidatingPassword {
            throw mockErrorWhileValidatingPassword
        }
        return mockApplicationPasswordValidationResult
    }

    func deleteApplicationPassword() async throws {
        deleteApplicationPasswordCalled = true
        if let mockErrorWhileDeletingPassword {
            throw mockErrorWhileDeletingPassword
        }
    }

    func shouldRetry(_ urlRequest: URLRequest) -> Bool {
        mockedShouldRetryValue ?? true
    }
}

private class MockNotificationCenter: NotificationCenter, @unchecked Sendable {
    private(set) var notificationName: NSNotification.Name?
    private(set) var notificationObject: Any?

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        notificationName = aName
        notificationObject = anObject
    }
}

private class MockRequest: Alamofire.DataRequest, @unchecked Sendable {
    var fakeRetryCount: Int = 0

    override var retryCount: Int {
        return fakeRetryCount
    }

    override var request: URLRequest? {
        return self.convertible.urlRequest
    }
}

private class MockRequestProcessorDelegate: RequestProcessorDelegate {
    private(set) var didFailToAuthenticateRequestForSiteID: Int64?

    func didFailToAuthenticateRequestWithAppPassword(siteID: Int64, error: Error) {
        didFailToAuthenticateRequestForSiteID = siteID
    }
}
