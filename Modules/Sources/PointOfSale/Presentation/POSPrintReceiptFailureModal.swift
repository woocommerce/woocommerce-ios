import SwiftUI

/// Tells the merchant why a receipt didn't print and offers Retry or Email receipt.
struct POSPrintReceiptFailureModal: View {
    let failure: POSPrintReceiptFailure
    let selectAction: (POSPrintReceiptFailureAction) -> Void
    let close: () -> Void

    var body: some View {
        VStack(spacing: POSSpacing.xLarge) {
            Spacer()

            POSErrorExclamationMark()

            VStack(spacing: POSSpacing.small) {
                Text(failure.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(failure.message)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurface)
            }
            .multilineTextAlignment(.center)

            Spacer()

            POSFlowButtonsView(configuration: .init(
                primaryButton: .init(title: Localization.retryButton,
                                     accessibilityIdentifier: "pos-print-failure-retry-button",
                                     action: { selectAction(.retry) }),
                secondaryButton: .init(title: Localization.emailButton,
                                       accessibilityIdentifier: "pos-print-failure-email-button",
                                       action: { selectAction(.emailReceipt) })))
        }
        .posModalCloseButton(action: close)
        .posModalSizing(fullScreenWhenCompact: true)
    }
}

private extension POSPrintReceiptFailureModal {
    enum Localization {
        static let retryButton = NSLocalizedString(
            "pos.printReceiptFailure.retryButton",
            value: "Retry",
            comment: "Button to print the receipt again from the POS print failure modal.")

        static let emailButton = NSLocalizedString(
            "pos.printReceiptFailure.emailButton",
            value: "Email receipt",
            comment: "Button to email the receipt instead of printing it, from the POS print failure modal.")
    }
}

#if DEBUG
#Preview("Paper empty") {
    POSPrintReceiptFailureModal(failure: .paperEmpty, selectAction: { _ in }, close: {})
        .posPreviewModalParentSize()
}

#Preview("Printer offline") {
    POSPrintReceiptFailureModal(failure: .printerOffline, selectAction: { _ in }, close: {})
        .posPreviewModalParentSize()
}
#endif
