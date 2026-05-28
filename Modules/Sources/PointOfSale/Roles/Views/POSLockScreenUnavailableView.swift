import SwiftUI

/// Shown on the lock screen when the staff fetch hasn't succeeded yet and we have no cached
/// state to fall back on (cold install + no connectivity, or an auth/decode failure on the
/// first attempt). The retry button re-runs `session.refreshPINStatus()`; while a fetch is
/// in flight the parent renders a spinner instead of this view.
struct POSLockScreenUnavailableView: View {
    let onRetry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            Image(systemName: Constants.iconName)
                .font(.system(size: Constants.iconSize, weight: .regular))
                .foregroundStyle(Color.posOnSurfaceVariantHighest)
                .accessibilityHidden(true)

            VStack(spacing: POSSpacing.small) {
                Text(Localization.title)
                    .font(.posBodyLargeBold)
                    .foregroundStyle(Color.posOnSurface)
                    .multilineTextAlignment(.center)
                    .accessibilityAddTraits(.isHeader)

                Text(Localization.subtitle)
                    .font(.posBodyMediumRegular())
                    .foregroundStyle(Color.posOnSurfaceVariantHighest)
                    .multilineTextAlignment(.center)
            }

            Button(action: retryTapped) {
                Text(Localization.retry)
                    .font(.posBodyMediumBold)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, POSPadding.medium)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color.posPrimary)
            .disabled(isRetrying)
            .accessibilityLabel(Localization.retry)
        }
        .padding(POSPadding.large)
        .frame(maxWidth: Constants.maxWidth)
    }

    private func retryTapped() {
        guard !isRetrying else { return }
        isRetrying = true
        Task {
            await onRetry()
            isRetrying = false
        }
    }
}

private extension POSLockScreenUnavailableView {
    enum Constants {
        static let iconName = "wifi.exclamationmark"
        static let iconSize: CGFloat = 48
        static let maxWidth: CGFloat = 360
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.lockScreen.unavailable.title",
            value: "Can't load staff",
            comment: "Title shown on the POS lock screen when the staff list can't be loaded."
        )
        static let subtitle = NSLocalizedString(
            "pos.lockScreen.unavailable.subtitle",
            value: "Check your connection and try again.",
            comment: "Subtitle shown on the POS lock screen when the staff list can't be loaded."
        )
        static let retry = NSLocalizedString(
            "pos.lockScreen.unavailable.retry",
            value: "Try Again",
            comment: "Button label on the POS lock screen to retry loading the staff list."
        )
    }
}

#if DEBUG
#Preview("Unavailable") {
    POSLockScreenUnavailableView(onRetry: {})
        .padding()
        .background(Color.posSurfaceContainerLow)
}
#endif
