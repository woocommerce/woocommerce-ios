import AutomatticTracks
import struct Networking.Site
import Foundation


/// Partial copy of the same file from WP-iOS
/// Trimmed down and adapted for WC
/// https://github.com/wordpress-mobile/WordPress-iOS/blob/9b1e03b/WordPress/Classes/Utility/Networking/RequestAuthenticator.swift

/// Authenticator for requests to self-hosted sites, wp.com sites, including private
/// sites and atomic sites.
///
class RequestAuthenticator: NSObject {

    enum DotComAuthenticationType {
        case regular
        case regularMapped(siteID: Int)
        case atomic(loginURL: String)
        case privateAtomic(blogID: Int)
    }

    enum WPNavigationActionType {
        case reload
        case allow
    }

    enum Credentials {
        case dotCom(username: String, authToken: String, authenticationType: DotComAuthenticationType)
        case siteLogin(loginURL: URL, username: String, password: String)
    }

    fileprivate let credentials: Credentials

    // MARK: - Services

    private let authenticationService: AuthenticationService

    // MARK: - Initializers

    init(credentials: Credentials, authenticationService: AuthenticationService = AuthenticationService()) {
        self.credentials = credentials
        self.authenticationService = authenticationService
    }

    convenience init?(site: Site, username: String, token: String) {
        var authenticationType: DotComAuthenticationType = .regular

        if site.isWordPressStore {
            authenticationType = .atomic(loginURL: site.loginURL)
            // TODO: consider private atomic case
        }

        self.init(credentials: .dotCom(username: username, authToken: token, authenticationType: authenticationType))
    }

