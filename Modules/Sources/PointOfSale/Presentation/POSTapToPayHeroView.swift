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
    /// is purely double-tap protection. While true the button renders its
    /// built-in `isLoading` spinner so the merchant gets immediate feedback
    /// that their tap landed, even when the pre-connect or PaymentIntent
    /// creation is still in flight.
    var isPayDisabled: Bool = false

    private static let illustrationSize: CGFloat = 96

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: Self.illustrationSize, weight: .regular))
                .foregroundStyle(Color.posPrimary)
                .accessibilityHidden(true)

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
            .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isPayDisabled))
            .padding(.horizontal, POSPadding.medium)
            .disabled(isPayDisabled)
            .accessibilityIdentifier("pos-tap-to-pay-hero-pay-button")
        }
    }
}

private extension POSTapToPayHeroView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.tapToPay.hero.title.v2",
            value: "Tap to Pay on iPhone",
            comment: "Title shown in the Tap to Pay on iPhone hero on the POS checkout. " +
                "\"Tap to Pay on iPhone\" is Apple's product name and must be capitalised exactly as shown."
        )
        static let subtitle = NSLocalizedString(
            "pos.tapToPay.hero.subtitle",
            value: "Use this device to accept contactless card payments.",
            comment: "Subtitle shown in the Tap to Pay on iPhone hero on the POS checkout."
        )
        static let payButton = NSLocalizedString(
            "pos.tapToPay.hero.payButton.v2",
            value: "Pay with Tap to Pay",
            comment: "Primary CTA shown in the Tap to Pay on iPhone hero on the POS checkout. " +
                "The full product name \"Tap to Pay on iPhone\" appears in the hero title above, " +
                "so the CTA uses the shortened form \"Tap to Pay\" — Apple's branding guidelines " +
                "permit this once the full name has been shown on the same screen."
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
