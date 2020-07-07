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
    
    // MARK: Lifecycle Methods

    override open func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationItem.largeTitleDisplayMode = .never
        styleNavigationBar()
        
        displayError(message: "")
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
    func setupNavBarIcon(showIcon: Bool = true) {
        showIcon ? addAppLogoToNavController() : removeAppLogoFromNavController()
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

    private func styleNavigationBar() {
        
        var navBarBackgroundColor: UIColor
        var navButtonTextColor: UIColor
        var hideBottomBorder: Bool
        
        switch navigationItem.largeTitleDisplayMode {
        // Original nav bar style
        case .never:
            setupNavBarIcon()
            navButtonTextColor = WordPressAuthenticator.shared.style.navButtonTextColor
            navBarBackgroundColor = WordPressAuthenticator.shared.style.navBarBackgroundColor
            hideBottomBorder = false
        // Unified nav bar style
        default:
            setupNavBarIcon(showIcon: false)
            navButtonTextColor = WordPressAuthenticator.shared.unifiedStyle?.navButtonTextColor ?? WordPressAuthenticator.shared.style.navButtonTextColor
            navBarBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.navBarBackgroundColor ?? WordPressAuthenticator.shared.style.navBarBackgroundColor
            hideBottomBorder = true
        }

        let largeTitleTextColor = WordPressAuthenticator.shared.unifiedStyle?.largeTitleTextColor ?? WordPressAuthenticator.shared.style.instructionColor
        let largeTitleFont = WPStyleGuide.serifFontForTextStyle(.largeTitle, fontWeight: .semibold)
        let largeTitleTextAttributes:[NSAttributedString.Key: Any] = [.foregroundColor: largeTitleTextColor,
                                                                      .font: largeTitleFont]
        if #available(iOS 13.0, *) {
            let appearance = UINavigationBarAppearance()
            appearance.shadowColor = hideBottomBorder ? .clear : .separator
            appearance.backgroundColor = navBarBackgroundColor
            appearance.largeTitleTextAttributes = largeTitleTextAttributes
            UIBarButtonItem.appearance().tintColor = navButtonTextColor
            
            UINavigationBar.appearance().standardAppearance = appearance
            UINavigationBar.appearance().compactAppearance = appearance
            UINavigationBar.appearance().scrollEdgeAppearance = appearance
        } else {
            let appearance = UINavigationBar.appearance()
            appearance.barTintColor = navBarBackgroundColor
            appearance.largeTitleTextAttributes = largeTitleTextAttributes
            UIBarButtonItem.appearance().tintColor = navButtonTextColor
        }

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
    }

}

// MARK: - Sync Helpers

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

// MARK: - Social Sign In Handling

extension LoginViewController {
    func signInAppleAccount() {
        guard let token = loginFields.meta.socialServiceIDToken else {
            WordPressAuthenticator.track(.loginSocialButtonFailure, properties: ["source": SocialServiceName.apple.rawValue])
            configureViewLoading(false)
            return
        }

        loginFacade.loginToWordPressDotCom(withSocialIDToken: token, service: SocialServiceName.apple.rawValue)
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

// MARK: - Navigation Bar Large Titles

extension LoginViewController {
    func setLargeTitleDisplayMode(_ largeTitleDisplayMode: UINavigationItem.LargeTitleDisplayMode) {

        // prefersLargeTitles needs to always be true if large titles are used anywhere.
        // In order to show/hide large titles, toggle largeTitleDisplayMode instead of prefersLargeTitles.
        // This allows the large titles to hide/show correctly, and animate properly when doing so,
        // when going from a view with large titles to one without, and vice versa.
        // Ref https://www.morningswiftui.com/blog/fix-large-title-animation-on-ios13

        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = largeTitleDisplayMode
        styleNavigationBar()
    }
}

// MARK: - LoginSocialError delegate methods

extension LoginViewController: LoginSocialErrorViewControllerDelegate {
    private func cleanupAfterSocialErrors() {
        dismiss(animated: true) {}
    }

    /// Displays the self-hosted login form.
    ///
    private func loginToSelfHostedSite() {
        guard let vc = LoginSiteAddressViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginViewController to LoginSiteAddressViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
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
