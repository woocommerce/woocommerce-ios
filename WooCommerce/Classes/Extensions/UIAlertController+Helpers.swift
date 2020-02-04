import UIKit


/// UIAlertController Helpers
///
extension UIAlertController {

    /// Discard Changes Action Sheet
    ///
    static func presentDiscardChangesActionSheet(viewController: UIViewController,
                                              onDiscard: (() -> Void)?, onCancel: (() -> Void)? = nil) {
        let actionSheet = UIAlertController(title: nil, message: ActionSheetStrings.message, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addDestructiveActionWithTitle(ActionSheetStrings.discard) { _ in
            onDiscard?()
        }

        actionSheet.addCancelActionWithTitle(ActionSheetStrings.cancel) { _ in
            onCancel?()
        }

        let popoverController = actionSheet.popoverPresentationController
        popoverController?.sourceView = viewController.view
        popoverController?.sourceRect = viewController.view.bounds

        viewController.present(actionSheet, animated: true)
    }
}

private enum ActionSheetStrings {
    static let message = NSLocalizedString("Are you sure you want to discard these changes?",
                                           comment: "Message title for Discard Changes Action Sheet")
    static let discard = NSLocalizedString("Discard changes",
                                          comment: "Button title Discard Changes in Discard Changes Action Sheet")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Button title Cancel in Discard Changes Action Sheet")
}
