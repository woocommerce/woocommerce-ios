import Alamofire
import Foundation

/// An authenticator to handle cookie-nonce authentication.
/// This differs from WordPressKit's version by handling the nonce retrieval as a separate request
/// instead of a redirect from the login request - to fix issues with Pressable sites.
///
/// This authenticator uses Ajax nonce retrieval method by default
/// since we are not supporting sites with WP versions earlier than 5.6.0.
///
final class CookieNonceAuthenticator: RequestInterceptor {
    private let username: String
    private let password: String
    private let loginURL: URL
    private let adminURL: URL
    private var nonce: String?

    private var canRetry = true
    private var isAuthenticating = false
    private var requestsToRetry = [(RetryResult) -> Void]()

    init(configuration: CookieNonceAuthenticatorConfiguration) {
        self.username = configuration.username
        self.password = configuration.password
        self.loginURL = configuration.loginURL
        self.adminURL = configuration.adminURL
    }

    // MARK: Request Adapter
    func adapt(_ urlRequest: URLRequest, for session: Alamofire.Session, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
        guard let nonce else {
            return completion(.success(urlRequest))
        }
        var adaptedRequest = urlRequest
        adaptedRequest.addValue(nonce, forHTTPHeaderField: "X-WP-Nonce")
        completion(.success(adaptedRequest))
    }

    // MARK: Retrier
    func retry(_ request: Alamofire.Request, for session: Alamofire.Session, dueTo error: Swift.Error, completion: @escaping (RetryResult) -> Void) {
        guard
            canRetry,
            // Only retry once
            request.retryCount == 0,
            // And don't retry the login request
            request.request?.url != loginURL,
            // Only retry because of failed authorization
            case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = error as? AFError
        else {
            return completion(.doNotRetry)
        }

        requestsToRetry.append(completion)
        if !isAuthenticating {
            startLoginSequence(session: session)
        }
    }

    enum Error: Swift.Error {
        case invalidNewPostURL
        case postLoginFailed(Swift.Error)
        case missingNonce
        case unknown(Swift.Error)
    }
}

// MARK: Private helpers
private extension CookieNonceAuthenticator {

    func startLoginSequence(session: Session) {
        DDLogInfo("Starting Cookie+Nonce login sequence for \(loginURL)")
        guard let nonceRetrievalURL = buildNonceRequestURL(base: adminURL),
              let nonceRequest = try? URLRequest(url: nonceRetrievalURL, method: .get) else {
            return invalidateLoginSequence(error: .invalidNewPostURL)
        }
        Task(priority: .medium) {
            do {
                try await handleSiteCredentialLogin(session: session)
                let page = try await handleNonceRetrieval(request: nonceRequest, session: session)
                guard let nonce = readNonceFromAjaxAction(html: page) else {
                    throw CookieNonceAuthenticator.Error.missingNonce
                }
                self.nonce = nonce
                successfulLoginSequence()
            } catch let error as CookieNonceAuthenticator.Error {
                invalidateLoginSequence(error: error)
            } catch {
                DDLogError("⛔️ Cookie nonce authenticator failed with uncaught error: \(error)")

                //  Complete the pending requests without retrying. This informs the clients waiting for response about the failure.
                //
                completeRequests(false)
            }
        }
    }

    func handleSiteCredentialLogin(session: Session) async throws {
        let request = authenticatedRequest()
        return try await withCheckedThrowingContinuation { continuation in
            session.request(request)
                .validate()
                .response { response in
                    if let error = response.error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume(returning: ())
                    }
                }
        }
    }

    func handleNonceRetrieval(request: URLRequest, session: Session) async throws -> String {
        try await withCheckedThrowingContinuation { continuation -> Void in
            session.request(request)
                .validate()
                .responseString { response in
                    switch response.result {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .success(let page):
                        continuation.resume(returning: page)
                    }
                }
        }
    }

    func successfulLoginSequence() {
        DDLogInfo("Completed Cookie+Nonce login sequence for \(loginURL)")
        completeRequests(true)
    }

    func invalidateLoginSequence(error: Error) {
        canRetry = false
        if case .postLoginFailed(let originalError) = error {
            let nsError = originalError as NSError
            if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorNotConnectedToInternet {
                canRetry = true
            }
        }
        DDLogInfo("Aborting Cookie+Nonce login sequence for \(loginURL)")
        completeRequests(false)
        isAuthenticating = false
    }

    func completeRequests(_ shouldRetry: Bool) {
        let result: RetryResult = shouldRetry ? .retryWithDelay(0) : .doNotRetry
        requestsToRetry.forEach { (completion) in
            completion(result)
        }
        requestsToRetry.removeAll()
    }

    func readNonceFromAjaxAction(html: String) -> String? {
        html.isEmpty ? nil : html
    }

    func buildNonceRequestURL(base: URL) -> URL? {
        URL(string: "admin-ajax.php?action=rest-nonce", relativeTo: base)
    }
}

// MARK: Public helpers
extension CookieNonceAuthenticator {
    func authenticatedRequest() -> URLRequest {
        var request = URLRequest(url: loginURL)

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        parameters.append(URLQueryItem(name: "pwd", value: password))
        parameters.append(URLQueryItem(name: "rememberme", value: "true"))
        var components = URLComponents()
        components.queryItems = parameters

        /// `percentEncodedQuery` creates a validly escaped URL query component, but
        /// doesn't encode the '+'. Percent encodes '+' to avoid this ambiguity.
        let characterSet = CharacterSet(charactersIn: "+").inverted
        request.httpBody = components.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: characterSet)?.data(using: .utf8)
        return request
    }
}
