import Foundation
import UIKit
import SafariServices
import WordPressAuthenticator


/// Displays the WooCommerce Prologue UI.
///
class LoginPrologueViewController: UIViewController {

    /// White-Background View, to be placed surrounding the bottom area.
    ///
    @IBOutlet var backgroundView: UIView!

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


    // MARK: - Overriden Properties

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }


    // MARK: - Overriden Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        setupMainView()
        setupBackgroundView()
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
        view.backgroundColor = StyleManager.wooCommerceBrandColor
    }

    func setupBackgroundView() {
        backgroundView.layer.masksToBounds = false
        backgroundView.layer.shadowOpacity = 0.5
    }

    func setupUpperLabel() {
        upperLabel.text = NSLocalizedString("Check your WooCommerce store on the go, fulfill your orders and get notifications of new sales.", comment: "Login Prologue Legend")
        upperLabel.font = UIFont.font(forStyle: .subheadline, weight: .bold)
        upperLabel.textColor = .white
    }

    func setupJetpackImage() {
        jetpackImageView.image = UIImage.jetpackLogoImage.imageWithTintColor(.jetpackGreen)
    }

    func setupDisclaimerLabel() {
        disclaimerTextView.attributedText = disclaimerAttributedText
        disclaimerTextView.textContainerInset = .zero
    }

    func setupLoginButton() {
        let title = NSLocalizedString("Log in with Jetpack", comment: "Authentication Login Button")
        loginButton.setTitle(title, for: .normal)
        loginButton.backgroundColor = .clear
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
        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true, completion: nil)
    }

    /// Proceeds with the Login Flow.
    ///
    @IBAction func loginWasPressed() {
        let loginViewController = WordPressAuthenticator.signinForWordPress()
        loginViewController.restrictToWPCom = true
        loginViewController.offerSignupOption = false

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
        let disclaimerText = NSLocalizedString("This app requires Jetpack to be able to connect to your WooCommerce Store.\nFor configuration instructions, ", comment: "Login Disclaimer Text")
        let disclaimerAttributes: [NSAttributedStringKey: Any] =  [
            .font: UIFont.font(forStyle: .caption1, weight: .thin),
            .foregroundColor: UIColor.black
        ]

        let readText = NSLocalizedString("read here.", comment: "Login Disclaimer Linked Text")
        var readAttributes = disclaimerAttributes
        readAttributes[.link] = WooConstants.jetpackSetupUrl

        let readAttrText = NSMutableAttributedString(string: readText, attributes: readAttributes)
        let disclaimerAttrText = NSMutableAttributedString(string: disclaimerText, attributes: disclaimerAttributes)
        disclaimerAttrText.append(readAttrText)

        return disclaimerAttrText
    }
}
