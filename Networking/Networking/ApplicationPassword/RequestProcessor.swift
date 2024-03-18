import Alamofire
import Foundation

/// Authenticates and retries requests
///
final class RequestProcessor: RequestInterceptor {
    private var requestsToRetry = [(RetryResult) -> Void]()

    private var isAuthenticating = false

    private let requestAuthenticator: RequestAuthenticator

    private let notificationCenter: NotificationCenter

    init(requestAuthenticator: RequestAuthenticator,
         notificationCenter: NotificationCenter = .default) {
        self.requestAuthenticator = requestAuthenticator
        self.notificationCenter = notificationCenter
    }
}

// MARK: Request Authentication
//
extension RequestProcessor: RequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let result = Result { try requestAuthenticator.authenticate(urlRequest) }
        completion(result)
    }
}

// MARK: Retrying Request
//
extension RequestProcessor: RequestRetrier {
    func retry(_ request: Alamofire.Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard
            request.retryCount == 0, // Only retry once
            let urlRequest = request.request,
            requestAuthenticator.shouldRetry(urlRequest), // Retry only REST API requests that use application password
            shouldRetry(error) // Retry only specific errors
        else {
            return completion(.doNotRetry)
        }

        requestsToRetry.append(completion)
        if !isAuthenticating {
            generateApplicationPassword()
        }
    }
}

// MARK: Helpers
//
private extension RequestProcessor {
    func generateApplicationPassword() {
        Task(priority: .medium) {
            isAuthenticating = true

            do {
                let _ = try await requestAuthenticator.generateApplicationPassword()
                isAuthenticating = false

                // Post a notification for tracking
                notificationCenter.post(name: .ApplicationPasswordsNewPasswordCreated, object: nil, userInfo: nil)

                completeRequests(true)
            } catch {
                isAuthenticating = false

                // Post a notification for tracking
                notificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

                completeRequests(false)
            }
        }
    }

    func shouldRetry(_ error: Error) -> Bool {
        // Need to generate application password
        if .applicationPasswordNotAvailable == error as? RequestAuthenticatorError {
            return true
        }

        // Failed authorization
        if case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = error as? AFError {
            return true
        }

        return false
    }

    func completeRequests(_ shouldRetry: Bool) {
        let result: RetryResult = shouldRetry ? .retryWithDelay(0) : .doNotRetry
        requestsToRetry.forEach { (completion) in
            completion(result)
        }
        requestsToRetry.removeAll()
    }
}

// MARK: - Application Password Notifications
//
public extension NSNotification.Name {
    /// Posted whenever a new password was created when a  regeneration is needed.
    ///
    static let ApplicationPasswordsNewPasswordCreated = NSNotification.Name(rawValue: "ApplicationPasswordsNewPasswordCreated")

    /// Posted when generating an application password fails
    ///
    static let ApplicationPasswordsGenerationFailed = NSNotification.Name(rawValue: "ApplicationPasswordsGenerationFailed")
}
