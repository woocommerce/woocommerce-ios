import Foundation
import WordPressUI
import SafariServices


public extension FancyAlertViewController {

    /// Create the fancy alert controller for the WC 3.5 upgrade alert
    ///
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makeWooUpgradeAlertController() -> FancyAlertViewController {

        let dismissButton = FancyAlertViewController.Config.ButtonConfig(Strings.dismissButtonText) { controller, _ in
            // TODO: Save 'seen alert' bool to user defaults
            controller.dismiss(animated: true)
        }

        let moreInfoButton = FancyAlertViewController.Config.ButtonConfig(Strings.moreInfoButtonText) { controller, _ in
            guard let url = URL(string: Strings.moreInfoURLString) else {
                return
            }

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            controller.present(safariViewController, animated: true)
        }

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: nil,
                                                     dividerPosition: .bottom,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: moreInfoButton,
                                                     dismissAction: {})

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}


// MARK: - Constants
//
private extension FancyAlertViewController {

    struct Strings {
        static let titleText          = NSLocalizedString("Update to WooCommerce 3.5 to keep using this app", comment: "Title of alert warning users to upgrade to WC 3.5.")
        static let bodyText           = NSLocalizedString("This app requires that you install WooCommerce 3.5 on your server, and won't work properly without it. Update as soon as possible to continue using this app.",
                                                         comment: "Body text of alert warning users to upgrade to WC 3.5.")
        static let moreInfoButtonText = NSLocalizedString("Update Instructions", comment: "Update instructions button title shown in alert warning users to upgrade to WC 3.5.")
        static let moreInfoURLString  = "https://docs.woocommerce.com/document/how-to-update-woocommerce/"
        static let dismissButtonText  = NSLocalizedString("Dismiss", comment: "Dismiss button title shown in alert warning users to upgrade to WC 3.5.")
    }
}
