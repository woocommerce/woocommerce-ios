import Foundation

extension POSDialog {
    static func exitPOS(exit: @escaping () -> Void, close: @escaping () -> Void) -> POSDialog {
        POSDialog(title: Localization.exitTitle,
                  message: Localization.exitBody,
                  primaryAction: .init(title: Localization.exitButton,
                                       accessibilityIdentifier: "pos-exit-confirm-button",
                                       action: exit),
                  closeAction: .init(accessibilityLabel: Localization.closeButtonAccessibilityLabel,
                                     accessibilityIdentifier: "pos-exit-modal-close-button",
                                     action: close))
    }
}

private enum Localization {
    static let exitTitle = NSLocalizedString(
        "pos.exitPOSModal.exitTitle",
        value: "Exit Point of Sale mode?",
        comment: "Title of the exit Point of Sale modal alert"
    )
    static let exitBody = NSLocalizedString(
        "pos.exitPOSModal.exitBody",
        value: "Any orders in progress will be lost.",
        comment: "Body text of the exit Point of Sale modal alert"
    )
    static let exitButton = NSLocalizedString(
        "pos.exitPOSModal.exitButtom",
        value: "Exit",
        comment: "Button text of the exit Point of Sale modal alert"
    )
    static let closeButtonAccessibilityLabel = NSLocalizedString(
        "pos.exitPOSModal.closeButton.accessibilityLabel",
        value: "Close",
        comment: "Accessibility label for the button to close the exit Point of Sale modal alert."
    )
}
