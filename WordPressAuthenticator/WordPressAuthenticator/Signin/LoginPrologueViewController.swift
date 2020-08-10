import UIKit
import Lottie
import WordPressShared
import WordPressUI
import WordPressKit

class LoginPrologueViewController: LoginViewController {

    private var buttonViewController: NUXButtonViewController?
    var showCancel = false

    // MARK: - Lifecycle Methods

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureButtonVC()
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WordPressAuthenticator.track(.loginPrologueViewed)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)

        self.navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return UIDevice.isPad() ? .all : .portrait
    }

    // MARK: - Segue

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form.")
        let createTitle = NSLocalizedString("Sign up for WordPress.com", comment: "Button title. Tapping begins the process of creating a WordPress.com account.")

        buttonViewController.setupTopButton(title: loginTitle, isPrimary: false, accessibilityIdentifier: "Prologue Log In Button") { [weak self] in
            self?.loginTapped()
        }
        buttonViewController.setupBottomButton(title: createTitle, isPrimary: true, accessibilityIdentifier: "Prologue Signup Button") { [weak self] in
            self?.signupTapped()
        }
        if showCancel {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Button title. Tapping it cancels the login flow.")
            buttonViewController.setupTertiaryButton(title: cancelTitle, isPrimary: false) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
        buttonViewController.backgroundColor = WordPressAuthenticator.shared.style.buttonViewBackgroundColor
    }

    // MARK: - Actions

    private func loginTapped() {
        tracker.set(source: .default)
        
        if WordPressAuthenticator.shared.configuration.showLoginOptions {
            guard let vc = LoginPrologueLoginMethodViewController.instantiate(from: .login) else {
                DDLogError("Failed to navigate to LoginPrologueLoginMethodViewController from LoginPrologueViewController")
                return
            }

            vc.transitioningDelegate = self

            // Continue with WordPress.com button action
            vc.emailTapped = { [weak self] in
                guard let toVC = LoginEmailViewController.instantiate(from: .login) else {
                    DDLogError("Failed to navigate to LoginEmailVC from LoginPrologueVC")
                    return
                }

                self?.navigationController?.pushViewController(toVC, animated: true)
            }

            // Continue with Google button action
            vc.googleTapped = { [weak self] in
                self?.googleTapped()
            }

            // Site address text link button action
            vc.selfHostedTapped = { [weak self] in
                self?.loginToSelfHostedSite()
            }

            // Sign In With Apple (SIWA) button action
            vc.appleTapped = { [weak self] in
                self?.appleTapped()
            }

            vc.modalPresentationStyle = .custom
            navigationController?.present(vc, animated: true, completion: nil)
        } else {
            guard let vc = LoginEmailViewController.instantiate(from: .login) else {
                DDLogError("Failed to navigate to LoginEmailViewController from LoginPrologueViewController")
                return
            }

            navigationController?.pushViewController(vc, animated: true)
        }
    }

    private func signupTapped() {
        tracker.set(source: .default)
        
        // This stat is part of a funnel that provides critical information.
        // Before making ANY modification to this stat please refer to: p4qSXL-35X-p2
        WordPressAuthenticator.track(.signupButtonTapped)

        guard let vc = LoginPrologueSignupMethodViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate to LoginPrologueSignupMethodViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.dismissBlock = dismissBlock
        vc.transitioningDelegate = self
        vc.modalPresentationStyle = .custom

        vc.emailTapped = { [weak self] in
            guard WordPressAuthenticator.shared.configuration.enableUnifiedSignup else {
                self?.presentSignUpEmailView()
                return
            }

            self?.presentUnifiedSignUpView()
        }

        vc.googleTapped = { [weak self] in
            guard let self = self else { return }
            
            guard WordPressAuthenticator.shared.configuration.enableUnifiedGoogle else {
                self.presentGoogleSignupView()
                return
            }

            self.tracker.track(click: .signUpWithGoogle)
            self.presentUnifiedGoogleView()
        }

        vc.appleTapped = { [weak self] in
            self?.appleTapped()
        }

        navigationController?.present(vc, animated: true, completion: nil)
    }

    private func appleTapped() {
        AppleAuthenticator.sharedInstance.delegate = self
        AppleAuthenticator.sharedInstance.showFrom(viewController: self)
    }

    private func googleTapped() {
        guard WordPressAuthenticator.shared.configuration.enableUnifiedGoogle else {
            GoogleAuthenticator.sharedInstance.loginDelegate = self
            GoogleAuthenticator.sharedInstance.showFrom(viewController: self, loginFields: loginFields, for: .login)
            return
        }

        self.tracker.track(click: .signUpWithGoogle)
        presentUnifiedGoogleView()
    }

    /// Determines which view to present for the site address form.
    ///
    private func loginToSelfHostedSite() {
        guard WordPressAuthenticator.shared.configuration.enableUnifiedSiteAddress else {
            presentSelfHostedView()
            return
        }

        presentUnifiedSiteAddressView()
    }

    private func presentSignUpEmailView() {
        guard let toVC = SignupEmailViewController.instantiate(from: .signup) else {
            DDLogError("Failed to navigate to SignupEmailViewController")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    private func presentUnifiedSignUpView() {
        guard let toVC = UnifiedSignUpViewController.instantiate(from: .unifiedSignUp) else {
            DDLogError("Failed to navigate to UnifiedSignUpViewController")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    // Shows the VC that handles both Google login & signup.
    private func presentUnifiedGoogleView() {
        guard let toVC = GoogleAuthViewController.instantiate(from: .googleAuth) else {
            DDLogError("Failed to navigate to GoogleAuthViewController from LoginPrologueVC")
            return
        }
        
        navigationController?.pushViewController(toVC, animated: true)
    }

    // Shows the VC that handles only Google signup.
    private func presentGoogleSignupView() {
        guard let toVC = SignupGoogleViewController.instantiate(from: .signup) else {
            DDLogError("Failed to navigate to SignupGoogleViewController from LoginPrologueVC")
            return
        }

        navigationController?.pushViewController(toVC, animated: true)
    }

    /// Navigates to the unified site address login flow.
    ///
    private func presentUnifiedSiteAddressView() {
        guard let vc = SiteAddressViewController.instantiate(from: .siteAddress) else {
            DDLogError("Failed to navigate from LoginPrologueViewController to SiteAddressViewController")
            return
        }

        navigationController?.pushViewController(vc, animated: true)
    }

    /// Navigates to the old self-hosted login flow.
    ///
    private func presentSelfHostedView() {
        guard let vc = LoginSiteAddressViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from LoginPrologueViewController to LoginSiteAddressViewController")
            return
        }

        vc.loginFields = loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }
    
}

// MARK: - LoginFacadeDelegate

extension LoginPrologueViewController {

    // Used by SIWA when logging with with a passwordless, 2FA account.
    //
    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(false)
        socialNeedsMultifactorCode(forUserID: userID, andNonceInfo: nonceInfo)
    }

}

// MARK: - AppleAuthenticatorDelegate

extension LoginPrologueViewController: AppleAuthenticatorDelegate {

    func showWPComLogin(loginFields: LoginFields) {
        self.loginFields = loginFields
        guard let vc = LoginWPComViewController.instantiate(from: .login) else {
            DDLogError("Failed to navigate from Prologue > Sign in with Apple to LoginWPComViewController")
            return
        }

        vc.loginFields = self.loginFields
        vc.dismissBlock = dismissBlock
        vc.errorToPresent = errorToPresent

        navigationController?.pushViewController(vc, animated: true)
    }

    func showApple2FA(loginFields: LoginFields) {
        self.loginFields = loginFields
        signInAppleAccount()
    }
    
    func authFailedWithError(message: String) {
        displayErrorAlert(message, sourceTag: .loginApple)
    }

}

// MARK: - GoogleAuthenticatorLoginDelegate

extension LoginPrologueViewController: GoogleAuthenticatorLoginDelegate {

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

    func googleLoginFailed(errorTitle: String, errorDescription: String, loginFields: LoginFields) {
        self.loginFields = loginFields

        let socialErrorVC = LoginSocialErrorViewController(title: errorTitle, description: errorDescription)
        let socialErrorNav = LoginNavigationController(rootViewController: socialErrorVC)
        socialErrorVC.delegate = self
        socialErrorVC.loginFields = loginFields
        socialErrorVC.modalPresentationStyle = .fullScreen
        present(socialErrorNav, animated: true)
    }

}
