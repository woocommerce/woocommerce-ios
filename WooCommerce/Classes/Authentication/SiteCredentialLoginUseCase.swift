import Foundation
import class Networking.UserAgent
import enum NetworkingCore.CookieNonceAuthenticationFailure
import struct NetworkingCore.CookieNonceAuthenticationEndpoints
import enum NetworkingCore.CookieNonceAuthenticationResponseStage
import enum NetworkingCore.CookieNonceAuthenticationRules
import protocol NetworkingCore.URLSessionProtocol

protocol SiteCredentialLoginProtocol {
    /// - Parameter onLoginFailure: called with the failure and whether the configured login entry was proven
    ///   to render one eligible WordPress login form before the failure occurred, plus whether the failure
    ///   came from the credential response and can plausibly be solved by browser authentication.
    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError, Bool, Bool) -> Void)

    func handleLogin(username: String, password: String)
}

enum SiteCredentialLoginError: LocalizedError {
    static let errorDomain = "SiteCredentialLogin"
    case unexpectedResponse(LoginUnexpectedResponseFailure)
    case invalidCredentials
    case basicAuthenticationRequired
    case loginFailed(message: String)
    case invalidLoginResponse
    case inaccessibleLoginPage
    case inaccessibleAdminPage
    case unacceptableStatusCode(code: Int)
    case genericFailure(underlyingError: Error)

    /// Preserve the established presentation and recovery policy independently of analytics context.
    var presentationError: SiteCredentialLoginError {
        guard case .unexpectedResponse(let failure) = self else { return self }
        return failure.statusCode.map { .unacceptableStatusCode(code: $0) } ?? .invalidLoginResponse
    }

    /// Used for tracking error code
    ///
    var underlyingError: NSError {
        switch self {
        case .unexpectedResponse:
            return presentationError.underlyingError
        case .inaccessibleLoginPage,
             .inaccessibleAdminPage,
             .invalidLoginResponse,
             .basicAuthenticationRequired,
             .invalidCredentials,
             .loginFailed,
             .unacceptableStatusCode:
            return NSError(domain: Self.errorDomain, code: errorCode, userInfo: [NSLocalizedDescriptionKey: errorMessage])
        case .genericFailure(let underlyingError):
            return underlyingError as NSError
        }
    }

    var errorCode: Int {
        switch self {
        case .unexpectedResponse:
            return presentationError.errorCode
        case .inaccessibleLoginPage, .inaccessibleAdminPage:
            return 404
        case .invalidLoginResponse:
            return -1
        case .loginFailed:
            return 403
        case .invalidCredentials:
            return 401
        case .basicAuthenticationRequired:
            return -2
        case .unacceptableStatusCode(let code):
            return code
        case .genericFailure(let underlyingError):
            return (underlyingError as NSError).code
        }
    }

    var errorMessage: String {
        switch self {
        case .unexpectedResponse:
            return presentationError.errorMessage
        case .inaccessibleLoginPage:
            return Localization.inaccessibleLoginPage
        case .inaccessibleAdminPage:
            return Localization.inaccessibleAdminPage
        case .basicAuthenticationRequired:
            return Localization.failedAuthenticationChallenge
        case .invalidLoginResponse:
            return Localization.invalidLoginResponse
        case .invalidCredentials:
            return Localization.invalidCredentials
        case .loginFailed(let message):
            return message
        case .unacceptableStatusCode(let code):
            return String(format: Localization.unacceptableStatusCode, code)
        case .genericFailure:
            return ""
        }
    }

    var errorDescription: String? {
        underlyingError.localizedDescription
    }

    func offersBrowserAlternative(at stage: CookieNonceAuthenticationResponseStage) -> Bool {
        guard stage == .credentials else {
            return false
        }
        switch self {
        case .unexpectedResponse:
            return presentationError.offersBrowserAlternative(at: stage)
        case .invalidCredentials, .invalidLoginResponse, .loginFailed:
            return true
        case .basicAuthenticationRequired,
             .inaccessibleLoginPage,
             .inaccessibleAdminPage,
             .unacceptableStatusCode,
             .genericFailure:
            return false
        }
    }