    /// Potentially rewrites a request for authentication.
    ///
    /// This method will call the completion block with the request to be used.
    ///
    /// - Warning: On WordPress.com, this uses a special redirect system. It
    /// requires the web view to call `interceptRedirect(request:)` before
    /// loading any request.
    ///
    /// - Parameters:
    ///     - url: the URL to be loaded.
    ///     - cookieJar: a CookieJar object where the authenticator will look
    ///     for existing cookies.
    ///     - completion: this will be called with either the request for
    ///     authentication, or a request for the original URL.
    ///
    @objc func request(url: URL, cookieJar: CookieJar, completion: @escaping (URLRequest) -> Void) {
        switch self.credentials {
        case .dotCom(let username, let authToken, let authenticationType):
            requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                authenticationType: authenticationType,
                completion: completion)
        case .siteLogin(let loginURL, let username, let password):
            requestForSelfHosted(
                url: url,
                loginURL: loginURL,
                cookieJar: cookieJar,
                username: username,
                password: password,
                completion: completion)
        }
    }

    private func requestForWPCom(url: URL,
                                 cookieJar: CookieJar,
                                 username: String,
                                 authToken: String,
                                 authenticationType: DotComAuthenticationType,
                                 completion: @escaping (URLRequest) -> Void) {

        switch authenticationType {
        case .regular:
            requestForWPCom(
                url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                completion: completion)
        case .regularMapped(let siteID):
            requestForMappedWPCom(url: url,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                siteID: siteID,
                completion: completion)

        case .privateAtomic:
            // not supported
            return
        case .atomic(let loginURL):
            requestForAtomicWPCom(
                url: url,
                loginURL: loginURL,
                cookieJar: cookieJar,
                username: username,
                authToken: authToken,
                completion: completion)
        }
    }

    private func requestForSelfHosted(url: URL,
                                      loginURL: URL,
                                      cookieJar: CookieJar,
                                      username: String,
                                      password: String,
                                      completion: @escaping (URLRequest) -> Void) {

        func done() {
            let request = URLRequest(url: url)
            completion(request)
        }

        authenticationService.loadAuthCookiesForSelfHosted(into: cookieJar, loginURL: loginURL, username: username, password: password, success: {
            done()
        }) { [weak self] error in
            // Make sure this error scenario isn't silently ignored.
            self?.logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForAtomicWPCom(url: URL,
                                       loginURL: String,
                                       cookieJar: CookieJar,
                                       username: String,
                                       authToken: String,
                                       completion: @escaping (URLRequest) -> Void) {

        func done() {
            // For non-private Atomic sites, proxy the request through wp-login like Calypso does.
            // If the site has SSO enabled auth should happen and we get redirected to our preview.
            // If SSO is not enabled wp-admin prompts for credentials, then redirected.
            var components = URLComponents(string: loginURL)
            var queryItems = components?.queryItems ?? []
            queryItems.append(URLQueryItem(name: "redirect_to", value: url.absoluteString))
            components?.queryItems = queryItems
            let requestURL = components?.url ?? url

            let request = URLRequest(url: requestURL)
            completion(request)
        }

        authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken, success: {
            done()
        }) { [weak self] error in
            // Make sure this error scenario isn't silently ignored.
            self?.logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForMappedWPCom(url: URL,
                                       cookieJar: CookieJar,
                                       username: String,
                                       authToken: String,
                                       siteID: Int,
                                       completion: @escaping (URLRequest) -> Void) {
        func done() {
            guard
                let host = url.host,
                !host.contains("wordpress.com")
            else {
                // The requested URL is to the unmapped version of the domain,
                // so skip proxying the request through r-login.
                completion(URLRequest(url: url))
                return
            }

            let rlogin = "https://r-login.wordpress.com/remote-login.php?action=auth"
            guard var components = URLComponents(string: rlogin) else {
                // Safety net in case something unexpected changes in the future.
                DDLogError("There was an unexpected problem initializing URLComponents via the rlogin string.")
                completion(URLRequest(url: url))
                return
            }
            var queryItems = components.queryItems ?? []
            queryItems.append(contentsOf: [
                URLQueryItem(name: "host", value: host),
                URLQueryItem(name: "id", value: String(siteID)),
                URLQueryItem(name: "back", value: url.absoluteString)
            ])
            components.queryItems = queryItems
            let requestURL = components.url ?? url

            let request = URLRequest(url: requestURL)
            completion(request)
        }

        authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken, success: {
            done()
        }) { [weak self] error in
            // Make sure this error scenario isn't silently ignored.
            self?.logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func requestForWPCom(url: URL, cookieJar: CookieJar, username: String, authToken: String, completion: @escaping (URLRequest) -> Void) {

        func done() {
            let request = URLRequest(url: url)
            completion(request)
        }

        authenticationService.loadAuthCookiesForWPCom(into: cookieJar, username: username, authToken: authToken, success: {
            done()
        }) { [weak self] error in
            // Make sure this error scenario isn't silently ignored.
            self?.logErrorIfNeeded(error)

            // Even if getting the auth cookies fail, we'll still try to load the URL
            // so that the user sees a reasonable error situation on screen.
            // We could opt to create a special screen but for now I'd rather users report
            // the issue when it happens.
            done()
        }
    }

    private func logErrorIfNeeded(_ error: Swift.Error) {
        let nsError = error as NSError

        switch nsError.code {
        case NSURLErrorTimedOut, NSURLErrorNotConnectedToInternet:
            return
        default:
            ServiceLocator.crashLogging.logError(error)
        }
    }
}

private extension RequestAuthenticator {
    static let wordPressComLoginUrl = URL(string: "https://wordpress.com/wp-login.php")!
}

extension RequestAuthenticator {
    func isLogin(url: URL) -> Bool {
        var components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        components?.queryItems = nil

        return components?.url == RequestAuthenticator.wordPressComLoginUrl
    }
}

// MARK: Navigation Validator
extension RequestAuthenticator {
    /// Validates that the navigation worked as expected then provides a recommendation on if the screen should reload or not.
    func decideActionFor(response: URLResponse, cookieJar: CookieJar, completion: @escaping (WPNavigationActionType) -> Void) {
        switch self.credentials {
        case .dotCom(let username, _, let authenticationType):
            decideActionForWPCom(response: response, cookieJar: cookieJar, username: username, authenticationType: authenticationType, completion: completion)
        case .siteLogin:
            completion(.allow)
        }
    }

    private func decideActionForWPCom(response: URLResponse,
                                      cookieJar: CookieJar,
                                      username: String,
                                      authenticationType: DotComAuthenticationType,
                                      completion: @escaping (WPNavigationActionType) -> Void) {

        guard didEncouterRecoverableChallenge(response) else {
            completion(.allow)
            return
        }

        cookieJar.removeWordPressComCookies {
            completion(.reload)
        }
    }

    private func didEncouterRecoverableChallenge(_ response: URLResponse) -> Bool {
        guard let url = response.url?.absoluteString else {
            return false
        }

        if url.contains("r-login.wordpress.com") || url.contains("wordpress.com/log-in?") {
            return true
        }

        guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
            return false
        }

        return 400 <= statusCode && statusCode < 500
    }
}
