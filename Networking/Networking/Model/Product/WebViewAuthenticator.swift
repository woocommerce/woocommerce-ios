import Foundation

/// Encapsulates all the authentication logic for web views.
///
/// This objects is in charge of deciding when a web view should be authenticated,
/// and rewriting requests to do so.
///
final class WebViewAuthenticator {
    private let credentials: Credentials

    init(credentials: Credentials) {
        self.credentials = credentials
    }

    /// Potentially rewrites a request for authentication.
    ///
    /// This method will call the completion block with the request to be used.
    ///
    /// - Parameters:
    ///     - url: the URL to be loaded.
    ///     - cookieJar: a CookieJar object where the authenticator will look
    ///     for existing cookies.
    ///     - completion: this will be called with either the request for
    ///     authentication, or a request for the original URL.
    ///
    func request(url: URL, cookieJar: CookieJar, completion: @escaping (URLRequest) -> Void) {
        cookieJar.hasCookie(url: loginURL, username: username) { [weak self] (hasCookie) in
            guard let authenticator = self else {
                return
            }

            let request = authenticator.request(url: url, authenticated: !hasCookie)
            completion(request)
        }
    }

    /// Rewrites a request for authentication.
    ///
    /// This method will always return an authenticated request. If you want to
    /// authenticate only if needed, by inspecting the existing cookies, use
    /// request(url:cookieJar:completion:) instead
    ///
    func authenticatedRequest(url: URL) -> URLRequest {
        var request = URLRequest(url: loginURL)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = body(url: url)
        request.setValue("Bearer \(authToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}

private extension WebViewAuthenticator {
    func request(url: URL, authenticated: Bool) -> URLRequest {
        if authenticated {
            return authenticatedRequest(url: url)
        } else {
            return unauthenticatedRequest(url: url)
        }
    }

    func unauthenticatedRequest(url: URL) -> URLRequest {
        return URLRequest(url: url)
    }

    func body(url: URL) -> Data? {
        guard let redirectedUrl = redirectUrl(url: url.absoluteString) else {
                return nil
        }
        var parameters = [URLQueryItem]()
        parameters.append(URLQueryItem(name: "log", value: username))
        parameters.append(URLQueryItem(name: "rememberme", value: "true"))
        parameters.append(URLQueryItem(name: "redirect_to", value: redirectedUrl))
        var components = URLComponents()
        components.queryItems = parameters

        return components.percentEncodedQuery?.data(using: .utf8)
    }

    func redirectUrl(url: String) -> String? {
        guard let escapedUrl = url.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) else {
            return url
        }

        return self.url(string: "https://wordpress.com/", parameters: [Constants.redirectParameter: escapedUrl])?.absoluteString
    }

    func url(string: String, parameters: [String: String]) -> URL? {
        guard var components = URLComponents(string: string) else {
            return nil
        }
        components.queryItems = parameters.map({ (key, value) in
            return URLQueryItem(name: key, value: value)
        })
        return components.url
    }

    var username: String {
        return credentials.username
    }

    var authToken: String {
        return credentials.authToken
    }

    var loginURL: URL {
        return Constants.wordPressComLoginUrl
    }
}

private extension WebViewAuthenticator {
    enum Constants {
        static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
        static let redirectParameter = "wpios_redirect"
    }
}
