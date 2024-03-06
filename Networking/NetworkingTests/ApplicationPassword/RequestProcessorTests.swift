import XCTest
@testable import Networking
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
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
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
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(())
            }
        }

        // Then
        XCTAssertFalse(mockRequestAuthenticator.generateApplicationPasswordCalled)
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
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
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
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
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
            self.sut.retry(request, for: session, dueTo: error) { shouldRetry in
                promise(())
            }
        }

        // Then
        waitUntil {
            (self.mockNotificationCenter.notificationObject as? ApplicationPasswordUseCaseError) == applicationPasswordGenerationError
        }
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

    private(set) var authenticateCalled = false
    private(set) var generateApplicationPasswordCalled = false

    var credentials: Networking.Credentials? = nil

    var mockErrorWhileGeneratingPassword: Error?

    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        authenticateCalled = true
        return urlRequest
    }

    func generateApplicationPassword() async throws {
        generateApplicationPasswordCalled = true
        if let mockErrorWhileGeneratingPassword {
            throw mockErrorWhileGeneratingPassword
        }
    }

    func shouldRetry(_ urlRequest: URLRequest) -> Bool {
        mockedShouldRetryValue ?? true
    }
}

private class MockNotificationCenter: NotificationCenter {
    private(set) var notificationName: NSNotification.Name?
    private(set) var notificationObject: Any?

    override func post(name aName: NSNotification.Name, object anObject: Any?, userInfo aUserInfo: [AnyHashable: Any]? = nil) {
        notificationName = aName
        notificationObject = anObject
    }
}

private class MockRequest: Alamofire.DataRequest {
    var fakeRetryCount: Int = 0

    override var retryCount: Int {
        return fakeRetryCount
    }

    override var request: URLRequest? {
        return self.convertible.urlRequest
    }
}
