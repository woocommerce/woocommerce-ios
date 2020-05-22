import Foundation
import GoogleSignIn
import WordPressKit

protocol GoogleAuthenticatorDelegate {
    
    // Logging in with a Google account was successful.
    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields)
    
    // Google account login was successful, but a WP 2FA code is required.
    func googleNeedsMultifactorCode(loginFields: LoginFields)
    
    // Google account login was successful, but a WP password is required.
    func googleExistingUserNeedsConnection(loginFields: LoginFields)
    
    // Google account login failed.
    func googleRemoteError(errorTitle: String, errorDescription: String, loginFields: LoginFields)
}

class GoogleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: GoogleAuthenticator = GoogleAuthenticator()
    private override init() {}
    var delegate: GoogleAuthenticatorDelegate?

    private var loginFields = LoginFields()
    private let authConfig = WordPressAuthenticator.shared.configuration
    
    private lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade(dotcomClientID: authConfig.wpcomClientId,
                                 dotcomSecret: authConfig.wpcomSecret,
                                 userAgent: authConfig.userAgent)
        facade.delegate = self
        return facade
    }()
    
    // MARK: - Start Authentication
    
    /// Public method to initiate the Google auth process.
    /// - Parameters:
    ///   - viewController: The UIViewController that Google is being presented from.
    ///                     Required by Google SDK.
    ///   - loginFields: LoginFields from the calling view controller.
    ///                  The values are updated during the Google process,
    ///                  and returned to the calling view controller via delegate methods.
    func showFrom(viewController: UIViewController, loginFields: LoginFields) {
        self.loginFields = loginFields
        self.loginFields.meta.socialService = SocialServiceName.google
        requestAuthorization(from: viewController)
    }
    
}

// MARK: - Private Extension

private extension GoogleAuthenticator {

    /// Initiates the Google authentication flow.
    ///   - viewController: The UIViewController that Google is being presented from.
    ///                     Required by Google SDK.
    func requestAuthorization(from viewController: UIViewController) {

        guard let googleInstance = GIDSignIn.sharedInstance() else {
            DDLogError("GoogleAuthenticator: Failed to get `GIDSignIn.sharedInstance()`.")
            return
        }

        googleInstance.disconnect()

        // This has no effect since we don't use Google UI, but presentingViewController is required, so here we are.
        googleInstance.presentingViewController = viewController
        
        googleInstance.delegate = self
        googleInstance.clientID = authConfig.googleLoginClientId
        googleInstance.serverClientID = authConfig.googleLoginServerClientId

        // Start the Google auth process. This presents the Google account selection view.
        googleInstance.signIn()

        WordPressAuthenticator.track(.loginSocialButtonClick, properties: ["source": "google"])
    }

    enum LocalizedText {
        static let googleConnected = NSLocalizedString("Connected But…", comment: "Title shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleConnectedError = NSLocalizedString("The Google account \"%@\" doesn't match any account on WordPress.com", comment: "Description shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleUnableToConnect = NSLocalizedString("Unable To Connect", comment: "Shown when a user logs in with Google but it subsequently fails to work as login to WordPress.com")
    }

}

// MARK: - GIDSignInDelegate

extension GoogleAuthenticator: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        
        // Get account information
        guard let user = user,
            let token = user.authentication.idToken,
            let email = user.profile.email else {
                
                // The Google SignIn may have been canceled.
                let properties = ["error": error?.localizedDescription,
                                  "source": SocialServiceName.google.rawValue]
                
                WordPressAuthenticator.track(.loginSocialButtonFailure, properties: properties as [AnyHashable : Any])
                return
        }
        
        // Save account information to pass back to delegate later.
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.googleUser = user
        
        // Initiate WP login.
        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
    }
    
}

// MARK: - LoginFacadeDelegate

extension GoogleAuthenticator: LoginFacadeDelegate {

    // Logging in with a Google account was successful.
    func finishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        GIDSignIn.sharedInstance().disconnect()
        
        WordPressAuthenticator.track(.signedIn, properties: ["source": "google"])
        WordPressAuthenticator.track(.loginSocialSuccess, properties: ["source": "google"])
        
        let wpcom = WordPressComCredentials(authToken: authToken,
                                            isJetpackLogin: loginFields.meta.jetpackLogin,
                                            multifactor: false,
                                            siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        delegate?.googleFinishedLogin(credentials: credentials, loginFields: loginFields)
    }

    // Google account login was successful, but a WP 2FA code is required.
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        GIDSignIn.sharedInstance().disconnect()

        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID
        
        var properties = [AnyHashable:Any]()
        if let service = loginFields.meta.socialService?.rawValue {
            properties["source"] = service
        }
        
        WordPressAuthenticator.track(.loginSocial2faNeeded, properties: properties)
        delegate?.googleNeedsMultifactorCode(loginFields: loginFields)
    }

    // Google account login was successful, but a WP password is required.
    func existingUserNeedsConnection(_ email: String) {
        GIDSignIn.sharedInstance().disconnect()
        
        loginFields.username = email
        loginFields.emailAddress = email
        
        WordPressAuthenticator.track(.loginSocialAccountsNeedConnecting, properties: ["source": "google"])
        delegate?.googleExistingUserNeedsConnection(loginFields: loginFields)
    }

    // Google account login failed.
    func displayRemoteError(_ error: Error) {
        GIDSignIn.sharedInstance().disconnect()
        
        let errorTitle: String
        let errorDescription: String
        if (error as NSError).code == WordPressComOAuthError.unknownUser.rawValue {
            errorTitle = LocalizedText.googleConnected
            errorDescription = String(format: LocalizedText.googleConnectedError, loginFields.username)
            WordPressAuthenticator.track(.loginSocialErrorUnknownUser)
        } else {
            errorTitle = LocalizedText.googleUnableToConnect
            errorDescription = error.localizedDescription
        }
        
        delegate?.googleRemoteError(errorTitle: errorTitle, errorDescription: errorDescription, loginFields: loginFields)
    }
    
}
