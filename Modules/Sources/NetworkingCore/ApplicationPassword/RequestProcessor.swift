import Alamofire
import Foundation

protocol RequestProcessorDelegate: AnyObject {
    func didFailToAuthenticateRequestWithApplicationPassword(siteID: Int64)
}

/// Authenticates and retries requests
///
final class RequestProcessor: RequestInterceptor {
    private var requestsToRetry = [(RetryResult) -> Void]()

    private var isAuthenticating = false

    private var requestAuthenticator: RequestAuthenticator

    private let notificationCenter: NotificationCenter

    private var isAuthenticatedWithWPCom = false

    private var currentSiteID: Int64?

    weak var delegate: RequestProcessorDelegate?

    init(requestAuthenticator: RequestAuthenticator,
         notificationCenter: NotificationCenter = .default) {
        self.requestAuthenticator = requestAuthenticator
        self.notificationCenter = notificationCenter
    }

    func updateAuthenticator(_ authenticator: RequestAuthenticator) {
        requestAuthenticator = authenticator
        isAuthenticatedWithWPCom = {
            switch authenticator.credentials {
            case .some(.wpcom): true
            default: false
            }
        }()
        currentSiteID = authenticator.jetpackSiteID
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
            isAuthenticating = true
            generateApplicationPassword()
        }
    }
}

// MARK: Helpers
//
private extension RequestProcessor {
    func generateApplicationPassword() {
        Task(priority: .medium) { @MainActor in
            do {
                let _ = try await requestAuthenticator.generateApplicationPassword()
                isAuthenticating = false

                // Post a notification for tracking
                notificationCenter.post(name: .ApplicationPasswordsNewPasswordCreated, object: nil, userInfo: nil)

                completeRequests(true)
            } catch {

                // Post a notification for tracking
                notificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: nil)

                if isAuthenticatedWithWPCom, let currentSiteID {
                    await retryPasswordGenerationIfNeeded(error: error, siteID: currentSiteID)
                } else {
                    isAuthenticating = false
                    completeRequests(false)
                }
            }
        }
    }

    @MainActor
    func retryPasswordGenerationIfNeeded(error: Error, siteID: Int64) async {
        defer {
            isAuthenticating = false
        }
        switch error {
        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 409)):
            /// Password with the same name already exists. Request deletion remotely and retry.
            do {
                try await requestAuthenticator.deleteApplicationPassword()
                generateApplicationPassword()
            } catch {
                completeRequests(false)
            }
        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)):
            /// Site doesn't support application password
            completeRequests(false)
            delegate?.didFailToAuthenticateRequestWithApplicationPassword(siteID: siteID)
        default:
            completeRequests(false)
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
