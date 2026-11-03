import Alamofire
import Foundation

protocol RequestProcessorDelegate: AnyObject {
    func didFailToAuthenticateRequestWithAppPassword(siteID: Int64, error: Error)
}

/// Authenticates and retries requests
///
/// Alamofire can invoke interceptors from multiple queues; mutable retry state is synchronized by `RequestProcessorState`.
final class RequestProcessor: RequestInterceptor, @unchecked Sendable {
    private let notificationCenter: NotificationCenter

    private let state: RequestProcessorState

    init(requestAuthenticator: RequestAuthenticator,
         notificationCenter: NotificationCenter = .default) {
        self.notificationCenter = notificationCenter
        self.state = RequestProcessorState(requestAuthenticator: requestAuthenticator)
    }

    weak var delegate: RequestProcessorDelegate? {
        get { state.delegate }
        set { state.delegate = newValue }
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

        if state.authenticator.canGenerateApplicationPassword() {
            // A 401 means the site rejected the saved password; otherwise none was saved.
            let isRegeneration = (error as? AFError)?.responseCode == 401
            // Non-pretty-permalink sites carry the REST route as a query parameter.
            let restRoute = urlRequest.url.flatMap { URLComponents(url: $0, resolvingAgainstBaseURL: false) }?
                .queryItems?.first { $0.name == "rest_route" }?.value
            switch state.enqueueGeneration(completion,
                                           path: restRoute ?? urlRequest.url?.path ?? "",
                                           isRegeneration: isRegeneration) {
            case .started:
                generateApplicationPassword()
            case .joined:
                break
            case .paused(let lastFailure):
                DDLogInfo("Skipping application password creation during the cooldown after: \(lastFailure)")
                completion(.doNotRetryWithError(lastFailure))
            }
            return
        }

        guard state.authenticator.canValidateApplicationPassword() else {
            completion(.doNotRetry)
            return
        }

        let shouldStartValidation = state.enqueueRetry(completion)

        if shouldStartValidation {
            validateApplicationPassword()
        }
    }
}

// MARK: Helpers
//
private extension RequestProcessor {
    func generateApplicationPassword() {
        Task(priority: .medium) { @MainActor [weak self] in
            guard let self, let generation = self.state.runningGeneration else {
                return
            }
            let authenticator = generation.authenticator
            var userInfo: [AnyHashable: Any] = [
                ApplicationPasswordGenerationUserInfoKey.path: generation.path,
                ApplicationPasswordGenerationUserInfoKey.isRegeneration: generation.isRegeneration
            ]
            // The attempt can end after a logout and a new login, so observers need to know whose credentials it used.
            userInfo[ApplicationPasswordGenerationUserInfoKey.siteAddress] = authenticator.credentials?.siteAddress
            userInfo[ApplicationPasswordGenerationUserInfoKey.username] = authenticator.credentials?.username
            do {
                let _ = try await authenticator.generateApplicationPassword()
                let finished = self.state.finishGeneration(failure: nil)

                // Post a notification for tracking
                self.notificationCenter.post(name: .ApplicationPasswordsNewPasswordCreated, object: nil, userInfo: userInfo)

                self.completeGeneration(finished, with: .retryWithDelay(0))
            } catch {

                // Post a notification for tracking
                self.notificationCenter.post(name: .ApplicationPasswordsGenerationFailed, object: error, userInfo: userInfo)

                let shouldRetry = await self.checkIfRetryingGenerationIsNeeded(for: error)
                if shouldRetry {
                    self.generateApplicationPassword()
                } else {
                    let finished = self.state.finishGeneration(failure: error)
                    self.completeGeneration(finished, with: .doNotRetryWithError(error))
                    if let siteID = generation.siteID {
                        self.notifyFailureIfNeeded(error, for: siteID)
                    }
                }
            }
        }
    }

    func completeGeneration(_ finished: RequestProcessorState.FinishedGeneration, with result: RetryResult) {
        finished.completions.forEach { $0(result) }
        // Requests for stores the user has left: a retry would use the selected store's authenticator,
        // which would send the WordPress.com token to the other store's site.
        finished.dropped.forEach { $0(.doNotRetry) }
        if finished.startsNext {
            generateApplicationPassword()
        }
    }

    func validateApplicationPassword() {
        Task(priority: .medium) { @MainActor [weak self] in
            guard let self else { return }
            let authenticator = self.state.authenticator
            do {
                let result = try await authenticator.validateApplicationPassword()
                self.state.setAuthenticating(false)

                if case let .invalid(error) = result {
                    self.notificationCenter.post(name: .ApplicationPasswordInvalidated, object: error, userInfo: nil)
                }

                self.completeRequests()
            } catch {
                self.state.setAuthenticating(false)
                self.completeRequests()
            }
        }
    }

