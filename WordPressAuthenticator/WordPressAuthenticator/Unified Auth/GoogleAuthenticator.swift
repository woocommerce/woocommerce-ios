import Foundation
import GoogleSignIn
import WordPressKit
import SVProgressHUD


/// Contains delegate methods for Google authentication unified auth flow.
/// Both Login and Signup are handled via this delegate.
///
protocol GoogleAuthenticatorDelegate: class {
    // Google account login was successful.
    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account login was successful, but a WP 2FA code is required.
    func googleNeedsMultifactorCode(loginFields: LoginFields)

    // Google account login was successful, but a WP password is required.
    func googleExistingUserNeedsConnection(loginFields: LoginFields)
    
    // Google account login failed.
    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields, unknownUser: Bool)

    // Google account selection cancelled by user.
    func googleAuthCancelled()

    // Google account signup was successful.
    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup redirected to login was successful.
    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account signup failed.
    func googleSignupFailed(error: Error, loginFields: LoginFields)
}

/// Indicate which type of authentication is initiated.
/// Utilized by ViewControllers that handle separate Google Login and Signup flows.
/// This is needed as long as:
///     Separate Google Login and Signup flows are utilized.
///     Tracking is specific to separate Login and Signup flows.
/// When separate Google Login and Signup flows are no longer used, this no longer needed.
///
enum GoogleAuthType {
    case login
    case signup
}

/// Contains delegate methods for Google login specific flow.
/// When separate Google Login and Signup flows are no longer used, this no longer needed.
///
protocol GoogleAuthenticatorLoginDelegate: class {
    // Google account login was successful.
    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields)

    // Google account login was successful, but a WP 2FA code is required.
    func googleNeedsMultifactorCode(loginFields: LoginFields)

    // Google account login was successful, but a WP password is required.
    func googleExistingUserNeedsConnection(loginFields: LoginFields)
    
    // Google account login failed.
    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields)
}

/// Contains delegate methods for Google signup specific flow.
/// When separate Google Login and Signup flows are no longer used, this no longer needed.
///
protocol GoogleAuthenticatorSignupDelegate: class {
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
    weak var loginDelegate: GoogleAuthenticatorLoginDelegate?
    weak var signupDelegate: GoogleAuthenticatorSignupDelegate?
    weak var delegate: GoogleAuthenticatorDelegate?

    private var loginFields = LoginFields()
    private let authConfig = WordPressAuthenticator.shared.configuration
    private var authType: GoogleAuthType = .login
    
    /// The analytics tracker for the Google sign in flows.
    ///
    private let tracker: GoogleAuthenticatorTracker?
    
    private lazy var loginFacade: LoginFacade = {
        let facade = LoginFacade(dotcomClientID: authConfig.wpcomClientId,
                                 dotcomSecret: authConfig.wpcomSecret,
                                 userAgent: authConfig.userAgent)
        facade.delegate = self
        return facade
    }()

    private lazy var authenticationDelegate: WordPressAuthenticatorDelegate = {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }
        return delegate
    }()
    
    // MARK: - Initializers
    
    private override init() {
        if WordPressAuthenticator.shared.configuration.enableUnifiedGoogle {
            tracker = GoogleAuthenticatorTracker(analyticsTracker: AnalyticsTracker.shared)
        } else {
            tracker = nil
        }
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
    func showFrom(viewController: UIViewController, loginFields: LoginFields, for authType: GoogleAuthType = .login) {
        self.loginFields = loginFields
        self.loginFields.meta.socialService = SocialServiceName.google
        self.authType = authType
        requestAuthorization(from: viewController)
    }
    
    /// Public method to create a WP account with a Google account.
    /// - Parameters:
    ///   - loginFields: LoginFields from the calling view controller.
    ///                  The values are updated during the Google process,
    ///                  and returned to the calling view controller via delegate methods.
    func createGoogleAccount(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let user = loginFields.meta.googleUser,
            let token = loginFields.meta.socialServiceIDToken else {
                DDLogError("GoogleAuthenticator - createGoogleAccount: Failed to get Google account information.")
                return
        }

        createWordPressComUser(user: user, token: token, email: loginFields.emailAddress)
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

        tracker?.trackSigninStart(authType: authType)

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
        guard authConfig.enableUnifiedGoogle else {
            return
        }
        
        var trackProperties = properties
        trackProperties["source"] = "google"
        WordPressAuthenticator.track(event, properties: trackProperties)
    }
    
    enum LocalizedText {
        static let googleConnected = NSLocalizedString("Connected But…", comment: "Title shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleConnectedError = NSLocalizedString("The Google account \"%@\" doesn't match any account on WordPress.com", comment: "Description shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleUnableToConnect = NSLocalizedString("Unable To Connect", comment: "Shown when a user logs in with Google but it subsequently fails to work as login to WordPress.com")
        static let processing = NSLocalizedString("Processing Account", comment: "Shown while the app waits for the account process to complete.")
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
                
                tracker?.trackSigninFailure(authType: authType, error: error)

                // Notify the delegates so the Google Auth view can be dismissed.
                signupDelegate?.googleSignupCancelled()
                delegate?.googleAuthCancelled()
                
                return
        }
        
        // Save account information to pass back to delegate later.
        loginFields.emailAddress = email
        loginFields.username = email
        loginFields.meta.socialServiceIDToken = token
        loginFields.meta.googleUser = user

        guard authConfig.enableUnifiedGoogle else {
            // Initiate separate WP login / signup paths.
            switch authType {
            case .login:
                SVProgressHUD.show(withStatus: LocalizedText.processing)
                loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
            case .signup:
                createWordPressComUser(user: user, token: token, email: email)
            }

            return
        }

        // Initiate unified path by attempting to login first.
        SVProgressHUD.show(withStatus: LocalizedText.processing)
        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
    }
    
}

