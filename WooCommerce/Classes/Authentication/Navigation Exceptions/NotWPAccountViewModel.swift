import UIKit
import SafariServices
import WordPressAuthenticator
import WordPressUI


/// Configuration and actions for an ULErrorViewController, modeling
/// an error when user attempts to log in with an invalid WordPressAccount
struct NotWPAccountViewModel: ULErrorViewModel {
    // MARK: - Data and configuration
    let image: UIImage = .loginNoWordPressError

    let text: NSAttributedString = .init(string: Localization.errorMessage)

    let isAuxiliaryButtonHidden = false

    let auxiliaryButtonTitle = Localization.needHelpFindingEmail

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        let popCommand = NavigateToEnterSite()
        popCommand.execute(from: viewController)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        let refreshCommand = NavigateToRoot()
        refreshCommand.execute(from: viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        let fancyAlert = FancyAlertViewController.makeNeedHelpFindingEmailAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)
    }
}


// MARK: - Private data structures
private extension NotWPAccountViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("It looks like this email isn't associated with a WordPress.com account.",
                                                    comment: "Message explaining that an email is not associated with a WordPress.com account. "
                                                        + "Presented when logging in with an email address that is not a WordPress.com account")

        static let needHelpFindingEmail = NSLocalizedString("Need help finding the connected email?",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let primaryButtonTitle = NSLocalizedString("Enter Your Store Address",
                                                          comment: "Action button linking to instructions for enter another store."
                                                          + "Presented when logging in with an email address that is not a WordPress.com account")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with an email address that does not match a WordPress.com account")

    }
}
