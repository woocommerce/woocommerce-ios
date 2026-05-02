import SwiftUI

/// Bottom sheet listing the long-tail POS payment methods that don't deserve a top-level button.
///
/// Each row dismisses the sheet first, then triggers the corresponding action so the parent view
/// can present its own UI (QR code, confirmation alert, etc.) without fighting the sheet.
struct PointOfSaleOtherPaymentMethodsSheet: View {
    let onScanToPay: () -> Void
    let onMarkAsPaid: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.medium) {
            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundColor(.posOnSurface)
                .accessibilityAddTraits(.isHeader)

            Text(Localization.subtitle)
                .font(.posBodyMediumRegular())
                .foregroundColor(.posOnSurfaceVariantHighest)

            VStack(spacing: POSSpacing.small) {
                // Scan to Pay is always enabled — the order is promoted to `.pending` on tap so
                // the payment URL is populated lazily. The QR view falls back gracefully if the
                // promotion fails.
                methodRow(systemImage: "qrcode",
                          title: Localization.scanToPayTitle,
                          subtitle: Localization.scanToPaySubtitle,
                          accessibilityIdentifier: "pos-other-payments-scan-to-pay") {
                    dismiss()
                    onScanToPay()
                }

                methodRow(systemImage: "checkmark.circle",
                          title: Localization.markAsPaidTitle,
                          subtitle: Localization.markAsPaidSubtitle,
                          accessibilityIdentifier: "pos-other-payments-mark-as-paid") {
                    dismiss()
                    onMarkAsPaid()
                }
            }
        }
        .padding(POSPadding.large)
        // iPad's default sheet is bigger than this content; without explicit alignment the
        // SwiftUI runtime centers the VStack vertically, leaving a tall blank gutter above
        // the title. Pin to the top instead.
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    }

    @ViewBuilder
    private func methodRow(systemImage: String,
                           title: String,
                           subtitle: String,
                           accessibilityIdentifier: String,
                           action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: POSSpacing.medium) {
                Image(systemName: systemImage)
                    .font(.posBodyLargeBold)
                    .foregroundColor(.posPrimary)
                    .frame(width: 32, alignment: .center)

                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(title)
                        .font(.posBodyLargeBold)
                        .foregroundColor(.posOnSurface)
                    Text(subtitle)
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posOnSurfaceVariantHighest)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: POSSpacing.medium)

                Image(systemName: "chevron.right")
                    .font(.posBodyMediumRegular())
                    .foregroundColor(.posOnSurfaceVariantHighest)
            }
            .padding(.vertical, POSPadding.medium)
            .padding(.horizontal, POSPadding.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityElement(children: .combine)
        .accessibilityHint(subtitle)
    }
}

private extension PointOfSaleOtherPaymentMethodsSheet {
    enum Localization {
        static let title = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.title",
            value: "Other payment methods",
            comment: "Title of the bottom sheet listing additional Point of Sale payment options."
        )
        static let subtitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.subtitle",
            value: "Choose how the customer is paying for this order.",
            comment: "Subtitle on the Point of Sale Other Payment Methods sheet."
        )
        static let scanToPayTitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.scanToPay.title",
            value: "Scan to Pay",
            comment: "Row title in the Other Payment Methods sheet for the QR-based scan-to-pay flow."
        )
        static let scanToPaySubtitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.scanToPay.subtitle",
            value: "Show a QR code for the customer to pay from their phone.",
            comment: "Row subtitle in the Other Payment Methods sheet for the QR-based scan-to-pay flow."
        )
        static let markAsPaidTitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.markAsPaid.title",
            value: "Mark order as paid",
            comment: "Row title in the Other Payment Methods sheet for manually marking an order as paid."
        )
        static let markAsPaidSubtitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.markAsPaid.subtitle",
            value: "Use when payment was already collected another way.",
            comment: "Row subtitle in the Other Payment Methods sheet for manually marking an order as paid."
        )
    }
}

#if DEBUG
#Preview {
    PointOfSaleOtherPaymentMethodsSheet(
        onScanToPay: {},
        onMarkAsPaid: {}
    )
    .background(Color.posSurface)
}
#endif