// MARK: - LoginFacadeDelegate

extension GoogleAuthenticator: LoginFacadeDelegate {

    // Google account login was successful.
    func finishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        SVProgressHUD.dismiss()
        GIDSignIn.sharedInstance().disconnect()

        track(.signedIn)
        track(.loginSocialSuccess)
        tracker?.trackSuccess()
        
        let wpcom = WordPressComCredentials(authToken: authToken,
                                            isJetpackLogin: loginFields.meta.jetpackLogin,
                                            multifactor: false,
                                            siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        loginDelegate?.googleFinishedLogin(credentials: credentials, loginFields: loginFields)
        delegate?.googleFinishedLogin(credentials: credentials, loginFields: loginFields)
    }

    // Google account login was successful, but a WP 2FA code is required.
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        SVProgressHUD.dismiss()
        GIDSignIn.sharedInstance().disconnect()

        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID

        track(.loginSocial2faNeeded)
        tracker?.trackTwoFactorAuthenticationRequested()
        
        loginDelegate?.googleNeedsMultifactorCode(loginFields: loginFields)
        delegate?.googleNeedsMultifactorCode(loginFields: loginFields)
    }

    // Google account login was successful, but a WP password is required.
    func existingUserNeedsConnection(_ email: String) {
        SVProgressHUD.dismiss()
        GIDSignIn.sharedInstance().disconnect()

        loginFields.username = email
        loginFields.emailAddress = email
        
        track(.loginSocialAccountsNeedConnecting)
        tracker?.trackPasswordRequested(authType: authType)
        
        loginDelegate?.googleExistingUserNeedsConnection(loginFields: loginFields)
        delegate?.googleExistingUserNeedsConnection(loginFields: loginFields)
    }

    // Google account login failed.
    func displayRemoteError(_ error: Error) {
        SVProgressHUD.dismiss()
        GIDSignIn.sharedInstance().disconnect()

        var errorTitle = LocalizedText.googleUnableToConnect
        var errorDescription = error.localizedDescription
        let unknownUser = (error as NSError).code == WordPressComOAuthError.unknownUser.rawValue

        if unknownUser {
            errorTitle = LocalizedText.googleConnected
            errorDescription = String(format: LocalizedText.googleConnectedError, loginFields.username)
            track(.loginSocialErrorUnknownUser)
        }

        tracker?.trackSigninFailure(authType: authType, error: error)

        loginDelegate?.googleLoginFailed(errorTitle: errorTitle, errorDescription: errorDescription, loginFields: loginFields)
        delegate?.googleLoginFailed(errorTitle: errorTitle, errorDescription: errorDescription, loginFields: loginFields, unknownUser: unknownUser)
    }
    
}

// MARK: - Sign Up Methods

private extension GoogleAuthenticator {

    /// Creates a WordPress.com account with the associated Google User + Google Token + Google Email.
    ///
    func createWordPressComUser(user: GIDGoogleUser, token: String, email: String) {
        SVProgressHUD.show(withStatus: LocalizedText.processing)
        let service = SignupService()
        
        tracker?.trackSignupStart()

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
        tracker?.trackSuccess()

        signupDelegate?.googleFinishedSignup(credentials: credentials, loginFields: loginFields)
        delegate?.googleFinishedSignup(credentials: credentials, loginFields: loginFields)
    }
    
    func logInInstead(credentials: AuthenticatorCredentials) {
        track(.signedIn)
        track(.signupSocialToLogin)
        track(.loginSocialSuccess)
        tracker?.trackLoginInstead()

        signupDelegate?.googleLoggedInInstead(credentials: credentials, loginFields: loginFields)
        delegate?.googleLoggedInInstead(credentials: credentials, loginFields: loginFields)
    }
    
    func signupFailed(error: Error) {
        track(.signupSocialFailure, properties: ["error": error.localizedDescription])
        tracker?.trackSignupFailure(error: error)

        signupDelegate?.googleSignupFailed(error: error, loginFields: loginFields)
        delegate?.googleSignupFailed(error: error, loginFields: loginFields)
    }

}
