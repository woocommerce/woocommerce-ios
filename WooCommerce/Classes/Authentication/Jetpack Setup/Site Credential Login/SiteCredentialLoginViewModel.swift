import Foundation
import Yosemite
import WordPressKit
import WordPressAuthenticator
import class Networking.UserAgent
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
    private let successHandler: (_ xmlrpc: String) -> Void
    private let analytics: Analytics

    private lazy var loginFacade = LoginFacade(dotcomClientID: ApiCredentials.dotcomAppId,
                                               dotcomSecret: ApiCredentials.dotcomSecret,
                                               userAgent: UserAgent.defaultUserAgent)

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
         onLoginSuccess: @escaping (String) -> Void = { _ in }) {
        self.siteURL = siteURL
        self.stores = stores
        self.analytics = analytics
        self.successHandler = onLoginSuccess
        super.init()
        loginFacade.delegate = self
        configurePrimaryButton()
    }

    func handleLogin() {
        analytics.track(.loginJetpackSiteCredentialInstallTapped)
        loginFacade.signIn(with: loginFields)
        isLoggingIn = true
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
}

// MARK: LoginFacadeDelegate conformance
//
extension SiteCredentialLoginViewModel: LoginFacadeDelegate {
    func displayRemoteError(_ error: Error) {
        isLoggingIn = false

        let err = error as NSError
        let wrongCredentials = err.domain == Constants.xmlrpcErrorDomain && err.code == Constants.invalidCredentialErrorCode
        errorMessage = wrongCredentials ? Localization.wrongCredentials : Localization.genericFailure
        shouldShowErrorAlert = true
        analytics.track(.loginJetpackSiteCredentialDidShowErrorAlert, withError: error)
    }

    func finishedLogin(withUsername username: String, password: String, xmlrpc: String, options: [AnyHashable: Any] = [:]) {
        analytics.track(.loginJetpackSiteCredentialDidFinishLogin)
        isLoggingIn = false
        let credentials = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)
        guard let authenticator = credentials.makeCookieNonceAuthenticator() else {
            return
        }
        let network = WordPressOrgNetwork(authenticator: authenticator)
        let action = JetpackConnectionAction.authenticate(siteURL: siteURL, network: network)
        stores.dispatch(action)
        successHandler(xmlrpc)
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
        static let xmlrpcErrorDomain = "WPXMLRPCFaultError"
        static let invalidCredentialErrorCode = 403
    }
}
