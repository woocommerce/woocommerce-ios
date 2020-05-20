import WordPressShared
import WordPressKit
import GoogleSignIn


/// View Controller for login-specific screens
open class LoginViewController: NUXViewController, LoginFacadeDelegate {
    @IBOutlet var instructionLabel: UILabel?
    @objc var errorToPresent: Error?

    lazy var loginFacade: LoginFacade = {
        let configuration = WordPressAuthenticator.shared.configuration
        let facade = LoginFacade(dotcomClientID: configuration.wpcomClientId,
                                 dotcomSecret: configuration.wpcomSecret,
                                 userAgent: configuration.userAgent)
        facade.delegate = self
        return facade
    }()

    var isJetpackLogin: Bool {
        return loginFields.meta.jetpackLogin
    }

    private var isSignUp: Bool {
        return loginFields.meta.emailMagicLinkSource == .signup
    }

    var authenticationDelegate: WordPressAuthenticatorDelegate {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            fatalError()
        }

        return delegate
    }

    private var awaitingGoogle = false
    
    // MARK: Lifecycle Methods

    override open func viewDidLoad() {
        super.viewDidLoad()
        displayError(message: "")
        setupNavBarIcon()
        styleBackground()
        styleInstructions()

        if let error = errorToPresent {
            displayRemoteError(error)
            errorToPresent = nil
        }
    }

    func didChangePreferredContentSize() {
        styleInstructions()
    }

    // MARK: - Setup and Configuration

    /// Places the WordPress logo in the navbar
    ///
    func setupNavBarIcon() {
        addWordPressLogoToNavController()
    }

    /// Styles the view's background color. Defaults to WPStyleGuide.lightGrey()
    ///
    @objc func styleBackground() {
        view.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }

    /// Configures instruction label font
    ///
    func styleInstructions() {
        instructionLabel?.font = WPStyleGuide.mediumWeightFont(forStyle: .subheadline)
        instructionLabel?.adjustsFontForContentSizeCategory = true
        instructionLabel?.textColor = WordPressAuthenticator.shared.style.instructionColor
    }

    func configureViewLoading(_ loading: Bool) {
        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Sets the text of the error label.
    ///
    /// - Parameter message: The message to display in the `errorLabel`. If empty, the `errorLabel`
    ///     will be hidden.
    /// - Parameter moveVoiceOverFocus: If `true`, moves the VoiceOver focus to the `errorLabel`.
    ///     You will want to set this to `true` if the error was caused after pressing a button
    ///     (e.g. Next button).
    func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        guard message.count > 0 else {
            errorLabel?.isHidden = true
            return
        }
        errorLabel?.isHidden = false
        errorLabel?.text = message
        errorToPresent = nil

        if moveVoiceOverFocus, let errorLabel = errorLabel {
            UIAccessibility.post(notification: .layoutChanged, argument: errorLabel)
        }
    }

    private func mustShowLoginEpilogue() -> Bool {
        return isSignUp == false && authenticationDelegate.shouldPresentLoginEpilogue(isJetpackLogin: isJetpackLogin)
    }

    private func mustShowSignupEpilogue() -> Bool {
        return isSignUp && authenticationDelegate.shouldPresentSignupEpilogue()
    }


    // MARK: - Epilogue

    func showSignupEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController = navigationController else {
            fatalError()
        }

        let service = loginFields.meta.googleUser.flatMap {
            return SocialService.google(user: $0)
        }

        authenticationDelegate.presentSignupEpilogue(in: navigationController, for: credentials, service: service)
    }

    func showLoginEpilogue(for credentials: AuthenticatorCredentials) {
        guard let navigationController = navigationController else {
            fatalError()
        }

        authenticationDelegate.presentLoginEpilogue(in: navigationController, for: credentials) { [weak self] in
            self?.dismissBlock?(false)
        }
    }

    /// Displays the self-hosted sign in form.
    ///
    func loginToSelfHostedSite() {
        guard let vc = LoginSiteAddressViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginViewController to LoginSiteAddressViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with login.
    ///
    func validateFormAndLogin() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !loginFields.validateFieldsPopulatedForSignin() {
            let errorMsg = LocalizedText.missingInfoError
            displayError(message: errorMsg)

            return
        }

        configureViewLoading(true)

        loginFacade.signIn(with: loginFields)
    }


    // MARK: SigninWPComSyncHandler methods
    dynamic open func finishedLogin(withAuthToken authToken: String, requiredMultifactorCode: Bool) {
        let wpcom = WordPressComCredentials(authToken: authToken, isJetpackLogin: isJetpackLogin, multifactor: requiredMultifactorCode, siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)

        syncWPComAndPresentEpilogue(credentials: credentials)

        linkSocialServiceIfNeeded(loginFields: loginFields, wpcomAuthToken: authToken)
    }

    func configureStatusLabel(_ message: String) {
        // this is now a no-op, unless status labels return
    }

    /// Overridden here to direct these errors to the login screen's error label
    dynamic open func displayRemoteError(_ error: Error) {
        configureViewLoading(false)

        let err = error as NSError
        guard err.code != 403 else {
            let message = LocalizedText.loginError
            displayError(message: message)
            return
        }

        displayError(err, sourceTag: sourceTag)
    }

    open func needsMultifactorCode() {
        displayError(message: "")
        configureViewLoading(false)

        WordPressAuthenticator.track(.twoFactorCodeRequested)

        guard let vc = Login2FAViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginViewController to Login2FAViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    // Update safari stored credentials. Call after a successful sign in.
    ///
    func updateSafariCredentialsIfNeeded() {
        SafariCredentialsService.updateSafariCredentialsIfNeeded(with: loginFields)
    }
    
    private enum LocalizedText {
        static let loginError = NSLocalizedString("Whoops, something went wrong and we couldn't log you in. Please try again!", comment: "An error message shown when a wpcom user provides the wrong password.")
        static let missingInfoError = NSLocalizedString("Please fill out all the fields", comment: "A short prompt asking the user to properly fill out all login fields.")
        static let gettingAccountInfo = NSLocalizedString("Getting account information", comment: "Alerts the user that wpcom account information is being retrieved.")
        static let googleConnected = NSLocalizedString("Connected But…", comment: "Title shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleConnectedError = NSLocalizedString("The Google account \"%@\" doesn't match any account on WordPress.com", comment: "Description shown when a user logs in with Google but no matching WordPress.com account is found")
        static let googleUnableToConnect = NSLocalizedString("Unable To Connect", comment: "Shown when a user logs in with Google but it subsequently fails to work as login to WordPress.com")
    }

}

