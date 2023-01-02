import XCTest
@testable import Networking
@testable import Alamofire

/// RequestProcessor Unit Tests
///
final class RequestProcessorTests: XCTestCase {
    private var mockRequestAuthenticator: MockRequestAuthenticator!
    private var sut: RequestProcessor!
    private var sessionManager: Alamofire.SessionManager!

    override func setUp() {
        super.setUp()

        sessionManager = Alamofire.SessionManager(configuration: URLSessionConfiguration.default)
        mockRequestAuthenticator = MockRequestAuthenticator()
        sut = RequestProcessor(requestAuthenticator: mockRequestAuthenticator)
    }

    override func tearDown() {
        sut = nil
        mockRequestAuthenticator = nil
        sessionManager = nil

        super.tearDown()
    }

    // MARK: Request Authentication
    //
    func test_adapt_authenticates_the_urlrequest() throws {
        // Given
        let urlRequest = URLRequest(url: URL(string: "https://test.com/")!)

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
            self.sut.should(sessionManager, retry: request, with: RequestAuthenticatorError.applicationPasswordNotAvailable) { shouldRetry, timeDelay in
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
            self.sut.should(sessionManager, retry: request, with: RequestAuthenticatorError.applicationPasswordNotAvailable) { shouldRetry, timeDelay in
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
            self.sut.should(sessionManager, retry: request, with: RequestAuthenticatorError.applicationPasswordNotAvailable) { shouldRetry, timeDelay in
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
            self.sut.should(sessionManager, retry: request, with: RequestAuthenticatorError.applicationPasswordNotAvailable) { shouldRetry, timeDelay in
                promise(shouldRetry)
            }
        }

        // Then
        XCTAssertFalse(shouldRetry)
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

    var credentials: Networking.Credentials? = nil

    func authenticate(_ urlRequest: URLRequest) throws -> URLRequest {
        authenticateCalled = true
        return urlRequest
    }

    func generateApplicationPassword() async throws {
        // Do nothing
    }

    func shouldRetry(_ urlRequest: URLRequest) -> Bool {
        mockedShouldRetryValue ?? true
    }
}
