import UIKit
import Lottie
import WordPressShared
import WordPressUI
import GoogleSignIn
import WordPressKit

class LoginPrologueViewController: LoginViewController {

    private var buttonViewController: NUXButtonViewController?
    var showCancel = false

    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

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
        else if let vc = segue.destination as? LoginPrologueSignupMethodViewController {
            vc.transitioningDelegate = self
            vc.emailTapped = { [weak self] in
                self?.performSegue(withIdentifier: .showSigninV2, sender: self)
            }
            vc.googleTapped = { [weak self] in
                self?.performSegue(withIdentifier: .showGoogle, sender: self)
            }
            vc.appleTapped = { [weak self] in
                self?.appleTapped()
            }
            vc.modalPresentationStyle = .custom
        }

        else if let vc = segue.destination as? LoginPrologueLoginMethodViewController {
            vc.transitioningDelegate = self
            
            vc.emailTapped = { [weak self] in
                guard let vc = LoginEmailViewController.instantiate(from: .login) else {
                    DDLogError("Failed to navigate to LoginEmailViewController")
                    return
                }

                self?.navigationController?.pushViewController(vc, animated: true)
            }
            vc.googleTapped = { [weak self] in
                self?.googleLoginTapped(withDelegate: self)
            }
            vc.selfHostedTapped = { [weak self] in
                self?.loginToSelfHostedSite()
            }
            vc.appleTapped = { [weak self] in
                self?.appleTapped()
            }

            vc.modalPresentationStyle = .custom
        }
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Log In", comment: "Button title.  Tapping takes the user to the login form.")
        let createTitle = NSLocalizedString("Sign up for WordPress.com", comment: "Button title. Tapping begins the process of creating a WordPress.com account.")

        buttonViewController.setupTopButton(title: loginTitle, isPrimary: true, accessibilityIdentifier: "Prologue Log In Button") { [weak self] in
            self?.loginTapped()
        }
        buttonViewController.setupBottomButton(title: createTitle, isPrimary: false, accessibilityIdentifier: "Prologue Signup Button") { [weak self] in
            self?.signupTapped()
        }
        if showCancel {
            let cancelTitle = NSLocalizedString("Cancel", comment: "Button title. Tapping it cancels the login flow.")
            buttonViewController.setupTertiaryButton(title: cancelTitle, isPrimary: false) { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            }
        }
        buttonViewController.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }

    // MARK: - Actions

    private func loginTapped() {
        if WordPressAuthenticator.shared.configuration.showLoginOptions {
            performSegue(withIdentifier: .showLoginMethod, sender: self)
        } else {
            performSegue(withIdentifier: .showEmailLogin, sender: self)
        }
    }

    private func signupTapped() {
        // This stat is part of a funnel that provides critical information.  Before
        // making ANY modification to this stat please refer to: p4qSXL-35X-p2
        WordPressAuthenticator.track(.signupButtonTapped)
        performSegue(withIdentifier: .showSignupMethod, sender: self)
    }

    private func appleTapped() {
        AppleAuthenticator.sharedInstance.delegate = self
        AppleAuthenticator.sharedInstance.showFrom(viewController: self)
    }

}

// MARK: - AppleAuthenticatorDelegate

extension LoginPrologueViewController: AppleAuthenticatorDelegate {

    func showWPComLogin(loginFields: LoginFields) {
        self.loginFields = loginFields
         performSegue(withIdentifier: .showWPComLogin, sender: self)
    }

    func showApple2FA(loginFields: LoginFields) {
        self.loginFields = loginFields
        signInAppleAccount()
    }
    
    func authFailedWithError(message: String) {
        displayErrorAlert(message, sourceTag: .loginApple)
    }

}

// MARK: - Social LoginFacadeDelegate Methods

extension LoginPrologueViewController {
    
    override open func displayRemoteError(_ error: Error) {
        configureViewLoading(false)
        displayRemoteErrorForGoogle(error)
    }
    
    func finishedLogin(withGoogleIDToken googleIDToken: String, authToken: String) {
        googleFinishedLogin(withGoogleIDToken: googleIDToken, authToken: authToken)
    }

    func existingUserNeedsConnection(_ email: String) {
        configureViewLoading(false)
        googleExistingUserNeedsConnection(email)
    }

    func needsMultifactorCode(forUserID userID: Int, andNonceInfo nonceInfo: SocialLogin2FANonceInfo) {
        configureViewLoading(false)
        socialNeedsMultifactorCode(forUserID: userID, andNonceInfo: nonceInfo)
    }

}

// MARK: - GIDSignInDelegate

extension LoginPrologueViewController: GIDSignInDelegate {
    open func sign(_ signIn: GIDSignIn?, didSignInFor user: GIDGoogleUser?, withError error: Error?) {
        signInGoogleAccount(signIn, didSignInFor: user, withError: error)
    }
}
