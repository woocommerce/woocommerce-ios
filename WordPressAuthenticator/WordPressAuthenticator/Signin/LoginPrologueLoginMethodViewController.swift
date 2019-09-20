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
        
        let wordpressTitle = NSLocalizedString("Continue with WordPress.com", comment: "Button title. Tapping begins our normal log in process.")
        buttonViewController.setupTopButton(title: wordpressTitle, isPrimary: false, accessibilityIdentifier: "Log in with Email Button") { [weak self] in
            self?.dismiss(animated: true)
            self?.emailTapped?()
        }

        let googleTitle = NSLocalizedString("Continue with Google", comment: "Button title. Tapping begins log in using Google.")
        buttonViewController.setupBottomButton(title: googleTitle, isPrimary: false, accessibilityIdentifier: "Log in with Google Button") { [weak self] in
            defer {
                WordPressAuthenticator.track(.loginSocialButtonClick, properties: ["source": "google"])
            }

            self?.dismiss(animated: true)
            self?.googleTapped?()
        }

        if !LoginFields().restrictToWPCom && selfHostedTapped != nil {
            let selfHostedLoginButton = WPStyleGuide.selfHostedLoginButton(alignment: .center)
            buttonViewController.stackView?.addArrangedSubview(selfHostedLoginButton)
            selfHostedLoginButton.addTarget(self, action: #selector(handleSelfHostedButtonTapped), for: .touchUpInside)
        }

        if WordPressAuthenticator.shared.configuration.enableSignInWithApple {
            if #available(iOS 13.0, *) {
                let appleButton = WPStyleGuide.appleLoginButton()
                appleButton.addTarget(self, action: #selector(handleAppleButtonTapped), for: .touchDown)
                buttonViewController.stackView?.insertArrangedSubview(appleButton, at: 2)
            }
        }
        
        buttonViewController.backgroundColor = WordPressAuthenticator.shared.style.viewControllerBackgroundColor
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

}