    private enum Localization {
        static let inaccessibleLoginPage = NSLocalizedString(
            "Unable to login because we cannot identify your store's login URL.",
            comment: "Error message explaining login failure due to blocked wp-login.php"
        )
        static let inaccessibleAdminPage = NSLocalizedString(
            "Unable to login because we cannot identify your store's admin URL.",
            comment: "Error message explaining login failure due to blocked WP Admin page"
        )
        static let invalidLoginResponse = NSLocalizedString(
            "siteCredentialLoginError.invalidLoginResponse.message",
            value: "Unable to login due to an unexpected response from your site.",
            comment: "Error message explaining login failure due to unexpected response."
        )
        static let unacceptableStatusCode = NSLocalizedString(
            "Unable to login with response status code %1$d.",
            comment: "Error message explaining login failure due to unacceptable status code."
        )
        static let invalidCredentials = NSLocalizedString(
            "It seems the username or password you entered doesn't quite match. Double-check your credentials and try again.",
            comment: "Error message explaining login failure due to invalid credentials."
        )
        static let failedAuthenticationChallenge = NSLocalizedString(
            "siteCredentialLoginError.failedAuthenticationChallenge.message",
            value: "Unable to log in due to an unexpected security measure on your store. Please contact support for troubleshooting.",
            comment: "Error message explaining login failure due to an unexpected authentication challenge."
        )
    }
}

/// This use case handles site credential login without the need to use XMLRPC API.
/// Steps for login:
/// - Preflight the configured login entry and verify one eligible WordPress login form.
/// - Post to that transaction's form action with the exact rest nonce endpoint as the redirect target.
/// - Prevent the HTTP stack from automatically following that redirect.
/// - Accept only the expected nonce or configured admin redirect as login-success evidence, but never follow it.
/// - Optionally prove the admin dashboard from its independently derived URL.
/// - Issue an explicit nonce GET using the same private session.
/// Ref: pe5sF9-1iQ-p2
///
final class SiteCredentialLoginUseCase: NSObject, SiteCredentialLoginProtocol {
    private let endpointConfiguration: Result<CookieNonceAuthenticationEndpoints, SiteCredentialLoginError>
    private let cookieJar: HTTPCookieStorage
    private let session: URLSessionProtocol
    private let loginSession: URLSessionProtocol
    private let ownedTransactionSession: URLSession?
    private let verifyAdminDashboard: Bool
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError, Bool, Bool) -> Void)?

    init(siteURL: String,
         endpoints configuredEndpoints: CookieNonceAuthenticationEndpoints? = nil,
         verifyAdminDashboard: Bool = false,
         cookieJar: HTTPCookieStorage = SiteCredentialLoginUseCase.makePrivateCookieJar(),
         session: URLSessionProtocol? = nil,
         loginSession: URLSessionProtocol? = nil) {
        do {
            guard let siteURL = URL(string: siteURL) else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
            let defaultEndpoints = try CookieNonceAuthenticationEndpoints(siteURL: siteURL)
            if let configuredEndpoints {
                guard defaultEndpoints.siteURL == configuredEndpoints.siteURL else {
                    throw SiteCredentialLoginError.invalidLoginResponse
                }
                self.endpointConfiguration = .success(configuredEndpoints)
            } else {
                self.endpointConfiguration = .success(defaultEndpoints)
            }
        } catch {
            self.endpointConfiguration = .failure(.invalidLoginResponse)
        }
        self.cookieJar = cookieJar
        let transactionSession = session ?? Self.makeRedirectBlockingSession(cookieJar: cookieJar)
        self.session = transactionSession
        self.loginSession = loginSession ?? transactionSession
        self.ownedTransactionSession = session == nil ? transactionSession as? URLSession : nil
        self.verifyAdminDashboard = verifyAdminDashboard
        super.init()
    }

    deinit {
        ownedTransactionSession?.finishTasksAndInvalidate()
    }

    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError, Bool, Bool) -> Void) {
        self.successHandler = onLoginSuccess
        self.errorHandler = onLoginFailure
    }

    func handleLogin(username: String, password: String) {
        // Old cookies can make the login succeeds even with incorrect credentials
        // So we need to clear all cookies before login.
        clearAllCookies()
        Task { @MainActor in
            var loginEntryVerified = false
            var responseStage = CookieNonceAuthenticationResponseStage.preflight
            do {
                let endpoints: CookieNonceAuthenticationEndpoints
                switch endpointConfiguration {
                case .success(let configuredEndpoints):
                    endpoints = configuredEndpoints
                case .failure(let error):
                    DDLogError("⛔️ Error constructing or validating login requests")
                    throw error
                }
                try await startLogin(
                    username: username,
                    password: password,
                    endpoints: endpoints,
                    onLoginEntryVerified: { loginEntryVerified = true },
                    onResponseStageChanged: { responseStage = $0 }
                )
                successHandler?()
            } catch let error as SiteCredentialLoginError {
                errorHandler?(error, loginEntryVerified, error.offersBrowserAlternative(at: responseStage))
            } catch {
                errorHandler?(.genericFailure(underlyingError: error as NSError), loginEntryVerified, false)
            }
        }
    }
}

