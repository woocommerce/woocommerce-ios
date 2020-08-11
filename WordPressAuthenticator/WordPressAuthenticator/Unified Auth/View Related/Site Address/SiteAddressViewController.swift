import UIKit
import WordPressUI
import WordPressKit


/// SiteAddressViewController: log in by Site Address.
///
final class SiteAddressViewController: LoginViewController {

    /// Private properties.
    ///
    @IBOutlet private weak var tableView: UITableView!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?

    // Required for `NUXKeyboardResponder` but unused here.
    var verticalCenterConstraint: NSLayoutConstraint?

    private var rows = [Row]()
    private weak var siteURLField: UITextField?
    private var errorMessage: String?
    private var shouldChangeVoiceOverFocus: Bool = false

    // MARK: - Actions
    @IBAction func handleContinueButtonTapped(_ sender: NUXButton) {
        validateForm()
    }


    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = WordPressAuthenticator.shared.displayStrings.logInTitle
        styleNavigationBar(forUnified: true)

        // Store default margin, and size table for the view.
        defaultTableViewMargin = tableViewLeadingConstraint?.constant ?? 0
        setTableViewMargins(forWidth: view.frame.width)

        localizePrimaryButton()
        registerTableViewCells()
        loadRows()
        configureSubmitButton(animating: false)
        configureForAccessibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        siteURLField?.text = loginFields.siteAddress
        configureSubmitButton(animating: false)
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

    /// Style individual ViewController status bars.
    ///
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return WordPressAuthenticator.shared.unifiedStyle?.statusBarStyle ?? WordPressAuthenticator.shared.style.statusBarStyle
    }

    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating && canSubmit()
        )
    }

    /// Sets up accessibility elements in the order which they should be read aloud
    /// and quiets repetitive elements.
    ///
    private func configureForAccessibility() {
        view.accessibilityElements = [
            tableView,
            submitButton as Any
        ]

        UIAccessibility.post(notification: .screenChanged, argument: siteURLField)

        if UIAccessibility.isVoiceOverRunning {
            // Remove the placeholder if VoiceOver is running, because it speaks the label
            // and the placeholder together. Since the placeholder matches the label, it's
            // like VoiceOver is reading the same thing twice.
            siteURLField?.placeholder = nil
        }
    }

    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        siteURLField?.isEnabled = !loading

        configureSubmitButton(animating: loading)
        navigationItem.hidesBackButton = loading
    }

    /// Configure the view for an editing state. Should only be called from viewWillAppear
    /// as this method skips animating any change in height.
    ///
    @objc func configureViewForEditingIfNeeded() {
        // Check the helper to determine whether an editing state should be assumed.
        adjustViewForKeyboard(SigninEditingState.signinEditingStateActive)
        if SigninEditingState.signinEditingStateActive {
            siteURLField?.becomeFirstResponder()
        }
    }

    /// Reload the tableview and show errors, if any.
    ///
    override func displayError(message: String, moveVoiceOverFocus: Bool = false) {
        if errorMessage != message {
            errorMessage = message
            shouldChangeVoiceOverFocus = moveVoiceOverFocus
            loadRows()
            tableView.reloadData()
        }
    }
}


// MARK: - UITableViewDataSource
extension SiteAddressViewController: UITableViewDataSource {
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
extension SiteAddressViewController: UITableViewDelegate {
    /// After the site address textfield cell is done displaying, remove the textfield reference.
    ///
    func tableView(_ tableView: UITableView, didEndDisplaying cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let row = rows[safe: indexPath.row] else {
            return
        }

        if row == .siteAddress {
            siteURLField = nil
        }
    }
}


// MARK: - Keyboard Notifications
extension SiteAddressViewController: NUXKeyboardResponder {
    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }

    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}


// MARK: - TextField Delegate conformance
extension SiteAddressViewController: UITextFieldDelegate {

    /// Handle the keyboard `return` button action.
    ///
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if canSubmit() {
            validateForm()
            return true
        }

        return false
    }
}


// MARK: - Private methods
private extension SiteAddressViewController {

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
        rows = [.instructions, .siteAddress]

        if let errorText = errorMessage, !errorText.isEmpty {
            rows.append(.errorMessage)
        }