    /// Checks error code to retry or mark site as unsupported for app password.
    /// Returns whether retry is needed.
    /// Runs before `finishGeneration`, so the running generation is still the one that failed.
    @MainActor
    func checkIfRetryingGenerationIsNeeded(for error: Error) async -> Bool {
        guard let authenticator = state.runningGeneration?.authenticator, authenticator.jetpackSiteID != nil else {
            return false
        }
        switch error {
        case NetworkError.unacceptableStatusCode(let statusCode, _) where statusCode == 409:
            /// Password with the same name already exists. Request deletion remotely and retry.
            do {
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

    func completeRequests() {
        let pendingCompletions = state.drainPendingRetries()
        pendingCompletions.forEach { completion in
            completion(.doNotRetry)
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

    /// Posted when the stored application password is rejected by the site.
    ///
    static let ApplicationPasswordInvalidated = NSNotification.Name(rawValue: "ApplicationPasswordInvalidated")

    /// Posted when site is flagged as unsupported for app password
    ///
    static let JetpackSiteFlaggedUnsupportedForApplicationPassword = NSNotification.Name(rawValue: "JetpackSiteFlaggedUnsupportedForApplicationPassword")

    /// Posted when site is detected as eligible for app password authentication
    ///
    static let JetpackSiteEligibleForAppPasswordSupport = NSNotification.Name(rawValue: "JetpackSiteEligibleForAppPasswordSupport")
}

public enum ApplicationPasswordGenerationUserInfoKey {
    public static let path = "path"
    public static let isRegeneration = "isRegeneration"
    public static let siteAddress = "siteAddress"
    public static let username = "username"
}

private extension RequestProcessor {
    final class RequestProcessorState {
        // Password validation only. Creation uses `running` and `waiting`.
        private var requestsToRetry: [(RetryResult) -> Void]
        private var isAuthenticating: Bool
        private var requestAuthenticator: RequestAuthenticator
        private var siteID: Int64?
        private var cooldown = ApplicationPasswordCreationCooldown()
        /// One creation runs at a time, because every store saves its password in the same keychain slot.
        private var running: Generation?
        /// Requests for other stores, waiting for the running creation to end.
        private var waiting: [Int64?: Generation] = [:]
        private weak var _delegate: RequestProcessorDelegate?

        struct Generation {
            let siteID: Int64?
            let authenticator: RequestAuthenticator
            let path: String
            let isRegeneration: Bool
            var completions: [(RetryResult) -> Void] = []
        }

        typealias FinishedGeneration = (completions: [(RetryResult) -> Void], dropped: [(RetryResult) -> Void], startsNext: Bool)

        enum GenerationQueueing {
            case started
            case joined
            case paused(lastFailure: Error)
        }

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

        var delegate: RequestProcessorDelegate? {
            get { queue.sync { _delegate } }
            set { queue.sync { _delegate = newValue } }
        }

        var authenticator: RequestAuthenticator {
            queue.sync { requestAuthenticator }
        }

        var runningGeneration: Generation? {
            queue.sync { running }
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

        func enqueueGeneration(_ completion: @escaping (RetryResult) -> Void,
                               path: String,
                               isRegeneration: Bool) -> GenerationQueueing {
            queue.sync {
                if let lastFailure = cooldown.pausedFailure(at: ContinuousClock.now) {
                    return .paused(lastFailure: lastFailure)
                }
                let generation = Generation(siteID: siteID,
                                            authenticator: requestAuthenticator,
                                            path: path,
                                            isRegeneration: isRegeneration)
                guard let current = running else {
                    running = generation
                    running?.completions.append(completion)
                    return .started
                }
                if current.siteID == siteID {
                    running?.completions.append(completion)
                } else {
                    waiting[siteID, default: generation].completions.append(completion)
                }
                return .joined
            }
        }

        func finishGeneration(failure: Error?) -> FinishedGeneration {
            queue.sync {
                let finished = running
                let finishedRequests = finished?.completions ?? []
                // Promote the hand-off's selected store so its password is written after the running creation.
                running = waiting.removeValue(forKey: siteID)
                let waitingRequests = waiting.values.flatMap { $0.completions }
                waiting.removeAll()
                // A creation for a store the user switched away from leaves the selected store's pause alone,
                // and its own requests are dropped like the other stores' waiting requests.
                guard let finished, finished.siteID == siteID else {
                    return ([], finishedRequests + waitingRequests, running != nil)
                }
                if let failure {
                    cooldown.recordFailure(failure, at: ContinuousClock.now)
                } else {
                    cooldown.reset()
                }
                return (finishedRequests, waitingRequests, running != nil)
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
                // Rebuilding the same store's authenticator must not clear its cooldown.
                if siteID != authenticator.jetpackSiteID {
                    cooldown.reset()
                }
                requestAuthenticator = authenticator
                siteID = authenticator.jetpackSiteID
            }
        }
    }
}
