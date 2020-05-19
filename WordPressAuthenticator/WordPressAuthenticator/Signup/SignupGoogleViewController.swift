import GoogleSignIn
import SVProgressHUD
import WordPressShared

/// View controller that handles the google signup code
class SignupGoogleViewController: LoginViewController {

    // MARK: - Properties

    private var hasShownGoogle = false
    @IBOutlet var titleLabel: UILabel?

    override var sourceTag: WordPressSupportSourceTag {
        get {
            return .wpComSignupWaitingForGoogle
        }
    }

    // MARK: - View

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel?.text = NSLocalizedString("Waiting for Google to complete…", comment: "Message shown on screen while waiting for Google to finish its signup process.")
        WordPressAuthenticator.track(.createAccountInitiated, properties: ["source": "google"])
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        showGoogleScreenIfNeeded()
    }

    private func showGoogleScreenIfNeeded() {
        guard !hasShownGoogle else {
            return
        }

        showGoogleScreen()
        hasShownGoogle = true
    }

    private func showGoogleScreen() {
        GIDSignIn.sharedInstance().disconnect()

        // Flag this as a social sign in.
        loginFields.meta.socialService = .google

        // Configure all the things and sign in.
        guard let googleSSO = GIDSignIn.sharedInstance() else {
            DDLogError("Something is very, very, very off. Well done, Google.")
            return
        }

        googleSSO.delegate = self
        googleSSO.presentingViewController = self
        googleSSO.clientID = WordPressAuthenticator.shared.configuration.googleLoginClientId
        googleSSO.serverClientID = WordPressAuthenticator.shared.configuration.googleLoginServerClientId

        googleSSO.signIn()
    }
}


// MARK: - GIDSignInDelegate

extension SignupGoogleViewController: GIDSignInDelegate {

    func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        GIDSignIn.sharedInstance().disconnect()

        guard let googleUser = user, let googleToken = googleUser.authentication.idToken, let googleEmail = googleUser.profile.email else {
            WordPressAuthenticator.track(.signupSocialButtonFailure, error: error)
            self.navigationController?.popViewController(animated: true)
            return
        }

        updateLoginFields(googleUser: googleUser, googleToken: googleToken, googleEmail: googleEmail)
        createWordPressComUser(googleUser: googleUser, googleToken: googleToken, googleEmail: googleEmail)
    }
}


// MARK: - WordPress.com Account Creation Methods
//
private extension SignupGoogleViewController {

    /// Creates a WordPress.com account with the associated GoogleUser + GoogleToken + GoogleEmail.
    ///
    func createWordPressComUser(googleUser: GIDGoogleUser, googleToken: String, googleEmail: String) {
        SVProgressHUD.show(withStatus: NSLocalizedString("Completing Signup", comment: "Shown while the app waits for the site creation process to complete."))

        let service = SignupService()

        service.createWPComUserWithGoogle(token: googleToken, success: { [weak self] accountCreated, wpcomUsername, wpcomToken in

            let wpcom = WordPressComCredentials(authToken: wpcomToken, isJetpackLogin: false, multifactor: false, siteURL: self?.loginFields.siteAddress ?? "")
            let credentials = AuthenticatorCredentials(wpcom: wpcom)

            /// New Account: We'll signal the host app right away!
            ///
            if accountCreated {
                SVProgressHUD.dismiss()
                self?.authenticationDelegate.createdWordPressComAccount(username: wpcomUsername, authToken: wpcomToken)
                self?.socialSignupWasSuccessful(with: credentials)
                return
            }

            /// Existing Account: We'll synchronize all the things before proceeding to the next screen.
            ///
            self?.authenticationDelegate.sync(credentials: credentials) {
                SVProgressHUD.dismiss()
                self?.wasLoggedInInstead(with: credentials)
            }

        }, failure: { [weak self] error in
            SVProgressHUD.dismiss()
            self?.socialSignupDidFail(with: error)
        })
    }


    /// Social Signup Successful: Analytics + Pushing the Signup Epilogue.
    ///
    func socialSignupWasSuccessful(with credentials: AuthenticatorCredentials) {
        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        WordPressAuthenticator.track(.createdAccount, properties: ["source": "google"])
        WordPressAuthenticator.track(.signedIn, properties: ["source": "google"])
        WordPressAuthenticator.track(.signupSocialSuccess, properties: ["source": "google"])

        showSignupEpilogue(for: credentials)
    }

    /// Social Login Successful: Analytics + Pushing the Login Epilogue.
    ///
    func wasLoggedInInstead(with credentials: AuthenticatorCredentials) {
        WordPressAuthenticator.track(.signedIn, properties: ["source": "google"])
        WordPressAuthenticator.track(.signupSocialToLogin, properties: ["source": "google"])
        WordPressAuthenticator.track(.loginSocialSuccess, properties: ["source": "google"])

        showLoginEpilogue(for: credentials)
    }

    /// Social Signup Failure: Analytics + UI Updates
    ///
    func socialSignupDidFail(with error: Error) {

        let properties = [ "source": "google",
                           "error": error.localizedDescription
        ]

        WordPressAuthenticator.track(.signupSocialFailure, properties: properties)

        if (error as? SignupError) == .unknown {
            navigationController?.popViewController(animated: true)
            return
        }

        titleLabel?.textColor = WPStyleGuide.errorRed()
        titleLabel?.text = NSLocalizedString("Google sign up failed.", comment: "Message shown on screen after the Google sign up process failed.")
        displayError(error as NSError, sourceTag: .wpComSignup)
    }
}
