import Foundation
import GoogleSignIn
import WordPressKit
import SVProgressHUD

// Indicate which type of authentication is initiated.
// TODO: remove when Google auth flows are unified.
enum GoogleAuthType {
    case login
    case signup
}

protocol GoogleAuthenticatorLoginDelegate {
    // Google account login was successful.
    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account login was successful, but a WP 2FA code is required.
    func googleNeedsMultifactorCode(loginFields: LoginFields)

    // Google account login was successful, but a WP password is required.
    func googleExistingUserNeedsConnection(loginFields: LoginFields)
    
    // Google account login failed.
    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields)
}

protocol GoogleAuthenticatorSignupDelegate {

    // Google account signup was successful.
    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup redirected to login was successful.
    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup failed.
    func googleSignupFailed(error: Error, loginFields: LoginFields)

    // Google account signup cancelled by user.
    func googleSignupCancelled()
}

class GoogleAuthenticator: NSObject {

    // MARK: - Properties

    static var sharedInstance: GoogleAuthenticator = GoogleAuthenticator()
    private override init() {}
    var loginDelegate: GoogleAuthenticatorLoginDelegate?
    var signupDelegate: GoogleAuthenticatorSignupDelegate?

    private var loginFields = LoginFields()
    private let authConfig = WordPressAuthenticator.shared.configuration
    private var authType: GoogleAuthType = .login
    
    private lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade(dotcomClientID: authConfig.wpcomClientId,
                                 dotcomSecret: authConfig.wpcomSecret,
                                 userAgent: authConfig.userAgent)
        facade.delegate = self
        return facade
    }()

    private var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }
        return delegate
    }

    // MARK: - Start Authentication
    
    /// Public method to initiate the Google auth process.
    /// - Parameters:
    ///   - viewController: The UIViewController that Google is being presented from.
    ///                     Required by Google SDK.
    ///   - loginFields: LoginFields from the calling view controller.
    ///                  The values are updated during the Google process,
    ///                  and returned to the calling view controller via delegate methods.
    ///   - authType: Indicates the type of authentication (login or signup)
    func showFrom(viewController: UIViewController, loginFields: LoginFields, for authType: GoogleAuthType) {
        self.loginFields = loginFields
        self.loginFields.meta.socialService = SocialServiceName.google
        self.authType = authType
        requestAuthorization(from: viewController)
    }
    
}

// MARK: - Private Extension

private extension GoogleAuthenticator {

    /// Initiates the Google authentication flow.
    ///   - viewController: The UIViewController that Google is being presented from.
    ///                     Required by Google SDK.
    func requestAuthorization(from viewController: UIViewController) {

        switch authType {
        case .login:
            track(.loginSocialButtonClick)
        case .signup:
            track(.createAccountInitiated)
        }

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
    }

    func track(_ event: WPAnalyticsStat, properties: [AnyHashable: Any] = [:]) {
        var trackProperties = properties
        trackProperties["source"] = "google"
        WordPressAuthenticator.track(event, properties: trackProperties)
    }
    
    enum LocalizedText {
        static let googleConnected = NSLocalizedString("Connected But…", comment: "Title shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleConnectedError = NSLocalizedString("The Google account \"%@\" doesn't match any account on WordPress.com", comment: "Description shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleUnableToConnect = NSLocalizedString("Unable To Connect", comment: "Shown when a user logs in with Google but it subsequently fails to work as login to WordPress.com")
        static let processing = NSLocalizedString("Processing Account", comment: "Shown while the app waits for the account process to complete.")
        static let signupFailed = NSLocalizedString("Google sign up failed.", comment: "Message shown on screen after the Google sign up process failed.")
    }

}

// MARK: - GIDSignInDelegate

extension GoogleAuthenticator: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        
        // Get account information
        guard let user = user,
            let token = user.authentication.idToken,
            let email = user.profile.email else {
                
                // The Google SignIn may have been cancelled.
                let properties = ["error": error?.localizedDescription ?? ""]

                switch authType {
                case .login:
                    track(.loginSocialButtonFailure, properties: properties)
                case .signup:
                    track(.signupSocialButtonFailure, properties: properties)
                }

                // Notify the signupDelegate so the Google Signup view can be dismissed.
                signupDelegate?.googleSignupCancelled()
                return
        }
        
        // Save account information to pass back to delegate later.
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.googleUser = user
        
