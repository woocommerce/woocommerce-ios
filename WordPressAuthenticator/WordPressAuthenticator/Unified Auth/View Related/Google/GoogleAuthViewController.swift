import WordPressKit


/// View controller that handles the google authentication flow
///
class GoogleAuthViewController: LoginViewController {

    // MARK: - Properties

    private var hasShownGoogle = false
    @IBOutlet var titleLabel: UILabel?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComAuthWaitingForGoogle
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.text = LocalizedText.waitingForGoogle
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showGoogleScreenIfNeeded()
    }

}

// MARK: - Private Methods

private extension GoogleAuthViewController {

    func showGoogleScreenIfNeeded() {
        guard !hasShownGoogle else {
            return
        }

        // Flag this as a social sign in.
        loginFields.meta.socialService = .google

        GoogleAuthenticator.sharedInstance.delegate = self
        GoogleAuthenticator.sharedInstance.showFrom(viewController: self, loginFields: loginFields)
        hasShownGoogle = true
    }

    func showLoginErrorView(errorTitle: String, errorDescription: String) {
        let socialErrorVC = LoginSocialErrorViewController(title: errorTitle, description: errorDescription)
        let socialErrorNav = LoginNavigationController(rootViewController: socialErrorVC)
        socialErrorVC.delegate = self
        socialErrorVC.loginFields = loginFields
        socialErrorVC.modalPresentationStyle = .fullScreen
        present(socialErrorNav, animated: true)
    }

    func showSignupConfirmationView() {
        guard let vc = GoogleSignupConfirmationViewController.instantiate(from: .googleSignupConfirmation) else {
            DDLogError("Failed to navigate from GoogleAuthViewController to GoogleSignupConfirmationViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    enum LocalizedText {
        static let waitingForGoogle = NSLocalizedString("Waiting for Google to complete…", comment: "Message shown on screen while waiting for Google to finish its signup process.")
        static let signupFailed = NSLocalizedString("Google sign up failed.", comment: "Message shown on screen after the Google sign up process failed.")
    }

}

// MARK: - GoogleAuthenticatorDelegate

extension GoogleAuthViewController: GoogleAuthenticatorDelegate {

    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        syncWPComAndPresentEpilogue(credentials: credentials)
    }

    func googleNeedsMultifactorCode(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let vc = Login2FAViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginViewController to Login2FAViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func googleExistingUserNeedsConnection(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from Google Login to LoginWPComViewController (password VC)")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields, unknownUser: Bool) {
        self.loginFields = loginFields

        // If login failed because there is no existing account, redirect to signup.
        // Otherwise, display the error.

        unknownUser ? showSignupConfirmationView() :
                      showLoginErrorView(errorTitle: errorTitle, errorDescription: errorDescription)
    }
    
    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        showSignupEpilogue(for: credentials)
    }
    
    func googleSignupFailed(error: Error, loginFields: LoginFields) {
        self.loginFields = loginFields
        titleLabel?.textColor = WPStyleGuide.errorRed()
        titleLabel?.text = LocalizedText.signupFailed
        displayError(error as NSError, sourceTag: .wpComSignup)
    }

    func googleAuthCancelled() {
        navigationController?.popViewController(animated: true)
    }

}
