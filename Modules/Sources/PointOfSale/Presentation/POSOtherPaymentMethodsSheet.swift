import SwiftUI

/// Bottom sheet shown when the merchant taps "Other payment methods" on phone POS checkout.
/// Lists secondary payment methods, keeping Card reader visible but disabled while Bluetooth is active.
struct POSOtherPaymentMethodsSheet: View {
    var isTapToPayAvailable: Bool = false
    var isTapToPayEnabled: Bool = true
    var onTapToPay: (() -> Void)?
    /// False while Bluetooth is already active for this payment.
    var isCardReaderEnabled: Bool = true
    let onCardReader: () -> Void
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
                    subtitle: isTapToPayEnabled ? Localization.tapToPaySubtitle : Localization.tapToPayDisabledSubtitle,
                    accessibilityIdentifier: "pos-other-payments-tap-to-pay",
                    isEnabled: isTapToPayEnabled) {
                    dismiss()
                    onTapToPay()
                }
            }

            row(systemImage: "creditcard",
                title: Localization.cardReaderTitle,
                subtitle: isCardReaderEnabled ? Localization.cardReaderSubtitle : Localization.cardReaderDisabledSubtitle,
                accessibilityIdentifier: "pos-other-payments-card-reader",
                isEnabled: isCardReaderEnabled) {
                dismiss()
                onCardReader()
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
                     isEnabled: Bool = true,
                     action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(alignment: .center, spacing: POSSpacing.medium) {
                Image(systemName: systemImage)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(isEnabled ? Color.posPrimary : Color.posOnSurfaceVariantLowest)
                    .frame(width: Constants.iconFrameWidth)

                VStack(alignment: .leading, spacing: POSSpacing.xSmall) {
                    Text(title)
                        .font(.posBodyMediumBold)
                        .foregroundStyle(isEnabled ? Color.posOnSurface : Color.posOnSurfaceVariantLowest)
                    Text(subtitle)
                        .font(.posBodySmallRegular())
                        .foregroundStyle(isEnabled ? Color.posOnSurfaceVariantHighest : Color.posOnSurfaceVariantLowest)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: POSSpacing.small)
            }
            .padding(POSPadding.medium)
            .frame(maxWidth: .infinity, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
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
        static let cardReaderTitle = NSLocalizedString(
            "pos.otherPaymentMethods.cardReader.title",
            value: "Card reader",
            comment: "Row title in the Other Payment Methods sheet for connecting an external Bluetooth card reader."
        )
        static let tapToPayTitle = NSLocalizedString(
            "pos.otherPaymentMethods.tapToPay.title",
            value: "Tap to Pay",
            comment: "Row title in the Other Payment Methods sheet for switching card payments to Tap to Pay."
        )
        static let tapToPaySubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.tapToPay.subtitle",
            value: "Use this iPhone to take card payments.",
            comment: "Row subtitle in the Other Payment Methods sheet for switching card payments to Tap to Pay."
        )
        static let tapToPayDisabledSubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.tapToPay.disabled.subtitle",
            value: "Tap to Pay is already selected for this payment.",
            comment: "Row subtitle in the Other Payment Methods sheet when Tap to Pay is disabled because it is already selected."
        )
        static let cardReaderSubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.cardReader.subtitle",
            value: "Connect a Bluetooth reader to take card payments.",
            comment: "Row subtitle in the Other Payment Methods sheet for connecting an external Bluetooth card reader."
        )
        static let cardReaderDisabledSubtitle = NSLocalizedString(
            "pos.otherPaymentMethods.cardReader.disabled.subtitle",
            value: "Card reader is already selected for this payment.",
            comment: "Row subtitle in the Other Payment Methods sheet when the external Bluetooth card reader option is disabled because it is already active."
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
        isTapToPayAvailable: true,
        onTapToPay: {},
        onCardReader: {},
        isScanToPayAvailable: true,
        onScanToPay: {},
        isMarkOrderAsPaidAvailable: true,
        onMarkOrderAsPaid: {}
    )
}

#Preview("Card reader disabled") {
    POSOtherPaymentMethodsSheet(
        isCardReaderEnabled: false,
        onCardReader: {},
        isScanToPayAvailable: true,
        onScanToPay: {},
        isMarkOrderAsPaidAvailable: true,
        onMarkOrderAsPaid: {}
    )
}
#endif
