import SwiftUI

struct POSRefundConfirmationView: View {
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let isProcessing: Bool
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            messageView
            if isProcessing {
                loadingSection
            } else {
                buttonsSection
            }
        }
        .background(Color.posSurfaceBright)
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding * 2))
    }
}

// MARK: - Subviews

private extension POSRefundConfirmationView {
    var headerView: some View {
        HStack {
            Text(String(format: isProcessing ? Localization.processingTitleFormat : Localization.titleFormat, formattedRefundTotal))
                .font(.posHeadingBold)
                .dynamicTypeSize(...DynamicTypeSize.accessibility2)
                .lineLimit(1)
            Spacer()
            Button {
                onClose()
            } label: {
                Text(Image(systemName: "xmark"))
                    .font(.posButtonSymbolLarge)
            }
            .accessibilityLabel(Localization.closeButtonAccessibilityLabel)
            .disabled(isProcessing)
            .opacity(isProcessing ? 0.5 : 1.0)
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var messageView: some View {
        Text(isProcessing
             ? Localization.processingMessage
             : String(format: Localization.confirmationMessageFormat,
                      formattedRefundTotal,
                      paymentMethodDescription))
            .font(.posBodyLargeRegular())
            .foregroundColor(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, POSPadding.xLarge)
    }

    var loadingSection: some View {
        VStack {
            ProgressView()
                .progressViewStyle(POSProgressViewStyle(size: 64, lineWidth: 20))
        }
        .frame(maxWidth: .infinity)
        .padding(POSPadding.xLarge)
    }

    var buttonsSection: some View {
        VStack(spacing: POSSpacing.medium) {
            Button(Localization.confirmButton, action: onConfirm)
                .buttonStyle(POSFilledButtonStyle(size: .normal))

            Button(Localization.backButton, action: onBack)
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .padding(POSPadding.xLarge)
    }
}

// MARK: - Localization

private extension POSRefundConfirmationView {
    enum Localization {
        static let titleFormat = NSLocalizedString(
            "pos.refundConfirmationView.titleFormat",
            value: "Refund %@",
            comment: "This text appears as the title of a refund confirmation modal dialog in a point-of-sale app, where %@ is replaced with the formatted refund amount (e.g., 'Refund $25.99'). It serves as the header text that users see when confirming a refund transaction."
        )

        static let processingTitleFormat = NSLocalizedString(
            "pos.refundConfirmationView.processingTitleFormat",
            value: "Refunding %@",
            comment: "Title for the refund confirmation modal while processing. %@ is the formatted refund amount."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundConfirmationView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "This is the accessibility label for a close button on the refund confirmation modal in the point-of-sale system. The label helps screen readers and other assistive technologies identify the button's purpose for users with disabilities."
        )

        static let confirmationMessageFormat = NSLocalizedString(
            "pos.refundConfirmationView.confirmationMessageFormat",
            value: "Are you sure you wish to process to refund %1$@ %2$@? This action cannot be undone.",
            comment: "Confirmation message displayed in a modal dialog when a user attempts to process a refund in the point-of-sale system. The message warns that the refund action is irreversible and includes placeholders for the refund amount (%1$@) and payment method (%2$@)."
        )

        static let processingMessage = NSLocalizedString(
            "pos.refundConfirmationView.processingMessage",
            value: "Please wait while we process the refund.",
            comment: "Message shown while the refund is being processed."
        )

        static let confirmButton = NSLocalizedString(
            "pos.refundConfirmationView.confirmButton",
            value: "Yes, proceed",
            comment: "This is the label for a confirmation button in the Point of Sale refund confirmation modal that appears when a user wants to process a refund. When tapped, it confirms and processes the refund transaction which cannot be undone."
        )

        static let backButton = NSLocalizedString(
            "pos.refundConfirmationView.backButton",
            value: "Back",
            comment: "Button label that appears on the refund confirmation modal in the Point of Sale system, allowing users to navigate back to the previous screen without proceeding with the refund action."
        )
    }
}

#if DEBUG
#Preview("POSRefundConfirmationView") {
    POSRefundConfirmationView(
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "via payment card ••••1456",
        isProcessing: false,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}

#Preview("POSRefundConfirmationView - Processing") {
    POSRefundConfirmationView(
        formattedRefundTotal: "$132.60",
        paymentMethodDescription: "via payment card ••••1456",
        isProcessing: true,
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
