import Foundation
import Alamofire
import os

/// Thread-safe handler for network error tracking and retry logic
final class AlamofireNetworkErrorHandler: Sendable {
    private struct State {
        var appPasswordFailures: [Int64: Int] = [:]
        var retriedJetpackRequests: [RetriedJetpackRequest] = []
    }

    private let state = OSAllocatedUnfairLock(initialState: State())

    /// Serializes the read-modify-write of the unsupported list. Kept apart from `state` so that KVO
    /// observers of `userDefaults` never run while `state` is held.
    private let userDefaultsLock = OSAllocatedUnfairLock()

    /// `UserDefaults` is documented as thread-safe but is not marked `Sendable` in the current SDK.
    /// Every write goes through `userDefaultsLock`. Remove the annotation once the SDK marks it `Sendable`.
    nonisolated(unsafe) private let userDefaults: UserDefaults
    private let credentials: Credentials?
    private let notificationCenter: NotificationCenter

    init(credentials: Credentials?,
         userDefaults: UserDefaults = .standard,
         notificationCenter: NotificationCenter = .default) {
        self.credentials = credentials
        self.userDefaults = userDefaults
        self.notificationCenter = notificationCenter
    }

    // MARK: - Public interface

    func prepareAppPasswordSupport(for siteID: Int64) {
        state.withLock { _ = $0.appPasswordFailures.removeValue(forKey: siteID) }
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
            state.withLock { $0.retriedJetpackRequests.append(retriedRequest) }
            logRequestFailure(request: convertedURLRequest, error: error)
            return true
        }
        return false
    }

    func flagSiteAsUnsupportedForAppPasswordIfNeeded(
        originalRequest: URLRequestConvertible,
        failure: Error?
    ) {
        guard let urlRequest = try? originalRequest.asURLRequest() else { return }
        let retriedRequest: RetriedJetpackRequest? = state.withLock { state in
            let retriedRequestIndex = state.retriedJetpackRequests.firstIndex { retriedRequest in
                guard let retriedURLRequest = try? retriedRequest.request.asURLRequest() else {
                    return false
                }
                return urlRequest.url == retriedURLRequest.url &&
                       urlRequest.httpMethod == retriedURLRequest.httpMethod
            }

            guard let index = retriedRequestIndex else { return nil }

            return state.retriedJetpackRequests.remove(at: index)
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
        let retriedJetpackRequests = state.withLock { $0.retriedJetpackRequests }
        return retriedJetpackRequests.contains { retriedRequest in
            guard let currentItem = try? retriedRequest.request.asURLRequest() else {
                return false
            }
            return currentItem.url == urlRequest.url &&
                   currentItem.httpMethod == urlRequest.httpMethod
        }
    }

    func flagSiteAsUnsupported(for siteID: Int64, flow: RequestFlow, cause: AppPasswordFlagCause, error: Error) {
        // Use a dedicated lock for UserDefaults operations to:
        // 1. Prevent race conditions where concurrent writes overwrite each other
        // 2. Avoid deadlock by not using the main queue that KVO observers may need
        userDefaultsLock.withLock {
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
        let updatedCount = state.withLock { state in
            let updatedCount = (state.appPasswordFailures[siteID] ?? 0) + 1
            state.appPasswordFailures[siteID] = updatedCount
            return updatedCount
        }
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
    }

    func clearUnsupportedFlag(for siteID: Int64) {
        // Use a dedicated lock for UserDefaults operations to:
        // 1. Prevent race conditions where concurrent writes overwrite each other
        // 2. Avoid deadlock by not using the main queue that KVO observers may need
        userDefaultsLock.withLock {
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
