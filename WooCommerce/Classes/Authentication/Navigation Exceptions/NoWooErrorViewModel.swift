import UIKit
import WordPressAuthenticator
import WordPressUI

/// Configuration and actions for an ULErrorViewController,
/// modelling an error when WooCommerce is not installed or activated.
struct NoWooErrorViewModel: ULErrorViewModel {
    private let siteURL: String
    private let showsConnectedStores: Bool
    private let analytics: Analytics

    init(siteURL: String?, showsConnectedStores: Bool, analytics: Analytics = ServiceLocator.analytics) {
        self.siteURL = siteURL ?? Localization.yourSite
        self.showsConnectedStores = showsConnectedStores
        self.analytics = analytics
    }

    // MARK: - Data and configuration
    let image: UIImage = .noStoreImage

    var text: NSAttributedString {
        let font: UIFont = .body
        let boldFont: UIFont = font.bold

        let boldSiteAddress = NSAttributedString(string: siteURL.trimHTTPScheme(),
                                                           attributes: [.font: boldFont])
        let message = NSMutableAttributedString(string: Localization.errorMessage)

        message.replaceFirstOccurrence(of: "%@", with: boldSiteAddress)

        return message
    }

    var isAuxiliaryButtonHidden: Bool { !showsConnectedStores }

    let auxiliaryButtonTitle = Localization.seeConnectedStores

    let primaryButtonTitle = Localization.primaryButtonTitle

    let secondaryButtonTitle = Localization.secondaryButtonTitle

    // MARK: - Actions
    func didTapPrimaryButton(in viewController: UIViewController?) {
        // TODO: Analytics
        guard let viewController = viewController else {
            return
        }
        let viewModel = WooSetupWebViewModel(siteURL: siteURL)
        let setupViewController = PluginSetupWebViewController(viewModel: viewModel)
        viewController.present(setupViewController, animated: true, completion: nil)
    }

    func didTapSecondaryButton(in viewController: UIViewController?) {
        let refreshCommand = NavigateToRoot()
        refreshCommand.execute(from: viewController)
    }

    func didTapAuxiliaryButton(in viewController: UIViewController?) {
        guard let navigationController = viewController?.navigationController else {
            return
        }

        let storePicker = StorePickerViewController()
        storePicker.configuration = .listStores

        navigationController.pushViewController(storePicker, animated: true)

        // TODO: Analytics
    }

    func viewDidLoad() {
        // TODO: Analytics
    }

}

// MARK: - Private data structures
private extension NoWooErrorViewModel {
    enum Localization {
        static let errorMessage = NSLocalizedString("It looks like %@ is not a WooCommerce site.",
                                                    comment: "Message explaining that the site entered doesn't have WooCommerce installed or activated. "
                                                        + "Reads like 'It looks like awebsite.com is not a WooCommerce site.")

        static let seeConnectedStores = NSLocalizedString("See Connected Stores",
                                                          comment: "Action button linking to a list of connected stores. "
                                                          + "Presented when logging in with a store address that does not have WooCommerce.")

        static let primaryButtonTitle = NSLocalizedString("Install WooCommerce",
                                                          comment: "Action button for installing WooCommerce."
                                                          + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let secondaryButtonTitle = NSLocalizedString("Log In With Another Account",
                                                            comment: "Action button that will restart the login flow."
                                                            + "Presented when logging in with a site address that does not have a valid Jetpack installation")

        static let yourSite = NSLocalizedString("your site",
                                                comment: "Placeholder for site url, if the url is unknown."
                                                    + "Presented when logging in with a site address that does not have a valid Jetpack installation."
                                                + "The error would read: to use this app for your site you'll need...")

    }
}
