import Alamofire
import Foundation

protocol RequestProcessorDelegate: AnyObject {
    func didFailToAuthenticateRequestWithAppPassword(siteID: Int64, error: Error)
}

/// Authenticates and retries requests
///
final class RequestProcessor: RequestInterceptor {
    private let notificationCenter: NotificationCenter

    private let state: RequestProcessorState

    weak var delegate: RequestProcessorDelegate?

    init(requestAuthenticator: RequestAuthenticator,
         notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        self.state = RequestProcessorState(requestAuthenticator: requestAuthenticator)
    }

    func updateAuthenticator(_ authenticator: RequestAuthenticator) {
        state.updateAuthenticator(authenticator)
    }
}

// MARK: Request Authentication
//
extension RequestProcessor: RequestAdapter {
    func adapt(_ urlRequest: URLRequest, for session: Session, completion: @escaping (Result<URLRequest, Error>) -> Void) {
        let authenticator = state.authenticator
        let result = Result { try authenticator.authenticate(urlRequest) }
        completion(result)
    }
}

// MARK: Retrying Request
//
extension RequestProcessor: RequestRetrier {
    func retry(_ request: Alamofire.Request, for session: Session, dueTo error: Error, completion: @escaping (RetryResult) -> Void) {
        guard request.retryCount == 0, // Only retry once
              let urlRequest = request.request else {
            completion(.doNotRetry)
            return
        }

        guard shouldRetry(error) else {
            completion(.doNotRetry)
            return
        }

        let shouldRetryRequest = state.shouldRetry(urlRequest)

        guard shouldRetryRequest else {
            completion(.doNotRetry)
            return
        }

        let shouldStartAuthentication = state.enqueueRetry(completion)

        if shouldStartAuthentication {
            generateApplicationPassword()
        }
    }
}

// MARK: Helpers
//
private extension RequestProcessor {
    func generateApplicationPassword() {
        Task(priority: .medium) { @MainActor [weak self] in
            guard let self else { return }
            let authenticator = self.state.authenticator
            do {
                let _ = try await authenticator.generateApplicationPassword()
                self.state.setAuthenticating(false)

                // Post a notification for tracking
                self.notificationCenter.post(name: .ApplicationPasswordsNewPasswordCreated, object: nil, userInfo: nil)

                self.completeRequests(true)
            } catch {

                // Post a notification for tracking
                self.notificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

                let shouldRetry = await self.checkIfRetryingGenerationIsNeeded(for: error)
                if shouldRetry {
                    self.generateApplicationPassword()
                } else {
                    self.state.setAuthenticating(false)
                    self.completeRequests(false, error: error)
                    if let siteID = self.state.currentSiteID {
                        self.notifyFailureIfNeeded(error, for: siteID)
                    }
                }
            }
        }
    }

    /// Checks error code to retry or mark site as unsupported for app password.
    /// Returns whether retry is needed.
    @MainActor
    func checkIfRetryingGenerationIsNeeded(for error: Error) async -> Bool {
        guard state.currentSiteID != nil else {
            return false
        }
        switch error {
        case NetworkError.unacceptableStatusCode(let statusCode, _) where statusCode == 409:
            /// Password with the same name already exists. Request deletion remotely and retry.
            do {
                let authenticator = state.authenticator
                try await authenticator.deleteApplicationPassword()
                return true
            } catch {
                return false
            }
        default:
            return false
        }
    }

    func notifyFailureIfNeeded(_ error: Error, for siteID: Int64) {
        let appPasswordNotSupported: Bool = {
            switch error {
            case NetworkError.notFound:
                return true
            case let networkError as NetworkError:
                if let code = networkError.errorCode,
                   AppPasswordConstants.disabledCodes.contains(code) {
                    return true
                }
                return false
            default:
                return false
            }
        }()
        if appPasswordNotSupported {
            delegate?.didFailToAuthenticateRequestWithAppPassword(siteID: siteID, error: error)
        }
    }

    func shouldRetry(_ error: Error) -> Bool {
        switch error {
        case RequestAuthenticatorError.applicationPasswordNotAvailable,
            AFError.requestAdaptationFailed(RequestAuthenticatorError.applicationPasswordNotAvailable),
            AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)): // Failed authorization
            return true
        default:
            return false
        }
    }

    func completeRequests(_ shouldRetry: Bool, error: Error? = nil) {
        let result: RetryResult = {
            if shouldRetry {
                .retryWithDelay(0)
            } else if let error {
                .doNotRetryWithError(error)
            } else {
                .doNotRetry
            }
        }()
        let pendingCompletions = state.drainPendingRetries()
        pendingCompletions.forEach { completion in
            completion(result)
        }
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

    /// Posted when site is flagged as unsupported for app password
    ///
    static let JetpackSiteFlaggedUnsupportedForApplicationPassword = NSNotification.Name(rawValue: "JetpackSiteFlaggedUnsupportedForApplicationPassword")

    /// Posted when site is detected as eligible for app password authentication
    ///
    static let JetpackSiteEligibleForAppPasswordSupport = NSNotification.Name(rawValue: "JetpackSiteEligibleForAppPasswordSupport")
}

private extension RequestProcessor {
    final class RequestProcessorState {
        private var requestsToRetry: [(RetryResult) -> Void]
        private var isAuthenticating: Bool
        private var requestAuthenticator: RequestAuthenticator
        private var siteID: Int64?

        private let queue = DispatchQueue(
            label: "com.woocommerce.networking.request-processor.state-queue",
            qos: .userInitiated
        )

        init(requestAuthenticator: RequestAuthenticator) {
            self.requestsToRetry = []
            self.isAuthenticating = false
            self.requestAuthenticator = requestAuthenticator
            self.siteID = requestAuthenticator.jetpackSiteID
        }

        var authenticator: RequestAuthenticator {
            queue.sync { requestAuthenticator }
        }

        var currentSiteID: Int64? {
            queue.sync { siteID }
        }

        func shouldRetry(_ request: URLRequest) -> Bool {
            queue.sync { requestAuthenticator.shouldRetry(request) }
        }

        func enqueueRetry(_ completion: @escaping (RetryResult) -> Void) -> Bool {
            queue.sync {
                requestsToRetry.append(completion)
                if isAuthenticating {
                    return false
                }
                isAuthenticating = true
                return true
            }
        }

        func setAuthenticating(_ value: Bool) {
            queue.sync {
                isAuthenticating = value
            }
        }

        func drainPendingRetries() -> [(RetryResult) -> Void] {
            queue.sync {
                let completions = requestsToRetry
                requestsToRetry.removeAll()
                return completions
            }
        }

        func updateAuthenticator(_ authenticator: RequestAuthenticator) {
            queue.sync {
                requestAuthenticator = authenticator
                siteID = authenticator.jetpackSiteID
            }
        }
    }
}