// MARK: - Sync Helpers
//
extension LoginViewController {


    /// Signals the Main App to synchronize the specified WordPress.com account. On completion, the epilogue will be pushed (if needed).
    ///
    func syncWPComAndPresentEpilogue(credentials: AuthenticatorCredentials) {
        syncWPCom(credentials: credentials) { [weak self] in
            guard let self = self else {
                return
            }

            if self.mustShowSignupEpilogue() {
                self.showSignupEpilogue(for: credentials)
            } else if self.mustShowLoginEpilogue() {
                self.showLoginEpilogue(for: credentials)
            } else {
                self.dismiss()
            }
        }
    }

    /// TODO: @jlp Mar.19.2018. Officially support wporg, and rename to `sync(site)` + Update LoginSelfHostedViewController
    ///
    /// Signals the Main App to synchronize the specified WordPress.com account.
    ///
    private func syncWPCom(credentials: AuthenticatorCredentials, completion: (() -> ())? = nil) {
        SafariCredentialsService.updateSafariCredentialsIfNeeded(with: loginFields)

        configureStatusLabel(LocalizedText.gettingAccountInfo)

        authenticationDelegate.sync(credentials: credentials) { [weak self] in

            self?.configureStatusLabel("")
            self?.configureViewLoading(false)
            self?.trackSignIn(credentials: credentials)

            completion?()
        }
    }

