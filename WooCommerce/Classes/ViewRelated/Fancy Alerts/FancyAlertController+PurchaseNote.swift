import Foundation
import WordPressUI
import SafariServices


public extension FancyAlertViewController {

    /// Create the fancy alert controller for displaying the full Purchase Note in Product Details.
    ///
    /// - Returns: FancyAlertViewController of the alert
    ///
    static func makePurchaseNoteAlertController(with bodyText: String?) -> FancyAlertViewController {
        let dismissButton = makeDismissButtonConfig()
        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: bodyText,
                                                     headerImage: nil,
                                                     dividerPosition: .bottom,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: nil,
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
}


// MARK: - Constants
//
private extension FancyAlertViewController {

    struct Strings {
        // Titles
        static let titleText = NSLocalizedString(
            "Purchase note",
            comment: "Title for purchase note alert."
        )

        // UI Elements
        static let dismissButtonText = NSLocalizedString(
            "Dismiss",
            comment: "Dismiss button title shown in an alert displaying full purchase note text."
        )
    }
}
