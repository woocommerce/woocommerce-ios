import Foundation
import Yosemite
import WordPressAuthenticator
import enum Alamofire.AFError
import struct Networking.CookieNonceAuthenticatorConfiguration
import class Networking.WordPressOrgNetwork

/// View model for `SiteCredentialLoginView`.
///
final class SiteCredentialLoginViewModel: NSObject, ObservableObject {
    let siteURL: String

    @Published var username: String = ""
    @Published var password: String = ""
    @Published private(set) var primaryButtonDisabled = true
    @Published private(set) var isLoggingIn = false
    @Published private(set) var errorMessage = ""
    @Published var shouldShowErrorAlert = false

    private let stores: StoresManager
    private let successHandler: () -> Void
    private let analytics: Analytics

    private var loginFields: LoginFields {
        let loginFields = LoginFields()
        loginFields.username = username
        loginFields.password = password
        loginFields.siteAddress = siteURL
        loginFields.meta.userIsDotCom = false
        return loginFields
    }

    init(siteURL: String,
         stores: StoresManager = ServiceLocator.stores,
         analytics: Analytics = ServiceLocator.analytics,
         onLoginSuccess: @escaping () -> Void = {}) {
        self.siteURL = siteURL
        self.stores = stores
        self.analytics = analytics
        self.successHandler = onLoginSuccess
        super.init()
        configurePrimaryButton()
    }

    func handleLogin() {
        analytics.track(.loginJetpackSiteCredentialInstallTapped)
        loginAndAttemptFetchingJetpackPluginDetails()
    }

    func resetPassword() {
        analytics.track(.loginJetpackSiteCredentialResetPasswordTapped)
        WordPressAuthenticator.openForgotPasswordURL(loginFields)
    }
}

// MARK: Private helpers
private extension SiteCredentialLoginViewModel {
    func configurePrimaryButton() {
        $username.combineLatest($password)
            .map { $0.isEmpty || $1.isEmpty }
            .assign(to: &$primaryButtonDisabled)
    }

    func loginAndAttemptFetchingJetpackPluginDetails() {
        // Makes sure the loading indicator is shown
        isLoggingIn = true

        handleCookieAuthentication()
        retrieveJetpackPluginDetails()
    }

    func handleCookieAuthentication() {
        guard let loginURL = URL(string: siteURL + Constants.loginPath),
              let adminURL = URL(string: siteURL + Constants.adminPath) else {
            DDLogWarn("⚠️ Cannot construct login URL and admin URL for site \(siteURL)")
            isLoggingIn = false
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
            self.isLoggingIn = false
            switch result {
            case .success:
                // Success to get the details means the authentication succeeds.
                self.handleCompletion()
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
            return handleCompletion()
        case AFError.responseValidationFailed(reason: .unacceptableStatusCode(code: 401)):
            errorMessage = Localization.wrongCredentials
        default:
            errorMessage = Localization.genericFailure
        }

        shouldShowErrorAlert = true
        analytics.track(.loginJetpackSiteCredentialDidShowErrorAlert, withError: error)
    }

    func handleCompletion() {
        analytics.track(.loginJetpackSiteCredentialDidFinishLogin)
        successHandler()
    }
}

extension SiteCredentialLoginViewModel {
    enum Localization {
        static let wrongCredentials = NSLocalizedString(
            "It looks like this username/password isn't associated with this site.",
            comment: "An error message shown during login when the username or password is incorrect."
        )
        static let genericFailure = NSLocalizedString("Login failed. Please try again.", comment: "A generic error during site credential login")
    }

    enum Constants {
        static let loginPath = "/wp-login.php"
        static let adminPath = "/wp-admin/"
    }
}