    /// Tracks the SignIn Event
    ///
    func trackSignIn(credentials: AuthenticatorCredentials) {
        var properties = [String: String]()

        if let wpcom = credentials.wpcom {
            properties = [
                "multifactor": wpcom.multifactor.description,
                "dotcom_user": true.description
            ]
        }

        WordPressAuthenticator.track(.signedIn, properties: properties)
    }

    /// Links the current WordPress Account to a Social Service (if possible!!).
    ///
    func linkSocialServiceIfNeeded(loginFields: LoginFields, wpcomAuthToken: String) {
        guard let serviceName = loginFields.meta.socialService, let serviceToken = loginFields.meta.socialServiceIDToken else {
            return
        }
        
        let appleConnectParameters:[String:AnyObject]? = {
            if let appleUser = loginFields.meta.appleUser {
                return AccountServiceRemoteREST.appleSignInParameters(email: appleUser.email, fullName: appleUser.fullName)
            }
            return nil
        }()
        
        linkSocialService(serviceName: serviceName,
                          serviceToken: serviceToken,
                          wpcomAuthToken: wpcomAuthToken,
                          appleConnectParameters: appleConnectParameters)
    }

    /// Links the current WordPress Account to a Social Service.
    ///
    func linkSocialService(serviceName: SocialServiceName,
                           serviceToken: String,
                           wpcomAuthToken: String,
                           appleConnectParameters: [String:AnyObject]? = nil) {
        let service = WordPressComAccountService()
        service.connect(wpcomAuthToken: wpcomAuthToken,
                        serviceName: serviceName,
                        serviceToken: serviceToken,
                        connectParameters: appleConnectParameters,
                        success: {
                            let source = appleConnectParameters != nil ? "apple" : "google"
                            WordPressAuthenticator.track(.signedIn, properties: ["source": source])
                            WordPressAuthenticator.track(.loginSocialConnectSuccess)
                            WordPressAuthenticator.track(.loginSocialSuccess)
        }, failure: { error in
            DDLogError("Social Link Error: \(error)")
            WordPressAuthenticator.track(.loginSocialConnectFailure, error: error)
            // We're opting to let this call fail silently.
            // Our user has already successfully authenticated and can use the app --
            // connecting the social service isn't critical.  There's little to
            // be gained by displaying an error that can not currently be resolved
            // in the app and doing so might tarnish an otherwise satisfying login
            // experience.
            // If/when we add support for manually connecting/disconnecting services
            // we can revisit.
        })
    }
}


// MARK: - Handle changes in traitCollections. In particular, changes in Dynamic Type
//
extension LoginViewController {
    override open func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)

        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            didChangePreferredContentSize()
        }
    }
}


// MARK: - Google Sign In Handling

extension LoginViewController {

    @objc func googleLoginTapped(withDelegate delegate: GIDSignInDelegate?) {
        awaitingGoogle = true
        configureViewLoading(true)

        GIDSignIn.sharedInstance().disconnect()

        // Flag this as a social sign in.
        loginFields.meta.socialService = SocialServiceName.google

        // Configure all the things and sign in.
        GIDSignIn.sharedInstance().delegate = delegate
        GIDSignIn.sharedInstance()?.presentingViewController = self
        GIDSignIn.sharedInstance().clientID = WordPressAuthenticator.shared.configuration.googleLoginClientId
        GIDSignIn.sharedInstance().serverClientID = WordPressAuthenticator.shared.configuration.googleLoginServerClientId
        GIDSignIn.sharedInstance().signIn()

        WordPressAuthenticator.track(.loginSocialButtonClick, properties: ["source": "google"])
    }

