import Foundation

protocol SiteCredentialLoginProtocol {
    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void)

    func handleLogin(username: String, password: String)
}

enum SiteCredentialLoginError: Error {
    static let errorDomain = "SiteCredentialLogin"
    case wrongCredentials
    case invalidLoginResponse
    case inaccessibleLoginPage
    case genericFailure(underlyingError: Error)

    /// Used for tracking error code
    ///
    var underlyingError: NSError {
        switch self {
        case .inaccessibleLoginPage:
            return NSError(domain: Self.errorDomain, code: 404, userInfo: nil)
        case .invalidLoginResponse:
            return NSError(domain: Self.errorDomain, code: -1, userInfo: nil)
        case .wrongCredentials:
            return NSError(domain: Self.errorDomain, code: 401, userInfo: nil)
        case .genericFailure(let underlyingError):
            return underlyingError as NSError
        }
    }
}

/// This use case handles site credential login without the need to use XMLRPC API.
/// Steps for login:
/// - Handle cookie authentication with provided credentials.
/// - Attempt retrieving plugin details. If the request fails with 401 error, the authentication fails.
///
final class SiteCredentialLoginUseCase: SiteCredentialLoginProtocol {
    private let siteURL: String
    private let cookieJar: HTTPCookieStorage
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError) -> Void)?

    init(siteURL: String,
         cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared) {
        self.siteURL = siteURL
        self.cookieJar = cookieJar
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
        startLogin(username: username, password: password, onSuccess: { [weak self] in
            self?.successHandler?()
        }, onFailure: { [weak self] error in
            self?.errorHandler?(error)
        })
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

    func startLogin(username: String, password: String, onSuccess: @escaping () -> Void, onFailure: @escaping (SiteCredentialLoginError) -> Void) {
        guard let request = buildLoginRequest(username: username, password: password) else {
            DDLogError("⛔️ Error constructing login request")
            return
        }
        let session = URLSession(configuration: .default)
        let task = session.dataTask(with: request) { data, response, error in
            DispatchQueue.main.async {
                if let error = error as? NSError {
                    return onFailure(.genericFailure(underlyingError: error))
                }
                guard let response = response as? HTTPURLResponse else {
                    return onFailure(.invalidLoginResponse)
                }
                if response.statusCode == 404 {
                    return onFailure(.inaccessibleLoginPage)
                }

                if let data, let html = String(data: data, encoding: .utf8) {
                    /// If we get data from the nonce retrieval request, consider this a success.
                    if let url = response.url, url.absoluteString.hasSuffix(Constants.wporgNoncePath) {
                        return onSuccess()
                    }
                    /// scrape html for the error tag to check for incorrect credentials.
                    if html.contains("<div id=\"login_error\">") {
                        return onFailure(.wrongCredentials)
                    } else {
                        return onFailure(.invalidLoginResponse)
                    }
                }
            }
        }
        task.resume()
    }

    func buildLoginRequest(username: String, password: String) -> URLRequest? {
        guard let loginURL = URL(string: siteURL + Constants.loginPath),
              let nonceRetrievalURL = URL(string: siteURL + Constants.wporgNoncePath) else {
            return nil
        }

        var request = URLRequest(url: loginURL)

        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        parameters.append(URLQueryItem(name: "pwd", value: password))
        parameters.append(URLQueryItem(name: "redirect_to", value: nonceRetrievalURL.absoluteString))
        var components = URLComponents()
        components.queryItems = parameters

        /// `percentEncodedQuery` creates a validly escaped URL query component, but
        /// doesn't encode the '+'. Percent encodes '+' to avoid this ambiguity.
        let characterSet = CharacterSet(charactersIn: "+").inverted
        request.httpBody = components.percentEncodedQuery?.addingPercentEncoding(withAllowedCharacters: characterSet)?.data(using: .utf8)
        return request
    }
}

extension SiteCredentialLoginUseCase {
    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin/"
        static let wporgNoncePath = "/wp-admin/admin-ajax.php?action=rest-nonce"
    }
}
