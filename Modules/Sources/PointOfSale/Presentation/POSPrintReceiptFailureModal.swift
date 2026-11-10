import SwiftUI

/// Tells the merchant why a receipt didn't print and offers Retry or Email receipt.
struct POSPrintReceiptFailureModal: View {
    @Environment(\.posMetrics) private var metrics
    let failure: POSPrintReceiptFailure
    let selectAction: (POSPrintReceiptFailureAction) -> Void
    let close: () -> Void
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        if horizontalSizeClass == .compact {
            compactBody
        } else {
            regularBody
        }
    }

    /// The phone dialog has no close button: a tap outside closes it, like the other POS dialogs.
    private var compactBody: some View {
        POSConfirmationDialog(title: failure.title,
                              message: failure.message,
                              primaryButton: retryButton,
                              secondaryButton: emailButton)
    }

    private var regularBody: some View {
        VStack(spacing: metrics.spacing.xLarge) {
            Spacer()

            POSErrorExclamationMark(size: .large)

            VStack(spacing: metrics.spacing.small) {
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

            POSFlowButtonsView(configuration: .init(primaryButton: retryButton, secondaryButton: emailButton))
        }
        .posModalCloseButton(action: close)
        .posModalSizing()
    }

    private var retryButton: PointOfSaleFlowButtonConfiguration.ButtonConfig {
        .init(title: Localization.retryButton, action: { selectAction(.retry) })
    }

    private var emailButton: PointOfSaleFlowButtonConfiguration.ButtonConfig {
        .init(title: Localization.emailButton, action: { selectAction(.emailReceipt) })
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
