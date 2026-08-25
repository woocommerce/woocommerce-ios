import Alamofire
import Foundation

/// An authenticator to handle cookie-nonce authentication.
/// This differs from WordPressKit's version by handling the nonce retrieval as a separate request
/// instead of following the login redirect - to fix issues with Pressable sites. Credential responses
/// may redirect to the expected nonce or configured admin base, but nonce retrieval always uses the
/// independently derived nonce URL.
///
/// This authenticator uses Ajax nonce retrieval method by default
/// since we are not supporting sites with WP versions earlier than 5.6.0.
///
final class CookieNonceAuthenticator: RequestInterceptor {
    private let username: String
    private let password: String
    private let endpoints: CookieNonceAuthenticationEndpoints
    private let authenticationSessionFactory: @Sendable (Session) -> Session
    private let state = CookieNonceAuthenticatorState()

    convenience init(configuration: CookieNonceAuthenticatorConfiguration) {
        self.init(
            configuration: configuration,
            authenticationSessionFactory: { session in
                Self.makeAuthenticationSession(from: session)
            }
        )
    }

    init(
        configuration: CookieNonceAuthenticatorConfiguration,
        authenticationSessionFactory: @escaping @Sendable (Session) -> Session
    ) {
        self.username = configuration.username
        self.password = configuration.password
        self.endpoints = configuration.endpoints
        self.authenticationSessionFactory = authenticationSessionFactory
    }

    // MARK: Request Adapter
    func adapt(_ urlRequest: URLRequest, for session: Alamofire.Session, completion: @escaping (Result<URLRequest, Swift.Error>) -> Void) {
        guard let nonce = state.nonce else {
            return completion(.success(urlRequest))
        }
        var adaptedRequest = urlRequest
        adaptedRequest.addValue(nonce, forHTTPHeaderField: "X-WP-Nonce")
        completion(.success(adaptedRequest))
    }

    // MARK: Retrier
    func retry(_ request: Alamofire.Request, for session: Alamofire.Session, dueTo error: Swift.Error, completion: @escaping (RetryResult) -> Void) {
        guard
            state.canRetry,
            // Only retry once
            request.retryCount == 0,
            // And don't retry the login request
            request.request?.url != endpoints.loginEntryURL,
            // Only retry because of failed authorization
            case .responseValidationFailed(reason: .unacceptableStatusCode(code: 401)) = error as? AFError
        else {
            return completion(.doNotRetry)
        }

        let shouldStartAuthentication = state.enqueueRetry(completion)
        if shouldStartAuthentication {
            startLoginSequence(session: session)
        }
    }

    enum Error: Swift.Error {
        case authenticationFailed(CookieNonceAuthenticationFailure)
        case postLoginFailed(Swift.Error)
    }

    private enum PreflightResult {
        case credentials(URL)
        case authenticated(URL)
    }

    func authenticate(session: Session) async throws -> String {
        let authenticationSession = authenticationSessionFactory(session)
        let preflightResult = try await preflight(session: authenticationSession)
        let finalLoginURL: URL
        let nonceURL: URL
        switch preflightResult {
        case .credentials(let submissionURL):
            finalLoginURL = submissionURL
            nonceURL = try await handleSiteCredentialLogin(submissionURL: submissionURL, session: authenticationSession)
        case .authenticated(let documentURL):
            finalLoginURL = documentURL
            nonceURL = try endpointValue { try endpoints.nonceURL(afterLoginAt: documentURL) }
        }
        return try await retrieveNonce(at: nonceURL, afterLoginAt: finalLoginURL, session: authenticationSession)
    }

    static func authenticationSessionConfiguration(from session: Session) -> URLSessionConfiguration {
        let sourceConfiguration = session.sessionConfiguration
        let configuration = sourceConfiguration.copy() as? URLSessionConfiguration ?? .ephemeral
        configuration.httpCookieStorage = sourceConfiguration.httpCookieStorage
        configuration.protocolClasses = []
        return configuration
    }
}

// MARK: Private helpers
private extension CookieNonceAuthenticator {

