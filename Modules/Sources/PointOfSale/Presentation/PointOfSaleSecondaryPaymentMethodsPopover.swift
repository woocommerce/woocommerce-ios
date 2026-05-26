import SwiftUI

/// Compact popover anchored to the "Other payment methods" button on the totals view.
///
/// Replaces `PointOfSaleOtherPaymentMethodsSheet` (a bottom sheet) for the routing decision —
/// picking which non-cash, non-card method to use is *navigation*, not a self-contained task,
/// and HIG flags routing UI as a poor fit for sheets. A popover anchored to the trigger button:
///
/// - keeps the right-pane context visible (the merchant doesn't lose sight of the order total)
/// - dismisses on outside tap without the modal-stack optics of "sheet → confirmation"
/// - scales naturally on iPad in landscape, which is POS's only supported configuration
///
/// Each row is gated by its own feature flag — when both flags are off, the entire popover is
/// dead code and the parent view's "Other payment methods" button is hidden.
struct PointOfSaleSecondaryPaymentMethodsPopover: View {
    let isScanToPayAvailable: Bool
    let isMarkOrderAsPaidAvailable: Bool
    let onScanToPay: () -> Void
    let onMarkOrderAsPaid: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
            if isScanToPayAvailable {
                methodRow(systemImage: "qrcode",
                          title: Localization.scanToPayTitle,
                          subtitle: Localization.scanToPaySubtitle,
                          accessibilityIdentifier: "pos-other-payments-scan-to-pay") {
                    dismiss()
                    onScanToPay()
                }
            }

            if isScanToPayAvailable && isMarkOrderAsPaidAvailable {
                Divider().overlay(Color.posOutlineVariant)
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
        .padding(POSPadding.small)
        // Popovers on iPad let us size to content. Cap the width so long subtitles wrap rather
        // than stretching across the whole pane.
        .frame(width: 360)
        .presentationCompactAdaptation(.popover)
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
                    .frame(width: 28, alignment: .center)

                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(title)
                        .font(.posBodyMediumBold)
                        .foregroundColor(.posOnSurface)
                    Text(subtitle)
                        .font(.posBodySmallRegular())
                        .foregroundColor(.posOnSurfaceVariantHighest)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: POSSpacing.small)
            }
            .padding(POSPadding.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(accessibilityIdentifier)
        .accessibilityElement(children: .combine)
        .accessibilityHint(subtitle)
    }
}

private extension PointOfSaleSecondaryPaymentMethodsPopover {
    enum Localization {
        static let scanToPayTitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.scanToPay.title",
            value: "Scan to Pay",
            comment: "Row title in the Other Payment Methods popover for the QR-based scan-to-pay flow."
        )
        static let scanToPaySubtitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.scanToPay.subtitle",
            value: "Show a QR code for the customer to pay from their phone.",
            comment: "Row subtitle in the Other Payment Methods popover for the QR-based scan-to-pay flow."
        )
        static let markOrderAsPaidTitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.markOrderAsPaid.title",
            value: "Mark order as paid",
            comment: "Row title in the Other Payment Methods popover for manually marking an order as paid."
        )
        static let markOrderAsPaidSubtitle = NSLocalizedString(
            "pointOfSale.otherPaymentMethods.markOrderAsPaid.subtitle",
            value: "Use when payment was already collected another way.",
            comment: "Row subtitle in the Other Payment Methods popover for manually marking an order as paid."
        )
    }
}

#if DEBUG
#Preview("Both rows") {
    PointOfSaleSecondaryPaymentMethodsPopover(
        isScanToPayAvailable: true,
        isMarkOrderAsPaidAvailable: true,
        onScanToPay: {},
        onMarkOrderAsPaid: {}
    )
    .background(Color.posSurface)
}

#Preview("Only Scan to Pay") {
    PointOfSaleSecondaryPaymentMethodsPopover(
        isScanToPayAvailable: true,
        isMarkOrderAsPaidAvailable: false,
        onScanToPay: {},
        onMarkOrderAsPaid: {}
    )
    .background(Color.posSurface)
}

#Preview("Only Mark order as paid") {
    PointOfSaleSecondaryPaymentMethodsPopover(
        isScanToPayAvailable: false,
        isMarkOrderAsPaidAvailable: true,
        onScanToPay: {},
        onMarkOrderAsPaid: {}
    )
    .background(Color.posSurface)
}
#endif
