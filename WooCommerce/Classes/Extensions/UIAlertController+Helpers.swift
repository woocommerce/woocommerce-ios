import UIKit


/// UIAlertController Helpers
///
extension UIAlertController {

    /// Save Changes Action Sheet
    ///
    static func presentSaveChangesActionSheet(viewController: UIViewController, onSave: (() -> Void)?, onDiscard: (() -> Void)?, onCancel: (() -> Void)?) {
        let actionSheet = UIAlertController(title: nil, message: ActionSheetStrings.message, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addDefaultActionWithTitle(ActionSheetStrings.save) { _ in
            onSave?()
        }

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
                                           comment: "Message title for Save Changes Action Sheet")
    static let save = NSLocalizedString("Save changes",
                                        comment: "Button title for Save Changes Action Sheet")
    static let discard = NSLocalizedString("Discard changes",
                                          comment: "Button title Discard Changes in Save Changes Action Sheet")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Button title Cancel in Save Changes Action Sheet")
}