private extension SiteCredentialLoginUseCase {
    func clearAllCookies() {
        if let cookies = cookieJar.cookies {
            for cookie in cookies {
                cookieJar.deleteCookie(cookie)
            }
        }
    }

    func startLogin(
        username: String,
        password: String,
        endpoints: CookieNonceAuthenticationEndpoints,
        onLoginEntryVerified: () -> Void,
        onResponseStageChanged: (CookieNonceAuthenticationResponseStage) -> Void
    ) async throws {
        let submissionURL = try await preflight(endpoints: endpoints)
        onLoginEntryVerified()
        let nonceURL = try endpointValue { try endpoints.nonceURL(afterLoginAt: submissionURL) }
        let loginRequest = try credentialRequest(
            username: username,
            password: password,
            submissionURL: submissionURL,
            nonceURL: nonceURL
        )
        onResponseStageChanged(.credentials)
        let loginResponse = try await load(loginRequest, using: loginSession, stage: .credentials)
        try validate(loginResponse, stage: .credentials, endpoints: endpoints)

        if CookieNonceAuthenticationRules.isRedirect(statusCode: loginResponse.http.statusCode) {
            guard let location = loginResponse.http.value(forHTTPHeaderField: "Location"),
                  let responseURL = loginResponse.http.url,
                  endpoints.isExpectedCredentialRedirect(
                    location: location,
                    from: responseURL,
                    afterLoginAt: submissionURL
                  ) else {
                throw SiteCredentialLoginError.unexpectedResponse(.init(stage: .credentials))
            }
        } else {
            let html = try decodedHTML(from: loginResponse.data, stage: .credentials)
            throw SiteCredentialLoginError(
                CookieNonceAuthenticationRules.credentialFailure(
                    in: html,
                    endpoints: endpoints
                ), stage: .credentials
            )
        }

        if verifyAdminDashboard {
            onResponseStageChanged(.dashboard)
            try await verifyDashboard(afterLoginAt: submissionURL, endpoints: endpoints)
        }
        onResponseStageChanged(.nonce)
        try await retrieveNonce(at: nonceURL, afterLoginAt: submissionURL, endpoints: endpoints)
    }

