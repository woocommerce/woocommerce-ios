import SwiftUI

/// Top-of-screen Tap to Pay promotion shown on the phone POS checkout when TTP is
/// available. Mirrors the Android phone POS layout (samiuelson / staskus): the
/// merchant's primary path is the big "Pay with Tap to pay" CTA; cash and the rest
/// of the methods live in a smaller two-button strip at the bottom of the totals
/// view (rendered separately by `TotalsView`).
struct POSTapToPayHeroView: View {
    let onPayTapped: () -> Void
    /// True between the merchant tapping the CTA and the payment state machine
    /// reacting. The button stays tappable on entry (silent pre-connect runs in
    /// the background — no visible indicator until the merchant taps), so this
    /// is purely double-tap protection. While true the illustration swaps to a
    /// spinner so the merchant gets immediate feedback that their tap landed,
    /// even when the pre-connect or PaymentIntent creation is still in flight.
    var isPayDisabled: Bool = false

    private static let illustrationSize: CGFloat = 96

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            illustration

            VStack(spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posHeadingBold)
                    .foregroundStyle(Color.posOnSurface)
                    .accessibilityAddTraits(.isHeader)

                Text(Localization.subtitle)
                    .font(.posBodyLargeRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, POSPadding.medium)

            Button(action: onPayTapped) {
                Text(Localization.payButton)
                    .font(POSFontStyle.posBodyLargeBold)
            }
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .padding(.horizontal, POSPadding.medium)
            .disabled(isPayDisabled)
            .accessibilityIdentifier("pos-tap-to-pay-hero-pay-button")
        }
    }

    /// Static SF Symbol normally, swapped to a `ProgressView` once the merchant
    /// taps the CTA. The placeholder illustration will get replaced with a real
    /// designer asset later; the spinner-on-tap behaviour stays the same once
    /// that lands.
    @ViewBuilder
    private var illustration: some View {
        if isPayDisabled {
            ProgressView()
                .controlSize(.extraLarge)
                .tint(Color.posPrimary)
                .frame(width: Self.illustrationSize, height: Self.illustrationSize)
                .accessibilityHidden(true)
        } else {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: Self.illustrationSize, weight: .regular))
                .foregroundStyle(Color.posPrimary)
                .accessibilityHidden(true)
        }
    }
}

private extension POSTapToPayHeroView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.tapToPay.hero.title",
            value: "Tap to pay",
            comment: "Title shown in the Tap to Pay hero on the POS checkout."
        )
        static let subtitle = NSLocalizedString(
            "pos.tapToPay.hero.subtitle",
            value: "Use this device to accept contactless card payments.",
            comment: "Subtitle shown in the Tap to Pay hero on the POS checkout."
        )
        static let payButton = NSLocalizedString(
            "pos.tapToPay.hero.payButton",
            value: "Pay with Tap to pay",
            comment: "Primary CTA shown in the Tap to Pay hero on the POS checkout."
        )
    }
}

#if DEBUG
#Preview("Idle") {
    POSTapToPayHeroView(onPayTapped: {})
        .padding()
}

#Preview("Tapped (loading)") {
    POSTapToPayHeroView(onPayTapped: {}, isPayDisabled: true)
        .padding()
}
#endif
