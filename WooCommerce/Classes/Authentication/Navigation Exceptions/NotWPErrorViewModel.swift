import UIKit
import SafariServices
import WordPressAuthenticator
import WordPressUI


/// Configuration and actions for an ULErrorViewController, modeling
/// an error when the site is not a WordPress site
struct NotWPErrorViewModel: ULErrorViewModel {
    // MARK: - Data and configuration
    let image: UIImage = .loginNoWordPressError

    let text: NSAttributedString = .init(string: Localization.errorMessage)

    let isAuxiliaryButtonHidden = true

    let auxiliaryButtonTitle = ""

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        let popCommand = NavigateBack()
        popCommand.execute(from: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        let refreshCommand = NavigateToRoot()
        refreshCommand.execute(from: viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        // NO-OP
    }
}


// MARK: - Private data structures
private extension NotWPErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("The website is not a WordPress site. For us to connect to it, the site must have WordPress installed.",
                                                    comment: "Message explaining that a site is not a WordPress site. "
                                                        + "Reads like 'The website awebsite.com you'll is not a WordPress site...")

        static let primaryButtonTitle = NSLocalizedString("Enter Another Store",
                                                          comment: "Action button linking to instructions for enter another store."
                                                          + "Presented when logging in with a site address that is not a WordPress site")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

    }
}
