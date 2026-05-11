import SwiftUI

/// Bottom sheet shown when the merchant taps "Other payment methods" on the phone
/// POS checkout (TTP-available layout). Lists the non-TTP payment methods available
/// to the merchant — currently Card reader only; Scan to Pay and Mark order as paid
/// will join here once those features land on this branch.
///
/// Mirrors the Android phone POS overflow dialog that pairs with the TTP hero
/// (samiuelson #15842 / #15825).
struct POSOtherPaymentMethodsSheet: View {
    let onCardReader: () -> Void

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(alignment: .leading, spacing: POSSpacing.none) {
            Text(Localization.title)
                .font(.posHeadingBold)
                .foregroundStyle(Color.posOnSurface)
                .padding(.horizontal, POSPadding.medium)
                .padding(.top, POSPadding.large)
                .padding(.bottom, POSPadding.medium)

            row(systemImage: "creditcard",
                title: Localization.cardReaderTitle,
                subtitle: Localization.cardReaderSubtitle,
                accessibilityIdentifier: "pos-other-payments-card-reader") {
                dismiss()
                onCardReader()
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
    }
}

#if DEBUG
#Preview {
    POSOtherPaymentMethodsSheet(onCardReader: {})
}
#endif
