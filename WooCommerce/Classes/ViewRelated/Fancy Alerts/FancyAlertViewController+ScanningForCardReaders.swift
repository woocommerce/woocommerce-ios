import Foundation
import WordPressUI

public extension FancyAlertViewController {
    typealias ButtonConfig = FancyAlertViewController.Config.ButtonConfig

    static func makeScanningForCardReadersAlertController(onDismiss: (() -> Void)? = nil) -> FancyAlertViewController {
        let dismissButton = ButtonConfig(Strings.dismissButtonText) { controller, _ in
            onDismiss?()
            controller.dismiss(animated: true, completion: nil)
        }

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: .cardReaderScanningImage,
                                                     dividerPosition: .bottom,
                                                     defaultButton: dismissButton,
                                                     cancelButton: nil,
                                                     moreInfoButton: nil,
                                                     dismissAction: onDismiss
        )

        let controller = FancyAlertViewController.controllerWithConfiguration(configuration: config)
        return controller
    }
}

// MARK: - Constants
//
private extension FancyAlertViewController {
    struct Strings {
        // Title
        static let titleText = NSLocalizedString(
            "Scanning for readers",
            comment: "Title of alert prompting users that we are scanning for card readers."
        )

        // Body
        static let bodyText = NSLocalizedString(
            "Press the power button of your reader unitl you see a flashing blue light",
            comment: "Body text of alert prompting users how to assist the card reader discovery process."
        )

        // UI Elements
        static let dismissButtonText = NSLocalizedString(
            "Dismiss",
            comment: "Dismiss button title shown in an alert used while scanning for card readers."
        )
    }
}
