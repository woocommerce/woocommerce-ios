import UIKit
import SafariServices
import WordPressKit

class GetStartedViewController: LoginViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet private weak var leadingDividerLine: UIView!
    @IBOutlet private weak var leadingDividerLineWidth: NSLayoutConstraint!
    @IBOutlet private weak var dividerLabel: UILabel!
    @IBOutlet private weak var trailingDividerLine: UIView!
    @IBOutlet private weak var trailingDividerLineWidth: NSLayoutConstraint!

    private weak var emailField: UITextField?
    // This is to contain the password selected by password auto-fill.
    // When it is populated, login is attempted.
    @IBOutlet private weak var hiddenPasswordField: UITextField?

    // This is public so it can be set from StoredCredentialsAuthenticator.
    var errorMessage: String?

    private var rows = [Row]()
    private var buttonViewController: NUXButtonViewController?
    private let configuration = WordPressAuthenticator.shared.configuration
    private var shouldChangeVoiceOverFocus: Bool = false

    // Submit button displayed in the table footer.
    private let continueButton: NUXButton = {
        let button = NUXButton()
        button.isPrimary = true

        let title = WordPressAuthenticator.shared.displayStrings.continueButtonTitle
        button.setTitle(title, for: .normal)
        button.setTitle(title, for: .highlighted)

        return button
    }()

    override open var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginEmail
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        configureNavBar()
        setupTable()
        registerTableViewCells()
        loadRows()
        setupContinueButton()
        configureDivider()
        configureSocialButtons()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureSubmitButton(animating: false)

        if errorMessage != nil {
            shouldChangeVoiceOverFocus = true
        }
    }

    override open func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        tracker.set(flow: .wpCom)

        if isMovingToParent {
            tracker.track(step: .start)
        } else {
            tracker.set(step: .start)
        }

        errorMessage = nil
        hiddenPasswordField?.text = nil
        hiddenPasswordField?.isAccessibilityElement = false
    }

    // MARK: - Overrides

    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ??
            WordPressAuthenticator.shared.style.statusBarStyle
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    override func configureViewLoading(_ loading: Bool) {
        configureContinueButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    override func enableSubmit(animating: Bool) -> Bool {
        return !animating && canSubmit()
    }

}

// MARK: - UITableViewDataSource

extension GetStartedViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)
        return cell
    }

}

// MARK: - Private methods

private extension GetStartedViewController {

    // MARK: - Configuration

    func configureNavBar() {
        navigationItem.title = WordPressAuthenticator.shared.displayStrings.getStartedTitle
        styleNavigationBar(forUnified: true)
    }

