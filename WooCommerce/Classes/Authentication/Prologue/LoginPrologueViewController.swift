import Foundation
import UIKit
import SafariServices
import WordPressAuthenticator


/// Displays the WooCommerce Prologue UI.
///
final class LoginPrologueViewController: UIViewController {

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

    @IBOutlet var slantedRectangle: UIImageView!
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
        setupSlantedRectangle()
        setupJetpackImage()

        setupLabels()
    }

    private func setupLabels() {
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
        view.backgroundColor = .basicBackground
    }

    func setupBackgroundView() {
        backgroundView.backgroundColor = .withColorStudio(.brand, shade: .shade80)
    }

    func setupContainerView() {
        containerView.backgroundColor = .withColorStudio(.brand, shade: .shade80)
    }

    func setupUpperLabel() {
        upperLabel.text = NSLocalizedString("Manage orders, track sales and monitor store activity with real-time alerts.", comment: "Login Prologue Legend")
        upperLabel.adjustsFontForContentSizeCategory = true
        upperLabel.font = StyleManager.subheadlineBoldFont
        upperLabel.textColor = .filterBarSelected
    }

    func setupSlantedRectangle() {
        slantedRectangle.image = UIImage.slantedRectangle.imageWithTintColor(.withColorStudio(.brand, shade: .shade80))
    }

    func setupJetpackImage() {
        jetpackImageView.image = UIImage.jetpackLogoImage.imageWithTintColor(.white)
    }

    func setupDisclaimerLabel() {
        disclaimerTextView.attributedText = disclaimerAttributedText
        disclaimerTextView.adjustsFontForContentSizeCategory = true
        disclaimerTextView.textContainerInset = .zero
        disclaimerTextView.linkTextAttributes = [
            .foregroundColor: UIColor.text,
            .underlineColor: UIColor.text,
            .underlineStyle: NSUnderlineStyle.single.rawValue
        ]
    }

    func setupLoginButton() {
        let title = NSLocalizedString("Log in with Jetpack", comment: "Authentication Login Button")
        loginButton.titleLabel?.adjustsFontForContentSizeCategory = true
        loginButton.setTitle(title, for: .normal)
        loginButton.setTitleColor(.black, for: .normal)
        loginButton.titleLabel?.font = StyleManager.headlineSemiBold
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
        ServiceLocator.analytics.track(.loginPrologueJetpackInstructions)
        let safariViewController = SFSafariViewController(url: url)

        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }

    /// Proceeds with the Login Flow.
    ///
    @IBAction func loginWasPressed() {
        ServiceLocator.analytics.track(.loginPrologueContinueTapped)
        let loginViewController = ServiceLocator.authenticationManager.loginForWordPressDotCom()

        navigationController?.pushViewController(loginViewController, animated: true)
        navigationController?.setNavigationBarHidden(false, animated: true)
    }
}


// MARK: - Handling updated trait collections
//
extension LoginPrologueViewController {
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if previousTraitCollection?.preferredContentSizeCategory != traitCollection.preferredContentSizeCategory {
            setupLabels()
        }
    }
}


// MARK: - Private Methods
//
private extension LoginPrologueViewController {

    /// Returns the Disclaimer Attributed Text (which contains a link to the Jetpack Setup URL).
    ///
    var disclaimerAttributedText: NSAttributedString {
        let disclaimerText = NSLocalizedString(
            "This app requires Jetpack to connect to your Store. <br /> Read the <a " +
                "href=\"https://jetpack.com/support/getting-started-with-jetpack/\">configuration instructions</a>.",
            comment: "Login Disclaimer Text and Jetpack config instructions. It reads: 'This app requires Jetpack to connect to your Store. " +
            "Read the configuration instructions.' and it links to a web page on the words 'configuration instructions'. " +
            "Place the second sentence after the `<br />` tag. " +
            "Place the noun, \'configuration instructions' between the opening `<a` tag and the closing `</a>` tags. " +
            "If a literal translation of 'Read the configuration instructions' does not make sense in your language, " +
            "please use a contextually appropriate substitution. " +
            "For example, you can translate it to say 'See: instructions' or any alternative that sounds natural in your language."
        )
        let disclaimerAttributes: [NSAttributedString.Key: Any] = [
            .font: StyleManager.thinCaptionFont,
            .foregroundColor: UIColor.white
        ]

        let disclaimerAttrText = NSMutableAttributedString()
        disclaimerAttrText.append(disclaimerText.htmlToAttributedString)
        disclaimerAttrText.addAttributes(disclaimerAttributes, range: NSRange(location: 0, length: disclaimerAttrText.length))

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
