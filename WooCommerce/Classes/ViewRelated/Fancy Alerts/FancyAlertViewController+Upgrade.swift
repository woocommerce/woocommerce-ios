import Foundation
import WordPressUI


public extension FancyAlertViewController {

    private struct Strings {
        static let titleText = NSLocalizedString("Update to WooCommerce 3.5 to keep using this app", comment: "Title of alert warning users to upgrade to WC 3.5.")
        static let bodyText = NSLocalizedString("This app requires that you install WooCommerce 3.5 on your server, and won't work properly without it. Update as soon as possible to continue using this app.",
                                                comment: "Body text of alert warning users to upgrade to WC 3.5.")
        static let dismissButtonText = NSLocalizedString("Got it!", comment: "Dismiss button title shown in alert warning users to upgrade to WC 3.5.")
    }

    /// Create the fancy alert controller for the WC 3.5 upgrade alert
    ///
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makeWooUpgradeAlertController() -> FancyAlertViewController {

        let dismissButton = FancyAlertViewController.Config.ButtonConfig(Strings.dismissButtonText) { controller, _ in
            // TODO: Save 'seen alert' bool to user defaults
            controller.dismiss(animated: true)
        }

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: nil,
                                                     dividerPosition: .bottom,
                                                     defaultButton: dismissButton,
                                                     cancelButton:  nil,
                                                     appearAction: nil,
                                                     dismissAction: nil)

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}
