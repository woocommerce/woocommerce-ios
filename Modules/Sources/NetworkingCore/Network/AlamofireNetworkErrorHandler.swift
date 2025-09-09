import Foundation
import Alamofire

/// Thread-safe handler for network error tracking and retry logic
final class AlamofireNetworkErrorHandler {
    private let queue = DispatchQueue(label: "com.networkingcore.errorhandler", attributes: .concurrent)
    private let userDefaults: UserDefaults
    private let credentials: Credentials?

    private var _appPasswordFailures: [Int64: Int] = [:]
    private var _retriedJetpackRequests: [RetriedJetpackRequest] = []

    init(credentials: Credentials?, userDefaults: UserDefaults = .standard) {
        self.credentials = credentials
        self.userDefaults = userDefaults
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

    func resetFailureCount(for siteID: Int64) {
        appPasswordFailures.removeValue(forKey: siteID)
    }

    func shouldRetryJetpackRequest(originalRequest: URLRequestConvertible,
                                   convertedRequest: URLRequestConvertible,
                                   failure: Error?) -> Bool {
        guard let error = failure,
              let request = originalRequest as? JetpackRequest,
              convertedRequest is RESTRequest,
              case .some(.wpcom) = self.credentials else {
            return false
        }

        let isExpectedError: Bool = {
            switch error {
            case AFError.requestAdaptationFailed:
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
            return true
        }
        return false
    }

    func flagSiteAsUnsupportedForAppPasswordIfNeeded(
        originalRequest: URLRequestConvertible,
        failure: Error?
    ) {
        let retriedRequestIndex = retriedJetpackRequests.firstIndex { retriedRequest in
            let urlRequest = try? originalRequest.asURLRequest()
            let retriedRequest = try? retriedRequest.request.asURLRequest()
            return urlRequest == retriedRequest
        }

        guard let index = retriedRequestIndex else { return }

        let retriedRequest = retriedJetpackRequests[index]

        if failure == nil {
            let siteID = retriedRequest.request.siteID
            let originalFailure = retriedRequest.error
            switch originalFailure {
            case NetworkError.unacceptableStatusCode(statusCode: 401, _),
                NetworkError.unacceptableStatusCode(statusCode: 403, _),
                NetworkError.unacceptableStatusCode(statusCode: 429, _):
                flagSiteAsUnsupported(for: siteID)
            default:
                if let networkError = originalFailure as? NetworkError,
                   let code = networkError.errorCode,
                    AppPasswordConstants.disabledCodes.contains(code) {
                    flagSiteAsUnsupported(for: siteID)
                } else {
                    incrementFailureCount(for: siteID)
                }
            }
        }

        retriedJetpackRequests.remove(at: index)
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
        retriedJetpackRequests.contains { retriedRequest in
            let urlRequest = try? request.asURLRequest()
            let currentItem = try? retriedRequest.request.asURLRequest()
            return currentItem == urlRequest
        }
    }

    func flagSiteAsUnsupported(for siteID: Int64) {
        queue.sync(flags: .barrier) {
            var currentList = userDefaults.applicationPasswordUnsupportedList
            currentList[String(siteID)] = Date()
            userDefaults.applicationPasswordUnsupportedList = currentList
        }
    }

    func siteFlaggedAsUnsupported(siteID: Int64, unsupportedList: [String: Date]) -> Bool {
        guard let flagDate = unsupportedList[String(siteID)] else {
            return false
        }

        let timeElapsed = Date().timeIntervalSince1970 - flagDate.timeIntervalSince1970
        if timeElapsed < Constants.flagRefreshDuration {
            return true
        } else {
            clearUnsupportedFlag(for: siteID)
            return false
        }
    }
}

// MARK: Private helpers
private extension AlamofireNetworkErrorHandler {
    func incrementFailureCount(for siteID: Int64) {
        let currentFailureCount = appPasswordFailures[siteID] ?? 0
        let updatedCount = currentFailureCount + 1
        if updatedCount == AppPasswordConstants.requestFailureThreshold {
            flagSiteAsUnsupported(for: siteID)
        }
        appPasswordFailures[siteID] = updatedCount
    }

    func clearUnsupportedFlag(for siteID: Int64) {
        queue.sync(flags: .barrier) {
            let currentList = userDefaults.applicationPasswordUnsupportedList
            userDefaults.applicationPasswordUnsupportedList = currentList.filter { flag in
                flag.key != String(siteID)
            }
        }
    }

    enum Constants {
        static let flagRefreshDuration: Double = 60 * 60 * 24 * 14 // flag can be reset after 14 days.
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
