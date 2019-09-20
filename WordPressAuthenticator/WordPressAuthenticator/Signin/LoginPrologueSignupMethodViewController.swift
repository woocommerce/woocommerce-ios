import SafariServices
import WordPressUI
import WordPressShared


class LoginPrologueSignupMethodViewController: NUXViewController {
    /// Buttons at bottom of screen
    private var buttonViewController: NUXButtonViewController?

    /// Gesture recognizer for taps on the dialog if no buttons are present
    fileprivate var dismissGestureRecognizer: UITapGestureRecognizer?

    open var emailTapped: (() -> Void)?
    open var googleTapped: (() -> Void)?
    open var appleTapped: (() -> Void)?

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtonVC()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }

        let loginTitle = NSLocalizedString("Sign up with Email", comment: "Button title. Tapping begins our normal sign up process.")
        let createTitle = NSLocalizedString("Sign up with Google", comment: "Button title. Tapping begins sign up using Google.")
        buttonViewController.setupTopButton(title: loginTitle, isPrimary: false, accessibilityIdentifier: "Sign up with Email Button") { [weak self] in
            defer {
                WordPressAuthenticator.track(.signupEmailButtonTapped)
            }
            self?.dismiss(animated: true)
            self?.emailTapped?()
        }

        buttonViewController.setupBottomButton(title: createTitle, isPrimary: false, accessibilityIdentifier: "Sign up with Google Button") { [weak self] in
            defer {
                WordPressAuthenticator.track(.signupSocialButtonTapped, properties: ["source": "google"])
            }

            self?.dismiss(animated: true)
            self?.googleTapped?()
        }
        let termsButton = WPStyleGuide.termsButton()
        termsButton.on(.touchUpInside) { [weak self] button in
            defer {
                WordPressAuthenticator.track(.signupTermsButtonTapped)
            }
            guard let url = URL(string: WordPressAuthenticator.shared.configuration.wpcomTermsOfServiceURL) else {
                return
            }

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            self?.present(safariViewController, animated: true, completion: nil)
        }
        buttonViewController.stackView?.insertArrangedSubview(termsButton, at: 0)

        if WordPressAuthenticator.shared.configuration.enableSignInWithApple {
            if #available(iOS 13.0, *) {
                let appleButton = WPStyleGuide.appleLoginButton()
                appleButton.addTarget(self, action: #selector(handleAppleButtonTapped), for: .touchDown)
                buttonViewController.stackView?.insertArrangedSubview(appleButton, at: 3)
            }
        }

        buttonViewController.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
    }

    @IBAction func dismissTapped() {
        WordPressAuthenticator.track(.signupCancelled)
        dismiss(animated: true)
    }

    @objc func handleAppleButtonTapped() {
        WordPressAuthenticator.track(.signupSocialButtonTapped, properties: ["source": "apple"])
        
        dismiss(animated: true)
        appleTapped?()
    }
}
