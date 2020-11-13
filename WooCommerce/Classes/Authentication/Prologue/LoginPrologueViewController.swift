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

    @IBOutlet private var slantedRectangle: UIImageView!
    /// Jetpack Logo ImageVIew
    ///
    @IBOutlet var jetpackImageView: UIImageView!


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

        setupUpperLabel()
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
        backgroundView.backgroundColor = .init(light: .brand, dark: .withColorStudio(.brand, shade: .shade80))
    }

    func setupContainerView() {
        containerView.backgroundColor = .authPrologueBottomBackgroundColor
    }

    func setupUpperLabel() {
        upperLabel.text = NSLocalizedString("Manage orders, track sales and monitor store activity with real-time alerts.", comment: "Login Prologue Legend")
        upperLabel.adjustsFontForContentSizeCategory = true
        upperLabel.font = StyleManager.headlineSemiBold
        upperLabel.textColor = .primary
    }

    func setupSlantedRectangle() {
        slantedRectangle.image = UIImage.slantedRectangle.withRenderingMode(.alwaysTemplate)
        slantedRectangle.tintColor = .authPrologueBottomBackgroundColor
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
}
