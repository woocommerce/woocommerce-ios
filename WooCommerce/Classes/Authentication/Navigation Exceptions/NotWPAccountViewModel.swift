import UIKit
import SafariServices
import WordPressAuthenticator
import WordPressUI


/// Configuration and actions for an ULErrorViewController, modeling
/// an error when user attempts to log in with an invalid WordPress.com account
/// (e.g. when the email is not linked to a WordPress.com account).
final class NotWPAccountViewModel: ULErrorViewModel {
    // MARK: - Data and configuration
    let image: UIImage = .loginNoWordPressError

    let text: NSAttributedString = .init(string: Localization.errorMessage)

    let isAuxiliaryButtonHidden = false

    let auxiliaryButtonTitle = AuthenticationConstants.whatIsWPComLinkTitle

    let primaryButtonTitle: String

    let secondaryButtonTitle = Localization.restartLogin
    let isSecondaryButtonHidden: Bool

    private weak var viewController: UIViewController?

    private(set) lazy var auxiliaryView: UIView? = {
        let button = UIButton(type: .custom)
        button.applyLinkButtonStyle(enableMultipleLines: true)
        button.titleLabel?.textAlignment = .center
        button.setTitle(Localization.needHelpFindingEmail, for: .normal)
        button.on(.touchUpInside) { [weak self] _ in
            self?.needHelpFindingEmailButtonTapped()
        }
        return button
    }()

    init(error: Error) {
        if let error = error as? SignInError,
           case let .invalidWPComEmail(source) = error,
           source == .wpComSiteAddress {
            isSecondaryButtonHidden = true
            primaryButtonTitle = Localization.restartLogin
        } else {
            isSecondaryButtonHidden = false
            primaryButtonTitle = Localization.loginWithSiteAddress
        }
    }

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
        whatIsWPComButtonTapped()
    }

    func viewDidLoad(_ viewController: UIViewController?) {
        self.viewController = viewController
    }
}

private extension NotWPAccountViewModel {
    func whatIsWPComButtonTapped() {
        guard let viewController = viewController else {
            return
        }
        ServiceLocator.analytics.track(.whatIsWPComOnInvalidEmailScreenTapped)
        WebviewHelper.launch(WooConstants.URLs.whatIsWPComURL.asURL(), with: viewController)
    }

    func needHelpFindingEmailButtonTapped() {
        let fancyAlert = FancyAlertViewController.makeNeedHelpFindingEmailAlertController()
        fancyAlert.modalPresentationStyle = .custom
        fancyAlert.transitioningDelegate = AppDelegate.shared.tabBarController
        viewController?.present(fancyAlert, animated: true)
    }
}

// MARK: - Private data structures
private extension NotWPAccountViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("This email isn't used with a WordPress.com account.",
                                                    comment: "Message explaining that an email is not associated with a WordPress.com account. "
                                                        + "Presented when logging in with an email address that is not a WordPress.com account")

        static let needHelpFindingEmail = NSLocalizedString("Need help finding the required email?",
                                                     comment: "Button linking to webview that explains what Jetpack is"
                                                        + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let loginWithSiteAddress = NSLocalizedString("Log in with your store address",
                                                            comment: "Action button linking to instructions for enter another store."
                                                            + "Presented when logging in with an email address that is not a WordPress.com account")

        static let restartLogin = NSLocalizedString("Log in with another account",
                                                    comment: "Action button that will restart the login flow."
                                                    + "Presented when logging in with an email address that does not match a WordPress.com account")

    }
}
