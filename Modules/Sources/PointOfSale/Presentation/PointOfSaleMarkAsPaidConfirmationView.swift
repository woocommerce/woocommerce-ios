import SwiftUI

/// Confirmation alert shown when the merchant taps "Mark order as paid".
/// Stays inline (modal over the totals view); on confirm it triggers the order update,
/// transitions to `.processing`, and on success the totals view shows the paymentSuccess UI.
struct PointOfSaleMarkAsPaidConfirmationView: View {
    let orderTotal: String
    let isProcessing: Bool
    let errorMessage: String?
    let onConfirm: () -> Void
    let onCancel: () -> Void

    var body: some View {
        VStack(alignment: .center, spacing: POSSpacing.medium) {
            Image(systemName: "checkmark.circle")
                .font(.system(size: 36))
                .foregroundColor(.posPrimary)

            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .multilineTextAlignment(.center)
                .accessibilityAddTraits(.isHeader)

            Text(String.localizedStringWithFormat(Localization.message, orderTotal))
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)
                .multilineTextAlignment(.center)

            if let errorMessage {
                Text(errorMessage)
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posError)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: POSSpacing.small) {
                Button(action: onConfirm) {
                    Text(Localization.confirmButton)
                        .font(POSFontStyle.posBodyLargeBold)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isProcessing))
                .disabled(isProcessing)
                .accessibilityIdentifier("pos-mark-as-paid-confirm-button")

                Button(action: onCancel) {
                    Text(Localization.cancelButton)
                        .font(POSFontStyle.posBodyLargeBold)
                }
                .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                .disabled(isProcessing)
                .accessibilityIdentifier("pos-mark-as-paid-cancel-button")
            }
            .frame(maxWidth: .infinity)
        }
        .padding(POSPadding.large)
        .frame(maxWidth: 480)
    }
}

private extension PointOfSaleMarkAsPaidConfirmationView {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.title",
            value: "Mark order as paid?",
            comment: "Title of the Point of Sale confirmation alert for manually marking an order as paid."
        )
        static let message = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.message",
            value: "This will mark the %1$@ order as completed. " +
            "Use this only if you've already collected payment another way.",
            comment: "Body of the Point of Sale confirmation alert for manually marking an order as paid. " +
            "%1$@ is the formatted order total, e.g. $24.99."
        )
        static let confirmButton = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.confirmButton",
            value: "Mark as paid",
            comment: "Confirmation button on the Point of Sale Mark as paid confirmation alert."
        )
        static let cancelButton = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.cancelButton",
            value: "Cancel",
            comment: "Cancel button on the Point of Sale Mark as paid confirmation alert."
        )
    }
}

#if DEBUG
#Preview {
    PointOfSaleMarkAsPaidConfirmationView(
        orderTotal: "$24.99",
        isProcessing: false,
        errorMessage: nil,
        onConfirm: {},
        onCancel: {}
    )
    .background(Color.posSurface)
}

#Preview("Processing") {
    PointOfSaleMarkAsPaidConfirmationView(
        orderTotal: "$24.99",
        isProcessing: true,
        errorMessage: nil,
        onConfirm: {},
        onCancel: {}
    )
    .background(Color.posSurface)
}

#Preview("Error") {
    PointOfSaleMarkAsPaidConfirmationView(
        orderTotal: "$24.99",
        isProcessing: false,
        errorMessage: "Couldn't update the order. Try again.",
        onConfirm: {},
        onCancel: {}
    )
    .background(Color.posSurface)
}
#endif
