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
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.view.tintColor = .text

        let openSettingsAction = UIAlertAction(title: AlertWithLinkToOpenSettings.Localization.openSettings, style: .default) { _ in
            AlertWithLinkToOpenSettings.openSettings()
        }
        alert.addAction(openSettingsAction)
        alert.preferredAction = openSettingsAction

        alert.addCancelActionWithTitle(AlertWithLinkToOpenSettings.Localization.cancel) { _ in
            onCancel?()
        }

        viewController.present(alert, animated: true)
    }

    open override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        if let window = view.window {
            popoverPresentationController?.sourceRect = CGRect(x: window.bounds.midX, y: window.bounds.midY, width: 0, height: 0)
        }
    }

    static func presentExpiredWPComPlanAlert(from viewController: UIViewController,
                                             onDismiss: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: ExpiredWPComPlanAlert.title,
                                                message: ExpiredWPComPlanAlert.message,
                                                preferredStyle: .alert)
        let action = UIAlertAction(title: ExpiredWPComPlanAlert.dismiss, style: .default) { _ in
            onDismiss?()
        }
        alertController.addAction(action)
        viewController.present(alertController, animated: true)
    }

    /// Unfinished App Password alert.
    ///
    static func presentUnfinishedApplicationPasswordAlert(from viewController: UIViewController, onExit: @escaping () -> Void) {
        let alertController = UIAlertController(title: UnfinishedApplicationPasswordAlert.title, message: nil, preferredStyle: .alert)
        let action = UIAlertAction(title: UnfinishedApplicationPasswordAlert.exit, style: .destructive) { _ in
            onExit()
        }
        alertController.addAction(action)
        alertController.addCancelActionWithTitle(ActionSheetStrings.cancel)
        viewController.present(alertController, animated: true)
    }
}

private enum ActionSheetStrings {
    static let message = NSLocalizedString("Are you sure you want to discard these changes?",
                                           comment: "This text appears as the confirmation message in an alert dialog that prompts users when they attempt to close or exit a screen with unsaved changes, asking them to confirm whether they want to discard their modifications.")
    static let saveAsDraft = NSLocalizedString("Save as Draft",
                                               comment: "Button title to save a product as draft in Discard Changes Action Sheet")
    static let discard = NSLocalizedString("Discard changes",
                                          comment: "Button title Discard Changes in Discard Changes Action Sheet")
    static let cancel = NSLocalizedString("Cancel",
                                          comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
}

private enum AlertWithLinkToOpenSettings {
    enum Localization {
        static let openSettings = NSLocalizedString("Open Settings",
                                                    comment: "Button title to open device settings in an alert")
        static let cancel = NSLocalizedString("Cancel",
                                              comment: "Button text used to dismiss action sheets, web views, and modal screens in authentication flows, including the store picker screen, Jetpack setup, and site credential login screens.")
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
                          comment: "This text appears as the title of an alert dialog that prompts users to enable camera permissions when they attempt to use barcode scanning functionality but camera access has been denied.")
        static let message =
        NSLocalizedString("Camera access is required for barcode scanning. " +
                          "Please enable camera permissions in your device settings",
                          comment: "Message of alert that links to settings for camera access.")
    }
}

private enum ExpiredWPComPlanAlert {
    static let title = NSLocalizedString("Site plan expired", comment: "Title of the expired WPCom plan alert")
    static let message = NSLocalizedString(
        "We have paused your store. You can purchase another plan by logging in to WordPress.com on your browser.",
        comment: "Message on the expired WPCom plan alert"
    )
    static let dismiss = NSLocalizedString("OK", comment: "Button to dismiss expired WPCom plan alert")
}

private enum UnfinishedApplicationPasswordAlert {
    static let title = NSLocalizedString("It seems that you have not approved the app connection yet. Are you sure you want to exit?",
                                         comment: "Title for the unfinished application password alert")
    static let exit = NSLocalizedString("Exit Anyway", comment: "Button to exit the application password flow.")
}