    /// Fetches a document, following only same-site redirects and never more than the shared bound.
    /// Returns the first non-redirect response, so callers only express their own terminal check.
    func loadDocument(
        from startURL: URL,
        stage: CookieNonceAuthenticationResponseStage,
        endpoints: CookieNonceAuthenticationEndpoints
    ) async throws -> (url: URL, html: String) {
        var requestURL = startURL
        var redirectCount = 0
        while true {
            let response = try await load(getRequest(url: requestURL), using: session, stage: stage)
            try validate(response, stage: stage, endpoints: endpoints)
            guard CookieNonceAuthenticationRules.isRedirect(statusCode: response.http.statusCode) else {
                let html = try decodedHTML(from: response.data, stage: stage)
                return (response.http.url ?? requestURL, html)
            }
            guard redirectCount < CookieNonceAuthenticationEndpoints.maximumRedirectCount,
                  let location = response.http.value(forHTTPHeaderField: "Location") else {
                throw SiteCredentialLoginError.unexpectedResponse(.init(stage: stage))
            }
            requestURL = try endpointValue(stage: stage) {
                try endpoints.resolveRedirect(location: location, from: response.http.url ?? requestURL)
            }
            redirectCount += 1
        }
    }

    func preflight(endpoints: CookieNonceAuthenticationEndpoints) async throws -> URL {
        let document = try await loadDocument(from: endpoints.loginEntryURL, stage: .preflight, endpoints: endpoints)
        guard let submissionURL = try endpointValue(stage: .preflight, {
            try endpoints.verifiedLoginFormSubmissionURL(in: document.html, documentURL: document.url)
        }) else {
            throw SiteCredentialLoginError.unexpectedResponse(.init(stage: .preflight))
        }
        return submissionURL
    }

    func retrieveNonce(
        at nonceURL: URL,
        afterLoginAt loginURL: URL,
        endpoints: CookieNonceAuthenticationEndpoints
    ) async throws {
        let response = try await load(getRequest(url: nonceURL), using: session, stage: .nonce)
        try validate(response, stage: .nonce, endpoints: endpoints)
        guard let responseURL = response.http.url,
              endpoints.isExpectedNonceURL(responseURL, afterLoginAt: loginURL),
              CookieNonceAuthenticationRules.validatedNonce(from: response.data) != nil else {
            throw SiteCredentialLoginError.unexpectedResponse(.init(stage: .nonce))
        }
    }

    func verifyDashboard(afterLoginAt loginURL: URL, endpoints: CookieNonceAuthenticationEndpoints) async throws {
        let adminBaseURL = try endpointValue { try endpoints.derivedAdminBaseURL(afterLoginAt: loginURL) }
        let document = try await loadDocument(from: adminBaseURL, stage: .dashboard, endpoints: endpoints)
        guard endpoints.isExpectedAdminBaseURL(document.url, afterLoginAt: loginURL),
              endpoints.isAuthenticatedDashboardHTML(document.html) else {
            throw SiteCredentialLoginError(
                CookieNonceAuthenticationRules.credentialFailure(
                    in: document.html,
                    endpoints: endpoints
                ), stage: .dashboard
            )
        }
    }

    func load(_ request: URLRequest, using session: URLSessionProtocol,
              stage: CookieNonceAuthenticationResponseStage) async throws -> (data: Data, http: HTTPURLResponse) {
        let (data, response) = try await session.data(for: request)
        guard let response = response as? HTTPURLResponse else {
            throw SiteCredentialLoginError.unexpectedResponse(.init(stage: stage))
        }
        return (data, response)
    }

    func validate(_ result: (data: Data, http: HTTPURLResponse),
                  stage: CookieNonceAuthenticationResponseStage,
                  endpoints: CookieNonceAuthenticationEndpoints) throws {
        let response = result.http
        if let failure = CookieNonceAuthenticationRules.failure(
            statusCode: response.statusCode,
            authenticateHeader: response.value(forHTTPHeaderField: "WWW-Authenticate"),
            locationHeader: response.value(forHTTPHeaderField: "Location"),
            stage: stage
        ) {
            if case .unacceptableStatusCode(let code) = failure,
               !isRecognizedContent(result.data, responseURL: response.url, stage: stage, endpoints: endpoints) {
                throw SiteCredentialLoginError.unexpectedResponse(.init(stage: stage, statusCode: code))
            }
            throw SiteCredentialLoginError(failure, stage: stage)
        }
    }

