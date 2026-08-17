import UIKit

/// Part two of the self-hosted sign in flow: username + password. Used by WPiOS and NiOS.
/// A valid site address should be acquired before presenting this view controller.
///
final class SiteCredentialsViewController: LoginViewController {

    /// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    private weak var usernameField: UITextField?
    private weak var passwordField: UITextField?
    private weak var recoveryURLField: UITextField?
    private weak var browserAlternativeCell: TextLinkButtonTableViewCell?
    private weak var cancelRecoveryCell: TextLinkButtonTableViewCell?
    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    /// Endpoint currently being asked for, or `nil` when the credential form is shown.
    private var recoveryEndpoint: SiteCredentialRecoveryEndpoint?
    private var recoveryDraft = ""
    private var recoveryError: SiteCredentialRecoveryError?

    /// Endpoints confirmed by the merchant so far. They survive later attempts so the merchant is never asked twice.
    private var recoveredLoginURL: String?
    private var recoveredAdminURL: String?
    private var isAuthenticatingSiteCredentials = false

    private let isDismissible: Bool
    private let completionHandler: ((WordPressOrgCredentials) -> Void)?
    private let configuration: WordPressAuthenticatorConfiguration

    private var isWPCom: Bool {
        return loginFields.siteAddress == "https://wordpress.com"
    }

    init?(coder: NSCoder,
          isDismissible: Bool,
          configuration: WordPressAuthenticatorConfiguration = WordPressAuthenticator.shared.configuration,
          onCompletion: @escaping (WordPressOrgCredentials) -> Void) {
        self.isDismissible = isDismissible
        self.configuration = configuration
        self.completionHandler = onCompletion
        super.init(coder: coder)
    }

    required init?(coder: NSCoder) {
        self.isDismissible = false
        self.configuration = WordPressAuthenticator.shared.configuration
        self.completionHandler = nil
        super.init(coder: coder)
    }

    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginUsernamePassword
        }
    }

    override var loginFields: LoginFields {
        didSet {
            // Clear the password (if any) from LoginFields
            loginFields.password = ""
        }
    }

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        tracker.track(click: .submit)

        validateForm()
    }

    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        loginFields.meta.userIsDotCom = false

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        if isDismissible {
            navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(dismissView))
        }
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureForAccessibility()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        if isMovingToParent {
            tracker.track(step: .usernamePassword)
        } else {
            tracker.set(step: .usernamePassword)
        }

        configureSubmitButton(animating: false)
        configureViewLoading(false)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        configureViewForEditingIfNeeded()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: - Overrides

    /// Style individual ViewController backgrounds, for now.
    ///
    override func styleBackground() {
        guard let unifiedBackgroundColor = WordPressAuthenticator.shared.unifiedStyle?.viewControllerBackgroundColor else {
            super.styleBackground()
            return
        }

        view.backgroundColor = unifiedBackgroundColor
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        if recoveryEndpoint != nil {
            submitButton?.isEnabled = !animating && recoveryDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
        } else {
            submitButton?.isEnabled = !animating && !loginFields.username.isEmpty && !loginFields.password.isEmpty
        }
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and chooses which element to focus on at the beginning.
    ///
    private func configureForAccessibility() {
        view.accessibilityElements = [
            usernameField as Any,
            tableView as Any,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: usernameField)
    }

    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        isAuthenticatingSiteCredentials = loading
        usernameField?.isEnabled = !loading
        passwordField?.isEnabled = !loading
        recoveryURLField?.isEnabled = !loading
        browserAlternativeCell?.enableButton(!loading)
        cancelRecoveryCell?.enableButton(!loading)

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Set error messages and reload the table to display them.
    ///
    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        if errorMessage != message {
            if !message.isEmpty {
                tracker.track(failure: message)
            }

            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }

    /// No-op. Required by LoginFacade.
    func displayLoginMessage(_ message: String) {}
}

