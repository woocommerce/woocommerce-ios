import SwiftUI

/// Bottom-of-totals payment-method layout used when card-present payments are
/// **not** available in the store's country (no external readers, no Tap to Pay).
///
/// Renders the first method as a full-width filled primary button on row 1, and
/// the remaining (up to three more) as outlined peer buttons inline on row 2.
/// Up to four buttons fit comfortably side-by-side, so the row scales with the
/// number of secondary methods feature-flagged on.
///
/// `TotalsView` builds the input array — typically `[.cashPayment, .scanToPay,
/// .markOrderAsPaid]` filtered by feature flags — and this view just paints.
///
/// Mirrors the Android promoted-no-card layout described in the POS all-countries
/// plan. Distinct from `POSCheckoutPaymentButtonsRow` (vertical stack), which is
/// still used for card-enabled stores where TTP / Card Reader / Cash live side-by-
/// side or stacked depending on idiom.
struct POSCheckoutPromotedPaymentButtons: View {
    let methods: [POSCheckoutPaymentMethod]
    let onSelect: (POSCheckoutPaymentMethod) -> Void

    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    var body: some View {
        VStack(spacing: POSSpacing.medium) {
            if let primary = methods.first {
                primaryButton(for: primary)
            }

            let secondaries = Array(methods.dropFirst())
            if !secondaries.isEmpty {
                HStack(spacing: POSSpacing.medium) {
                    ForEach(secondaries, id: \.self) { method in
                        secondaryButton(for: method)
                    }
                }
            }
        }
        .padding(.horizontal, POSPadding.medium)
        .if(horizontalSizeClass == .compact) {
            $0.padding(.bottom, POSPadding.xxLarge)
        }
        .if(horizontalSizeClass != .compact) {
            $0.safeAreaPadding(.bottom, POSPadding.medium)
        }
    }

    private func primaryButton(for method: POSCheckoutPaymentMethod) -> some View {
        Button {
            onSelect(method)
        } label: {
            Text(POSCheckoutPaymentMethodLocalization.title(for: method))
                .font(.posBodyLargeBold)
                .frame(maxWidth: .infinity)
        }
        .layoutPriority(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .buttonStyle(POSFilledButtonStyle(size: .normal))
        .accessibilityIdentifier(POSCheckoutPaymentMethodLocalization.accessibilityIdentifier(for: method))
    }

    private func secondaryButton(for method: POSCheckoutPaymentMethod) -> some View {
        Button {
            onSelect(method)
        } label: {
            Text(POSCheckoutPaymentMethodLocalization.title(for: method))
                .font(.posBodyLargeBold)
                .frame(maxWidth: .infinity)
        }
        .layoutPriority(1)
        .dynamicTypeSize(...DynamicTypeSize.accessibility1)
        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
        .accessibilityIdentifier(POSCheckoutPaymentMethodLocalization.accessibilityIdentifier(for: method))
    }
}

#if DEBUG
#Preview("Promoted — Cash only") {
    POSCheckoutPromotedPaymentButtons(methods: [.cashPayment], onSelect: { _ in })
}

#Preview("Promoted — Cash + Scan to Pay") {
    POSCheckoutPromotedPaymentButtons(methods: [.cashPayment, .scanToPay], onSelect: { _ in })
}

#Preview("Promoted — Cash + Mark as paid") {
    POSCheckoutPromotedPaymentButtons(methods: [.cashPayment, .markOrderAsPaid], onSelect: { _ in })
}

#Preview("Promoted — Cash + Scan + Mark") {
    POSCheckoutPromotedPaymentButtons(
        methods: [.cashPayment, .scanToPay, .markOrderAsPaid],
        onSelect: { _ in }
    )
}
#endif
