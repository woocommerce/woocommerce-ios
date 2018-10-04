import Foundation
import UIKit
import SafariServices
import WordPressAuthenticator


/// Displays the WooCommerce Prologue UI.
///
class LoginPrologueViewController: UIViewController {

    /// Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet var backgroundView: UIView!

    /// Container View: Holds up the Button + bottom legend.
    ///
    @IBOutlet var containerView: UIView!

    /// Label to be displayed at the top of the Prologue.
    ///
    @IBOutlet var upperLabel: UILabel!

    /// Disclaimer Label
    ///
    @IBOutlet var disclaimerTextView: UITextView!

    /// Jetpack Logo ImageVIew
    ///
    @IBOutlet var jetpackImageView: UIImageView!

    /// Default Action Button.
    ///
    @IBOutlet var loginButton: UIButton!


    // MARK: - Overridden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - Overridden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupBackgroundView()
        setupContainerView()
        setupJetpackImage()
        setupDisclaimerLabel()
        setupUpperLabel()
        setupLoginButton()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }
}


// MARK: - Initialization Methods
//
private extension LoginPrologueViewController {

    func setupMainView() {
        view.backgroundColor = .white
    }

    func setupBackgroundView() {
        backgroundView.backgroundColor = StyleManager.wooCommerceBrandColor
    }

    func setupContainerView() {
        containerView.backgroundColor = StyleManager.wooCommerceBrandColor
    }

    func setupUpperLabel() {
        upperLabel.text = NSLocalizedString("Manage orders, track sales and monitor store activity with real-time alerts.", comment: "Login Prologue Legend")
        upperLabel.font = UIFont.font(forStyle: .subheadline, weight: .bold)
        upperLabel.textColor = StyleManager.wooCommerceBrandColor
    }

    func setupJetpackImage() {
        jetpackImageView.image = UIImage.jetpackLogoImage.imageWithTintColor(.white)
    }

    func setupDisclaimerLabel() {
        disclaimerTextView.attributedText = disclaimerAttributedText
        disclaimerTextView.textContainerInset = .zero
        disclaimerTextView.linkTextAttributes = [
            .foregroundColor: UIColor.white,
            .underlineColor: UIColor.white,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    func setupLoginButton() {
        let title = NSLocalizedString("Log in with Jetpack", comment: "Authentication Login Button")
        loginButton.setTitle(title, for: .normal)
        loginButton.setTitleColor(StyleManager.wooSecondary, for: .normal)
        loginButton.titleLabel?.font = UIFont.font(forStyle: .headline, weight: .semibold)
        loginButton.backgroundColor = .white
        loginButton.layer.cornerRadius = Settings.buttonCornerRadius
    }
}


// MARK: - UITextViewDeletgate Conformance
//
extension LoginPrologueViewController: UITextViewDelegate {

    func textView(_ textView: UITextView, shouldInteractWith URL: URL, in characterRange: NSRange, interaction: UITextItemInteraction) -> Bool {
        displaySafariViewController(at: URL)
        return false
    }
}


// MARK: - Action Handlers
//
extension LoginPrologueViewController {

    /// Opens SafariViewController at the specified URL.
    ///
    func displaySafariViewController(at url: URL) {
        WooAnalytics.shared.track(.loginPrologueJetpackInstructions)
        let safariViewController = SafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }

    /// Proceeds with the Login Flow.
    ///
    @IBAction func loginWasPressed() {
        WooAnalytics.shared.track(.loginPrologueContinueTapped)
        let loginViewController = AppDelegate.shared.authenticationManager.loginForWordPressDotCom()

        navigationController?.pushViewController(loginViewController, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}


// MARK: - Private Methods
//
private extension LoginPrologueViewController {

    /// Returns the Disclaimer Attributed Text (which contains a link to the Jetpack Setup URL).
    ///
    var disclaimerAttributedText: NSAttributedString {
        let disclaimerText = NSLocalizedString("This app requires Jetpack to connect to your Store. Read the ", comment: "Login Disclaimer Text and Jetpack config instructions")
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: UIFont.font(forStyle: .caption1, weight: .thin),
            .foregroundColor: UIColor.white
        ]

        let readText = NSLocalizedString("configuration instructions", comment: "Login Disclaimer Linked Text")
        let readAttributes: [NSAttributedString.Key: Any] = [
            .link: URL(string: WooConstants.jetpackSetupUrl) as Any,
            .font: UIFont.font(forStyle: .caption1, weight: .thin)
        ]

        let readAttrText = NSMutableAttributedString(string: readText, attributes: readAttributes)

        let endSentenceText = "."
        let endSentenceAttrText = NSMutableAttributedString(string: endSentenceText, attributes: disclaimerAttributes)

        let disclaimerAttrText = NSMutableAttributedString(string: disclaimerText, attributes: disclaimerAttributes)
        disclaimerAttrText.append(readAttrText)
        disclaimerAttrText.append(endSentenceAttrText)

        return disclaimerAttrText
    }
}


// MARK: - (Private) Constants!
//
private enum Settings {

    /// Login Button's Corner Radius
    ///
    static let buttonCornerRadius = CGFloat(8.0)
}
