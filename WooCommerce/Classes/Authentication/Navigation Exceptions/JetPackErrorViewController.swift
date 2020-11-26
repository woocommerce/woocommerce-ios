
import UIKit
import WordPressAuthenticator
import SafariServices

final class JetPackErrorViewController: UIViewController {
    private let siteURL: String

    @IBOutlet private var primaryButton: NUXButton!
    @IBOutlet private var secondaryButton: NUXButton!
    @IBOutlet private var imageView: UIImageView!
    @IBOutlet weak var errorMessage: UILabel!
    @IBOutlet weak var extraInfoButton: UIButton!

    init(siteURL: String) {
        self.siteURL = siteURL
        super.init(nibName: Self.nibName, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        configureImageView()
        configureErrorMessage()
        configureExtraInfoButton()

        configurePrimaryButton()
        configureSecondaryButton()
    }
}


// MARK: - View configuration
private extension JetPackErrorViewController {
    func configureImageView() {
        imageView.image = .loginNoJetpackError
    }

    func configureErrorMessage() {
        print("siteURL ", siteURL)
        let message = String(format: Localization.errorMessage, siteURL)
        errorMessage.text = message
    }

    func configureExtraInfoButton() {
        extraInfoButton.applyLinkButtonStyle()
        extraInfoButton.setTitle("What is Jetpack?", for: .normal)
        extraInfoButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapAuxiliaryButton()
        }
    }

    func configurePrimaryButton() {
        primaryButton.isPrimary = true
        primaryButton.setTitle(Localization.primaryButtonTitle, for: .normal)
        primaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapPrimaryButton()
        }
    }

    func configureSecondaryButton() {
        secondaryButton.setTitle(Localization.secondaryButtonTitle, for: .normal)
        secondaryButton.on(.touchUpInside) { [weak self] _ in
            self?.didTapSecondaryButton()
        }
    }
}


// MARK: - Actions
private extension JetPackErrorViewController {
    func didTapPrimaryButton() {
        guard let url = URL(string: Strings.instructionsURLString) else {
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true)
    }

    func didTapSecondaryButton() {
        let refreshCommand = NavigateToEnterSite()
        refreshCommand.execute(from: self)
    }

    func didTapAuxiliaryButton() {
        guard let url = URL(string: Strings.whatsJetpackURLString) else {
            return
        }

        let safariViewController = SFSafariViewController(url: url)
        safariViewController.modalPresentationStyle = .pageSheet
        present(safariViewController, animated: true)
    }
}

// MARK: - Strings
private extension JetPackErrorViewController {
    enum Localization {
        static let errorMessage = NSLocalizedString("To use this app for %@ you'll need to have the Jetpack plugin installed and connected on your store.",
                                                    comment: "Message explaining that Jetpack needs to be installed for a particular site. "
                                                        + "Reads like 'To use this ap for awebsite.com you'll need to have...")

        static let whatIsJetpack = NSLocalizedString("What is Jetpack",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let primaryButtonTitle = NSLocalizedString("See Instructions",
                                                          comment: "Action button linking to instructions for installing Jetpack."
                                                          + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Refresh After Install",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

    }

    enum Strings {
        static let instructionsURLString = "https://docs.woocommerce.com/document/jetpack-setup-instructions-for-the-woocommerce-mobile-app/"

        static let whatsJetpackURLString = "https://jetpack.com/about/"
    }
}
