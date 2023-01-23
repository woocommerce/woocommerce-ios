import XCTest
@testable import Networking
@testable import Alamofire

/// RequestProcessor Unit Tests
///
final class RequestProcessorTests: XCTestCase {
    private var mockRequestAuthenticator: MockRequestAuthenticator!
    private var sut: RequestProcessor!
    private var sessionManager: Alamofire.SessionManager!
    private var mockNotificationCenter: MockNotificationCenter!

    private let url = URL(string: "https://test.com/")!

    override func setUp() {
        super.setUp()

        sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        mockRequestAuthenticator = MockRequestAuthenticator()
        mockNotificationCenter = MockNotificationCenter()
        sut = RequestProcessor(requestAuthenticator: mockRequestAuthenticator,
                               notificationCenter: mockNotificationCenter)
    }

    override func tearDown() {
        sut = nil
        mockRequestAuthenticator = nil
        sessionManager = nil
        mockNotificationCenter = nil

        super.tearDown()
    }

    // MARK: Request Authentication
    //
    func test_adapt_authenticates_the_urlrequest() throws {
        // Given
        let urlRequest = URLRequest(url: url)

        // When
        let _ = try sut.adapt(urlRequest)

        // Then
        XCTAssertTrue(mockRequestAuthenticator.authenticateCalled)
    }

    // MARK: Retry count
    //
    func test_request_with_zero_retryCount_is_scheduled_for_retry() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        request.retryCount = 0
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry)
    }

    func test_request_with_non_zero_retryCount_is_not_scheduled_for_retry() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        request.retryCount = 1
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry)
    }

    // MARK: `shouldRetry` from RequestAuthenticator
    //
    func test_request_is_scheduled_for_retry_when_request_authenticator_shouldRetry_returns_true() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        mockRequestAuthenticator.mockedShouldRetryValue = true
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry)
    }

    func test_request_is_not_scheduled_for_retry_when_request_authenticator_shouldRetry_returns_false() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        mockRequestAuthenticator.mockedShouldRetryValue = false
        let shouldRetry = waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry)
    }

    // MARK: Error type
    //
    func test_request_is_scheduled_for_retry_when_applicationPasswordNotAvailable_error_occurs() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        let shouldRetry = waitFor { promise in
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry)
    }

    func test_request_is_scheduled_for_retry_when_401_error_occurs() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401))
        let shouldRetry = waitFor { promise in
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertTrue(shouldRetry)
    }

    func test_request_is_not_scheduled_for_retry_when_irrelavant_error_occurs() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = AFError.invalidURL(url: url)
        let shouldRetry = waitFor { promise in
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry)
    }

    // MARK: Generate application password
    //
    func test_application_password_is_generated_upon_retrying_a_request() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        let error = RequestAuthenticatorError.applicationPasswordNotAvailable
        waitFor { promise in
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(())
            }
        }

        // Then
        XCTAssertTrue(mockRequestAuthenticator.generateApplicationPasswordCalled)
    }

    func test_application_password_is_not_generated_when_a_request_is_not_eligible_for_retry() throws {
        // Given
        let sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        let request = try mockRequest()

        // When
        mockRequestAuthenticator.mockedShouldRetryValue = false
        waitFor { promise in
            let error = RequestAuthenticatorError.applicationPasswordNotAvailable
            self.sut.should(sessionManager, retry: request, with: error) { shouldRetry, timeDelay in
                promise(())
            }
        }

        // Then
        XCTAssertFalse(mockRequestAuthenticator.generateApplicationPasswordCalled)
    }
}

// MARK: Helpers
//
private extension RequestProcessorTests {
    func mockRequest() throws -> Alamofire.Request {
        let originalTask = MockTaskConvertible()
        let task = try originalTask.task(session: sessionManager.session, adapter: nil, queue: .main)
        return Alamofire.Request(session: sessionManager.session, requestTask: .data(originalTask, task))
    }
}


private class MockTaskConvertible: TaskConvertible {
    let urlRequest = URLRequest(url: URL(string: "https://test.com/")!)

    func task(session: URLSession, adapter: RequestAdapter?, queue: DispatchQueue) throws -> URLSessionTask {
        session.dataTask(with: urlRequest)
    }
}

private class MockRequestAuthenticator: RequestAuthenticator {
    var mockedShouldRetryValue: Bool?

    private(set) var authenticateCalled = false
    private(set) var generateApplicationPasswordCalled = false

    var credentials: Networking.Credentials? = nil

    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        authenticateCalled = true
        return urlRequest
    }

    func generateApplicationPassword() async throws {
        generateApplicationPasswordCalled = true
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