    /// Status rejection must not turn a recognized credential error or an expected document into an unexpected response.
    func isRecognizedContent(_ data: Data, responseURL: URL?, stage: CookieNonceAuthenticationResponseStage,
                             endpoints: CookieNonceAuthenticationEndpoints) -> Bool {
        guard let html = String(data: data, encoding: .utf8) else { return false }
        if CookieNonceAuthenticationRules.credentialFailure(in: html, endpoints: endpoints) != .invalidResponse {
            return true
        }
        switch stage {
        case .preflight:
            guard let responseURL else { return false }
            return (try? endpoints.verifiedLoginFormSubmissionURL(in: html, documentURL: responseURL)) != nil
        case .dashboard:
            return endpoints.isAuthenticatedDashboardHTML(html)
        case .nonce:
            return CookieNonceAuthenticationRules.validatedNonce(from: data) != nil
        case .credentials:
            return false
        }
    }

    func credentialRequest(username: String, password: String, submissionURL: URL, nonceURL: URL) throws -> URLRequest {
        guard let body = CookieNonceAuthenticationRules.credentialBody(
            username: username,
            password: password,
            redirectTo: nonceURL
        ) else {
            throw SiteCredentialLoginError.invalidLoginResponse
        }
        var request = URLRequest(url: submissionURL)
        request.httpMethod = "POST"
        request.httpBody = body
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    func getRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalCacheData)
        request.httpMethod = "GET"
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    func decodedHTML(from data: Data, stage: CookieNonceAuthenticationResponseStage) throws -> String {
        guard let html = String(data: data, encoding: .utf8) else {
            throw SiteCredentialLoginError.unexpectedResponse(.init(stage: stage))
        }
        return html
    }

    func endpointValue<T>(stage: CookieNonceAuthenticationResponseStage? = nil, _ operation: () throws -> T) throws -> T {
        do {
            return try operation()
        } catch {
            if let stage {
                throw SiteCredentialLoginError.unexpectedResponse(.init(stage: stage))
            }
            throw SiteCredentialLoginError.invalidLoginResponse
        }
    }

    static func makeRedirectBlockingSession(cookieJar: HTTPCookieStorage) -> URLSession {
        return URLSession(configuration: makeSessionConfiguration(cookieJar: cookieJar),
                          delegate: RedirectBlockingURLSessionDelegate(),
                          delegateQueue: nil)
    }
}

extension SiteCredentialLoginUseCase {
    static func makePrivateCookieJar() -> HTTPCookieStorage {
        if let cookieJar = URLSessionConfiguration.ephemeral.httpCookieStorage,
           cookieJar !== HTTPCookieStorage.shared {
            return cookieJar
        }
        return HTTPCookieStorage()
    }

    static func makeSessionConfiguration(cookieJar: HTTPCookieStorage,
                                         baseConfiguration: URLSessionConfiguration = .ephemeral) -> URLSessionConfiguration {
        let configuration = baseConfiguration
        configuration.httpCookieStorage = cookieJar
        configuration.httpShouldSetCookies = true
        configuration.httpCookieAcceptPolicy = .always
        // This login flow depends on handling the redirect itself and should not be intercepted by debug URLProtocol handlers.
        configuration.protocolClasses = []
        return configuration
    }

    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin"
        static let wporgNoncePath = "/admin-ajax.php?action=rest-nonce"
    }
}

private final class RedirectBlockingURLSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest) async -> URLRequest? {
        nil
    }
}

private extension SiteCredentialLoginError {
    init(_ failure: CookieNonceAuthenticationFailure, stage: CookieNonceAuthenticationResponseStage) {
        switch failure {
        case .basicAuthenticationRequired:
            self = .basicAuthenticationRequired
        case .invalidCredentials:
            self = .invalidCredentials
        case .loginFailed(let message):
            self = .loginFailed(message: message)
        case .inaccessibleLoginPage:
            self = .inaccessibleLoginPage
        case .inaccessibleAdminPage:
            self = .inaccessibleAdminPage
        case .invalidResponse:
            self = .unexpectedResponse(.init(stage: stage))
        case .unacceptableStatusCode(let code):
            self = .unacceptableStatusCode(code: code)
        }
    }
}
