import SwiftUI

struct POSRefundConfirmationView: View {
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let isProcessing: Bool
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

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
        .clipShape(RoundedRectangle(cornerRadius: POSRefundModalLayout.cornerRadius(for: horizontalSizeClass)))
        .frame(width: parentSize.width - (POSRefundModalLayout.horizontalPadding(for: horizontalSizeClass) * 2))
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
                .progressViewStyle(POSRefundModalLayout.progressViewStyle)
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
            comment: "Title for the refund confirmation modal. %@ is the formatted refund amount."
        )

        static let processingTitleFormat = NSLocalizedString(
            "pos.refundConfirmationView.processingTitleFormat",
            value: "Refunding %@",
            comment: "Title for the refund confirmation modal while processing. %@ is the formatted refund amount."
        )

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundConfirmationView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund confirmation modal"
        )

        static let confirmationMessageFormat = NSLocalizedString(
            "pos.refundConfirmationView.confirmationMessageFormat.1",
            value: "Are you sure you wish to refund %1$@ %2$@? This action cannot be undone.",
            comment: "Confirmation message for the refund. %1$@ is the formatted amount, %2$@ is the payment method description."
        )

        static let processingMessage = NSLocalizedString(
            "pos.refundConfirmationView.processingMessage",
            value: "Please wait while we process the refund.",
            comment: "Message shown while the refund is being processed."
        )

        static let confirmButton = NSLocalizedString(
            "pos.refundConfirmationView.confirmButton",
            value: "Yes, proceed",
            comment: "Button to confirm and process the refund"
        )

        static let backButton = NSLocalizedString(
            "pos.refundConfirmationView.backButton",
            value: "Back",
            comment: "Button to go back to the previous screen"
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
