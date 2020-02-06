import UIKit
import GoogleSignIn
import WordPressShared
import WordPressKit


/// This is the first screen following the log in prologue screen if the user chooses to log in.
///
open class LoginEmailViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet var emailTextField: WPWalkthroughTextField!
    @IBOutlet open var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet open var verticalCenterConstraint: NSLayoutConstraint?
    @IBOutlet var inputStack: UIStackView?
    @IBOutlet var alternativeLoginLabel: UILabel?
    @IBOutlet var hiddenPasswordField: WPWalkthroughTextField?

    var googleLoginButton: UIButton?
    var selfHostedLoginButton: UIButton?

    // This signup button isn't for the main flow; it's only shown during Jetpack installation
    var wpcomSignupButton: UIButton?

    override open var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginEmail
        }
    }

    var didFindSafariSharedCredentials = false
    var didRequestSafariSharedCredentials = false
    open var offerSignupOption = false
    private let showLoginOptions = WordPressAuthenticator.shared.configuration.showLoginOptions

    private struct Constants {
        static let alternativeLogInAnimationDuration: TimeInterval = 0.33
        static let keyboardThreshold: CGFloat = 100.0
    }


    // MARK: Lifecycle Methods


    override open func viewDidLoad() {
        super.viewDidLoad()

        localizeControls()
        setupOnePasswordButtonIfNeeded()
        
        alternativeLoginLabel?.isHidden = showLoginOptions
        if !showLoginOptions {
            addGoogleButton()
        }

        addSelfHostedLogInButton()
        addSignupButton()
    }

    override open func didChangePreferredContentSize() {
        super.didChangePreferredContentSize()
        configureEmailField()
        configureAlternativeLabel()
    }

    override open func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // The old create account vc hides the nav bar, so make sure its always visible.
        navigationController?.setNavigationBarHidden(false, animated: false)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = true

        configureEmailField()
        configureAlternativeLabel()
        configureSubmitButton()
        configureViewForEditingIfNeeded()
        configureForWPComOnlyIfNeeded()
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        WordPressAuthenticator.track(.loginEmailFormViewed)

        hiddenPasswordField?.text = nil
        errorToPresent = nil
    }


    override open func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }


    // MARK: - Setup and Configuration


    /// Hides the self-hosted login option.
    ///
    func configureForWPComOnlyIfNeeded() {
        wpcomSignupButton?.isHidden = !offerSignupOption
        selfHostedLoginButton?.isHidden = loginFields.restrictToWPCom
    }


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    func localizeControls() {
        if loginFields.meta.jetpackLogin {
            instructionLabel?.text = WordPressAuthenticator.shared.displayStrings.jetpackLoginInstructions
        } else {
            instructionLabel?.text = WordPressAuthenticator.shared.displayStrings.emailLoginInstructions
        }
        emailTextField.placeholder = NSLocalizedString("Email address", comment: "Placeholder for a textfield. The user may enter their email address.")
        emailTextField.accessibilityIdentifier = "Login Email Address"

        alternativeLoginLabel?.text = NSLocalizedString("Alternatively:", comment: "String displayed before offering alternative login methods")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: .normal)
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Login Email Next Button"
    }


    /// Sets up a 1Password button if 1Password is available.
    ///
    func setupOnePasswordButtonIfNeeded() {
        WPStyleGuide.configureOnePasswordButtonForTextfield(emailTextField,
                                                            target: self,
                                                            selector: #selector(handleOnePasswordButtonTapped(_:)))
    }

    /// Add the log in with Google button to the view
    ///
    func addGoogleButton() {
        guard let instructionLabel = instructionLabel,
            let stackView = inputStack else {
            return
        }

        let button = WPStyleGuide.googleLoginButton()
        stackView.addArrangedSubview(button)
        button.addTarget(self, action: #selector(handleGoogleLoginTapped), for: .touchUpInside)

        stackView.addConstraints([
            button.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            ])

        googleLoginButton = button
    }

    /// Add the log in with site address button to the view
    ///
    func addSelfHostedLogInButton() {
        guard let instructionLabel = instructionLabel,
            let stackView = inputStack else {
                return
        }

        let button = WPStyleGuide.selfHostedLoginButton()
        stackView.addArrangedSubview(button)
        button.addTarget(self, action: #selector(handleSelfHostedButtonTapped), for: .touchUpInside)

        stackView.addConstraints([
            button.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            ])

        selfHostedLoginButton = button
    }

    /// Add the sign up button
    ///
    /// Note: This is only used during Jetpack setup, not the normal flows
    ///
    func addSignupButton() {
        guard let instructionLabel = instructionLabel,
            let stackView = inputStack else {
                return
        }

        let button = WPStyleGuide.wpcomSignupButton()
        stackView.addArrangedSubview(button)
        button.on(.touchUpInside) { [weak self] (button) in
            self?.performSegue(withIdentifier: .showSignupMethod, sender: self)
        }

        stackView.addConstraints([
            button.leadingAnchor.constraint(equalTo: instructionLabel.leadingAnchor),
            button.trailingAnchor.constraint(equalTo: instructionLabel.trailingAnchor),
            ])

        wpcomSignupButton = button
    }

    /// Configures the email text field, updating its text based on what's stored
    /// in `loginFields`.
    ///
    func configureEmailField() {
        emailTextField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        emailTextField.text = loginFields.username
        emailTextField.adjustsFontForContentSizeCategory = true
        hiddenPasswordField?.isAccessibilityElement = false
    }

    private func configureAlternativeLabel() {
        alternativeLoginLabel?.font = WPStyleGuide.fontForTextStyle(.subheadline)
        alternativeLoginLabel?.textColor = WordPressAuthenticator.shared.style.subheadlineColor
    }

    /// Configures whether appearance of the submit button.
    ///
    func configureSubmitButton() {
        submitButton?.isEnabled = canSubmit()
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override open func configureViewLoading(_ loading: Bool) {
        emailTextField.isEnabled = !loading
        googleLoginButton?.isEnabled = !loading

        submitButton?.isEnabled = !loading
        submitButton?.showActivityIndicator(loading)
    }


    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editiing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            emailTextField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Makes the call to retrieve Safari shared credentials if they exist.
    ///
    func fetchSharedWebCredentialsIfAvailable() {
        didRequestSafariSharedCredentials = true
        SafariCredentialsService.requestSharedWebCredentials { [weak self] (found, username, password) in
            self?.handleFetchedWebCredentials(found, username: username, password: password)
        }
    }


    /// Handles Safari shared credentials if any where found.
    ///
    /// - Parameters:
    ///     - found: True if credentails were found.
    ///     - username: The selected username or nil.
    ///     - password: The selected password or nil.
    ///
    func handleFetchedWebCredentials(_ found: Bool, username: String?, password: String?) {
        didFindSafariSharedCredentials = found

        guard let username = username, let password = password else {
            return
        }

        // Update the login fields
        loginFields.username = username
        loginFields.password = password

        // Persist credentials as autofilled credentials so we can update them later if needed.
        loginFields.setStoredCredentials(usernameHash: username.hash, passwordHash: password.hash)

        loginWithUsernamePassword(immediately: true)

        WordPressAuthenticator.track(.loginAutoFillCredentialsFilled)
    }


    /// Displays the wpcom sign in form, optionally telling it to immedately make
    /// the call to authenticate with the available credentials.
    ///
    /// - Parameters:
    ///     - immediately: True if the newly loaded controller should immedately attempt
    ///                        to authenticate the user with the available credentails.  Default is `false`.
    ///
    func loginWithUsernamePassword(immediately: Bool = false) {
        if immediately {
            validateFormAndLogin()
        } else {
            performSegue(withIdentifier: .showWPComLogin, sender: self)
        }
    }

    /// Proceeds along the "magic link" sign-in flow, showing a form that let's
    /// the user request a magic link.
    ///
    func requestLink() {
        performSegue(withIdentifier: .startMagicLinkFlow, sender: self)
    }


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action. Empties loginFields.meta.socialService as
    /// social signin does not require form validation.
    ///
    func validateForm() {
        loginFields.meta.socialService = nil
        displayError(message: "")

        guard EmailFormatValidator.validate(string: loginFields.username) else {
            assertionFailure("Form should not be submitted unless there is a valid looking email entered.")
            return
        }

        configureViewLoading(true)
        let service = WordPressComAccountService()
        service.isPasswordlessAccount(username: loginFields.username,
                                      success: { [weak self] passwordless in
                                        self?.configureViewLoading(false)
                                        self?.loginFields.meta.passwordless = passwordless
                                        self?.requestLink()
            },
                                      failure: { [weak self] error in
                                        WordPressAuthenticator.track(.loginFailed, error: error)
                                        DDLogError(error.localizedDescription)
                                        guard let strongSelf = self else {
                                            return
                                        }
                                        strongSelf.configureViewLoading(false)

                                        let userInfo = (error as NSError).userInfo
                                        let errorCode = userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String
                                        if errorCode == "unknown_user" {
                                            let msg = NSLocalizedString("This email address is not registered on WordPress.com.",
                                                                        comment: "An error message informing the user the email address they entered did not match a WordPress.com account.")
                                            strongSelf.displayError(message: msg)
                                        } else if errorCode == "email_login_not_allowed" {
                                                // If we get this error, we know we have a WordPress.com user but their
                                                // email address is flagged as suspicious.  They need to login via their
                                                // username instead.
                                                strongSelf.showSelfHostedUsernamePasswordAndError(error)
                                        } else {
                                            strongSelf.displayError(error as NSError, sourceTag: strongSelf.sourceTag)
                                        }
        })
    }

    /// When password autofill has entered a password on this screen, attempt to login immediately
    func attemptAutofillLogin() {
        loginFields.password = hiddenPasswordField?.text ?? ""
        loginFields.meta.socialService = nil
        displayError(message: "")

        loginWithUsernamePassword(immediately: true)
    }
    
    /// Configures loginFields to log into wordpress.com and
    /// navigates to the selfhosted username/password form. Displays the specified
    /// error message when the new view controller appears.
    ///
    @objc func showSelfHostedUsernamePasswordAndError(_ error: Error) {
        loginFields.siteAddress = "https://wordpress.com"
        errorToPresent = error
        performSegue(withIdentifier: .showURLUsernamePassword, sender: self)
    }

    override open func displayRemoteError(_ error: Error) {
        configureViewLoading(false)
        displayRemoteErrorForGoogle(error)
    }


    /// Whether the form can be submitted.
    ///
    func canSubmit() -> Bool {
        return EmailFormatValidator.validate(string: loginFields.username)
    }


    // MARK: - Segue

    override open func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? LoginPrologueSignupMethodViewController {
            vc.transitioningDelegate = self
            vc.emailTapped = { [weak self] in
                self?.performSegue(withIdentifier: .showSigninV2, sender: self)
            }
            vc.googleTapped = { [weak self] in
                self?.performSegue(withIdentifier: .showGoogle, sender: self)
            }
            vc.modalPresentationStyle = .custom
        }
    }

    // MARK: - Actions


    @IBAction func handleSubmitForm() {
        if canSubmit() {
            validateForm()
        }
    }


    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        validateForm()
    }


    @objc func handleOnePasswordButtonTapped(_ sender: UIButton) {
        view.endEditing(true)

        WordPressAuthenticator.fetchOnePasswordCredentials(self, sourceView: sender, loginFields: loginFields) { [weak self] (loginFields) in
            self?.emailTextField.text = loginFields.username
            self?.loginWithUsernamePassword(immediately: true)
        }
    }

    @objc func handleGoogleLoginTapped() {
        googleLoginTapped(withDelegate: self)
    }

    @IBAction func handleSelfHostedButtonTapped(_ sender: UIButton) {
        loginToSelfHostedSite()
    }


    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        switch sender {
        case emailTextField:
            loginFields.username = emailTextField.nonNilTrimmedText()
            configureSubmitButton()
        case hiddenPasswordField:
            attemptAutofillLogin()
        default:
            break
        }
    }


    @IBAction func handleTextFieldEditingDidBegin(_ sender: UITextField) {
        if !didRequestSafariSharedCredentials {
            fetchSharedWebCredentialsIfAvailable()
        }
    }


    // MARK: - Keyboard Notifications


    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)

        adjustAlternativeLogInElementsVisibility(true)
    }


    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)

        adjustAlternativeLogInElementsVisibility(false)
    }

    func adjustAlternativeLogInElementsVisibility(_ visible: Bool) {
        let errorLength = errorLabel?.text?.count ?? 0
        let keyboardTallEnough = SigninEditingState.signinLastKeyboardHeightDelta > Constants.keyboardThreshold
        let keyboardVisible = visible && keyboardTallEnough

        let baseAlpha: CGFloat = errorLength > 0 ? 0.0 : 1.0
        let newAlpha: CGFloat = keyboardVisible ? baseAlpha : 1.0

        UIView.animate(withDuration: Constants.alternativeLogInAnimationDuration) { [weak self] in
            self?.alternativeLoginLabel?.alpha = newAlpha
            self?.googleLoginButton?.alpha = newAlpha
            if let selfHostedLoginButton = self?.selfHostedLoginButton,
                selfHostedLoginButton.isEnabled {
                selfHostedLoginButton.alpha = newAlpha
            }
        }
    }

}

// MARK: - Google Sign In

// LoginFacadeDelegate methods for Google Google Sign In
extension LoginEmailViewController {
    func finishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        googleFinishedLogin(withGoogleIDToken: googleIDToken, authToken: authToken)
    }

    func existingUserNeedsConnection(_ email: String) {
        configureViewLoading(false)
        googleExistingUserNeedsConnection(email)
    }

    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(false)
        socialNeedsMultifactorCode(forUserID: userID, andNonceInfo: nonceInfo)
    }
}

extension LoginEmailViewController: GIDSignInDelegate {
    open func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        signInGoogleAccount(signIn, didSignInFor: user, withError: error)
    }
}