// MARK: - UITableViewDataSource
extension SiteCredentialsViewController: UITableViewDataSource {
    /// Returns the number of rows in a section.
    ///
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return rows.count
    }

    /// Configure cells delegate method.
    ///
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let row = rows[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: row.reuseIdentifier, for: indexPath)
        configure(cell, for: row, at: indexPath)

        return cell
    }
}

// MARK: - UITableViewDelegate conformance
extension SiteCredentialsViewController: UITableViewDelegate {
    /// After a textfield cell is done displaying, remove the textfield reference.
    ///
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if let textFieldCell = cell as? TextFieldTableViewCell {
            if usernameField === textFieldCell.textField {
                usernameField = nil
            } else if passwordField === textFieldCell.textField {
                passwordField = nil
            } else if recoveryURLField === textFieldCell.textField {
                recoveryURLField = nil
            }
        }
        if browserAlternativeCell === cell {
            browserAlternativeCell = nil
        } else if cancelRecoveryCell === cell {
            cancelRecoveryCell = nil
        }
    }
}

// MARK: - Keyboard Notifications
extension SiteCredentialsViewController: NUXKeyboardResponder {
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}

// MARK: - TextField Delegate conformance
extension SiteCredentialsViewController: UITextFieldDelegate {

    /// Handle the keyboard `return` button action.
    ///
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField == usernameField {
            if UIAccessibility.isVoiceOverRunning {
                passwordField?.placeholder = nil
            }
            passwordField?.becomeFirstResponder()
        } else if textField == passwordField || textField == recoveryURLField {
            validateForm()
        }
        return true
    }
}

// MARK: - Private Methods
private extension SiteCredentialsViewController {

