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

    /// Optional popover wiring for the `.otherPaymentMethods` button.
    ///
    /// When non-nil, the popover is anchored to that specific button — used on iPad where
    /// routing UI (picking which non-cash, non-card method to use) should attach to its
    /// trigger rather than take over the screen with a bottom sheet. Phone callers leave
    /// this nil and present a `POSOtherPaymentMethodsSheet` from the parent instead.
    ///
    /// The original iPad popover wiring was added by `024afec9f7` and lost in the phone
    /// POS Part 2 refactor (`8500620a69`); this restores it without touching the phone path.
    var otherPaymentMethodsPopover: OtherPaymentMethodsPopoverConfig?

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    /// Optional popover configuration for the `.otherPaymentMethods` button slot.
    /// Holds the presentation binding + the secondary-method action callbacks; the
    /// popover view itself is rebuilt per render so the gated flags can update.
    struct OtherPaymentMethodsPopoverConfig {
        let isPresented: Binding<Bool>
        let isScanToPayAvailable: Bool
        let isMarkOrderAsPaidAvailable: Bool
        let onScanToPay: () -> Void
        let onMarkOrderAsPaid: () -> Void
    }

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
                .font(.posBodyLargeBold)
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
        .if(shouldAttachOtherPaymentMethodsPopover(to: method)) { button in
            button.popover(
                isPresented: otherPaymentMethodsPopover!.isPresented,
                attachmentAnchor: .point(.top),
                arrowEdge: .bottom
            ) {
                PointOfSaleSecondaryPaymentMethodsPopover(
                    isScanToPayAvailable: otherPaymentMethodsPopover!.isScanToPayAvailable,
                    isMarkOrderAsPaidAvailable: otherPaymentMethodsPopover!.isMarkOrderAsPaidAvailable,
                    onScanToPay: otherPaymentMethodsPopover!.onScanToPay,
                    onMarkOrderAsPaid: otherPaymentMethodsPopover!.onMarkOrderAsPaid
                )
            }
        }
    }

    private func shouldAttachOtherPaymentMethodsPopover(to method: POSCheckoutPaymentMethod) -> Bool {
        method == .otherPaymentMethods && otherPaymentMethodsPopover != nil
    }

    private func title(for method: POSCheckoutPaymentMethod) -> String {
        POSCheckoutPaymentMethodLocalization.title(for: method)
    }

    private func accessibilityIdentifier(for method: POSCheckoutPaymentMethod) -> String {
        POSCheckoutPaymentMethodLocalization.accessibilityIdentifier(for: method)
    }
}

/// Shared title + accessibility-id lookups for `POSCheckoutPaymentMethod`. Consumed by
/// both `POSCheckoutPaymentButtonsRow` (card-enabled vertical stack) and
/// `POSCheckoutPromotedPaymentButtons` (no-card 1+2 layout) so the labels stay in sync.
enum POSCheckoutPaymentMethodLocalization {
    static func title(for method: POSCheckoutPaymentMethod) -> String {
        switch method {
        case .tapToPay:
            return tapToPay
        case .cardReader:
            return cardReader
        case .cashPayment:
            return cashPayment
        case .scanToPay:
            return scanToPay
        case .markOrderAsPaid:
            return markOrderAsPaid
        case .otherPaymentMethods:
            return otherPaymentMethods
        }
    }

    static func accessibilityIdentifier(for method: POSCheckoutPaymentMethod) -> String {
        switch method {
        case .tapToPay:
            return "pos-tap-to-pay-button"
        case .cardReader:
            return "pos-card-reader-button"
        case .cashPayment:
            return "pos-cash-payment-button"
        case .scanToPay:
            return "pos-scan-to-pay-button"
        case .markOrderAsPaid:
            return "pos-mark-order-as-paid-button"
        case .otherPaymentMethods:
            return "pos-other-payment-methods-button"
        }
    }

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
    static let scanToPay = NSLocalizedString(
        "pos.checkout.paymentMethod.scanToPay",
        value: "Scan to Pay",
        comment: "Title for the Scan to Pay (QR code) button in the POS checkout payment-method row."
    )
    static let markOrderAsPaid = NSLocalizedString(
        "pos.checkout.paymentMethod.markOrderAsPaid",
        value: "Mark order as paid",
        comment: "Title for the Mark-as-paid button in the POS checkout payment-method row."
    )
    static let otherPaymentMethods = NSLocalizedString(
        "pos.checkout.paymentMethod.otherPaymentMethods",
        value: "Other payment methods",
        comment: "Title for the button that opens the Other Payment Methods sheet (Scan to Pay, Mark order as paid) " +
            "in the POS checkout payment-method row on card-enabled stores."
    )
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
