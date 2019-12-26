import Foundation
import WordPressUI
import SafariServices


public extension FancyAlertViewController {

    /// Create the fancy alert controller for the WC 3.5 upgrade alert that appears after the login flow is completed.
    ///
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makeWooUpgradeAlertController() -> FancyAlertViewController {

        let dismissButton = makeDismissButtonConfig()
        let moreInfoButton = makeMoreInfoButtonConfig()
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


    /// Create the fancy alert controller for the WC 3.5 upgrade alert that appears on the Site Picker screen
    /// (before the login flow is completed).
    ///
    /// - Parameter siteName: Friendly site name to appear in the fancy alert's title
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makewWooUpgradeAlertControllerForSitePicker(siteName: String) -> FancyAlertViewController {

        let dismissButton = makeDismissButtonConfig()
        let moreInfoButton = makeMoreInfoButtonConfig()
        let titleText = String.localizedStringWithFormat(Strings.titleTextForSite, siteName)
        let config = FancyAlertViewController.Config(titleText: titleText,
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


// MARK: - Private Helpers
//
private extension FancyAlertViewController {

    static func makeDismissButtonConfig() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Strings.dismissButtonText) { controller, _ in
            controller.dismiss(animated: true)
        }
    }

    static func makeMoreInfoButtonConfig() -> FancyAlertViewController.Config.ButtonConfig {
        return FancyAlertViewController.Config.ButtonConfig(Strings.moreInfoButtonText) { controller, _ in
            guard let url = URL(string: Strings.moreInfoURLString) else {
                return
            }

            let safariViewController = SFSafariViewController(url: url)
            safariViewController.modalPresentationStyle = .pageSheet
            controller.present(safariViewController, animated: true)
        }
    }
}


// MARK: - Constants
//
private extension FancyAlertViewController {

    struct Strings {
        // Titles
        static let titleText = NSLocalizedString(
            "Update to WooCommerce 3.5 to keep using this app",
            comment: "Title of alert warning users to upgrade to WC 3.5."
        )

        static let titleTextForSite = NSLocalizedString("Update %@ to WooCommerce 3.5",
            comment: "Title of alert warning users to upgrade to WC 3.5 WITH a site name. It reads: Update {site name} to WooCommerce 3.5 to use this app"
        )

        // Body
        static let bodyText = NSLocalizedString("This app requires that you install WooCommerce 3.5 on your server, and won't work properly without it." +
            " Update as soon as possible to continue using this app.",
            comment: "Body text of alert warning users to upgrade to WC 3.5."
        )

        // UI Elements
        static let moreInfoButtonText = NSLocalizedString(
            "Update Instructions",
            comment: "Update instructions button title shown in alert warning users to upgrade to WC 3.5."
        )

        static let moreInfoURLString = "https://docs.woocommerce.com/document/how-to-update-woocommerce/"

        static let dismissButtonText = NSLocalizedString(
            "Dismiss",
            comment: "Dismiss button title shown in alert warning users to upgrade to WC 3.5."
        )
    }
}
