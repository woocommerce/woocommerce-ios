import SwiftUI

/// Bottom sheet listing the long-tail POS payment methods that don't deserve a top-level button.
///
/// Each row dismisses the sheet first, then triggers the corresponding action so the parent view
/// can present its own UI (QR code, confirmation alert, etc.) without fighting the sheet.
///
/// Each row is gated by its own feature flag — when both flags are off, the entire sheet is
/// dead code and the parent view's "Other payment methods" button is hidden.
struct PointOfSaleOtherPaymentMethodsSheet: View {
    let isScanToPayAvailable: Bool
    let isMarkOrderAsPaidAvailable: Bool
    let onScanToPay: () -> Void
    let onMarkOrderAsPaid: () -> Void

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
                if isScanToPayAvailable {
                    methodRow(systemImage: "qrcode",
                              title: Localization.scanToPayTitle,
                              subtitle: Localization.scanToPaySubtitle,
                              accessibilityIdentifier: "pos-other-payments-scan-to-pay") {
                        dismiss()
                        onScanToPay()
                    }
                }

                if isMarkOrderAsPaidAvailable {
                    methodRow(systemImage: "checkmark.circle",
                              title: Localization.markOrderAsPaidTitle,
                              subtitle: Localization.markOrderAsPaidSubtitle,
                              accessibilityIdentifier: "pos-other-payments-mark-order-as-paid") {
                        dismiss()
                        onMarkOrderAsPaid()
                    }
                }
            }
        }
        .padding(POSPadding.large)
        // iPad's default sheet is taller than this content; without explicit alignment SwiftUI
        // centers the VStack vertically, leaving a tall blank gutter above the title.
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
        static let markOrderAsPaidTitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.markOrderAsPaid.title",
            value: "Mark order as paid",
            comment: "Row title in the Other Payment Methods sheet for manually marking an order as paid."
        )
        static let markOrderAsPaidSubtitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.markOrderAsPaid.subtitle",
            value: "Use when payment was already collected another way.",
            comment: "Row subtitle in the Other Payment Methods sheet for manually marking an order as paid."
        )
    }
}

#if DEBUG
#Preview("Both rows") {
    PointOfSaleOtherPaymentMethodsSheet(
        isScanToPayAvailable: true,
        isMarkOrderAsPaidAvailable: true,
        onScanToPay: {},
        onMarkOrderAsPaid: {}
    )
    .background(Color.posSurface)
}

#Preview("Only Scan to Pay") {
    PointOfSaleOtherPaymentMethodsSheet(
        isScanToPayAvailable: true,
        isMarkOrderAsPaidAvailable: false,
        onScanToPay: {},
        onMarkOrderAsPaid: {}
    )
    .background(Color.posSurface)
}

#Preview("Only Mark order as paid") {
    PointOfSaleOtherPaymentMethodsSheet(
        isScanToPayAvailable: false,
        isMarkOrderAsPaidAvailable: true,
        onScanToPay: {},
        onMarkOrderAsPaid: {}
    )
    .background(Color.posSurface)
}
#endif
