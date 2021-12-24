import UIKit
import WordPressAuthenticator

/// Configuration and actions for a `ULErrorViewController`, modelling an error when the merchant
/// attempts to log in with a site that has an invalid SSL certificate.
struct NoSecureConnectionErrorViewModel: ULErrorViewModel {
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

    func viewDidLoad() {
        // NO-OP
    }

}

private extension NoSecureConnectionErrorViewModel {
    enum Localization {
        static let errorMessage =
            NSLocalizedString("A secure connection to the site could not be made. " +
                                "Please make sure that your site has a valid SSL certificate.",
                              comment: "Message explaining that the site may have an invalid SSL certificate.")

        static let primaryButtonTitle =
            NSLocalizedString("Enter Another Store",
                              comment: "Action button linking to instructions for enter another store."
                                + "Presented when logging in with a site address that appears to be invalid.")

        static let secondaryButtonTitle =
            NSLocalizedString("Log In With Another Account",
                              comment: "Action button that will restart the login flow."
                                + "Presented when logging in with a site address that appears to be invalid.")
    }
}
