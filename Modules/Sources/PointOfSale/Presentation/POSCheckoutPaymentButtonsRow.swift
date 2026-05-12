import SwiftUI

/// Bottom-of-totals payment-method row.
///
/// Takes an ordered array of `POSCheckoutPaymentMethod` cases and renders the first as a
/// filled primary button, the rest as outlined secondary buttons. The TotalsView is
/// responsible for building the array (which methods, in which order) based on payment
/// state, reader connection, and feature-flag-gated availability — this view just paints.
///
/// Mirrors the Android `WooPosCheckoutPaymentButtons` composable. Lives in its own type
/// rather than being embedded in TotalsView so the array-driven layout is reviewable in
/// isolation as TTP and additional payment methods land in later parts.
struct POSCheckoutPaymentButtonsRow: View {
    let methods: [POSCheckoutPaymentMethod]
    let onSelect: (POSCheckoutPaymentMethod) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            ForEach(Array(methods.enumerated()), id: \.element) { index, method in
                button(for: method, isPrimary: index == 0)
            }
        }
        .padding(.horizontal, POSPadding.medium)
        // Match the cart button's bottom inset on phone so the row clears the home
        // indicator. iPad uses safeAreaPadding so the row hugs the side panel's bottom.
        .if(horizontalSizeClass == .compact) {
            $0.padding(.bottom, POSPadding.xxLarge)
        }
        .if(horizontalSizeClass != .compact) {
            $0.safeAreaPadding(.bottom, POSPadding.medium)
        }
    }

    @ViewBuilder
    private func button(for method: POSCheckoutPaymentMethod, isPrimary: Bool) -> some View {
        Button {
            onSelect(method)
        } label: {
            Text(title(for: method))
                .font(POSFontStyle.posBodyLargeBold)
        }
        .layoutPriority(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .if(isPrimary) {
            $0.buttonStyle(POSFilledButtonStyle(size: .normal))
        }
        .if(!isPrimary) {
            $0.buttonStyle(POSOutlinedButtonStyle(size: .normal))
        }
        .accessibilityIdentifier(accessibilityIdentifier(for: method))
    }

    private func title(for method: POSCheckoutPaymentMethod) -> String {
        switch method {
        case .tapToPay:
            return Localization.tapToPay
        case .cardReader:
            return Localization.cardReader
        case .cashPayment:
            return Localization.cashPayment
        }
    }

    private func accessibilityIdentifier(for method: POSCheckoutPaymentMethod) -> String {
        switch method {
        case .tapToPay:
            return "pos-tap-to-pay-button"
        case .cardReader:
            return "pos-card-reader-button"
        case .cashPayment:
            return "pos-cash-payment-button"
        }
    }
}

private extension POSCheckoutPaymentButtonsRow {
    enum Localization {
        static let tapToPay = NSLocalizedString(
            "pos.checkout.paymentMethod.tapToPay",
            value: "Tap to Pay",
            comment: "Title for the Tap to Pay button in the POS checkout payment-method row."
        )
        static let cardReader = NSLocalizedString(
            "pos.checkout.paymentMethod.cardReader",
            value: "Card reader",
            comment: "Title for the card-reader button in the POS checkout payment-method row. " +
                "Tapping it starts the connect-reader flow when no reader is connected."
        )
        static let cashPayment = NSLocalizedString(
            "pos.checkout.paymentMethod.cashPayment",
            value: "Cash payment",
            comment: "Title for the cash-payment button in the POS checkout payment-method row."
        )
    }
}

#if DEBUG
#Preview("Row — Cash only") {
    POSCheckoutPaymentButtonsRow(methods: [.cashPayment], onSelect: { _ in })
}

#Preview("Row — Card reader + Cash") {
    POSCheckoutPaymentButtonsRow(methods: [.cardReader, .cashPayment], onSelect: { _ in })
}

#Preview("Row — Tap to Pay + Card reader + Cash") {
    POSCheckoutPaymentButtonsRow(methods: [.tapToPay, .cardReader, .cashPayment], onSelect: { _ in })
}
#endif