    static func makeAuthenticationSession(from session: Session) -> Session {
        Session(
            configuration: authenticationSessionConfiguration(from: session),
            redirectHandler: Redirector.doNotFollow
        )
    }

    func startLoginSequence(session: Session) {
        DDLogInfo("Starting Cookie+Nonce login sequence for \(endpoints.loginEntryURL)")
        Task(priority: .medium) {
            do {
                let nonce = try await authenticate(session: session)
                self.state.nonce = nonce
                successfulLoginSequence()
            } catch let error as CookieNonceAuthenticator.Error {
                invalidateLoginSequence(error: error)
            } catch {
                invalidateLoginSequence(error: .postLoginFailed(error))
            }
        }
    }

    private func preflight(session: Session) async throws -> PreflightResult {
        var requestURL = endpoints.loginEntryURL
        var redirectCount = 0
        while true {
            let response = try await load(getRequest(url: requestURL), session: session)
            try validate(response.http, stage: .preflight)
            if CookieNonceAuthenticationRules.isRedirect(statusCode: response.http.statusCode) {
                guard redirectCount < CookieNonceAuthenticationEndpoints.maximumRedirectCount,
                      let location = response.http.value(forHTTPHeaderField: "Location") else {
                    throw Error.authenticationFailed(.invalidResponse)
                }
                requestURL = try endpointValue {
                    try endpoints.resolveRedirect(location: location, from: response.http.url ?? requestURL)
                }
                redirectCount += 1
                continue
            }
            let documentURL = response.http.url ?? requestURL
            let html = try decodeHTML(response)
            if endpoints.isAuthenticatedDashboardHTML(html) {
                return .authenticated(documentURL)
            }
            guard let submissionURL = try endpointValue({
                      try endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: documentURL)
                  }) else {
                throw Error.authenticationFailed(.invalidResponse)
            }
            return .credentials(submissionURL)
        }
    }

    func handleSiteCredentialLogin(submissionURL: URL, session: Session) async throws -> URL {
        let nonceURL = try endpointValue { try endpoints.nonceURL(afterLoginAt: submissionURL) }
        let request = try authenticatedRequest(submissionURL: submissionURL, nonceURL: nonceURL)
        let response = try await load(request, session: session)
        try validate(response.http, stage: .credentials)
        if CookieNonceAuthenticationRules.isRedirect(statusCode: response.http.statusCode) {
            guard let location = response.http.value(forHTTPHeaderField: "Location"),
                  let responseURL = response.http.url,
                  endpoints.isExpectedCredentialRedirect(
                    location: location,
                    from: responseURL,
                    afterLoginAt: submissionURL
                  ) else {
                throw Error.authenticationFailed(.invalidResponse)
            }
            return nonceURL
        }
        let html = try decodeHTML(response)
        throw Error.authenticationFailed(
            CookieNonceAuthenticationRules.credentialFailure(
                in: html,
                endpoints: endpoints
            )
        )
    }

    func retrieveNonce(at nonceURL: URL, afterLoginAt finalLoginURL: URL, session: Session) async throws -> String {
        let response = try await load(getRequest(url: nonceURL), session: session)
        try validate(response.http, stage: .nonce)
        guard let responseURL = response.http.url,
              endpoints.isExpectedNonceURL(responseURL, afterLoginAt: finalLoginURL),
              let nonce = CookieNonceAuthenticationRules.validatedNonce(from: response.data) else {
            throw Error.authenticationFailed(.invalidResponse)
        }
        return nonce
    }

    func load(_ request: URLRequest, session: Session) async throws -> (data: Data, http: HTTPURLResponse) {
        try await withCheckedThrowingContinuation { continuation in
            session.request(request)
                .response { response in
                    if let error = response.error {
                        continuation.resume(throwing: error)
                    } else if let http = response.response {
                        continuation.resume(returning: (response.data ?? Data(), http))
                    } else {
                        continuation.resume(throwing: Error.authenticationFailed(.invalidResponse))
                    }
                }
        }
    }

    func decodeHTML(_ response: (data: Data, http: HTTPURLResponse)) throws -> String {
        do {
            return try StringResponseSerializer().serialize(
                request: nil,
                response: response.http,
                data: response.data,
                error: nil
            )
        } catch {
            throw Error.authenticationFailed(.invalidResponse)
        }
    }

    func validate(_ response: HTTPURLResponse, stage: CookieNonceAuthenticationResponseStage) throws {
        if let failure = CookieNonceAuthenticationRules.failure(
            statusCode: response.statusCode,
            authenticateHeader: response.value(forHTTPHeaderField: "WWW-Authenticate"),
            locationHeader: response.value(forHTTPHeaderField: "Location"),
            stage: stage
        ) {
            throw Error.authenticationFailed(failure)
        }
    }

    func getRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData, timeoutInterval: 8)
        request.httpMethod = HTTPMethod.get.rawValue
        return request
    }

    func endpointValue<T>(_ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            throw Error.authenticationFailed(.invalidResponse)
        }
    }

    func successfulLoginSequence() {
        DDLogInfo("Completed Cookie+Nonce login sequence for \(endpoints.loginEntryURL)")
        state.resetAfterSuccess()
        completeRequests(true)
    }

    func invalidateLoginSequence(error: Error) {
        DDLogError("⛔️ Cookie nonce authentication failed for \(endpoints.loginEntryURL): \(error)")
        var allowRetry = false
        if case .postLoginFailed(let originalError) = error {
            allowRetry = Self.isOfflineError(originalError)
        }
        state.invalidate(allowRetry: allowRetry)
        DDLogInfo("Aborting Cookie+Nonce login sequence for \(endpoints.loginEntryURL)")
        completeRequests(false)
    }

    func completeRequests(_ shouldRetry: Bool) {
        let result: RetryResult = shouldRetry ? .retryWithDelay(0) : .doNotRetry
        let pendingCompletions = state.drainPendingRetries()
        pendingCompletions.forEach { completion in
            completion(result)
        }
    }
}

