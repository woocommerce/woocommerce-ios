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
        titleLabel?.text = NSLocalizedString("Waiting for Google to complete…", comment: "Message shown on screen while waiting for Google to finish its signup process.")
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

}

// MARK: - GoogleAuthenticatorDelegate

extension GoogleAuthViewController: GoogleAuthenticatorDelegate {

    // MARK: - Login

    func googleFinishedLogin(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        self.loginFields = loginFields
        syncWPComAndPresentEpilogue(credentials: credentials)
    }

    func googleNeedsMultifactorCode(loginFields: LoginFields) {
        self.loginFields = loginFields

        guard let vc = Login2FAViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from GoogleAuthViewController to Login2FAViewController")
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
            DDLogError("Failed to navigate from GoogleAuthViewController to LoginWPComViewController")
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
        let redirectToSignup = unknownUser && WordPressAuthenticator.shared.configuration.enableSignupWithGoogle

        redirectToSignup ? showSignupConfirmationView() :
                           showLoginErrorView(errorTitle: errorTitle, errorDescription: errorDescription)
    }

    func googleAuthCancelled() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Signup

    func googleFinishedSignup(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        // Here for protocol compliance.
    }

    func googleLoggedInInstead(credentials: AuthenticatorCredentials, loginFields: LoginFields) {
        // Here for protocol compliance.
    }

    func googleSignupFailed(error: Error, loginFields: LoginFields) {
        // Here for protocol compliance.
    }

}