    func displayRemoteErrorForGoogle(_ error: Error) {

        if awaitingGoogle {
            awaitingGoogle = false
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

            let socialErrorVC = LoginSocialErrorViewController(title: errorTitle, description: errorDescription)
            let socialErrorNav = LoginNavigationController(rootViewController: socialErrorVC)
            socialErrorVC.delegate = self
            socialErrorVC.loginFields = loginFields
            socialErrorVC.modalPresentationStyle = .fullScreen
            present(socialErrorNav, animated: true) {}
        } else {
            errorToPresent = error
            guard let vc = LoginWPComViewController.instantiate(from: .login) else {
                DDLogError("Failed to navigate from Google Login to LoginWPComViewController (password VC)")
                return
            }

            vc.loginFields = loginFields
            vc.dismissBlock = dismissBlock
            vc.errorToPresent = errorToPresent

            navigationController?.pushViewController(vc, animated: true)
        }
    }
    
    func googleFinishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        let wpcom = WordPressComCredentials(authToken: authToken, isJetpackLogin: isJetpackLogin, multifactor: false, siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)
        syncWPComAndPresentEpilogue(credentials: credentials)

        // Disconnect now that we're done with Google.
        GIDSignIn.sharedInstance().disconnect()
        WordPressAuthenticator.track(.signedIn, properties: ["source": "google"])
        WordPressAuthenticator.track(.loginSocialSuccess, properties: ["source": "google"])
    }

    func googleExistingUserNeedsConnection(_ email: String) {
        // Disconnect now that we're done with Google.
        GIDSignIn.sharedInstance().disconnect()

        loginFields.username = email
        loginFields.emailAddress = email

        WordPressAuthenticator.track(.loginSocialAccountsNeedConnecting, properties: ["source": "google"])
        configureViewLoading(false)

        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from Google Login to LoginWPComViewController (password VC)")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func socialNeedsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        loginFields.nonceInfo = nonceInfo
        loginFields.nonceUserID = userID

        var properties = [AnyHashable:Any]()
        if let service = loginFields.meta.socialService?.rawValue {
            properties["source"] = service
        }

        WordPressAuthenticator.track(.loginSocial2faNeeded, properties: properties)

        guard let vc = Login2FAViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginViewController to Login2FAViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func signInAppleAccount() {
        guard let token = loginFields.meta.socialServiceIDToken else {
            WordPressAuthenticator.track(.loginSocialButtonFailure, properties: ["source": SocialServiceName.apple.rawValue])
            configureViewLoading(false)
            return
        }

        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.apple.rawValue)
    }

    func signInGoogleAccount(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        guard let user = user,
            let token = user.authentication.idToken,
            let email = user.profile.email else {
                // The Google SignIn for may have been canceled.

                let properties = ["error": error?.localizedDescription,
                                  "source": SocialServiceName.google.rawValue]

                WordPressAuthenticator.track(.loginSocialButtonFailure, properties: properties as [AnyHashable : Any])
                configureViewLoading(false)
                return
        }

        updateLoginFields(googleUser: user, googleToken: token, googleEmail: email)
        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.google.rawValue)
    }
    
    /// Updates the LoginFields structure, with the specified Google User + Token + Email.
    ///
    func updateLoginFields(googleUser: GIDGoogleUser, googleToken: String, googleEmail: String) {
        loginFields.emailAddress = googleEmail
        loginFields.username = googleEmail
        loginFields.meta.socialServiceIDToken = googleToken
        loginFields.meta.googleUser = googleUser
    }
    
}

extension LoginViewController: LoginSocialErrorViewControllerDelegate {
    private func cleanupAfterSocialErrors() {
        dismiss(animated: true) {}
    }

    func retryWithEmail() {
        loginFields.username = ""
        cleanupAfterSocialErrors()
    }

    func retryWithAddress() {
        cleanupAfterSocialErrors()
        loginToSelfHostedSite()
    }

    func retryAsSignup() {
        cleanupAfterSocialErrors()

        if let controller = SignupEmailViewController.instantiate(from: .signup) {
            controller.loginFields = loginFields
            navigationController?.pushViewController(controller, animated: true)
        }
    }
}
