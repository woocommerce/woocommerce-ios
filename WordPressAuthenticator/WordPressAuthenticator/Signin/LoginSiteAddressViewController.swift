import UIKit
import WordPressShared
import WordPressKit
import WordPressUI


class LoginSiteAddressViewController: LoginViewController, NUXKeyboardResponder {
    @IBOutlet weak var siteURLField: WPWalkthroughTextField!
    @IBOutlet var siteAddressHelpButton: UIButton!
    @IBOutlet var bottomContentConstraint: NSLayoutConstraint?
    @IBOutlet var verticalCenterConstraint: NSLayoutConstraint?
    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .loginSiteAddress
        }
    }


    override var loginFields: LoginFields {
        didSet {
            // Clear the site url and site info (if any) from LoginFields
            loginFields.siteAddress = ""
            loginFields.meta.siteInfo = nil
        }
    }
    
    // MARK: - URL Validation
    
    private lazy var urlErrorDebouncer = Debouncer(delay: 2) { [weak self] in
        let errorMessage = NSLocalizedString("Enter a valid URL eg. example.com.", comment: "Error message shown when a URL is invalid.")
        
        self?.displayError(message: errorMessage)
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        localizeControls()
    }


    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // Update special case login fields.
        loginFields.meta.userIsDotCom = false

        configureTextFields()
        configureSubmitButton(animating: false)
        configureViewForEditingIfNeeded()

        navigationController?.setNavigationBarHidden(false, animated: false)
    }


    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        registerForKeyboardEvents(keyboardWillShowAction: #selector(handleKeyboardWillShow(_:)),
                                  keyboardWillHideAction: #selector(handleKeyboardWillHide(_:)))
        WordPressAuthenticator.track(.loginURLFormViewed)
    }


    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterForKeyboardEvents()
    }

    // MARK: Setup and Configuration


    /// Assigns localized strings to various UIControl defined in the storyboard.
    ///
    @objc func localizeControls() {
        instructionLabel?.text = WordPressAuthenticator.shared.displayStrings.siteLoginInstructions

        siteURLField.placeholder = NSLocalizedString("example.com", comment: "Site Address placeholder")

        let submitButtonTitle = NSLocalizedString("Next", comment: "Title of a button. The text should be capitalized.").localizedCapitalized
        submitButton?.setTitle(submitButtonTitle, for: .normal)
        submitButton?.setTitle(submitButtonTitle, for: .highlighted)
        submitButton?.accessibilityIdentifier = "Site Address Next Button"

        let siteAddressHelpTitle = NSLocalizedString("Need help finding your site address?", comment: "A button title.")
        siteAddressHelpButton.setTitle(siteAddressHelpTitle, for: .normal)
        siteAddressHelpButton.setTitle(siteAddressHelpTitle, for: .highlighted)
        siteAddressHelpButton.titleLabel?.numberOfLines = 0
    }


    /// Configures the content of the text fields based on what is saved in `loginFields`.
    ///
    @objc func configureTextFields() {
        siteURLField.contentInsets = WPStyleGuide.edgeInsetForLoginTextFields()
        siteURLField.text = loginFields.siteAddress
    }


    /// Configures the appearance and state of the submit button.
    ///
    override func configureSubmitButton(animating: Bool) {
        submitButton?.showActivityIndicator(animating)

        submitButton?.isEnabled = (
            !animating && canSubmit()
        )
    }


    /// Sets the view's state to loading or not loading.
    ///
    /// - Parameter loading: True if the form should be configured to a "loading" state.
    ///
    override func configureViewLoading(_ loading: Bool) {
        siteURLField.isEnabled = !loading

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
            siteURLField.becomeFirstResponder()
        }
    }


    // MARK: - Instance Methods


    /// Validates what is entered in the various form fields and, if valid,
    /// proceeds with the submit action.
    ///
    @objc func validateForm() {
        view.endEditing(true)
        displayError(message: "")
        
        let siteAddress = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)

        configureViewLoading(true)

        let facade = WordPressXMLRPCAPIFacade()
        facade.guessXMLRPCURL(forSite: siteAddress, success: { [weak self] (url) in
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
            WordPressAuthenticator.track(.loginFailedToGuessXMLRPC, error: error)
            WordPressAuthenticator.track(.loginFailed, error: error)
            self.configureViewLoading(false)

            let err = self.originalErrorOrError(error: error as NSError)

            if self.errorDiscoveringJetpackSite(error: err) {
                self.displayError(error as NSError, sourceTag: .jetpackLogin)

            } else if let xmlrpcValidatorError = err as? WordPressOrgXMLRPCValidatorError {
                self.displayError(message: xmlrpcValidatorError.localizedDescription)

            } else if (err.domain == NSURLErrorDomain && err.code == NSURLErrorCannotFindHost) ||
                (err.domain == NSURLErrorDomain && err.code == NSURLErrorNetworkConnectionLost) {
                // NSURLErrorNetworkConnectionLost can be returned when an invalid URL is entered.
                let msg = NSLocalizedString(
                    "The site at this address is not a WordPress site. For us to connect to it, the site must use WordPress.",
                    comment: "Error message shown a URL does not point to an existing site.")
                self.displayError(message: msg)

            } else {
                self.displayError(error as NSError, sourceTag: self.sourceTag)
            }
        })
    }


    @objc func fetchSiteInfo() {
        let baseSiteUrl = WordPressAuthenticator.baseSiteURL(string: loginFields.siteAddress)
        let successBlock: (WordPressComSiteInfo) -> Void = { [weak self] siteInfo in
            self?.loginFields.meta.siteInfo = siteInfo
            if WordPressAuthenticator.shared.delegate?.allowWPComLogin == false {
                // Hey, you have to log out of your existing WP.com account before logging into another one.
                self?.promptUserToLogoutBeforeConnectingWPComSite()
                self?.configureViewLoading(false)
            } else {
                self?.configureViewLoading(false)
                guard let self = self else {
                    return
                }
                self.presentNextControllerIfPossible(siteInfo: siteInfo)
            }
        }

        // Is this a WP.com site address?
        if let siteAddress = baseSiteUrl.components(separatedBy: "://").last {
            let service = WordPressComBlogService()
            // Yes. Then let's attempt to grab the site info.
            service.fetchSiteInfo(for: siteAddress, success: successBlock, failure: { [weak self] (error) in
                // If fetchSiteInfo failed because the site is private (errorCode == .authorizationRequired),
                // then we try to fetch the site info with a call to the `connect/site-info` endpoint.
                // If this call succeeds, we check if login is allowed.
                let originalError = error as NSError
                let errorCode = WordPressComRestApiError(rawValue: originalError.code)
                if errorCode == .authorizationRequired {
                    service.fetchUnauthenticatedSiteInfoForAddress(for: baseSiteUrl, success: successBlock, failure: { error in
                        // The un-authed site info request failed.
                        self?.configureViewLoading(false)
                        guard let self = self else {
                            return
                        }

                        self.presentNextControllerIfPossible(siteInfo: nil)
                    })
                } else {
                    // Failed to get the site info.
                    self?.configureViewLoading(false)
                    guard let self = self else {
                        return
                    }

                    self.presentNextControllerIfPossible(siteInfo: nil)
                }
            })
        } else {
            // Not a WP.com site. Let's make an un-authenticated site info request.
            let service = WordPressComBlogService()
            service.fetchUnauthenticatedSiteInfoForAddress(for: baseSiteUrl, success: successBlock, failure: { [weak self] error in
                self?.configureViewLoading(false)
                guard let self = self else {
                    return
                }

                self.presentNextControllerIfPossible(siteInfo: nil)
            })
        }
    }

    func presentNextControllerIfPossible(siteInfo: WordPressComSiteInfo?) {
        WordPressAuthenticator.shared.delegate?.shouldPresentUsernamePasswordController(for: siteInfo, onCompletion: { (error, isSelfHosted) in
            guard let originalError = error else {
                if isSelfHosted {
                    self.showSelfHostedUsernamePassword()
                } else {
                    self.showWPUsernamePassword()
                }

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


    @objc func errorDiscoveringJetpackSite(error: NSError) -> Bool {
        if let _ = error.userInfo[WordPressOrgXMLRPCValidator.UserInfoHasJetpackKey] {
            return true
        }

        return false
    }

    /// Here we will continue with the self-hosted flow.
    ///
    @objc func showSelfHostedUsernamePassword() {
        configureViewLoading(false)
        performSegue(withIdentifier: .showURLUsernamePassword, sender: self)
    }

    /// Break away from the self-hosted flow.
    /// Display a username / password login screen for WP.com sites.
    @objc func showWPUsernamePassword() {
        configureViewLoading(false)
        performSegue(withIdentifier: .showWPUsernamePassword, sender: self)
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
    
    // MARK: - URL Validation
    
    /// Does a local / quick Site Adrress validation and refreshes the UI with an error
    /// if necessary.
    ///
    /// - Returns: `true` if the Site Address contains a valid URL.  `false` otherwise.
    ///
    private func refreshSiteAddressError(immediate: Bool) {
        let showError = !loginFields.siteAddress.isEmpty && !loginFields.validateSiteForSignin()
        
        if showError {
            urlErrorDebouncer.call(immediate: immediate)
        } else {
            urlErrorDebouncer.cancel()
            displayError(message: "")
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

    @IBAction func handleSiteAddressHelpButtonTapped(_ sender: UIButton) {
        let alert = FancyAlertViewController.siteAddressHelpController(loginFields: loginFields, sourceTag: sourceTag)
        alert.modalPresentationStyle = .custom
        alert.transitioningDelegate = self
        present(alert, animated: true, completion: nil)
        WordPressAuthenticator.track(.loginURLHelpScreenViewed)
    }

    @IBAction func handleTextFieldDidChange(_ sender: UITextField) {
        displayError(message: "")
        loginFields.siteAddress = siteURLField.nonNilTrimmedText()
        configureSubmitButton(animating: false)
        refreshSiteAddressError(immediate: false)
    }

    @IBAction func handleEditingDidEnd(_ sender: UITextField) {
        refreshSiteAddressError(immediate: true)
    }
    
    // MARK: - Keyboard Notifications


    @objc func handleKeyboardWillShow(_ notification: Foundation.Notification) {
        keyboardWillShow(notification)
    }


    @objc func handleKeyboardWillHide(_ notification: Foundation.Notification) {
        keyboardWillHide(notification)
    }
}
