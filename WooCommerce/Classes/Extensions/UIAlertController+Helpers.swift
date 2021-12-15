import UIKit
import Observables


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

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = viewController.view.bounds
            popoverController.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true)
    }

    /// Present a discard changes action sheet when the user navigates away from adding a product.
    static func presentDiscardNewProductActionSheet(viewController: UIViewController,
                                                    onSaveDraft: @escaping (() -> Void),
                                                    onDiscard: @escaping (() -> Void),
                                                    onCancel: (() -> Void)? = nil) {
        let actionSheet = UIAlertController(title: nil, message: ActionSheetStrings.message, preferredStyle: .actionSheet)
        actionSheet.view.tintColor = .text

        actionSheet.addDefaultActionWithTitle(ActionSheetStrings.saveAsDraft) { _ in
            onSaveDraft()
        }

        actionSheet.addDestructiveActionWithTitle(ActionSheetStrings.discard) { _ in
            onDiscard()
        }

        actionSheet.addCancelActionWithTitle(ActionSheetStrings.cancel) { _ in
            onCancel?()
        }

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = viewController.view.bounds
            popoverController.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true)
    }

    /// Present an alert when the app does not have permission to use camera for barcode scanner.
    /// The alert has an action that links to device settings and a cancel action.
    static func presentBarcodeScannerNoCameraPermissionAlert(viewController: UIViewController,
                                                             onCancel: (() -> Void)? = nil) {
        presentAlertWithLinkToOpenSettings(viewController: viewController,
                                           title: BarcodeScannerNoCameraPermissionAlert.Localization.title,
                                           message: BarcodeScannerNoCameraPermissionAlert.Localization.message,
                                           onCancel: onCancel)
    }

    /// Present an alert with an action that links to device settings and cancel action.
    static func presentAlertWithLinkToOpenSettings(viewController: UIViewController,
                                                   title: String? = nil,
                                                   message: String? = nil,
                                                   onCancel: (() -> Void)? = nil) {
        let actionSheet = UIAlertController(title: title, message: message, preferredStyle: .alert)
        actionSheet.view.tintColor = .text

        actionSheet.addDefaultActionWithTitle(AlertWithLinkToOpenSettings.Localization.openSettings) { _ in
            AlertWithLinkToOpenSettings.openSettings()
        }

        actionSheet.addCancelActionWithTitle(AlertWithLinkToOpenSettings.Localization.cancel) { _ in
            onCancel?()
        }

        if let popoverController = actionSheet.popoverPresentationController {
            popoverController.sourceView = viewController.view
            popoverController.sourceRect = viewController.view.bounds
            popoverController.permittedArrowDirections = []
        }

        viewController.present(actionSheet, animated: true)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let window = UIApplication.shared.currentKeyWindow {
            popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
        }
    }
}

private enum ActionSheetStrings {
    static let message = NSLocalizedString("Are you sure you want to discard these changes?",
                                           comment: "Message title for Discard Changes Action Sheet")
    static let saveAsDraft = NSLocalizedString("Save as Draft",
                                               comment: "Button title to save a product as draft in Discard Changes Action Sheet")
    static let discard = NSLocalizedString("Discard changes",
                                          comment: "Button title Discard Changes in Discard Changes Action Sheet")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Button title Cancel in Discard Changes Action Sheet")
}

private enum AlertWithLinkToOpenSettings {
    enum Localization {
        static let openSettings = NSLocalizedString("Open Settings",
                                                    comment: "Button title to open device settings in an alert")
        static let cancel = NSLocalizedString("Cancel",
                                              comment: "Button title to cancel opening device settings in an alert")
    }

    static let openSettings: () -> Void = {
        guard let targetURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        UIApplication.shared.open(targetURL)
    }
}

private enum BarcodeScannerNoCameraPermissionAlert {
    enum Localization {
        static let title =
        NSLocalizedString("Allow camera access",
                          comment: "Title of alert that links to settings for camera access.")
        static let message =
        NSLocalizedString("Please change your camera permissions in device settings.",
                          comment: "Message of alert that links to settings for camera access.")
    }
}
