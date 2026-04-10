import Foundation
import Alamofire

/// Thread-safe handler for network error tracking and retry logic
final class AlamofireNetworkErrorHandler {
    private let queue = DispatchQueue(label: "com.networkingcore.errorhandler", attributes: .concurrent)
    /// Serial queue for UserDefaults operations to prevent race conditions while avoiding deadlocks
    private let userDefaultsQueue = DispatchQueue(label: "com.networkingcore.errorhandler.userdefaults")
    private let userDefaults: UserDefaults
    private let credentials: Credentials?
    private let notificationCenter: NotificationCenter

    private var _appPasswordFailures: [Int64: Int] = [:]
    private var _retriedJetpackRequests: [RetriedJetpackRequest] = []

    init(credentials: Credentials?,
         userDefaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default) {
        self.credentials = credentials
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
    }

    // MARK: - Thread-safe property access

    private var appPasswordFailures: [Int64: Int] {
        get {
            queue.sync { _appPasswordFailures }
        }
        set {
            queue.sync(flags: .barrier) { [weak self] in
                self?._appPasswordFailures = newValue
            }
        }
    }

    private var retriedJetpackRequests: [RetriedJetpackRequest] {
        get {
            queue.sync { _retriedJetpackRequests }
        }
        set {
            queue.sync(flags: .barrier) { [weak self] in
                self?._retriedJetpackRequests = newValue
            }
        }
    }

    // MARK: - Public interface

    func prepareAppPasswordSupport(for siteID: Int64) {
        appPasswordFailures.removeValue(forKey: siteID)
        notificationCenter.post(name: .JetpackSiteEligibleForAppPasswordSupport, object: siteID)
    }

    func shouldRetryJetpackRequest(originalRequest: URLRequestConvertible,
                                   convertedRequest: URLRequestConvertible,
                                   failure: Error?) -> Bool {
        guard let error = failure,
              let request = originalRequest as? JetpackRequest,
              convertedRequest is RESTRequest,
              let convertedURLRequest = try? convertedRequest.asURLRequest(),
              case .some(.wpcom) = self.credentials else {
            return false
        }

        let isExpectedError: Bool = {
            switch error {
            case AFError.requestRetryFailed:
                return true
            case _ as NetworkError:
                return true
            default:
                return false
            }
        }()

        if isExpectedError {
            let retriedRequest = RetriedJetpackRequest(request: request, error: error)
            retriedJetpackRequests.append(retriedRequest)
            logRequestFailure(request: convertedURLRequest, error: error)
            return true
        }
        return false
    }

    func flagSiteAsUnsupportedForAppPasswordIfNeeded(
        originalRequest: URLRequestConvertible,
        failure: Error?
    ) {
        let retriedRequest: RetriedJetpackRequest? = queue.sync(flags: .barrier) { [weak self] in
            guard let self else { return nil }
            guard let urlRequest = try? originalRequest.asURLRequest() else { return nil }
            let retriedRequestIndex = _retriedJetpackRequests.firstIndex { retriedRequest in
                guard let retriedURLRequest = try? retriedRequest.request.asURLRequest() else {
                    return false
                }
                return urlRequest.url == retriedURLRequest.url &&
                       urlRequest.httpMethod == retriedURLRequest.httpMethod
            }

            guard let index = retriedRequestIndex else { return nil }

            return _retriedJetpackRequests.remove(at: index)
        }

        guard let retriedRequest else { return }

        if failure == nil {
            let siteID = retriedRequest.request.siteID
            let originalFailure = retriedRequest.error
            switch originalFailure {
            case NetworkError.unacceptableStatusCode(statusCode: 401, _),
                NetworkError.unacceptableStatusCode(statusCode: 403, _),
                NetworkError.unacceptableStatusCode(statusCode: 429, _):
                flagSiteAsUnsupported(
                    for: siteID,
                    flow: .apiRequest,
                    cause: .majorError,
                    error: originalFailure
                )
            default:
                if let networkError = originalFailure as? NetworkError,
                   let code = networkError.errorCode,
                    AppPasswordConstants.disabledCodes.contains(code) {
                    flagSiteAsUnsupported(
                        for: siteID,
                        flow: .apiRequest,
                        cause: .majorError,
                        error: originalFailure
                    )
                } else {
                    incrementFailureCount(for: siteID, originalFailure: originalFailure)
                }
            }
        }
    }

    func handleFailureForDirectRequestIfNeeded(originalRequest: URLRequestConvertible,
                                               convertedRequest: URLRequestConvertible,
                                               failure: Error?,
                                               onRetry: @escaping () -> Void,
                                               onCompletion: @escaping () -> Void) {
        if shouldRetryJetpackRequest(originalRequest: originalRequest,
                                     convertedRequest: convertedRequest,
                                     failure: failure) {
            onRetry()
        } else {
            flagSiteAsUnsupportedForAppPasswordIfNeeded(originalRequest: originalRequest, failure: failure)
            onCompletion()
        }
    }

    func isRequestRetried(_ request: URLRequestConvertible) -> Bool {
        guard let urlRequest = try? request.asURLRequest() else {
            return false
        }
        return retriedJetpackRequests.contains { retriedRequest in
            guard let currentItem = try? retriedRequest.request.asURLRequest() else {
                return false
            }
            return currentItem.url == urlRequest.url &&
                   currentItem.httpMethod == urlRequest.httpMethod
        }
    }

