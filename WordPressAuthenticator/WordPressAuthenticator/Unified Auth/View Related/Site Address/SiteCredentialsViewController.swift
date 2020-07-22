import UIKit


/// Part two of the self-hosted sign in flow: username + password. Used by WPiOS and NiOS.
/// A valid site address should be acquired before presenting this view controller.
///
class SiteCredentialsViewController: LoginViewController {

	/// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!
	private var rows = [Row]()
	private weak var usernameField: UITextField?
	private weak var passwordField: UITextField?

	/// Internal properties.
	///
	@IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    // Required property declaration for `NUXKeyboardResponder` but unused here.
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

    }

	// MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

		localizePrimaryButton()
		registerTableViewCells()
		loadRows()
		configureForAccessibility()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        configureViewForEditingIfNeeded()
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


	/// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
       // Check the helper to determine whether an editing state should be assumed.
       adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
       if SigninEditingState.signinEditingStateActive {
           usernameField?.becomeFirstResponder()
       }
    }
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
		if rows[indexPath.row] == .username {
			usernameField = nil
		} else if rows[indexPath.row] == .password {
			passwordField = nil
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
            passwordField?.becomeFirstResponder()
        } else if textField == passwordField {
            validateForm()
        }
        return true
    }
}


// MARK: - Private Methods
private extension SiteCredentialsViewController {

	/// Localize the "Continue" button.
    ///
    func localizePrimaryButton() {
        let primaryTitle = WordPressAuthenticator.shared.displayStrings.continueButtonTitle
        submitButton?.setTitle(primaryTitle, for: .normal)
        submitButton?.setTitle(primaryTitle, for: .highlighted)
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
		rows = [.instructions, .username, .password, .forgotPassword]
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
		case let cell as TextLinkButtonTableViewCell:
			configureForgotPassword(cell)
        default:
            DDLogError("Error: Unidentified tableViewCell type found.")
        }
    }

	/// Configure the instruction cell.
    ///
    func configureInstructionLabel(_ cell: TextLabelTableViewCell) {
		let displayURL = sanitizedSiteAddress(siteAddress: loginFields.siteAddress)
		let text = String.localizedStringWithFormat(WordPressAuthenticator.shared.displayStrings.siteCredentialInstructions, displayURL)
        cell.configureLabel(text: text, style: .body)
    }

	/// Configure the username textfield cell.
	///
	func configureUsernameTextField(_ cell: TextFieldTableViewCell) {
		cell.configureTextFieldStyle(with: .username,
									 and: WordPressAuthenticator.shared.displayStrings.usernamePlaceholder)
		// Save a reference to the textField so it can becomeFirstResponder.
        usernameField = cell.textField
		cell.textField.delegate = self
        SigninEditingState.signinEditingStateActive = true
		cell.onePasswordHandler = { [weak self] in
			guard let self = self else {
				return
			}

			guard let sourceView = self.usernameField else {
				return
			}

			self.view.endEditing(true)

			WordPressAuthenticator.fetchOnePasswordCredentials(self, sourceView: sourceView, loginFields: self.loginFields) { [unowned self] loginFields in
				self.usernameField?.text = loginFields.username
				self.passwordField?.text = loginFields.password
				self.validateForm()
			}
		}
	}

	/// Configure the password textfield cell.
	///
	func configurePasswordTextField(_ cell: TextFieldTableViewCell) {
		cell.configureTextFieldStyle(with: .password,
									 and: WordPressAuthenticator.shared.displayStrings.passwordPlaceholder)
		passwordField = cell.textField
		cell.textField.delegate = self
	}

	/// Configure the forgot password cell.
	///
	func configureForgotPassword(_ cell: TextLinkButtonTableViewCell) {
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
			WordPressAuthenticator.track(.loginForgotPasswordClicked)
		}
	}

	/// Sets up necessary accessibility labels and attributes for the all the UI elements in self.
	///
	func configureForAccessibility() {
		usernameField?.accessibilityLabel =
			NSLocalizedString("Username", comment: "Accessibility label for the username text field in the self-hosted login page.")
		passwordField?.accessibilityLabel =
			NSLocalizedString("Password", comment: "Accessibility label for the password text field in the self-hosted login page.")

		if UIAccessibility.isVoiceOverRunning {
			// Remove the placeholder if VoiceOver is running. VoiceOver speaks the label and the
			// placeholder together. In this case, both labels and placeholders are the same so it's
			// like VoiceOver is reading the same thing twice.
			usernameField?.placeholder = nil
			passwordField?.placeholder = nil
		}
	}

	// MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
		case username
		case password
		case forgotPassword

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
			case .username:
				return TextFieldTableViewCell.reuseIdentifier
			case .password:
				return TextFieldTableViewCell.reuseIdentifier
			case .forgotPassword:
				return TextLinkButtonTableViewCell.reuseIdentifier
			}
        }
    }
}


// MARK: - Instance Methods
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
		validateFormAndLogin()
	}
}
