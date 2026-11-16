import Foundation

extension POSDialog {
    static func printReceiptFailure(_ failure: POSPrintReceiptFailure,
                                    selectAction: @escaping (POSPrintReceiptFailureAction) -> Void,
                                    close: @escaping () -> Void) -> POSDialog {
        POSDialog(icon: .exclamationMark,
                  title: failure.title,
                  message: failure.message,
                  primaryAction: .init(title: Localization.retryButton, action: { selectAction(.retry) }),
                  secondaryAction: .init(title: Localization.emailButton, action: { selectAction(.emailReceipt) }),
                  closeAction: .init(accessibilityLabel: Localization.closeButtonAccessibilityLabel, action: close))
    }
}

private enum Localization {
    static let retryButton = NSLocalizedString(
        "pos.printReceiptFailure.retryButton",
        value: "Retry",
        comment: "Button to print the receipt again from the POS print failure modal.")

    static let emailButton = NSLocalizedString(
        "pos.printReceiptFailure.emailButton",
        value: "Email receipt",
        comment: "Button to email the receipt instead of printing it, from the POS print failure modal.")

    static let closeButtonAccessibilityLabel = NSLocalizedString(
        "pos.printReceiptFailure.closeButton.accessibilityLabel",
        value: "Close",
        comment: "Accessibility label of the button that closes the POS print failure dialog.")
}