// MARK: State
fileprivate extension CookieNonceAuthenticator {
    final class CookieNonceAuthenticatorState: @unchecked Sendable {
        private var _nonce: String?
        private var _canRetry = true
        private var _isAuthenticating = false
        private var _requestsToRetry = [(RetryResult) -> Void]()

        private let queue = DispatchQueue(
            label: "com.woocommerce.networking.cookie-nonce-authenticator.state-queue",
            qos: .userInitiated
        )

        var nonce: String? {
            get { queue.sync { _nonce } }
            set { queue.sync { _nonce = newValue } }
        }

        var canRetry: Bool {
            queue.sync { _canRetry }
        }

        /// Enqueues a retry completion and returns `true` if authentication should start.
        func enqueueRetry(_ completion: @escaping (RetryResult) -> Void) -> Bool {
            queue.sync {
                _requestsToRetry.append(completion)
                if _isAuthenticating {
                    return false
                }
                _isAuthenticating = true
                return true
            }
        }

        func resetAfterSuccess() {
            queue.sync {
                _isAuthenticating = false
            }
        }

        func invalidate(allowRetry: Bool) {
            queue.sync {
                _canRetry = allowRetry
                _isAuthenticating = false
            }
        }

        func drainPendingRetries() -> [(RetryResult) -> Void] {
            queue.sync {
                let completions = _requestsToRetry
                _requestsToRetry.removeAll()
                return completions
            }
        }
    }
}

// MARK: Public helpers
extension CookieNonceAuthenticator {
    static func isOfflineError(_ error: Swift.Error) -> Bool {
        if case .sessionTaskFailed(let underlyingError) = error as? AFError {
            return isOfflineError(underlyingError)
        }
        let nsError = error as NSError
        return nsError.domain == NSURLErrorDomain && nsError.code == NSURLErrorNotConnectedToInternet
    }

    func authenticatedRequest(submissionURL: URL, nonceURL: URL) throws -> URLRequest {
        guard let body = CookieNonceAuthenticationRules.credentialBody(
            username: username,
            password: password,
            redirectTo: nonceURL
        ) else {
            throw Error.authenticationFailed(.invalidResponse)
        }
        var request = URLRequest(url: submissionURL)
        request.httpMethod = HTTPMethod.post.rawValue
        request.httpBody = body
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        return request
    }
}
