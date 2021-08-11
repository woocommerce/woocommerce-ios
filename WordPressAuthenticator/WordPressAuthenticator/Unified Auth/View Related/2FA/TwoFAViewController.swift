import UIKit
import WordPressKit
import SVProgressHUD

/// TwoFAViewController: view to enter 2FA code.
///
final class TwoFAViewController: LoginViewController {

    // MARK: - Properties

    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    private weak var codeField: UITextField?

    private var rows = [Row]()
    private var errorMessage: String?
    private var pasteboardChangeCountBeforeBackground: Int?
    private var shouldChangeVoiceOverFocus: Bool = false

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .login2FA
        }
    }

    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()

        removeGoogleWaitingView()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

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
            tracker.track(step: .twoFactorAuthentication)
        } else {
            tracker.set(step: .twoFactorAuthentication)
        }

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))

        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        let nc = NotificationCenter.default
        nc.addObserver(self, selector: #selector(applicationBecameInactive), name: UIApplication.willResignActiveNotification, object: nil)
        nc.addObserver(self, selector: #selector(applicationBecameActive), name: UIApplication.didBecomeActiveNotification, object: nil)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()

        // Multifactor codes are time sensitive, so clear the stored code if the
        // user dismisses the view. They'll need to reenter it upon return.
        loginFields.multifactorCode = ""
        codeField?.text = ""
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

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        let isNumeric = loginFields.multifactorCode.rangeOfCharacter(from: CharacterSet.decimalDigits.inverted) == nil
        let isValidLength = SocialLogin2FANonceInfo.TwoFactorTypeLengths(rawValue: loginFields.multifactorCode.count) != nil

        submitButton?.isEnabled = (
            !animating &&
            isNumeric &&
            isValidLength
        )
    }

    override func configureViewLoading(_ loading: Bool) {
        super.configureViewLoading(loading)
        codeField?.isEnabled = !loading
    }

    override func displayRemoteError(_ error: Error) {
        displayError(message: "")

        configureViewLoading(false)
        let err = error as NSError
        if err.domain == "WordPressComOAuthError" && err.code == WordPressComOAuthError.invalidOneTimePassword.rawValue {
            // Invalid verification code.
            displayError(message: LocalizedText.bad2FAMessage, moveVoiceOverFocus: true)
        } else if err.domain == "WordPressComOAuthError" && err.code == WordPressComOAuthError.invalidTwoStepCode.rawValue {
            // Invalid 2FA during social login
            if let newNonce = (error as NSError).userInfo[WordPressComOAuthClient.WordPressComOAuthErrorNewNonceKey] as? String {
                loginFields.nonceInfo?.updateNonce(with: newNonce)
            }
            displayError(message: LocalizedText.bad2FAMessage, moveVoiceOverFocus: true)
        } else {
            displayError(error as NSError, sourceTag: sourceTag)
        }
    }

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

}

// MARK: - Validation and Login

private extension TwoFAViewController {

    // MARK: - Button Actions

    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        tracker.track(click: .submitTwoFactorCode)
        validateForm()
    }

    func requestCode() {
        SVProgressHUD.showSuccess(withStatus: LocalizedText.smsSent)
        SVProgressHUD.dismiss(withDelay: TimeInterval(1))

        if loginFields.nonceInfo != nil {
            // social login
            loginFacade.requestSocial2FACode(with: loginFields)
        } else {
            loginFacade.requestOneTimeCode(with: loginFields)
        }
    }

    // MARK: - Login

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    func validateForm() {
        if let nonce = loginFields.nonceInfo {
            loginWithNonce(info: nonce)
            return
        }
        validateFormAndLogin()
    }

    func loginWithNonce(info nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(true)
        let code = loginFields.multifactorCode
        let (authType, nonce) = nonceInfo.authTypeAndNonce(for: code)
        loginFacade.loginToWordPressDotCom(withUser: loginFields.nonceUserID, authType: authType, twoStepCode: code, twoStepNonce: nonce)
    }

    func finishedLogin(withNonceAuthToken authToken: String) {
        let wpcom = WordPressComCredentials(authToken: authToken, isJetpackLogin: isJetpackLogin, multifactor: true, siteURL: loginFields.siteAddress)
        let credentials = AuthenticatorCredentials(wpcom: wpcom)
        syncWPComAndPresentEpilogue(credentials: credentials)
    }

    // MARK: - Code Validation

    enum CodeValidation {
        case invalid(nonNumbers: Bool)
        case valid(String)
    }

    func isValidCode(code: String) -> CodeValidation {
        let codeStripped = code.components(separatedBy: .whitespacesAndNewlines).joined()
        let allowedCharacters = CharacterSet.decimalDigits
        let resultCharacterSet = CharacterSet(charactersIn: codeStripped)
        let isOnlyNumbers = allowedCharacters.isSuperset(of: resultCharacterSet)
        let isShortEnough = codeStripped.count <= SocialLogin2FANonceInfo.TwoFactorTypeLengths.backup.rawValue

        if isOnlyNumbers && isShortEnough {
            return .valid(codeStripped)
        }

        if isOnlyNumbers {
            return .invalid(nonNumbers: false)
        }

        return .invalid(nonNumbers: true)
    }

    // MARK: - Text Field Handling

    func handleTextFieldDidChange(_ sender: UITextField) {
        loginFields.multifactorCode = codeField?.nonNilTrimmedText() ?? ""
        configureSubmitButton(animating: false)
    }

}