        // Initiate WP login / signup.
        switch authType {
        case .login:
            loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
        case .signup:
            createWordPressComUser(user: user, token: token, email: email)
        }
    }
    
}

// MARK: - LoginFacadeDelegate

extension GoogleAuthenticator: LoginFacadeDelegate {

    // Google account login was successful.
    func finishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        GIDSignIn.sharedInstance().disconnect()

        track(.signedIn)
        track(.loginSocialSuccess)
        
        let wpcom = WordPressComCredentials(authToken: authToken,
                                            isJetpackLogin: loginFields.meta.jetpackLogin,
                                            multifactor: false,
                                            siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        loginDelegate?.googleFinishedLogin(credentials: credentials, loginFields: loginFields)
    }

    // Google account login was successful, but a WP 2FA code is required.
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        GIDSignIn.sharedInstance().disconnect()

        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID

        track(.loginSocial2faNeeded)
        loginDelegate?.googleNeedsMultifactorCode(loginFields: loginFields)
    }

    // Google account login was successful, but a WP password is required.
    func existingUserNeedsConnection(_ email: String) {
        GIDSignIn.sharedInstance().disconnect()
        
        loginFields.username = email
        loginFields.emailAddress = email
        
        track(.loginSocialAccountsNeedConnecting)
        loginDelegate?.googleExistingUserNeedsConnection(loginFields: loginFields)
    }

    // Google account login failed.
    func displayRemoteError(_ error: Error) {
        GIDSignIn.sharedInstance().disconnect()
        
        let errorTitle: String
        let errorDescription: String
        if (error as NSError).code == WordPressComOAuthError.unknownUser.rawValue {
            errorTitle = LocalizedText.googleConnected
            errorDescription = String(format: LocalizedText.googleConnectedError, loginFields.username)
            track(.loginSocialErrorUnknownUser)
        } else {
            errorTitle = LocalizedText.googleUnableToConnect
            errorDescription = error.localizedDescription
        }
        
        loginDelegate?.googleLoginFailed(errorTitle: errorTitle, errorDescription: errorDescription, loginFields: loginFields)
    }
    
}

// MARK: - Sign Up Methods

private extension GoogleAuthenticator {

    /// Creates a WordPress.com account with the associated Google User + Google Token + Google Email.
    ///
    func createWordPressComUser(user: GIDGoogleUser, token: String, email: String) {

        // At this point, we don't know if we're logging in or signing up.
        // So we'll show a generic message in the HUD.
        SVProgressHUD.show(withStatus: LocalizedText.processing)

        let service = SignupService()

        service.createWPComUserWithGoogle(token: token, success: { [weak self] accountCreated, wpcomUsername, wpcomToken in

            let wpcom = WordPressComCredentials(authToken: wpcomToken, isJetpackLogin: false, multifactor: false, siteURL: self?.loginFields.siteAddress ?? "")
            let credentials = AuthenticatorCredentials(wpcom: wpcom)

            // New Account
            if accountCreated {
                SVProgressHUD.dismiss()
                // Notify the host app
                self?.authenticationDelegate.createdWordPressComAccount(username: wpcomUsername, authToken: wpcomToken)
                // Notify the delegate
                self?.accountCreated(credentials: credentials)

                return
            }

            // Existing Account
            // Sync host app
            self?.authenticationDelegate.sync(credentials: credentials) {
                SVProgressHUD.dismiss()
                // Notify delegate
                self?.logInInstead(credentials: credentials)
            }

        }, failure: { [weak self] error in
            SVProgressHUD.dismiss()
            // Notify delegate
            self?.signupFailed(error: error)
        })
    }
    
    func accountCreated(credentials: AuthenticatorCredentials) {
        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        track(.createdAccount)
        track(.signedIn)
        track(.signupSocialSuccess)

        self.signupDelegate?.googleFinishedSignup(credentials: credentials, loginFields: loginFields)
    }
    
    func logInInstead(credentials: AuthenticatorCredentials) {
        track(.signedIn)
        track(.signupSocialToLogin)
        track(.loginSocialSuccess)

        self.signupDelegate?.googleLoggedInInstead(credentials: credentials, loginFields: loginFields)
    }
    
    func signupFailed(error: Error) {
        track(.signupSocialFailure, properties: ["error": error.localizedDescription])
        self.signupDelegate?.googleSignupFailed(error: error, loginFields: loginFields)
    }
    
}
