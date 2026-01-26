import SwiftUI

struct POSRefundConfirmationView: View {
    let formattedRefundTotal: String
    let paymentMethodDescription: String
    let onClose: () -> Void
    let onConfirm: () -> Void
    let onBack: () -> Void

    @Environment(\.posModalParentSize) private var parentSize

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            headerView
            messageView
            buttonsSection
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
            Text(String(format: Localization.titleFormat, formattedRefundTotal))
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
        }
        .foregroundColor(Color.posOnSurface)
        .padding(POSPadding.xLarge)
    }

    var messageView: some View {
        Text(String(format: Localization.confirmationMessageFormat,
                    formattedRefundTotal,
                    paymentMethodDescription))
            .font(.posBodyLargeRegular())
            .foregroundColor(Color.posOnSurface)
            .multilineTextAlignment(.leading)
            .padding(.horizontal, POSPadding.xLarge)
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

        static let closeButtonAccessibilityLabel = NSLocalizedString(
            "pos.refundConfirmationView.closeButton.accessibilityLabel",
            value: "Close",
            comment: "Accessibility label for close button on refund confirmation modal"
        )

        static let confirmationMessageFormat = NSLocalizedString(
            "pos.refundConfirmationView.confirmationMessageFormat",
            value: "Are you sure you wish to process to refund %1$@ %2$@? This action cannot be undone.",
            comment: "Confirmation message for the refund. %1$@ is the formatted amount, %2$@ is the payment method description."
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
        onClose: {},
        onConfirm: {},
        onBack: {}
    )
    .environment(\.posModalParentSize, CGSize(width: 1192, height: 822))
}
#endif
