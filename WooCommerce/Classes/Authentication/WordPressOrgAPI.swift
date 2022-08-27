import Alamofire
import Foundation
import WordPressKit
import WordPressAuthenticator
import class Networking.UserAgent

/// Error constants for the WordPress.org REST API

/// - RequestSerializationFailed: The serialization of the request failed
///
enum WordPressOrgRestApiError: Int, Error {
    case requestSerializationFailed
}

/// Class to handle WP.org REST API requests.
///
final class WordPressOrgAPI {
    private let apiBase: URL
    private let authenticator: Authenticator?
    private let userAgent: String?

    init(apiBase: URL, authenticator: Authenticator? = nil, userAgent: String? = nil) {
        self.apiBase = apiBase
        self.authenticator = authenticator
        self.userAgent = userAgent
    }

    convenience init?(credentials: WordPressOrgCredentials) {
        guard let baseURL = try? (credentials.siteURL + "/wp-json/").asURL(),
              let authenticator = credentials.makeCookieNonceAuthenticator() else {
            return nil
        }
        self.init(apiBase: baseURL, authenticator: authenticator, userAgent: UserAgent.defaultUserAgent)
    }

    func request(method: HTTPMethod,
                 path: String,
                 parameters: [String: AnyObject]?) async throws -> Data? {
        return try await withCheckedThrowingContinuation { [weak self] continuation in
            guard let self = self else { return }
            let relativePath = path.removingPrefix("/")
            guard let url = URL(string: relativePath, relativeTo: apiBase) else {
                return continuation.resume(throwing: WordPressOrgRestApiError.requestSerializationFailed)
            }

            self.sessionManager.request(url, method: method, parameters: parameters, encoding: URLEncoding.default)
                .validate()
                .responseData(completionHandler: { (response) in
                switch response.result {
                case .success(let responseObject):
                    continuation.resume(returning: responseObject)
                case .failure(let error):
                    DDLogWarn("⚠️ Error requesting \(url): \(error.localizedDescription)")
                    continuation.resume(throwing: error)
                }

            })
        }
    }

    /// Cancels all ongoing and makes the session so the object will not fullfil any more request
    ///
    func invalidateAndCancelTasks() {
        sessionManager.session.invalidateAndCancel()
    }

    private lazy var sessionManager: Alamofire.SessionManager = {
        let sessionConfiguration = URLSessionConfiguration.default
        let sessionManager = self.makeSessionManager(configuration: sessionConfiguration)
        return sessionManager
    }()

    private func makeSessionManager(configuration sessionConfiguration: URLSessionConfiguration) -> Alamofire.SessionManager {
        var additionalHeaders: [String: AnyObject] = [:]
        if let userAgent = self.userAgent {
            additionalHeaders["User-Agent"] = userAgent as AnyObject?
        }

        sessionConfiguration.httpAdditionalHeaders = additionalHeaders

        let sessionManager = Alamofire.SessionManager(configuration: sessionConfiguration)
        sessionManager.adapter = authenticator
        sessionManager.retrier = authenticator
        return sessionManager
    }
}
