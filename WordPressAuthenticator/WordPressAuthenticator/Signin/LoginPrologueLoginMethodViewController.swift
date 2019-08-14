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
        let googleTitle = NSLocalizedString("Continue with Google", comment: "Button title. Tapping begins log in using Google.")
        
        buttonViewController.setupTopButton(title: wordpressTitle, isPrimary: false, accessibilityIdentifier: "Log in with Email Button") { [weak self] in
            self?.dismiss(animated: true)
            self?.emailTapped?()
        }

        buttonViewController.setupBottomButton(title: googleTitle, isPrimary: false, accessibilityIdentifier: "Log in with Google Button") { [weak self] in
            defer {
                WordPressAuthenticator.track(.loginSocialButtonClick)
            }

            self?.dismiss(animated: true)
            self?.googleTapped?()
        }
        
        if !LoginFields().restrictToWPCom {
            let selfHostedLoginButton = WPStyleGuide.selfHostedLoginButton(alignment: .center)
            buttonViewController.stackView?.addArrangedSubview(selfHostedLoginButton)
            selfHostedLoginButton.addTarget(self, action: #selector(handleSelfHostedButtonTapped), for: .touchUpInside)
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

}
