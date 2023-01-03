import Alamofire
import Foundation

/// Authenticates and retries requests
///
final class RequestProcessor {
    private var requestsToRetry = [RequestRetryCompletion]()

    private var isAuthenticating = false

    private let requestAuthenticator: RequestAuthenticator

    init(requestAuthenticator: RequestAuthenticator) {
        self.requestAuthenticator = requestAuthenticator
    }
}

// MARK: Request Authentication
//
extension RequestProcessor: RequestAdapter {
    func adapt(_ urlRequest: URLRequest) throws -> URLRequest {
        return try requestAuthenticator.authenticate(urlRequest)
    }
}

// MARK: Retrying Request
//
extension RequestProcessor: RequestRetrier {
    func should(_ manager: Alamofire.SessionManager,
                retry request: Alamofire.Request,
                with error: Error,
                completion: @escaping Alamofire.RequestRetryCompletion) {
        guard
            request.retryCount == 0, // Only retry once
            let urlRequest = request.request,
            requestAuthenticator.shouldRetry(urlRequest), // Retry only REST API requests that use application password
            shouldRetry(error) // Retry only specific errors
        else {
            return completion(false, 0.0)
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
                completeRequests(true)
            } catch {
                isAuthenticating = false
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
        requestsToRetry.forEach { (completion) in
            completion(shouldRetry, 0.0)
        }
        requestsToRetry.removeAll()
    }
}
