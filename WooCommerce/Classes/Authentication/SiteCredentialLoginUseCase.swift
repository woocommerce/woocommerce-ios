import enum Alamofire.AFError
import struct Networking.CookieNonceAuthenticatorConfiguration
import class Networking.WordPressOrgNetwork
import Yosemite

protocol SiteCredentialLoginProtocol {
    func setupHandlers(onLoading: @escaping (Bool) -> Void,
                       onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void)

    func handleLogin(username: String, password: String)
}

enum SiteCredentialLoginError: Error {
    case wrongCredentials
    case genericFailure(underlyingError: Error)

    /// Used for tracking error code
    ///
    var underlyingError: NSError {
        switch self {
        case .wrongCredentials:
            return NSError(domain: "SiteCredentialLogin", code: 401, userInfo: nil)
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
    private var loadingHandler: ((Bool) -> Void)?
    private var successHandler: (() -> Void)?
    private var errorHandler: ((SiteCredentialLoginError) -> Void)?

    init(siteURL: String,
         stores: StoresManager = ServiceLocator.stores) {
        self.siteURL = siteURL
        self.stores = stores
    }

    func setupHandlers(onLoading: @escaping (Bool) -> Void,
                       onLoginSuccess: @escaping () -> Void,
                       onLoginFailure: @escaping (SiteCredentialLoginError) -> Void) {
        self.loadingHandler = onLoading
        self.successHandler = onLoginSuccess
        self.errorHandler = onLoginFailure
    }

    func handleLogin(username: String, password: String) {
        loginAndAttemptFetchingJetpackPluginDetails(username: username, password: password)
    }
}

private extension SiteCredentialLoginUseCase {
    func loginAndAttemptFetchingJetpackPluginDetails(username: String, password: String) {
        loadingHandler?(true)
        handleCookieAuthentication(username: username, password: password)
        retrieveJetpackPluginDetails()
    }

    func handleCookieAuthentication(username: String, password: String) {
        guard let loginURL = URL(string: siteURL + Constants.loginPath),
              let adminURL = URL(string: siteURL + Constants.adminPath) else {
            DDLogWarn("⚠️ Cannot construct login URL and admin URL for site \(siteURL)")
            loadingHandler?(false)
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
            self.loadingHandler?(false)
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
        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 404)),
            AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 403)):
            // Error 404 means Jetpack is not installed. Allow this to come through.
            // Error 403 means the lack of permission to manage plugins. Also allow this error
            // since we want to show the error on the next screen.
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