// MARK: - UITextFieldDelegate

extension TwoFAViewController: UITextFieldDelegate {

    /// Only allow digits in the 2FA text field
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString: String) -> Bool {

        guard let fieldText = textField.text as NSString? else {
            return true
        }

        let resultString = fieldText.replacingCharacters(in: range, with: replacementString)

        switch isValidCode(code: resultString) {
        case .valid(let cleanedCode):
            displayError(message: "")

            // because the string was stripped of whitespace, we can't return true and we update the textfield ourselves
            textField.text = cleanedCode
            handleTextFieldDidChange(textField)
        case .invalid(nonNumbers: true):
            displayError(message: LocalizedText.numericalCode)
        default:
            if let pasteString = UIPasteboard.general.string, pasteString == replacementString {
                displayError(message: LocalizedText.invalidCode)
            }
        }

        return false
    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        validateForm()
        return true
    }

}

// MARK: - UITableViewDataSource

extension TwoFAViewController: UITableViewDataSource {

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

extension TwoFAViewController: NUXKeyboardResponder {

    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }

}

// MARK: - Application state changes

private extension TwoFAViewController {

    @objc func applicationBecameInactive() {
        pasteboardChangeCountBeforeBackground = UIPasteboard.general.changeCount
    }

    @objc func applicationBecameActive() {
        guard let codeField = codeField else {
            return
        }

        let emptyField = codeField.text?.isEmpty ?? true
        guard emptyField,
            pasteboardChangeCountBeforeBackground != UIPasteboard.general.changeCount else {
                return
        }

        if #available(iOS 14.0, *) {
            UIPasteboard.general.detectAuthenticatorCode { [weak self] result in
                switch result {
                    case .success(let authenticatorCode):
                        self?.handle(code: authenticatorCode, textField: codeField)
                    case .failure:
                        break
                }
            }
        } else {
            if let pasteString = UIPasteboard.general.string {
                handle(code: pasteString, textField: codeField)
            }
        }
    }

    private func handle(code: String, textField: UITextField) {
        switch isValidCode(code: code) {
        case .valid(let cleanedCode):
            displayError(message: "")
            textField.text = cleanedCode
            handleTextFieldDidChange(textField)
        default:
            break
        }
    }

}

// MARK: - Table Management

private extension TwoFAViewController {

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
        rows = [.instructions, .code]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }

        rows.append(.sendCode)
    }

    /// Configure cells.
    ///
    func configure(_ cell: UITableViewCell, for row: Row, at indexPath: IndexPath) {
        switch cell {
        case let cell as TextLabelTableViewCell where row == .instructions:
            configureInstructionLabel(cell)
        case let cell as TextFieldTableViewCell:
            configureTextField(cell)
        case let cell as TextLinkButtonTableViewCell:
            configureTextLinkButton(cell)
        case let cell as TextLabelTableViewCell where row == .errorMessage:
            configureErrorLabel(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

    /// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.twoFactorInstructions)
    }

    /// Configure the textfield cell.
    ///
    func configureTextField(_ cell: TextFieldTableViewCell) {
        cell.configure(withStyle: .numericCode,
                       placeholder: WordPressAuthenticator.shared.displayStrings.twoFactorCodePlaceholder)

        // Save a reference to the first textField so it can becomeFirstResponder.
        codeField = cell.textField
        cell.textField.delegate = self

        SigninEditingState.signinEditingStateActive = true
        if UIAccessibility.isVoiceOverRunning {
            // Quiet repetitive VoiceOver elements.
            codeField?.placeholder = nil
        }
    }

    /// Configure the link cell.
    ///
    func configureTextLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.textCodeButtonTitle)

        cell.actionHandler = { [weak self] in
            guard let self = self else { return }

            self.tracker.track(click: .sendCodeWithText)
            self.requestCode()
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
           codeField?.becomeFirstResponder()
       }
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and chooses which element to focus on at the beginning.
    ///
    func configureForAccessibility() {
        view.accessibilityElements = [
            codeField as Any,
            tableView as Any,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: codeField)
    }

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case code
        case sendCode
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .code:
                return TextFieldTableViewCell.reuseIdentifier
            case .sendCode:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }

    enum LocalizedText {
        static let bad2FAMessage = NSLocalizedString("Whoops, that's not a valid two-factor verification code. Double-check your code and try again!", comment: "Error message shown when an incorrect two factor code is provided.")
        static let numericalCode = NSLocalizedString("A verification code will only contain numbers.", comment: "Shown when a user types a non-number into the two factor field.")
        static let invalidCode = NSLocalizedString("That doesn't appear to be a valid verification code.", comment: "Shown when a user pastes a code into the two factor field that contains letters or is the wrong length")
        static let smsSent = NSLocalizedString("SMS Sent", comment: "One Time Code has been sent via SMS")
    }

}
