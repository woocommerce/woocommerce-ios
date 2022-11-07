import UIKit
import WordPressAuthenticator

/// Configuration and actions for an ULErrorViewController, modeling
/// an error when there is a error accessing `/xmlrpc.php` of the site
struct XMLRPCErrorViewModel: ULErrorViewModel {
    // MARK: - Data and configuration
    let image: UIImage = .errorImage

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteAddress + "/xmlrpc.php",
                                                 attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    let isAuxiliaryButtonHidden = true

    let auxiliaryButtonTitle = ""

    let primaryButtonTitle = Localization.tryAnotherAddress

    let secondaryButtonTitle = ""

    let isSecondaryButtonHidden = true

    private let siteAddress: String

    private let analytics: Analytics

    init(siteAddress: String,
         analytics: Analytics = ServiceLocator.analytics) {
        self.siteAddress = siteAddress
        self.analytics = analytics
    }

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        let refreshCommand = NavigateToRoot()
        refreshCommand.execute(from: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        // NO-OP
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        // NO-OP
    }

    func viewDidLoad(_ viewController: UIViewController?) {
        // NO-OP
    }
}


// MARK: - Private data structures
private extension XMLRPCErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("While your site is publicly accessible, we cannot access your site’s XML-RPC file. \n\n%@\n\n"
                                                    + " You will need to contact your hosting provider to ensure that XML-RPC is enabled on your server.",
                                                    comment: "Message explaining that /xmlrpc.php was not accessible.")

        static let tryAnotherAddress = NSLocalizedString("Try Another Address",
                                                         comment: "Action button that will restart the login flow."
                                                         + "Presented when logging in with an email address that does not match a WordPress.com account")
    }
}
