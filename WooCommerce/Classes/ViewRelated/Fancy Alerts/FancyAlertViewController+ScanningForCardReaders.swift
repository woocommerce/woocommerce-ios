import Foundation
import WordPressUI

public extension FancyAlertViewController {
    typealias ButtonConfig = FancyAlertViewController.Config.ButtonConfig

    static func makeScanningForCardReadersAlertController(onCancel: (() -> Void)? = nil) -> FancyAlertViewController {
        let cancelButton = ButtonConfig(Strings.cancelButtonText) { controller, _ in
            onCancel?()
            controller.dismiss(animated: true, completion: nil)
        }

        let config = FancyAlertViewController.Config(titleText: Strings.titleText,
                                                     bodyText: Strings.bodyText,
                                                     headerImage: .cardReaderScanningImage,
                                                     dividerPosition: .none,
                                                     defaultButton: nil,
                                                     cancelButton: cancelButton,
                                                     moreInfoButton: nil,
                                                     dismissAction: onCancel
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
            "Scanning for reader",
            comment: "Title of alert prompting users that we are scanning for a card reader."
        )

        // Body
        static let bodyText = NSLocalizedString(
            "Press the power button of your reader until you see a flashing blue light",
            comment: "Body text of alert prompting users how to assist the card reader discovery process."
        )

        // UI Elements
        static let cancelButtonText = NSLocalizedString(
            "Cancel",
            comment: "Button title shown in an alert used while scanning for card readers."
        )
    }
}
