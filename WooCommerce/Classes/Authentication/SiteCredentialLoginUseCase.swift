import Foundation
import class Networking.UserAgent
import protocol NetworkingCore.URLSessionProtocol

protocol SiteCredentialLoginProtocol {
    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void)

    func handleLogin(username: String, password: String)
}

enum SiteCredentialLoginError: LocalizedError {
    static let errorDomain = "SiteCredentialLogin"
    case invalidCredentials
    case basicAuthenticationRequired
    case loginFailed(message: String)
    case invalidLoginResponse
    case inaccessibleLoginPage
    case inaccessibleAdminPage
    case unacceptableStatusCode(code: Int)
    case genericFailure(underlyingError: Error)

    /// Used for tracking error code
    ///
    var underlyingError: NSError {
        switch self {
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
/// - Post to `wp-login.php` with a redirect target for the rest nonce endpoint.
/// - Prevent the HTTP stack from automatically following that redirect.
/// - Validate the redirect target and then issue an explicit nonce GET using the same cookie store.
/// Ref: pe5sF9-1iQ-p2
///
final class SiteCredentialLoginUseCase: NSObject, SiteCredentialLoginProtocol {
    private let siteURL: String
    private let cookieJar: HTTPCookieStorage
    private let session: URLSessionProtocol
    private let loginSession: URLSessionProtocol
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError) -> Void)?

    init(siteURL: String,
         cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared,
         session: URLSessionProtocol? = nil,
         loginSession: URLSessionProtocol? = nil) {
        self.siteURL = siteURL
        self.cookieJar = cookieJar
        self.session = session ?? Self.makeSession(cookieJar: cookieJar)
        self.loginSession = loginSession ?? Self.makeRedirectBlockingSession(cookieJar: cookieJar)
        super.init()
    }

    deinit {
        (loginSession as? URLSession)?.finishTasksAndInvalidate()
    }

    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void) {
        self.successHandler = onLoginSuccess
        self.errorHandler = onLoginFailure
    }

    func handleLogin(username: String, password: String) {
        // Old cookies can make the login succeeds even with incorrect credentials
        // So we need to clear all cookies before login.
        clearAllCookies()
        guard let loginRequest = buildLoginRequest(username: username, password: password) else {
            DDLogError("⛔️ Error constructing login requests")
            return
        }
        Task { @MainActor in
            do {
                try await startLogin(with: loginRequest)
                successHandler?()
            } catch let error as SiteCredentialLoginError {
                errorHandler?(error)
            } catch {
                errorHandler?(.genericFailure(underlyingError: error as NSError))
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

    func startLogin(with loginRequest: URLRequest) async throws {
        try await detectBasicAuthProbe()

        let (data, response): (Data, URLResponse) = try await loginSession.data(for: loginRequest)

        guard let response = response as? HTTPURLResponse else {
            throw SiteCredentialLoginError.invalidLoginResponse
        }

        if response.containsHTTPBasicAuthenticationChallenge {
            throw SiteCredentialLoginError.basicAuthenticationRequired
        }

        switch response.statusCode {
        case 300..<400:
            guard let nonceRequest = buildNonceRequest(from: response) else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
            try await retrieveNonce(with: nonceRequest)
        case 404:
            throw SiteCredentialLoginError.inaccessibleLoginPage
        case 200:
            // 200 for the login URL, which means a failure
            guard let html = String(data: data, encoding: .utf8) else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }

            // Extracts error message from the HTML to determine whether there's an authentication issue
            // otherwise we'll assume it's an invalid response
            let errorMessage = html.findLoginErrorMessage() ?? ""

            if html.hasInvalidCredentialsPattern(),
               !errorMessage.lowercased().contains(Constants.captchaText) {
                throw SiteCredentialLoginError.invalidCredentials
            } else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
        default:
            throw SiteCredentialLoginError.unacceptableStatusCode(code: response.statusCode)
        }
    }

    func buildLoginRequest(username: String, password: String) -> URLRequest? {
        guard let loginURL = URL(string: siteURL + Constants.loginPath) else {
            return nil
        }

        let nonceRetrievalPath = siteURL + Constants.adminPath + Constants.wporgNoncePath
        var request = URLRequest(url: loginURL)

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        parameters.append(URLQueryItem(name: "pwd", value: password))
        parameters.append(URLQueryItem(name: "redirect_to", value: nonceRetrievalPath))
        var components = URLComponents()
        components.queryItems = parameters

        /// `percentEncodedQuery` creates a validly escaped URL query component, but
        /// doesn't encode the '+'. Percent encodes '+' to avoid this ambiguity.
        let characterSet = CharacterSet(charactersIn: "+").inverted
        request.httpBody = components.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: characterSet)?.data(using: .utf8)
        return request
    }

    func buildNonceRequest(from response: HTTPURLResponse) -> URLRequest? {
        guard let nonceURL = nonceURL(from: response) else {
            return nil
        }

        var request = URLRequest(url: nonceURL)
        request.httpMethod = "GET"
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")
        return request
    }

    /// Issues a lightweight GET to detect Basic Auth without engaging URLSession auth challenge flow.
    func detectBasicAuthProbe() async throws {
        guard let loginURL = URL(string: siteURL + Constants.loginPath) else {
            return
        }
        var request = URLRequest(
            url: loginURL,
            cachePolicy: .reloadIgnoringLocalCacheData,
            timeoutInterval: 8
        )
        request.httpMethod = "GET"
        request.setValue(UserAgent.defaultUserAgent, forHTTPHeaderField: "User-Agent")

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return }
        if http.containsHTTPBasicAuthenticationChallenge {
            throw SiteCredentialLoginError.basicAuthenticationRequired
        }
    }