        if WordPressAuthenticator.shared.configuration.displayHintButtons {
            rows.append(.findSiteAddress)
        }
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
        cell.configureLabel(text: WordPressAuthenticator.shared.displayStrings.siteLoginInstructions, style: .body)
    }

    /// Configure the textfield cell.
    ///
    func configureTextField(_ cell: TextFieldTableViewCell) {
        cell.configureTextFieldStyle(with: .url,
                                     and: WordPressAuthenticator.shared.displayStrings.siteAddressPlaceholder)

        // Save a reference to the first textField so it can becomeFirstResponder.
        siteURLField = cell.textField
        cell.textField.delegate = self
        cell.onChangeSelectionHandler = { [weak self] textfield in
            self?.loginFields.siteAddress = textfield.nonNilTrimmedText()
            self?.configureSubmitButton(animating: false)
        }

        SigninEditingState.signinEditingStateActive = true
    }

    /// Configure the "Find your site address" cell.
    ///
    func configureTextLinkButton(_ cell: TextLinkButtonTableViewCell) {
        cell.configureButton(text: WordPressAuthenticator.shared.displayStrings.findSiteButtonTitle)
        cell.actionHandler = { [weak self] in
            guard let self = self else {
                return
            }

            let alert = FancyAlertViewController.siteAddressHelpController(loginFields: self.loginFields, sourceTag: self.sourceTag)
            alert.modalPresentationStyle = .custom
            alert.transitioningDelegate = self
            self.present(alert, animated: true, completion: nil)
            // TODO: - Tracks.
            // WordPressAuthenticator.track(.loginURLHelpScreenViewed)
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

    // MARK: - Private Constants

    /// Rows listed in the order they were created.
    ///
    enum Row {
        case instructions
        case siteAddress
        case findSiteAddress
        case errorMessage

        var reuseIdentifier: String {
            switch self {
            case .instructions:
                return TextLabelTableViewCell.reuseIdentifier
            case .siteAddress:
                return TextFieldTableViewCell.reuseIdentifier
            case .findSiteAddress:
                return TextLinkButtonTableViewCell.reuseIdentifier
            case .errorMessage:
                return TextLabelTableViewCell.reuseIdentifier
            }
        }
    }
}


// MARK: - Instance Methods
extension SiteAddressViewController {

    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        view.endEditing(true)
        displayError(message: "")

        // We need to to this here because before this point we need the URL to be pre-validated
        // exactly as the user inputs it, and after this point we need the URL to be the base site URL.
        // This isn't really great, but it's the only sane solution I could come up with given the current
        // architecture of this pod.
        loginFields.siteAddress = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)

        configureViewLoading(true)

        let facade = WordPressXMLRPCAPIFacade()
        facade.guessXMLRPCURL(forSite: loginFields.siteAddress, success: { [weak self] (url) in
            // Success! We now know that we have a valid XML-RPC endpoint.
            // At this point, we do NOT know if this is a WP.com site or a self-hosted site.
            if let url = url {
                self?.loginFields.meta.xmlrpcURL = url as NSURL
            }
            // Let's try to grab site info in preparation for the next screen.
            self?.fetchSiteInfo()

            }, failure: { [weak self] (error) in
                guard let error = error, let self = self else {
                    return
                }

                DDLogError(error.localizedDescription)
                // TODO: - Tracks.
                // WordPressAuthenticator.track(.loginFailedToGuessXMLRPC, error: error)
                // WordPressAuthenticator.track(.loginFailed, error: error)
                self.configureViewLoading(false)

                let err = self.originalErrorOrError(error: error as NSError)

                if let xmlrpcValidatorError = err as? WordPressOrgXMLRPCValidatorError {
                    self.displayError(message: xmlrpcValidatorError.localizedDescription, moveVoiceOverFocus: true)

                } else if (err.domain == NSURLErrorDomain && err.code == NSURLErrorCannotFindHost) ||
                    (err.domain == NSURLErrorDomain && err.code == NSURLErrorNetworkConnectionLost) {
                    // NSURLErrorNetworkConnectionLost can be returned when an invalid URL is entered.
                    let msg = NSLocalizedString(
                        "The site at this address is not a WordPress site. For us to connect to it, the site must use WordPress.",
                        comment: "Error message shown a URL does not point to an existing site.")
                    self.displayError(message: msg, moveVoiceOverFocus: true)

                } else {
                    self.displayError(error as NSError, sourceTag: self.sourceTag)
                }
        })
    }

    @objc func fetchSiteInfo() {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)
        let service = WordPressComBlogService()
        let successBlock: (WordPressComSiteInfo) -> Void = { [weak self] siteInfo in
            guard let self = self else {
                return
            }
            self.configureViewLoading(false)
            if siteInfo.isWPCom && WordPressAuthenticator.shared.delegate?.allowWPComLogin == false {
                // Hey, you have to log out of your existing WP.com account before logging into another one.
                self.promptUserToLogoutBeforeConnectingWPComSite()
                return
            }
            self.presentNextControllerIfPossible(siteInfo: siteInfo)
        }
        service.fetchUnauthenticatedSiteInfoForAddress(for: baseSiteUrl, success: successBlock, failure: { [weak self] error in
            self?.configureViewLoading(false)
            guard let self = self else {
                return
            }
            self.presentNextControllerIfPossible(siteInfo: nil)
        })
    }

    func presentNextControllerIfPossible(siteInfo: WordPressComSiteInfo?) {
        WordPressAuthenticator.shared.delegate?.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { (error, isSelfHosted) in
            guard let originalError = error else {

                if isSelfHosted {
                    self.showSelfHostedUsernamePassword()
                    return
                }

                self.showWPUsernamePassword()
                return
            }

            self.displayError(message: originalError.localizedDescription)
        })
    }

    @objc func originalErrorOrError(error: NSError) -> NSError {
        guard let err = error.userInfo[XMLRPCOriginalErrorKey] as? NSError else {
            return error
        }

        return err
    }

    /// Here we will continue with the self-hosted flow.
    ///
    @objc func showSelfHostedUsernamePassword() {
        configureViewLoading(false)
        guard let vc = SiteCredentialsViewController.instantiate(from: .siteAddress) else {
            DDLogError("Failed to navigate from SiteAddressViewController to SiteCredentialsViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Break away from the self-hosted flow.
    /// Display a username / password login screen for WP.com sites.
    ///
    @objc func showWPUsernamePassword() {
        configureViewLoading(false)

        guard let vc = LoginUsernamePasswordViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginSiteAddressViewController to LoginUsernamePasswordViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }
    
    /// Whether the form can be submitted.
    ///
    @objc func canSubmit() -> Bool {
        return loginFields.validateSiteForSignin()
    }

    @objc private func promptUserToLogoutBeforeConnectingWPComSite() {
        let acceptActionTitle = NSLocalizedString("OK", comment: "Alert dismissal title")
        let message = NSLocalizedString("Please log out before connecting to a different wordpress.com site", comment: "Message for alert to prompt user to logout before connecting to a different wordpress.com site.")
        let alertController = UIAlertController(title: nil, message: message, preferredStyle: .alert)
        alertController.addDefaultActionWithTitle(acceptActionTitle)
        present(alertController, animated: true)
    }
}