    func flagSiteAsUnsupported(for siteID: Int64, flow: RequestFlow, cause: AppPasswordFlagCause, error: Error) {
        // Use dedicated serial queue for UserDefaults operations to:
        // 1. Prevent race conditions where concurrent writes overwrite each other
        // 2. Avoid deadlock by not using the main queue that KVO observers may need
        userDefaultsQueue.sync { [weak self] in
            guard let self else { return }
            var currentList = userDefaults.applicationPasswordUnsupportedList
            currentList[String(siteID)] = Date()
            userDefaults.applicationPasswordUnsupportedList = currentList
        }

        /// Tracks error
        let apiErrorCode = (error as? NetworkError)?.errorCode ?? error.localizedDescription
        let httpStatusCode = (error as? NetworkError)?.responseCode  ?? (error as NSError).code

        let tracksProperties: [String: Any] = [
            TracksProperty.flow.rawValue: flow.rawValue,
            TracksProperty.cause.rawValue: cause.rawValue,
            TracksProperty.apiErrorCode.rawValue: apiErrorCode,
            TracksProperty.httpStatusCode.rawValue: httpStatusCode
        ]
        notificationCenter.post(name: .JetpackSiteFlaggedUnsupportedForApplicationPassword, object: tracksProperties)
    }

    func siteFlaggedAsUnsupported(siteID: Int64, unsupportedList: [String: Date]) -> Bool {
        guard let flagDate = unsupportedList[String(siteID)] else {
            return false
        }

        let timeElapsed = Date().timeIntervalSince(flagDate)
        if timeElapsed < Constants.flagRefreshDuration {
            return true
        } else {
            clearUnsupportedFlag(for: siteID)
            return false
        }
    }
}

enum RequestFlow: String {
    case appPasswordGeneration = "app_password_generation"
    case apiRequest = "api_request"
}

enum AppPasswordFlagCause: String {
    case majorError = "major_error"
    case generalFailuresThresholdReached = "general_failures_threshold_reached"
}

// MARK: Private helpers
private extension AlamofireNetworkErrorHandler {
    func incrementFailureCount(for siteID: Int64, originalFailure: Error) {
        let currentFailureCount = appPasswordFailures[siteID] ?? 0
        let updatedCount = currentFailureCount + 1
        if updatedCount == AppPasswordConstants.requestFailureThreshold {
            let flow: RequestFlow
            let failure: Error
            switch originalFailure {
            case AFError.requestRetryFailed(let error, _):
                flow = .appPasswordGeneration
                failure = error
            default:
                flow = .apiRequest
                failure = originalFailure
            }
            flagSiteAsUnsupported(
                for: siteID,
                flow: flow,
                cause: .generalFailuresThresholdReached,
                error: failure
            )
        }
        appPasswordFailures[siteID] = updatedCount
    }

    func clearUnsupportedFlag(for siteID: Int64) {
        // Use dedicated serial queue for UserDefaults operations to:
        // 1. Prevent race conditions where concurrent writes overwrite each other
        // 2. Avoid deadlock by not using the main queue that KVO observers may need
        userDefaultsQueue.sync { [weak self] in
            guard let self else { return }
            let currentList = userDefaults.applicationPasswordUnsupportedList
            let filteredList = currentList.filter { flag in
                flag.key != String(siteID)
            }
            userDefaults.applicationPasswordUnsupportedList = filteredList
        }
    }

    func logRequestFailure(request: URLRequest, error: Error) {
        let networkError: NetworkError? = {
            switch error {
            case AFError.requestRetryFailed(let retryError, _):
                return (retryError as? NetworkError)
            case let networkError as NetworkError:
                return networkError
            default:
                return nil
            }
        }()

        let siteURL = request.url?.host() ?? ""
        let path = request.url?.path(percentEncoded: false) ?? ""
        let method = request.httpMethod ?? ""
        let apiErrorCode = networkError?.errorCode ?? error.localizedDescription
        let httpCode = networkError?.responseCode ?? (error as NSError).code

        DDLogError(
            """
            ⛔️ Request failed using Application Passwords for Jetpack Site:
            - Site URL: \(siteURL)
            - Path: \(path)
            - Method: \(method)
            - Error: HTTP status code \(httpCode)
            - Error message: \(apiErrorCode)
            """
        )
    }

    enum Constants {
        static let flagRefreshDuration: Double = 60 * 60 * 24 * 14 // flag can be reset after 14 days.
    }

    enum TracksProperty: String {
        case flow
        case cause
        case apiErrorCode = "api_error_code"
        case httpStatusCode = "http_status_code"
    }
}
/// Helper type to keep track of retried requests with accompanied error
struct RetriedJetpackRequest {
    let request: JetpackRequest
    let error: Error
}

// MARK: - Constants for direct request error handling
enum AppPasswordConstants {
    static let requestFailureThreshold = 10
    static let disabledCodes = [
        "application_passwords_disabled",
        "application_passwords_disabled_for_user",
        "incorrect_password"
    ]
}