    func retrieveNonce(with request: URLRequest) async throws {
        let (data, response) = try await session.data(for: request)

        guard let response = response as? HTTPURLResponse else {
            throw SiteCredentialLoginError.invalidLoginResponse
        }

        if response.containsHTTPBasicAuthenticationChallenge {
            throw SiteCredentialLoginError.basicAuthenticationRequired
        }

        switch response.statusCode {
        case 200:
            guard let nonceString = String(data: data, encoding: .utf8),
                  nonceString.isValidNonce() else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
        case 404:
            throw SiteCredentialLoginError.inaccessibleAdminPage
        default:
            throw SiteCredentialLoginError.unacceptableStatusCode(code: response.statusCode)
        }
    }

    func nonceURL(from response: HTTPURLResponse) -> URL? {
        guard let location = response.value(forHTTPHeaderField: "Location"),
              let resolvedURL = URL(string: location, relativeTo: response.url)?.absoluteURL,
              resolvedURL.isExpectedRestNonceURL(for: siteURL) else {
            return nil
        }
        return resolvedURL
    }

    static func makeSession(cookieJar: HTTPCookieStorage) -> URLSession {
        URLSession(configuration: makeSessionConfiguration(cookieJar: cookieJar))
    }

    static func makeRedirectBlockingSession(cookieJar: HTTPCookieStorage) -> URLSession {
        return URLSession(configuration: makeSessionConfiguration(cookieJar: cookieJar),
                          delegate: RedirectBlockingURLSessionDelegate(),
                          delegateQueue: nil)
    }
}

extension SiteCredentialLoginUseCase {
    static func makeSessionConfiguration(cookieJar: HTTPCookieStorage,
                                         baseConfiguration: URLSessionConfiguration = .default) -> URLSessionConfiguration {
        let configuration = baseConfiguration
        configuration.httpCookieStorage = cookieJar
        configuration.httpShouldSetCookies = true
        // This login flow depends on handling the redirect itself and should not be intercepted by debug URLProtocol handlers.
        configuration.protocolClasses = []
        return configuration
    }

    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin"
        static let wporgNoncePath = "/admin-ajax.php?action=rest-nonce"
        static let wporgNonceEndpointPath = adminPath + "/admin-ajax.php"
        static let restNonceActionParameter = "action"
        static let restNonceAction = "rest-nonce"
        static let captchaText = "captcha"
    }
}

nonisolated private final class RedirectBlockingURLSessionDelegate: NSObject, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession,
                    task: URLSessionTask,
                    willPerformHTTPRedirection response: HTTPURLResponse,
                    newRequest request: URLRequest,
                    completionHandler: @escaping @Sendable (URLRequest?) -> Void) {
        completionHandler(nil)
    }
}

extension HTTPURLResponse {
    /// Detects whether the server requires HTTP Basic authentication.
    ///
    /// When a site is behind basic auth it responds with a 401 and a `WWW-Authenticate` header containing `Basic`.
    /// That reliably distinguishes it from a normal WordPress login failure, which returns 200.
    var containsHTTPBasicAuthenticationChallenge: Bool {
        guard statusCode == 401 else {
            return false
        }
        return value(forHTTPHeaderField: "WWW-Authenticate")?
            .localizedCaseInsensitiveContains("basic") == true
    }
}

