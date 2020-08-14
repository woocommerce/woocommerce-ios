import UIKit
import WordPressKit

/// PasswordViewController: view to enter WP account password.
///
class PasswordViewController: LoginViewController {
    
    // MARK: - Properties
    
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    
    private weak var passwordField: UITextField?
    private var rows = [Row]()
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    override var loginFields: LoginFields {
        didSet {
            loginFields.password = ""
        }
    }
    
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginWPComPassword
        }
    }
    
    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?
    
    // MARK: - View
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)
        
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureForAccessibility()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        loginFields.meta.userIsDotCom = true
        configureSubmitButton(animating: false)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        configureViewForEditingIfNeeded()
        
        // TODO: - Tracks. Old track: WordPressAuthenticator.track(.loginPasswordFormViewed)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
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
    
    override func configureViewLoading(_ loading: Bool) {
        super.configureViewLoading(loading)
        passwordField?.isEnabled = !loading
    }

    override func displayRemoteError(_ error: Error) {
        configureViewLoading(false)

        let errorCode = (error as NSError).code
        let errorDomain = (error as NSError).domain
        if errorDomain == WordPressComOAuthClient.WordPressComOAuthErrorDomain, errorCode == WordPressComOAuthError.invalidRequest.rawValue {
            let message = NSLocalizedString("It seems like you've entered an incorrect password. Want to give it another try?", comment: "An error message shown when a wpcom user provides the wrong password.")
            displayError(message: message, moveVoiceOverFocus: true)
        } else {
            super.displayRemoteError(error)
        }
    }

    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        configureViewLoading(false)
        if errorMessage != message {
            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }
    
}

// MARK: - Validation and Continue

private extension PasswordViewController {
    
    // MARK: - Button Actions
    
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        configureViewLoading(true)
        validateForm()
    }

    func validateForm() {
        validateFormAndLogin()
    }
    
}

// MARK: - UITextFieldDelegate

extension PasswordViewController: UITextFieldDelegate {
        
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if enableSubmit(animating: false) {
            validateForm()
        }
        return true
    }

}

// MARK: - UITableViewDataSource

extension PasswordViewController: UITableViewDataSource {
    
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

// MARK: - Keyboard Notifications

extension PasswordViewController: NUXKeyboardResponder {
    
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

}

// MARK: - Table Management

private extension PasswordViewController {
    
    /// Registers all of the available TableViewCells.
    ///
    func registerTableViewCells() {
        let cells = [
            GravatarEmailTableViewCell.reuseIdentifier: GravatarEmailTableViewCell.loadNib(),
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
        rows = [.gravatarEmail]
        
        // Instructions only for social accounts
        if loginFields.meta.socialService != nil {
            rows.append(.instructions)
        }
        
        rows.append(.password)
        
        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }
        
        rows.append(.forgotPassword)
    }
    
    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as GravatarEmailTableViewCell:
            configureGravatarEmail(cell)
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell where row == .password:
            configurePasswordTextField(cell)
        case let cell as TextLinkButtonTableViewCell:
            configureTextLinkButton(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the gravatar + email cell.
    ///
    func configureGravatarEmail(_ cell: GravatarEmailTableViewCell) {
        cell.configure(withEmail: loginFields.username)
        
        cell.onChangeSelectionHandler = { [weak self] textfield in
            // The email can only be changed via a password manager.
            // In this case, don't update username for social accounts.
            // This prevents inadvertent account linking.
            if self?.loginFields.meta.socialService != nil {
                cell.updateEmailAddress(self?.loginFields.username)
            } else {
                self?.loginFields.username = textfield.nonNilTrimmedText()
                self?.loginFields.emailAddress = textfield.nonNilTrimmedText()
            }
            
            self?.configureSubmitButton(animating: false)
        }
        
        cell.onePasswordHandler = { [weak self] sourceView in
            guard let self = self else {
                return
            }
            
            self.view.endEditing(true)
            
            // Don't update username for social accounts.
            // This prevents inadvertent account linking.
            let allowUsernameChange = (self.loginFields.meta.socialService == nil)
            
            WordPressAuthenticator.fetchOnePasswordCredentials(self, sourceView: sourceView, loginFields: self.loginFields, allowUsernameChange: allowUsernameChange) { [weak self] (loginFields) in
                cell.updateEmailAddress(loginFields.username)
                self?.passwordField?.text = loginFields.password
                self?.validateForm()
            }
        }
    }
    
    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        // Instructions only for social accounts
        guard let service = loginFields.meta.socialService else {
            return
        }

        let displayStrings = WordPressAuthenticator.shared.displayStrings
        let instructions = (service == .google) ? displayStrings.googlePasswordInstructions :
                                                  displayStrings.applePasswordInstructions

        cell.configureLabel(text: instructions)
    }
    
    /// Configure the password textfield cell.
    ///
    func configurePasswordTextField(_ cell: TextFieldTableViewCell) {
        cell.configureTextFieldStyle(with: .password,
                                     and: WordPressAuthenticator.shared.displayStrings.passwordPlaceholder)
        // Save a reference to the first textField so it can becomeFirstResponder.
        passwordField = cell.textField
        cell.textField.delegate = self
        
        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.password = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }
        
        SigninEditingState.signinEditingStateActive = true
        
        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive VoiceOver elements.
            passwordField?.placeholder = nil
        }
    }
    
    /// Configure the forgot password link cell.
    ///
    func configureTextLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.resetPasswordButtonTitle, accessibilityTrait: .link)
        cell.actionHandler = { [weak self] in
            guard let self = self else {
                return
            }

            // If information is currently processing, ignore button tap.
            guard self.enableSubmit(animating: false) else {
                return
            }

            WordPressAuthenticator.openForgotPasswordURL(self.loginFields)

            // TODO: add new tracks. Old track: WordPressAuthenticator.track(.loginForgotPasswordClicked)
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
    
    /// Configure the view for an editing state.
    ///
    func configureViewForEditingIfNeeded() {
       // Check the helper to determine whether an editing state should be assumed.
       adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
       if SigninEditingState.signinEditingStateActive {
           passwordField?.becomeFirstResponder()
       }
    }
    
    /// Sets up accessibility elements in the order which they should be read aloud
    /// and chooses which element to focus on at the beginning.
    ///
    func configureForAccessibility() {
        view.accessibilityElements = [
            passwordField as Any,
            tableView,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: passwordField)
    }
    
    /// Rows listed in the order they were created.
    ///
    enum Row {
        case gravatarEmail
        case instructions
        case password
        case forgotPassword
        case errorMessage
        
        var reuseIdentifier: String {
            switch self {
            case .gravatarEmail:
                return GravatarEmailTableViewCell.reuseIdentifier
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .password:
                return TextFieldTableViewCell.reuseIdentifier
            case .forgotPassword:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }

}