    @objc func dismissView() {
        dismissBlock?(true)
    }
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            TextLabelTableViewCell.reuseIdentifier: TextLabelTableViewCell.loadNib(),
            TextFieldTableViewCell.reuseIdentifier: TextFieldTableViewCell.loadNib(),
            TextLinkButtonTableViewCell.reuseIdentifier: TextLinkButtonTableViewCell.loadNib()
        ]

        for (reuseIdentifier, nib) in cells {
            tableView.register(nib, forCellReuseIdentifier: reuseIdentifier)
        }
    }

    /// Describes how the tableView rows should be rendered.
    ///
    func loadRows() {
        guard recoveryEndpoint == nil else {
            rows = [.recoveryTitle, .recoveryDescription, .recoveryURL]
            if recoveryError != nil {
                rows.append(.recoveryError)
            }
            rows.append(contentsOf: [.browserAlternative, .cancelRecovery])
            return
        }

        rows = [.instructions, .username, .password]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }

        if configuration.displayHintButtons {
            rows.append(.forgotPassword)
        }
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell where row == .username:
            configureUsernameTextField(cell)
        case let cell as TextFieldTableViewCell where row == .password:
            configurePasswordTextField(cell)
        case let cell as TextLinkButtonTableViewCell where row == .forgotPassword:
            configureForgotPassword(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        case let cell as TextLabelTableViewCell where row == .recoveryTitle:
            configureRecoveryTitle(cell)
        case let cell as TextLabelTableViewCell where row == .recoveryDescription:
            configureRecoveryDescription(cell)
        case let cell as TextFieldTableViewCell where row == .recoveryURL:
            configureRecoveryURLField(cell)
        case let cell as TextLabelTableViewCell where row == .recoveryError:
            configureRecoveryError(cell)
        case let cell as TextLinkButtonTableViewCell where row == .browserAlternative:
            configureBrowserAlternative(cell)
        case let cell as TextLinkButtonTableViewCell where row == .cancelRecovery:
            configureCancelRecovery(cell)
        default:
            WPAuthenticatorLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        let text: String
        if isWPCom {
            text = NSLocalizedString(
                "login.sitecredentials.wpcom_instructions",
                value: "Enter your WordPress.com username and password to log in.",
                comment: "Instructions for logging in to WordPress.com using username and password."
            )
        } else {
            let displayURL = sanitizedSiteAddress(siteAddress: loginFields.siteAddress)
            text = String.localizedStringWithFormat(WordPressAuthenticator.shared.displayStrings.siteCredentialInstructions, displayURL)
        }
        cell.configureLabel(text: text, style: .body)
    }

    /// Configure the username textfield cell.
    ///
    func configureUsernameTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .username,
                       placeholder: WordPressAuthenticator.shared.displayStrings.usernamePlaceholder,
                       text: isWPCom ? nil : loginFields.username)

        // Save a reference to the textField so it can becomeFirstResponder.
        usernameField = cell.textField
        cell.textField.delegate = self

        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.username = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }

        SigninEditingState.signinEditingStateActive = true
        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive elements in VoiceOver.
            usernameField?.placeholder = nil
        }
    }

    /// Configure the password textfield cell.
    ///
    func configurePasswordTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .password,
                       placeholder: WordPressAuthenticator.shared.displayStrings.passwordPlaceholder,
                       text: loginFields.password)
        passwordField = cell.textField
        cell.textField.delegate = self
        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.password = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }

        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive elements in VoiceOver.
            passwordField?.placeholder = nil
        }
    }

    /// Configure the forgot password cell.
    ///
    func configureForgotPassword(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.resetPasswordButtonTitle, accessibilityTrait: .link)
        cell.actionHandler = { [weak self] in
            guard let self else {
                return
            }

            self.tracker.track(click: .forgottenPassword)

            // If information is currently processing, ignore button tap.
            guard self.enableSubmit(animating: false) else {
                return
            }

            WordPressAuthenticator.openForgotPasswordURL(self.loginFields)
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

    func configureRecoveryTitle(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: recoveryEndpoint == .login ? Localization.loginRecoveryTitle : Localization.adminRecoveryTitle,
                            style: .headline)
    }

    func configureRecoveryDescription(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: recoveryEndpoint == .login ? Localization.loginRecoveryDescription : Localization.adminRecoveryDescription,
                            style: .body)
    }

    func configureRecoveryURLField(_ cell: TextFieldTableViewCell) {
        let placeholder = recoveryEndpoint == .login ? Localization.loginURLPlaceholder : Localization.adminURLPlaceholder
        // `.url` styling reports the current text back, so silence the handler until the draft is in place.
        cell.onChangeSelectionHandler = nil
        cell.configure(withStyle: .url, placeholder: placeholder, text: recoveryDraft)
        recoveryURLField = cell.textField
        cell.textField.delegate = self
        cell.textField.isEnabled = !isAuthenticatingSiteCredentials
        cell.textField.accessibilityLabel = placeholder
        cell.onChangeSelectionHandler = { [weak self] textField in
            guard let self else {
                return
            }
            self.recoveryDraft = textField.text ?? ""
            self.updateRecoveryError(nil)
            self.configureSubmitButton(animating: self.isAuthenticatingSiteCredentials)
        }
    }

    func configureRecoveryError(_ cell: TextLabelTableViewCell) {
        let text = switch recoveryError {
        case .invalidURL: Localization.invalidURL
        case .differentSite: Localization.differentSite
        case .notFound where recoveryEndpoint == .login: Localization.loginURLNotFound
        case .notFound: Localization.adminURLNotFound
        case nil: ""
        }
        cell.configureLabel(text: text, style: .error)
    }

    func configureBrowserAlternative(_ cell: TextLinkButtonTableViewCell) {
        browserAlternativeCell = cell
        cell.configureButton(text: Localization.browserAlternative, accessibilityTrait: .link)
        cell.enableButton(!isAuthenticatingSiteCredentials)
        cell.actionHandler = { [weak self] in
            guard let self, !self.isAuthenticatingSiteCredentials else {
                return
            }
            WordPressAuthenticator.shared.delegate?.presentSiteCredentialBrowserAlternative(
                for: self.loginFields.siteAddress,
                in: self
            )
        }
    }

    func configureCancelRecovery(_ cell: TextLinkButtonTableViewCell) {
        cancelRecoveryCell = cell
        cell.configureButton(text: Localization.cancelRecovery, accessibilityTrait: .link)
        cell.enableButton(!isAuthenticatingSiteCredentials)
        cell.actionHandler = { [weak self] in
            self?.cancelEndpointRecovery()
        }
    }

    /// Configure the view for an editing state.
    ///
    func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            usernameField?.becomeFirstResponder()
        }
    }

    /// Presents verify email instructions screen
    ///
    /// - Parameters:
    ///   - loginFields: `LoginFields` instance created using `makeLoginFieldsUsing` helper method
    ///
    func presentVerifyEmail(loginFields: LoginFields) {
        guard let vc = VerifyEmailViewController.instantiate(from: .verifyEmail) else {
            WPAuthenticatorLogError("Failed to navigate from SiteCredentialsViewController to VerifyEmailViewController")
            return
        }

        vc.loginFields = loginFields
        navigationController?.pushViewController(vc, animated: true)
    }

    /// Used for creating `LoginFields`
    ///
    /// - Parameters:
    ///   - xmlrpc: XML-RPC URL as a String
    ///   - options: Dictionary received from .org site credential authentication response. (Containing `jetpack_user_email` and `home_url` values)
    ///
    /// - Returns: A valid `LoginFields` instance or `nil`
    ///
    func makeLoginFieldsUsing(xmlrpc: String, options: [AnyHashable: Any]) -> LoginFields? {
        guard let xmlrpcURL = URL(string: xmlrpc) else {
            WPAuthenticatorLogError("Failed to initiate XML-RPC URL from \(xmlrpc)")
            return nil
        }

        // `jetpack_user_email` to be used for WPCOM login
        guard let email = options["jetpack_user_email"] as? [String: Any],
              let userName = email["value"] as? String else {
            WPAuthenticatorLogError("Failed to find jetpack_user_email value.")
            return nil
        }

        // Site address
        guard let home_url = options["home_url"] as? [String: Any],
              let siteAddress = home_url["value"] as? String else {
            WPAuthenticatorLogError("Failed to find home_url value.")
            return nil
        }

        let loginFields = LoginFields()
        loginFields.meta.xmlrpcURL = xmlrpcURL as NSURL
        loginFields.username = userName
        loginFields.siteAddress = siteAddress
        return loginFields
    }

    func validateFormAndTriggerDelegate() {
        view.endEditing(true)
        displayError(message: "")

        // Is everything filled out?
        if !loginFields.validateFieldsPopulatedForSignin() {
            let errorMsg = NSLocalizedString("Please fill out all the fields",
                                             comment: "A short prompt asking the user to properly fill out all login fields.")
            displayError(message: errorMsg)

            return
        }

        authenticateSiteCredentials(verifying: nil)
    }

    /// Submits the address the merchant entered for the endpoint currently being recovered.
    ///
    func validateRecoveryURL() {
        guard let recoveryEndpoint else {
            return
        }
        let candidate = recoveryDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard candidate.isEmpty == false else {
            return
        }
        if recoveryEndpoint == .login {
            recoveredLoginURL = candidate
        } else {
            recoveredAdminURL = candidate
        }
        authenticateSiteCredentials(verifying: recoveryEndpoint)
    }

    func authenticateSiteCredentials(verifying endpoint: SiteCredentialRecoveryEndpoint?) {
        guard let delegate = WordPressAuthenticator.shared.delegate else {
            // The authenticator cannot present this screen without a delegate, so the flow is already unusable here.
            fatalError("Error: Where did the delegate go?")
        }
        // manually construct the XMLRPC since this is needed to get the site address later
        let credentials = WordPressOrgCredentials(
            username: loginFields.username,
            password: loginFields.password,
            xmlrpc: loginFields.siteAddress + "/xmlrpc.php",
            options: [:]
        )
        delegate.authenticateSiteCredentials(
            credentials: credentials,
            loginURL: recoveredLoginURL,
            adminURL: recoveredAdminURL,
            endpointUnderVerification: endpoint,
            onLoading: { [weak self] in self?.configureViewLoading($0) },
            onSuccess: { [weak self] credentials in
                self?.finishedLogin(withUsername: credentials.username,
                                    password: credentials.password,
                                    xmlrpc: credentials.xmlrpc,
                                    options: credentials.options)
            },
            onRecovery: { [weak self] recovery in
                self?.showEndpointRecovery(recovery)
            },
            onFailure: { [weak self] error, incorrectCredentials, verifiedLoginURL in
                self?.handleStructuredLoginFailure(
                    error: error,
                    incorrectCredentials: incorrectCredentials,
                    verifiedLoginURL: verifiedLoginURL
                )
            }
        )
    }

    /// Swaps the credential form for the inline prompt asking where the given endpoint lives.
    ///
    func showEndpointRecovery(_ recovery: SiteCredentialRecovery) {
        switch recovery {
        case .login(let draftURL, let error):
            recoveryEndpoint = .login
            recoveryError = error
            recoveredLoginURL = error == .invalidURL || error == .differentSite ? nil : draftURL
            recoveredAdminURL = nil
            recoveryDraft = draftURL
        case .admin(let verifiedLoginURL, let draftURL, let error):
            recoveryEndpoint = .admin
            recoveryError = error
            recoveredLoginURL = verifiedLoginURL
            recoveredAdminURL = error == .invalidURL || error == .differentSite ? nil : draftURL
            recoveryDraft = draftURL
        }
        reloadRecoveryRows(focusingError: recoveryError != nil)
    }

    /// Adds, removes, or refreshes only the inline error row so editing is never interrupted.
    ///
    func updateRecoveryError(_ error: SiteCredentialRecoveryError?) {
        guard recoveryError != error else {
            return
        }
        let hadError = recoveryError != nil
        recoveryError = error
        let errorIndexPath = IndexPath(row: 3, section: 0)
        switch (hadError, error != nil) {
        case (false, true):
            rows.insert(.recoveryError, at: errorIndexPath.row)
            tableView.insertRows(at: [errorIndexPath], with: .none)
        case (true, false):
            rows.remove(at: errorIndexPath.row)
            tableView.deleteRows(at: [errorIndexPath], with: .none)
        case (true, true):
            tableView.reloadRows(at: [errorIndexPath], with: .none)
        case (false, false):
            break
        }
        guard error != nil else {
            return
        }
        tableView.layoutIfNeeded()
        UIAccessibility.post(notification: .layoutChanged, argument: tableView.cellForRow(at: errorIndexPath) ?? tableView)
    }

    func cancelEndpointRecovery() {
        guard !isAuthenticatingSiteCredentials else {
            return
        }
        let cancelledEndpoint = recoveryEndpoint
        recoveryEndpoint = nil
        recoveryDraft = ""
        recoveryError = nil
        if cancelledEndpoint == .login {
            recoveredLoginURL = nil
        }
        recoveredAdminURL = nil
        reloadRecoveryRows(focusingError: false)
    }

    func reloadRecoveryRows(focusingError: Bool) {
        loadRows()
        tableView.reloadData()
        tableView.layoutIfNeeded()
        let focus: Any? = if focusingError, let errorIndex = rows.firstIndex(of: .recoveryError) {
            tableView.cellForRow(at: IndexPath(row: errorIndex, section: 0)) ?? tableView
        } else if recoveryEndpoint == nil {
            usernameField ?? tableView
        } else {
            recoveryURLField ?? tableView
        }
        UIAccessibility.post(notification: focusingError ? .layoutChanged : .screenChanged, argument: focus)
        configureSubmitButton(animating: isAuthenticatingSiteCredentials)
    }

    /// Handles a failure that is not an endpoint recovery request.
    ///
    /// A verified login entry is promoted back onto the credential form so the merchant is never asked for it again.
    ///
    func handleStructuredLoginFailure(error: Error, incorrectCredentials: Bool, verifiedLoginURL: String?) {
        configureViewLoading(false)
        if let verifiedLoginURL,
           recoveryEndpoint == .login || (incorrectCredentials && recoveryEndpoint != nil) {
            recoveredLoginURL = verifiedLoginURL
            recoveredAdminURL = nil
            recoveryEndpoint = nil
            recoveryDraft = ""
            recoveryError = nil
            reloadRecoveryRows(focusingError: false)
        }
        guard configuration.enableManualErrorHandlingForSiteCredentialLogin else {
            handleLoginFailure(error: error, incorrectCredentials: incorrectCredentials)
            return
        }
        WordPressAuthenticator.shared.delegate?.presentSiteCredentialLoginFailure(
            error: error,
            offersBrowserAlternative: recoveryEndpoint == nil && recoveredLoginURL == nil && verifiedLoginURL == nil,
            for: loginFields.siteAddress,
            in: self
        )
    }

    func handleLoginFailure(error: Error, incorrectCredentials: Bool) {
        configureViewLoading(false)
        guard configuration.enableManualErrorHandlingForSiteCredentialLogin == false else {
            WordPressAuthenticator.shared.delegate?.handleSiteCredentialLoginFailure(error: error, for: loginFields.siteAddress, in: self)
            return
        }
        if incorrectCredentials {
            let message = NSLocalizedString("It looks like this username/password isn't associated with this site.",
                                            comment: "An error message shown during log in when the username or password is incorrect.")
            displayError(message: message, moveVoiceOverFocus: true)
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }

    func syncDataOrPresentWPComLogin(with wporgCredentials: WordPressOrgCredentials) {
        if configuration.isWPComLoginRequiredForSiteCredentialsLogin {
            presentWPComLogin(wporgCredentials: wporgCredentials)
            return
        }
        // Client didn't explicitly ask for WPCOM credentials. (`isWPComLoginRequiredForSiteCredentialsLogin` is false)
        // So, sync the available credentials and finish sign in.
        //
        let credentials = AuthenticatorCredentials(wporg: wporgCredentials)
        WordPressAuthenticator.shared.delegate?.sync(credentials: credentials) { [weak self] in
            NotificationCenter.default.post(name: Foundation.Notification.Name(rawValue: WordPressAuthenticator.WPSigninDidFinishNotification), object: nil)
            self?.showLoginEpilogue(for: credentials)
        }
    }

    func presentWPComLogin(wporgCredentials: WordPressOrgCredentials) {
        // Try to get the jetpack email from XML-RPC response dictionary.
        //
        guard let loginFields = makeLoginFieldsUsing(xmlrpc: wporgCredentials.xmlrpc,
                                                     options: wporgCredentials.options) else {
            WPAuthenticatorLogError("Unexpected response from .org site credentials sign in using XMLRPC.")
            let credentials = AuthenticatorCredentials(wporg: wporgCredentials)
            showLoginEpilogue(for: credentials)
            return
        }

        // Present verify email instructions screen. Passing loginFields will prefill the jetpack email in `VerifyEmailViewController`
        //
        presentVerifyEmail(loginFields: loginFields)
    }

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case username
        case password
        case forgotPassword
        case errorMessage
        case recoveryTitle
        case recoveryDescription
        case recoveryURL
        case recoveryError
        case browserAlternative
        case cancelRecovery

        var reuseIdentifier: String {
            switch self {
            case .instructions, .recoveryTitle, .recoveryDescription, .recoveryError:
                return TextLabelTableViewCell.reuseIdentifier
            case .username, .password, .recoveryURL:
                return TextFieldTableViewCell.reuseIdentifier
            case .forgotPassword, .browserAlternative, .cancelRecovery:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }

    enum Localization {
        static let loginRecoveryTitle = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.login.title", value: "Where do you sign in to your store?",
            comment: "Title shown when asking for a custom WordPress sign-in address.")
        static let loginRecoveryDescription = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.login.description",
            value: "A security plugin may use a custom WordPress sign-in address. Enter the address you use to sign in.",
            comment: "Description shown when asking for a custom WordPress sign-in address.")
        static let loginURLPlaceholder = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.login.placeholder", value: "WordPress sign-in address",
            comment: "Placeholder for a custom WordPress sign-in address.")
        static let adminRecoveryTitle = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.admin.title", value: "Where is your store’s dashboard?",
            comment: "Title shown when asking for a custom WordPress dashboard address.")
        static let adminRecoveryDescription = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.admin.description",
            value: "A security plugin may move the WordPress dashboard. Enter the address you use to open it.",
            comment: "Description shown when asking for a custom WordPress dashboard address.")
        static let adminURLPlaceholder = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.admin.placeholder", value: "WordPress dashboard address",
            comment: "Placeholder for a custom WordPress dashboard address.")
        static let invalidURL = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.error.invalidURL", value: "Enter a full web address, including http:// or https://.",
            comment: "Error shown when a custom WordPress address is not a full web address.")
        static let differentSite = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.error.differentSite",
            value: "Enter an address on the same site without changing its secure connection or port.",
            comment: "Error shown when a custom WordPress address does not belong to the current site.")
        static let loginURLNotFound = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.error.loginNotFound",
            value: "We couldn’t find a WordPress sign-in page at that address. Check it and try again.",
            comment: "Error shown when no WordPress sign-in page exists at the custom address.")
        static let adminURLNotFound = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.error.adminNotFound",
            value: "We couldn’t reach the WordPress dashboard at that address. Check it and try again.",
            comment: "Error shown when no WordPress dashboard exists at the custom address.")
        static let browserAlternative = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.browserAlternative", value: "Try signing in with your browser instead",
            comment: "Browser authentication button shown during custom address recovery.")
        static let cancelRecovery = NSLocalizedString(
            "com.woocommerce.siteCredentials.recovery.cancel", value: "Cancel",
            comment: "Button returning to the username and password form.")
    }
}