    func setupTable() {
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)
    }

    func setupContinueButton() {
        let tableFooter = UIView(frame: Constants.footerFrame)
        tableFooter.addSubview(continueButton)
        tableFooter.pinSubviewToSafeArea(continueButton, insets: Constants.footerButtonInsets)
        continueButton.translatesAutoresizingMaskIntoConstraints = false
        continueButton.isEnabled = false
        continueButton.addTarget(self, action: #selector(handleSubmitButtonTapped(_:)), for: .touchUpInside)
        continueButton.accessibilityIdentifier = "Get Started Email Continue Button"
        tableView.tableFooterView = tableFooter
    }

    /// Style the "OR" divider.
    ///
    func configureDivider() {
        let color = WordPressAuthenticator.shared.unifiedStyle?.borderColor ?? WordPressAuthenticator.shared.style.primaryNormalBorderColor
        leadingDividerLine.backgroundColor = color
        leadingDividerLineWidth.constant = WPStyleGuide.hairlineBorderWidth
        trailingDividerLine.backgroundColor = color
        trailingDividerLineWidth.constant = WPStyleGuide.hairlineBorderWidth
        dividerLabel.textColor = color
        dividerLabel.text = NSLocalizedString("Or", comment: "Divider on initial auth view separating auth options.").localizedUppercase
    }

    // MARK: - Continue Button Action

    @IBAction func handleSubmitButtonTapped(_ sender: UIButton) {
        tracker.track(click: .submit)
        validateForm()
    }

    // MARK: - Hidden Password Field Action

    @IBAction func handlePasswordFieldDidChange(_ sender: UITextField) {
        attemptAutofillLogin()
    }

    // MARK: - Table Management

    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextWithLinkTableViewCell.reuseIdentifier: TextWithLinkTableViewCell.loadNib(),
            SpacerTableViewCell.reuseIdentifier: SpacerTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        rows = [.instructions, .email]

        if let authenticationDelegate = WordPressAuthenticator.shared.delegate, authenticationDelegate.wpcomTermsOfServiceEnabled {
            rows.append(.tos)
        } else {
            rows.append(.spacer)
        }

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell:
            configureEmailField(cell)
        case let cell as TextWithLinkTableViewCell:
            configureTextWithLink(cell)
        case cell as SpacerTableViewCell:
            break
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.getStartedInstructions)
    }

    /// Configure the email cell.
    ///
    func configureEmailField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .email,
                       placeholder: WordPressAuthenticator.shared.displayStrings.emailAddressPlaceholder,
                       text: loginFields.username)
        cell.textField.delegate = self
        emailField = cell.textField

        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.username = textfield.nonNilTrimmedText()
            self?.configureContinueButton(animating: false)
        }

        cell.onePasswordHandler = { [weak self] in
            guard let self = self,
            let sourceView = self.emailField else {
                return
            }

            self.view.endEditing(true)

            WordPressAuthenticator.fetchOnePasswordCredentials(self, sourceView: sourceView, loginFields: self.loginFields) { [weak self] (loginFields) in
                self?.emailField?.text = loginFields.username
                self?.validateFormAndLogin()
            }
        }

        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive elements in VoiceOver.
            emailField?.placeholder = nil
        }
    }

    /// Configure the link cell.
    ///
    func configureTextWithLink(_ cell: TextWithLinkTableViewCell) {
        cell.configureButton(markedText: WordPressAuthenticator.shared.displayStrings.loginTermsOfService)

        cell.actionHandler = { [weak self] in
            self?.termsTapped()
        }
    }

    /// Configure the error message cell.
    ///
    func configureErrorLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: errorMessage, style: .error)

        if shouldChangeVoiceOverFocus {
            UIAccessibility.post(notification: .layoutChanged, argument: cell)
        }
    }

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case email
        case tos
        case spacer
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .instructions, .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            case .email:
                return TextFieldTableViewCell.reuseIdentifier
            case .tos:
                return TextWithLinkTableViewCell.reuseIdentifier
            case .spacer:
                return SpacerTableViewCell.reuseIdentifier
            }
        }
    }

    enum Constants {
        static let footerFrame = CGRect(x: 0, y: 0, width: 0, height: 44)
        static let footerButtonInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
    }

}

// MARK: - Validation

private extension GetStartedViewController {

    /// Configures appearance of the submit button.
    ///
    func configureContinueButton(animating: Bool) {
        continueButton.showActivityIndicator(animating)
        continueButton.isEnabled = enableSubmit(animating: animating)
    }

    /// Whether the form can be submitted.
    ///
    func canSubmit() -> Bool {
        return EmailFormatValidator.validate(string: loginFields.username)
    }

    /// Validates email address and proceeds with the submit action.
    /// Empties loginFields.meta.socialService as
    /// social signin does not require form validation.
    ///
    func validateForm() {

        loginFields.meta.socialService = nil
        displayError(message: "")

        guard EmailFormatValidator.validate(string: loginFields.username) else {
            present(buildInvalidEmailAlert(), animated: true, completion: nil)
            return
        }

        configureViewLoading(true)
        let service = WordPressComAccountService()
        service.isPasswordlessAccount(username: loginFields.username,
                                      success: { [weak self] passwordless in
                                        self?.configureViewLoading(false)
                                        self?.loginFields.meta.passwordless = passwordless
                                        passwordless ? self?.requestAuthenticationLink() : self?.showPasswordView()
            },
                                      failure: { [weak self] error in
                                        WordPressAuthenticator.track(.loginFailed, error: error)
                                        DDLogError(error.localizedDescription)
                                        guard let self = self else {
                                            return
                                        }
                                        self.configureViewLoading(false)

                                        self.handleLoginError(error)
        })
    }

