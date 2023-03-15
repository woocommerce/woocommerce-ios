import enum Alamofire.AFError
import struct Networking.CookieNonceAuthenticatorConfiguration
import class Networking.WordPressOrgNetwork
import enum Networking.NetworkError
import Yosemite

protocol SiteCredentialLoginProtocol {
    func setupHandlers(onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void)

    func handleLogin(username: String, password: String)
}

enum SiteCredentialLoginError: Error {
    static let errorDomain = "SiteCredentialLogin"
    case wrongCredentials
    case invalidCookieNonce
    case genericFailure(underlyingError: Error)

    /// Used for tracking error code
    ///
    var underlyingError: NSError {
        switch self {
        case .invalidCookieNonce:
            return NSError(domain: Self.errorDomain, code: 403, userInfo: nil)
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
    private let stores: StoresManager
    private let cookieJar: HTTPCookieStorage
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError) -> Void)?

    init(siteURL: String,
         stores: StoresManager = ServiceLocator.stores,
         cookieJar: HTTPCookieStorage = HTTPCookieStorage.shared) {
        self.siteURL = siteURL
        self.stores = stores
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
        loginAndAttemptFetchingJetpackPluginDetails(username: username, password: password)
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

    func loginAndAttemptFetchingJetpackPluginDetails(username: String, password: String) {
        handleCookieAuthentication(username: username, password: password)
        retrieveJetpackPluginDetails()
    }

    func handleCookieAuthentication(username: String, password: String) {
        guard let loginURL = URL(string: siteURL + Constants.loginPath),
              let adminURL = URL(string: siteURL + Constants.adminPath) else {
            DDLogWarn("⚠️ Cannot construct login URL and admin URL for site \(siteURL)")
            let error = NSError(domain: SiteCredentialLoginError.errorDomain, code: -1)
            errorHandler?(.genericFailure(underlyingError: error))
            return
        }
        // Prepares the authenticator with username and password
        let config = CookieNonceAuthenticatorConfiguration(username: username,
                                                           password: password,
                                                           loginURL: loginURL,
                                                           adminURL: adminURL)
        let network = WordPressOrgNetwork(configuration: config)
        let authenticationAction = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        stores.dispatch(authenticationAction)
    }

    func retrieveJetpackPluginDetails() {
        // Retrieves Jetpack plugin details to see if the authentication succeeds.
        let jetpackAction = JetpackConnectionAction.retrieveJetpackPluginDetails { [weak self] result in
            guard let self else { return }
            switch result {
            case .success:
                // Success to get the details means the authentication succeeds.
                self.successHandler?()
            case .failure(let error):
                self.handleRemoteError(error)
            }
        }
        stores.dispatch(jetpackAction)
    }

    func handleRemoteError(_ error: Error) {
        switch error {
        case NetworkError.invalidCookieNonce:
            errorHandler?(.invalidCookieNonce)
        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)),
            AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403)):
            // Error 404 means Jetpack is not installed. Allow this to come through.
            // Error 403 means the lack of permission to manage plugins. Also allow this error
            // since we want to let users with shop manager roles to log in.
            successHandler?()
        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)):
            errorHandler?(.wrongCredentials)
        default:
            errorHandler?(.genericFailure(underlyingError: error))
        }
    }
}

extension SiteCredentialLoginUseCase {
    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin/"
    }
}