private extension URL {
    func isExpectedRestNonceURL(for siteURLString: String) -> Bool {
        guard let resolvedComponents = URLComponents(url: self, resolvingAgainstBaseURL: true),
              let siteURL = URL(string: siteURLString),
              let siteComponents = URLComponents(url: siteURL, resolvingAgainstBaseURL: true),
              resolvedComponents.isRestNonceURL else {
            return false
        }

        return resolvedComponents.isOnExpectedSite(as: siteComponents)
    }
}

private extension URLComponents {
    var isRestNonceURL: Bool {
        let action = queryItems?.first(where: { $0.name == SiteCredentialLoginUseCase.Constants.restNonceActionParameter })?.value
        return path.hasSuffix(SiteCredentialLoginUseCase.Constants.wporgNonceEndpointPath) &&
            action == SiteCredentialLoginUseCase.Constants.restNonceAction
    }

    func isOnExpectedSite(as siteComponents: URLComponents) -> Bool {
        guard let scheme = scheme?.lowercased(),
              let siteScheme = siteComponents.scheme?.lowercased(),
              let host = host?.lowercased(),
              let siteHost = siteComponents.host?.lowercased() else {
            return false
        }

        if scheme == siteScheme {
            return host == siteHost && effectivePort == siteComponents.effectivePort
        }

        return isHTTPSUpgrade(from: siteComponents, redirectScheme: scheme, redirectHost: host, siteHost: siteHost)
    }

    var effectivePort: Int? {
        if let port {
            return port
        }

        switch scheme?.lowercased() {
        case "http":
            return 80
        case "https":
            return 443
        default:
            return nil
        }
    }

    func isHTTPSUpgrade(from siteComponents: URLComponents,
                        redirectScheme: String,
                        redirectHost: String,
                        siteHost: String) -> Bool {
        guard siteComponents.scheme?.lowercased() == "http",
              redirectScheme == "https",
              redirectHost == siteHost else {
            return false
        }

        let usesDefaultUpgradePorts = (siteComponents.port == nil || siteComponents.port == 80) &&
            (port == nil || port == 443)
        return usesDefaultUpgradePorts || siteComponents.port == port
    }
}

private extension String {
    /// Gets contents between HTML tags with regex.
    ///
    func findLoginErrorMessage() -> String? {
        let pattern = "<div[^>]*id=\"login_error\"[^>]*>([\\s\\S]+?)</div>"
        let urlPattern = "<a href=\".*\">[^~]*?</a>"
        let regexOptions = NSRegularExpression.Options.caseInsensitive
        let matchOptions = NSRegularExpression.MatchingOptions(rawValue: UInt(0))
        do {
            let regex = try NSRegularExpression(pattern: pattern, options: regexOptions)
            guard let textCheckingResult = regex.firstMatch(in: self,
                                                            options: matchOptions,
                                                            range: NSMakeRange(0, count)) else {
                return nil
            }
            let matchRange = textCheckingResult.range(at: 0)
            let match = (self as NSString).substring(with: matchRange)

            /// Removes any <a> tag
            let urlRegex = try NSRegularExpression(pattern: urlPattern, options: regexOptions)
            let results = urlRegex.matches(in: match,
                                           options: matchOptions,
                                           range: NSMakeRange(0, match.count))
            var urlMatches: [String] = []
            for result in results {
                let range = result.range(at: 0)
                let urlMatch = (match as NSString).substring(with: range)
                urlMatches.append(urlMatch)
            }
            if urlMatches.isNotEmpty {
                var updatedMatch = match
                urlMatches.forEach { url in
                    updatedMatch = updatedMatch.replacingOccurrences(of: url, with: "")
                }
                return updatedMatch.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
            }
            return match.strippedHTML.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            DDLogError("⚠️" + pattern + "<-- not found in string -->" + self )
            return nil
        }
    }

    /// When logging in with site credentials there is no way to properly tell if an error message is an invalid credentials error.
    /// However, the server injects this `shake` pattern when an invalid credential error is found.
    /// For the time being, we will use that pattern as a guess for an invalid credential error message.
    /// ref: https://github.com/WordPress/WordPress/blob/master/wp-login.php#L65-L67
    ///
    func hasInvalidCredentialsPattern() -> Bool {
        contains("document.querySelector('form').classList.add('shake')")
    }

    /// Validates if the string matches the expected nonce format.
    /// A valid nonce should contain at least 2 alphanumeric characters.
    ///
    func isValidNonce() -> Bool {
        guard let regex = try? Regex("^[0-9a-zA-Z]{2,}$") else {
            DDLogError("⚠️ Invalid regex pattern")
            return false
        }
        return wholeMatch(of: regex) != nil
    }
}
