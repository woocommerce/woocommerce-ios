import WordPressUI
import WordPressShared

class LoginPrologueLoginMethodViewController: NUXViewController {
    /// Buttons at bottom of screen
    private var buttonViewController: NUXButtonViewController?

    /// Gesture recognizer for taps on the dialog if no buttons are present
    fileprivate var dismissGestureRecognizer: UITapGestureRecognizer?

    open var emailTapped: (() -> Void)?
    open var googleTapped: (() -> Void)?
    open var selfHostedTapped: (() -> Void)?
    open var appleTapped: (() -> Void)?

    private var tracker: AuthenticatorAnalyticsTracker {
        AuthenticatorAnalyticsTracker.shared
    }
    
    /// The big transparent (dismiss) button behind the buttons
    @IBOutlet private weak var dismissButton: UIButton!

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        super.prepare(for: segue, sender: sender)

        if let vc = segue.destination as? NUXButtonViewController {
            buttonViewController = vc
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        configureButtonVC()
        configureForAccessibility()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(true, animated: false)
    }

    private func configureButtonVC() {
        guard let buttonViewController = buttonViewController else {
            return
        }
        
        let wordpressTitle = NSLocalizedString("Continue with WordPress.com", comment: "Button title. Tapping begins our normal log in process.")
        buttonViewController.setupTopButton(title: wordpressTitle, isPrimary: false, accessibilityIdentifier: "Log in with Email Button") { [weak self] in
            self?.dismiss(animated: true)
            self?.emailTapped?()
        }
        
        buttonViewController.setupButtomButtonFor(socialService: .google, onTap: handleGoogleButtonTapped)

        if !LoginFields().restrictToWPCom && selfHostedTapped != nil {
            let selfHostedLoginButton = WPStyleGuide.selfHostedLoginButton(alignment: .center)
            buttonViewController.stackView?.addArrangedSubview(selfHostedLoginButton)
            selfHostedLoginButton.addTarget(self, action: #selector(handleSelfHostedButtonTapped), for: .touchUpInside)
        }

        if WordPressAuthenticator.shared.configuration.enableSignInWithApple {
            if #available(iOS 13.0, *) {
                buttonViewController.setupTertiaryButtonFor(socialService: .apple, onTap: handleAppleButtonTapped)
            }
        }

        buttonViewController.backgroundColor = WordPressAuthenticator.shared.style.buttonViewBackgroundColor
    }

    @IBAction func dismissTapped() {
        dismiss(animated: true)
    }

    @IBAction func handleSelfHostedButtonTapped(_ sender: UIButton) {
        dismiss(animated: true)
        selfHostedTapped?()
    }

    @objc func handleAppleButtonTapped() {
        WordPressAuthenticator.track(.loginSocialButtonClick, properties: ["source": "apple"])
        
        dismiss(animated: true)
        appleTapped?()
    }

    @objc func handleGoogleButtonTapped() {
        tracker.track(click: .loginWithGoogle)
        
        dismiss(animated: true)
        googleTapped?()
    }
    
    // MARK: - Accessibility

    private func configureForAccessibility() {
        dismissButton.accessibilityLabel = NSLocalizedString("Dismiss", comment: "Accessibility label for the transparent space above the login dialog which acts as a button to dismiss the dialog.")

        // Ensure that the first button (in buttonViewController) is automatically selected by
        // VoiceOver instead of the dismiss button.
        if buttonViewController?.isViewLoaded == true, let buttonsView = buttonViewController?.view {
            view.accessibilityElements = [
                buttonsView,
                dismissButton
            ]
        }
    }

    override func accessibilityPerformEscape() -> Bool {
        dismiss(animated: true)
        return true
    }
}
