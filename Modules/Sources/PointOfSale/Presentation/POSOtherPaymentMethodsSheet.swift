import SwiftUI

/// Bottom sheet shown when the merchant taps "Other payment methods" on the phone
/// POS checkout. Lists the non-primary payment methods available to the merchant
/// for the current screen state:
///
/// - On the TTP-available + no-reader-connected screen (paired with the TTP hero),
///   this lists Card reader, Scan to Pay, and Mark order as paid.
/// - On the TTP-available + BT-reader-connected screen, this lists only Scan to Pay
///   and Mark order as paid. The Card reader row is hidden because a reader is
///   already connected; Tap to Pay is hidden too because the iOS phone POS uses a
///   one-shot Bluetooth model — the BT session must finish (success / cancel /
///   abandonment) before the merchant returns to the TTP hero, where Tap to Pay
///   is the primary CTA again.
///
/// Mirrors the Android phone POS overflow dialog that pairs with the TTP hero
/// (samiuelson #15842 / #15825). The iOS layout deliberately diverges in one
/// respect: Android offers Tap to Pay as a sheet row during a BT session (lets
/// the merchant switch mid-flow); iOS does not (see commentary on the
/// `isTapToPayRowAvailableInOtherMethodsSheet` gate in `TotalsView`).
struct POSOtherPaymentMethodsSheet: View {
    /// True when the Card reader row should appear. Pass false when a reader is
    /// already connected — the "Connect a Bluetooth reader…" subtitle would
    /// mislead the merchant in that case.
    var isCardReaderAvailable: Bool = true
    let onCardReader: () -> Void
    /// True when the Tap to Pay row should appear. In the current one-shot
    /// Bluetooth model every caller passes `false`: on the TTP hero screen
    /// Tap to Pay is already the primary CTA above the sheet, and during a
    /// Bluetooth collection the iOS phone POS doesn't let the merchant
    /// switch methods mid-flow. Parameter kept on the API for symmetry with
    /// the other rows and to leave room if that policy ever changes.
    var isTapToPayAvailable: Bool = false
    var onTapToPay: (() -> Void)?
    var isScanToPayAvailable: Bool = false
    var onScanToPay: (() -> Void)?
    var isMarkOrderAsPaidAvailable: Bool = false
    var onMarkOrderAsPaid: (() -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundStyle(Color.posOnSurface)
                .padding(.horizontal, POSPadding.medium)
                .padding(.top, POSPadding.large)
                .padding(.bottom, POSPadding.medium)

            if isTapToPayAvailable, let onTapToPay {
                row(systemImage: "wave.3.right.circle",
                    title: Localization.tapToPayTitle,
                    subtitle: Localization.tapToPaySubtitle,
                    accessibilityIdentifier: "pos-other-payments-tap-to-pay") {
                    dismiss()
                    onTapToPay()
                }
            }

            if isCardReaderAvailable {
                row(systemImage: "creditcard",
                    title: Localization.cardReaderTitle,
                    subtitle: Localization.cardReaderSubtitle,
                    accessibilityIdentifier: "pos-other-payments-card-reader") {
                    dismiss()
                    onCardReader()
                }
            }

            if isScanToPayAvailable, let onScanToPay {
                row(systemImage: "qrcode",
                    title: Localization.scanToPayTitle,
                    subtitle: Localization.scanToPaySubtitle,
                    accessibilityIdentifier: "pos-other-payments-scan-to-pay") {
                    dismiss()
                    onScanToPay()
                }
            }

            if isMarkOrderAsPaidAvailable, let onMarkOrderAsPaid {
                row(systemImage: "checkmark.circle",
                    title: Localization.markAsPaidTitle,
                    subtitle: Localization.markAsPaidSubtitle,
                    accessibilityIdentifier: "pos-other-payments-mark-as-paid") {
                    dismiss()
                    onMarkOrderAsPaid()
                }
            }

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.posSurface)
    }

    @ViewBuilder
    private func row(systemImage: String,
                     title: String,
                     subtitle: String,
                     accessibilityIdentifier: String,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: POSSpacing.medium) {
                Image(systemName: systemImage)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posPrimary)
                    .frame(width: Constants.iconFrameWidth)

                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(title)
                        .font(.posBodyMediumBold)
                        .foregroundStyle(Color.posOnSurface)
                    Text(subtitle)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(Color.posOnSurfaceVariantHighest)
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

private extension POSOtherPaymentMethodsSheet {
    enum Constants {
        /// Fixed width for the leading icon in each payment method row. Not a
        /// POSSpacing token — it sizes the icon column, not a semantic gap.
        static let iconFrameWidth: CGFloat = 28
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.otherPaymentMethods.sheet.title",
            value: "Other payment methods",
            comment: "Title of the bottom sheet listing non-Tap-to-Pay payment methods on phone POS checkout."
        )
        static let tapToPayTitle = NSLocalizedString(
            "pos.otherPaymentMethods.tapToPay.title",
            value: "Tap to Pay on iPhone",
            comment: "Row title in the Other Payment Methods sheet for switching to Tap to Pay on iPhone. " +
                "\"Tap to Pay on iPhone\" is Apple's product name and must be capitalised exactly as shown."
        )
        static let tapToPaySubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.tapToPay.subtitle",
            value: "Use this device to accept contactless card payments.",
            comment: "Row subtitle in the Other Payment Methods sheet for switching to Tap to Pay on iPhone."
        )
        static let cardReaderTitle = NSLocalizedString(
            "pos.otherPaymentMethods.cardReader.title",
            value: "Card reader",
            comment: "Row title in the Other Payment Methods sheet for connecting an external Bluetooth card reader."
        )
        static let cardReaderSubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.cardReader.subtitle",
            value: "Connect a Bluetooth reader to take card payments.",
            comment: "Row subtitle in the Other Payment Methods sheet for connecting an external Bluetooth card reader."
        )
        static let scanToPayTitle = NSLocalizedString(
            "pos.otherPaymentMethods.scanToPay.title",
            value: "Scan to pay",
            comment: "Row title in the Other Payment Methods sheet for collecting payment via a QR code the customer scans."
        )
        static let scanToPaySubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.scanToPay.subtitle",
            value: "Show a QR code for the customer to pay from their phone.",
            comment: "Row subtitle in the Other Payment Methods sheet for collecting payment via a QR code the customer scans."
        )
        static let markAsPaidTitle = NSLocalizedString(
            "pos.otherPaymentMethods.markAsPaid.title",
            value: "Mark order as paid",
            comment: "Row title in the Other Payment Methods sheet for marking the order paid out-of-band."
        )
        static let markAsPaidSubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.markAsPaid.subtitle",
            value: "Record payment collected outside this device.",
            comment: "Row subtitle in the Other Payment Methods sheet for marking the order paid out-of-band."
        )
    }
}

#if DEBUG
#Preview("Card reader only") {
    POSOtherPaymentMethodsSheet(onCardReader: {})
}

#Preview("All methods enabled") {
    POSOtherPaymentMethodsSheet(
        onCardReader: {},
        isScanToPayAvailable: true,
        onScanToPay: {},
        isMarkOrderAsPaidAvailable: true,
        onMarkOrderAsPaid: {}
    )
}
#endif