    /// Show the Password entry view.
    ///
    func showPasswordView() {
        guard let vc = PasswordViewController.instantiate(from: .password) else {
            DDLogError("Failed to navigate to PasswordViewController from GetStartedViewController")
            return
        }

        vc.loginFields = loginFields
        vc.trackAsPasswordChallenge = false

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Handle errors when attempting to log in with an email address
    ///
    func handleLoginError(_ error: Error) {
        let userInfo = (error as NSError).userInfo
        let errorCode = userInfo[WordPressComRestApi.ErrorKeyErrorCode] as? String

        if WordPressAuthenticator.shared.configuration.enableSignUp, errorCode == "unknown_user" {
            self.sendEmail()
        } else if errorCode == "email_login_not_allowed" {
                // If we get this error, we know we have a WordPress.com user but their
                // email address is flagged as suspicious.  They need to login via their
                // username instead.
                self.showSelfHostedWithError(error)
        } else {
            guard let authenticationDelegate = WordPressAuthenticator.shared.delegate,
                  authenticationDelegate.shouldHandleError(error) else {
                self.displayError(error as NSError, sourceTag: self.sourceTag)
                return
            }

            /// Hand over control to the host app.
            authenticationDelegate.handleError(error) { customUI in
                // Setting the rightBarButtonItems of the custom UI before pushing the view controller
                // and resetting the navigationController's navigationItem after the push seems to be the
                // only combination that gets the Help button to show up.
                customUI.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems
                self.navigationController?.navigationItem.rightBarButtonItems = self.navigationItem.rightBarButtonItems

                self.navigationController?.pushViewController(customUI, animated: true)
            }
        }
    }

    // MARK: - Send email

    /// Makes the call to request a magic signup link be emailed to the user.
    ///
    private func sendEmail() {
        tracker.set(flow: .signup)
        loginFields.meta.emailMagicLinkSource = .signup

        configureSubmitButton(animating: true)

        let service = WordPressComAccountService()
        service.requestSignupLink(for: loginFields.username,
                                  success: { [weak self] in
                                    self?.didRequestSignupLink()
                                    self?.configureSubmitButton(animating: false)

            }, failure: { [weak self] (error: Error) in
                DDLogError("Request for signup link email failed.")

                guard let self = self else {
                    return
                }

                self.tracker.track(failure: error.localizedDescription)
                self.displayError(error as NSError, sourceTag: self.sourceTag)
                self.configureSubmitButton(animating: false)
        })
    }

    private func didRequestSignupLink() {
        guard let vc = SignupMagicLinkViewController.instantiate(from: .unifiedSignup) else {
            DDLogError("Failed to navigate from UnifiedSignupViewController to SignupMagicLinkViewController")
            return
        }

        vc.loginFields = loginFields
        vc.loginFields.restrictToWPCom = true

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Makes the call to request a magic authentication link be emailed to the user.
    ///
    func requestAuthenticationLink() {
        loginFields.meta.emailMagicLinkSource = .login

        let email = loginFields.username
        guard email.isValidEmail() else {
            present(buildInvalidEmailAlert(), animated: true, completion: nil)
            return
        }

        configureViewLoading(true)
        let service = WordPressComAccountService()
        service.requestAuthenticationLink(for: email,
                                          jetpackLogin: loginFields.meta.jetpackLogin,
                                          success: { [weak self] in
                                            self?.didRequestAuthenticationLink()
                                            self?.configureViewLoading(false)

            }, failure: { [weak self] (error: Error) in
                guard let self = self else {
                    return
                }

                self.tracker.track(failure: error.localizedDescription)

                self.displayError(error as NSError, sourceTag: self.sourceTag)
                self.configureViewLoading(false)
        })
    }

    /// When a magic link successfully sends, navigate the user to the next step.
    ///
    func didRequestAuthenticationLink() {
        guard let vc = LoginMagicLinkViewController.instantiate(from: .unifiedLoginMagicLink) else {
            DDLogError("Failed to navigate to LoginMagicLinkViewController from GetStartedViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.loginFields.restrictToWPCom = true
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Build the alert message when the email address is invalid.
    ///
    func buildInvalidEmailAlert() -> UIAlertController {
        let title = NSLocalizedString("Can Not Request Link",
                                      comment: "Title of an alert letting the user know")
        let message = NSLocalizedString("A valid email address is needed to mail an authentication link. Please return to the previous screen and provide a valid email address.",
                                        comment: "An error message.")
        let helpActionTitle = NSLocalizedString("Need help?",
                                                comment: "Takes the user to get help")
        let okActionTitle = NSLocalizedString("OK",
                                              comment: "Dismisses the alert")
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)

        alert.addActionWithTitle(helpActionTitle,
                                 style: .cancel,
                                 handler: { _ in
                                    WordPressAuthenticator.shared.delegate?.presentSupportRequest(from: self, sourceTag: .loginEmail)
        })

        alert.addActionWithTitle(okActionTitle, style: .default, handler: nil)

        return alert
    }

    /// When password autofill has entered a password on this screen, attempt to login immediately
    ///
    func attemptAutofillLogin() {
        // Even though there was no explicit submit action by the user, we'll interpret
        // the credentials selection as such.
        tracker.track(click: .submit)

        loginFields.password = hiddenPasswordField?.text ?? ""
        loginFields.meta.socialService = nil
        displayError(message: "")
        validateFormAndLogin()
    }

    /// Configures loginFields to log into wordpress.com and navigates to the selfhosted username/password form.
    /// Displays the specified error message when the new view controller appears.
    ///
    func showSelfHostedWithError(_ error: Error) {
        loginFields.siteAddress = "https://wordpress.com"
        errorToPresent = error

        tracker.track(failure: error.localizedDescription)

        guard let vc = SiteCredentialsViewController.instantiate(from: .siteAddress) else {
            DDLogError("Failed to navigate to SiteCredentialsViewController from GetStartedViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

}

// MARK: - Social Button Management

private extension GetStartedViewController {

    func configureSocialButtons() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        buttonViewController.hideShadowView()

        if WordPressAuthenticator.shared.configuration.enableSignInWithApple {
            if #available(iOS 13.0, *) {
                buttonViewController.setupTopButtonFor(socialService: .apple, onTap: appleTapped)
            }
        }

        buttonViewController.setupButtomButtonFor(socialService: .google, onTap: googleTapped)

        let termsButton = WPStyleGuide.signupTermsButton()
        buttonViewController.stackView?.addArrangedSubview(termsButton)
        termsButton.addTarget(self, action: #selector(termsTapped), for: .touchUpInside)
    }

    @objc func appleTapped() {
        tracker.track(click: .loginWithApple)

        AppleAuthenticator.sharedInstance.delegate = self
        AppleAuthenticator.sharedInstance.showFrom(viewController: self)
    }

    @objc func googleTapped() {
        tracker.track(click: .loginWithGoogle)

        guard let toVC = GoogleAuthViewController.instantiate(from: .googleAuth) else {
            DDLogError("Failed to navigate to GoogleAuthViewController from GetStartedViewController")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    @objc func termsTapped() {
        tracker.track(click: .termsOfService)

        guard let url = URL(string: configuration.wpcomTermsOfServiceURL) else {
            DDLogError("GetStartedViewController: wpcomTermsOfServiceURL unavailable.")
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        safariViewController.delegate = self
        self.present(safariViewController, animated: true, completion: nil)
    }
}

// MARK: - SFSafariViewControllerDelegate

extension GetStartedViewController: SFSafariViewControllerDelegate {
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        // This will only work when the user taps "Done" in the terms of service screen.
        // It won't be executed if the user dismisses the terms of service VC by sliding it out of view.
        // Unfortunately I haven't found a way to track that scenario.
        //
        tracker.track(click: .dismiss)
    }
}

// MARK: - AppleAuthenticatorDelegate

extension GetStartedViewController: AppleAuthenticatorDelegate {

    func showWPComLogin(loginFields: LoginFields) {
        self.loginFields = loginFields
        showPasswordView()
    }

    func showApple2FA(loginFields: LoginFields) {
        self.loginFields = loginFields
        signInAppleAccount()
    }

    func authFailedWithError(message: String) {
        displayErrorAlert(message, sourceTag: .loginApple)
        tracker.set(flow: .wpCom)
    }

}

// MARK: - LoginFacadeDelegate

extension GetStartedViewController {

    // Used by SIWA when logging with with a passwordless, 2FA account.
    //
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(false)
        socialNeedsMultifactorCode(forUserID: userID, andNonceInfo: nonceInfo)
    }

}

// MARK: - UITextFieldDelegate

extension GetStartedViewController: UITextFieldDelegate {

    func textFieldDidBeginEditing(_ textField: UITextField) {
        tracker.track(click: .selectEmailField)
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if canSubmit() {
            validateForm()
        }
        return true
    }

}
