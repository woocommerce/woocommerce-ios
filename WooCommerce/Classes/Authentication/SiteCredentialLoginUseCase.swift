import Foundation

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
/// - Make a request to the site wp-login.php with a redirect to the nonce retrieval URL.
/// - If the redirect succeeds with a nonce in the response, login is successful.
/// - If the request does not redirect or the redirect fails, login fails.
/// Ref: pe5sF9-1iQ-p2
///
final class SiteCredentialLoginUseCase: NSObject, SiteCredentialLoginProtocol {
    private let siteURL: String
    private let cookieJar: HTTPCookieStorage
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError) -> Void)?
    private lazy var session = URLSession(configuration: .default)

    init(siteURL: String,
         cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared) {
        self.siteURL = siteURL
        self.cookieJar = cookieJar
        super.init()
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

        let (data, response): (Data, URLResponse) = try await session.data(for: loginRequest)

        guard let response = response as? HTTPURLResponse else {
            throw SiteCredentialLoginError.invalidLoginResponse
        }

        if response.containsHTTPBasicAuthenticationChallenge {
            throw SiteCredentialLoginError.basicAuthenticationRequired
        }

        /// The login request comes with a redirect header to nonce retrieval URL.
        /// If we get a response from this URL, that means the redirect is successful.
        /// We need to check the result of this redirect first to determine if login is successful.
        let isNonceUrl = response.url?.absoluteString.hasSuffix(Constants.wporgNoncePath) == true

        switch (isNonceUrl, response.statusCode) {
        case (true, 200):
            if let nonceString = String(data: data, encoding: .utf8),
               nonceString.isValidNonce() {
                // success!
                return
            } else {
                throw SiteCredentialLoginError.invalidLoginResponse
            }
        case (true, 404):
            throw SiteCredentialLoginError.inaccessibleAdminPage
        case (false, 404):
            throw SiteCredentialLoginError.inaccessibleLoginPage
        case (false, 200):
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

        let (_, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else { return }
        if http.containsHTTPBasicAuthenticationChallenge {
            throw SiteCredentialLoginError.basicAuthenticationRequired
        }
    }
}

extension SiteCredentialLoginUseCase {
    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin"
        static let wporgNoncePath = "/admin-ajax.php?action=rest-nonce"
        static let captchaText = "captcha"
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
