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
    var isPayDisabled: Bool = false
    /// Drives the inline "Preparing Tap to Pay…" indicator. Set true while the
    /// silent pre-connect is still in flight (`POSPaymentModel.isPreparingTapToPay`).
    /// The CTA stays tappable — `startPaymentFlow` already handles a tap that
    /// arrives before the reader connects by waiting for the connection event.
    var isPreparing: Bool = false

    /// Delays the indicator's first appearance so the common fast-pre-connect
    /// case (sub-second) doesn't flash a spinner.
    private static let appearanceDelay: Duration = .milliseconds(700)
    /// If the pre-connect hasn't finished after this, give up showing the
    /// indicator. Stops it sitting forever when pre-connect silently fails
    /// (entitlement / Apple ToS / location-services edge cases the
    /// `.connectingFailed*` suppression on `POSPaymentModel` swallows).
    private static let timeout: Duration = .seconds(12)

    @State private var isIndicatorVisible: Bool = false

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
            // `isLoading` is gated on `isPayDisabled` rather than the broader
            // `isPayDisabled || isIndicatorVisible` below, so the in-button
            // spinner only shows during the "merchant just tapped, waiting for
            // Apple's TTP modal to open" gap. While the silent pre-connect
            // indicator is up the button is disabled (greyed) but the spinner
            // doesn't show — the inline "Preparing Tap to Pay…" text already
            // explains the wait there.
            .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isPayDisabled))
            .padding(.horizontal, POSPadding.medium)
            // Disabled while preparing only once the indicator becomes visible
            // (after the 700ms grace). Fast pre-connects therefore never flicker
            // the button into a disabled state, and slow pre-connects show the
            // disabled button alongside the "Preparing…" indicator that
            // explains why it's not tappable.
            .disabled(isPayDisabled || isIndicatorVisible)
            .accessibilityIdentifier("pos-tap-to-pay-hero-pay-button")

            preparingIndicator
        }
        .task(id: isPreparing) {
            await updateIndicatorVisibility()
        }
    }

    @ViewBuilder
    private var preparingIndicator: some View {
        HStack(spacing: POSSpacing.small) {
            ProgressView()
                .controlSize(.small)
            Text(Localization.preparing)
                .font(.posBodyMediumRegular())
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
        }
        .accessibilityElement(children: .combine)
        .opacity(isIndicatorVisible ? 1 : 0)
        .animation(.default, value: isIndicatorVisible)
        .accessibilityHidden(!isIndicatorVisible)
    }

    private func updateIndicatorVisibility() async {
        guard isPreparing else {
            isIndicatorVisible = false
            return
        }
        // Hold for the appearance delay; bail if pre-connect finished first.
        try? await Task.sleep(for: Self.appearanceDelay)
        guard !Task.isCancelled, isPreparing else { return }
        isIndicatorVisible = true
        // Auto-hide after the timeout so a silently failed pre-connect doesn't
        // leave the indicator sitting indefinitely.
        try? await Task.sleep(for: Self.timeout)
        guard !Task.isCancelled else { return }
        isIndicatorVisible = false
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
        static let preparing = NSLocalizedString(
            "pos.tapToPay.hero.preparing",
            value: "Preparing Tap to Pay…",
            comment: "Inline indicator shown under the Tap to Pay CTA while the silent reader pre-connect is in flight."
        )
    }
}

#if DEBUG
#Preview("Idle") {
    POSTapToPayHeroView(onPayTapped: {})
        .padding()
}

#Preview("Preparing") {
    POSTapToPayHeroView(onPayTapped: {}, isPreparing: true)
        .padding()
}
#endif
