import SwiftUI

/// Right-pane confirmation pushed when the merchant taps "Mark order as paid". Capturing an
/// optional free-form note here gives the merchant somewhere to record what the payment was
/// (e.g. "Bank transfer from Maria") so the order has reconciliation context in WP-Admin.
/// On confirm the host triggers the order update; on success the totals view shows the
/// `paymentSuccess` UI driven by `PointOfSaleMarkAsPaidState.paymentSuccess`.
struct PointOfSaleMarkAsPaidConfirmationView: View {
    let orderTotal: String
    let isProcessing: Bool
    let errorMessage: String?
    let onConfirm: (_ note: String?) -> Void
    let onCancel: () -> Void

    /// Optional merchant-supplied free-form note. Empty string is treated as nil downstream —
    /// see `trimmedNote`.
    @State private var note: String = ""
    @FocusState private var isNoteFieldFocused: Bool

    private var trimmedNote: String? {
        let trimmed = note.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? nil : trimmed
    }

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

            // Optional free-form note. Persisted as a private order note alongside the
            // mark-as-paid completion, giving the merchant reconciliation context in WP-Admin
            // (e.g. "Bank transfer from Maria"). Defaults to empty → no note is added and
            // behaviour matches the previous (note-less) flow exactly.
            VStack(alignment: .leading, spacing: POSSpacing.small) {
                Text(Localization.noteFieldLabel)
                    .font(.posBodySmallBold())
                    .foregroundColor(.posOnSurfaceVariantHighest)
                TextField(Localization.notePlaceholder,
                          text: $note,
                          axis: .vertical)
                    .lineLimit(2...4)
                    .font(.posBodyMediumRegular())
                    .focused($isNoteFieldFocused)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled(false)
                    .submitLabel(.done)
                    .onSubmit { isNoteFieldFocused = false }
                    .padding(POSPadding.medium)
                    .background(Color.posSurfaceContainerLow)
                    .cornerRadius(POSCornerRadiusStyle.small.value)
                    .disabled(isProcessing)
                    .accessibilityIdentifier("pos-mark-as-paid-note-field")
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if let errorMessage {
                Text(errorMessage)
                    .font(.posBodySmallRegular())
                    .foregroundColor(.posError)
                    .multilineTextAlignment(.center)
            }

            VStack(spacing: POSSpacing.small) {
                Button(action: { onConfirm(trimmedNote) }) {
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
            comment: "Title of the Point of Sale confirmation for manually marking an order as paid."
        )
        static let message = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.message",
            value: "This will mark the %1$@ order as completed. " +
            "Use this only if you've already collected payment another way.",
            comment: "Body of the Point of Sale confirmation for manually marking an order as paid. " +
            "%1$@ is the formatted order total, e.g. $24.99."
        )
        static let confirmButton = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.confirmButton",
            value: "Mark as paid",
            comment: "Confirmation button on the Point of Sale Mark as paid confirmation."
        )
        static let cancelButton = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.cancelButton",
            value: "Cancel",
            comment: "Cancel button on the Point of Sale Mark as paid confirmation."
        )
        static let noteFieldLabel = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.noteLabel",
            value: "Add a note (optional)",
            comment: "Label above the optional note text field on the Point of Sale Mark as paid confirmation, " +
            "where the merchant can record reconciliation context for the order."
        )
        static let notePlaceholder = NSLocalizedString(
            "pointOfSale.markAsPaid.confirmation.notePlaceholder",
            value: "e.g. Bank transfer from Maria, ref 4827",
            comment: "Placeholder shown inside the optional note text field on the Point of Sale Mark as paid confirmation."
        )
    }
}

#if DEBUG
#Preview("Idle") {
    PointOfSaleMarkAsPaidConfirmationView(
        orderTotal: "$24.99",
        isProcessing: false,
        errorMessage: nil,
        onConfirm: { _ in },
        onCancel: {}
    )
    .background(Color.posSurface)
}

#Preview("Processing") {
    PointOfSaleMarkAsPaidConfirmationView(
        orderTotal: "$24.99",
        isProcessing: true,
        errorMessage: nil,
        onConfirm: { _ in },
        onCancel: {}
    )
    .background(Color.posSurface)
}

#Preview("Error") {
    PointOfSaleMarkAsPaidConfirmationView(
        orderTotal: "$24.99",
        isProcessing: false,
        errorMessage: "Couldn't update the order. Try again.",
        onConfirm: { _ in },
        onCancel: {}
    )
    .background(Color.posSurface)
}
#endif
