import SwiftUI

/// Top-of-screen Tap to Pay promotion shown on the phone POS checkout when TTP is
/// available. Mirrors the Android phone POS layout (samiuelson / staskus): the
/// merchant's primary path is the big "Pay with Tap to pay" CTA; cash and the rest
/// of the methods live in a smaller two-button strip at the bottom of the totals
/// view (rendered separately by `TotalsView`).
///
/// Idle-state visual only for now. Preparing / collecting / success / error states
/// are still handled by the existing `POSCardPaymentContentView` modal flow until
/// they're folded into a richer hero in a follow-up commit.
struct POSTapToPayHeroView: View {
    let onPayTapped: () -> Void

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            // Placeholder illustration — the Android design uses a layered cards
            // graphic; the matching iOS asset will swap in here once design provides
            // it. Using an SF Symbol keeps the layout shaped correctly in the meantime.
            Image(systemName: "wave.3.right.circle.fill")
                .font(.system(size: 96, weight: .regular))
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
            .buttonStyle(POSFilledButtonStyle(size: .normal))
            .padding(.horizontal, POSPadding.medium)
            .accessibilityIdentifier("pos-tap-to-pay-hero-pay-button")
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
#Preview {
    POSTapToPayHeroView(onPayTapped: {})
        .padding()
}
#endif