// MARK: - Instance Methods
/// Implementation methods copied from LoginSelfHostedViewController.
///
extension SiteCredentialsViewController {
    /// Sanitize and format the site address we show to users.
    ///
    @objc func sanitizedSiteAddress(siteAddress: String) -> String {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: siteAddress) as NSString
        if let str = baseSiteUrl.components(separatedBy: "://").last {
            return str
        }
        return siteAddress
    }

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        if configuration.enableManualSiteCredentialLogin,
           !isWPCom {
            // asks the delegate to handle the login
            if recoveryEndpoint == nil {
                validateFormAndTriggerDelegate()
            } else {
                validateRecoveryURL()
            }
        } else {
            validateFormAndLogin()
        }
    }

    func finishedLogin(withUsername username: String, password: String, xmlrpc: String, options: [AnyHashable: Any]) {
        let wporg = WordPressOrgCredentials(username: username, password: password, xmlrpc: xmlrpc, options: options)
        /// If `completionHandler` is available, return early with the credentials.
        if let completionHandler {
            completionHandler(wporg)
        } else {
            syncDataOrPresentWPComLogin(with: wporg)
        }
    }

    override func displayRemoteError(_ error: Error) {
        configureViewLoading(false)
        let err = error as NSError
        if err.code == 403 {
            let message = NSLocalizedString("It looks like this username/password isn't associated with this site.",
                                            comment: "An error message shown during log in when the username or password is incorrect.")
            displayError(message: message, moveVoiceOverFocus: true)
        } else {
            displayError(error, sourceTag: sourceTag)
        }
    }
}
