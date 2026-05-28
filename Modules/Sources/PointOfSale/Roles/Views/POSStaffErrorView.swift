import SwiftUI

/// Shown by the POS entry point when the staff fetch hasn't succeeded yet and we have no
/// cached state to fall back on (cold install + no connectivity, or an auth/decode failure
/// on the first attempt). Sibling to the dashboard, not part of the lock-screen overlay -
/// the lock screen only renders when we know there is a PIN to enter.
///
/// The retry button re-runs `accessSession.refreshPINStatus()` via the entry point's
/// wrapper, which toggles `isStaffRefreshing` so the parent re-derives its startup state.
/// While a retry is in flight the parent renders `PointOfSaleLoadingView` instead of this
/// view.
struct POSStaffErrorView: View {
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

private extension POSStaffErrorView {
    enum Constants {
        static let iconName = "wifi.exclamationmark"
        static let iconSize: CGFloat = 48
        static let maxWidth: CGFloat = 360
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.staffError.title",
            value: "Can't load staff",
            comment: "Title shown when the POS staff list can't be loaded."
        )
        static let subtitle = NSLocalizedString(
            "pos.staffError.subtitle",
            value: "Check your connection and try again.",
            comment: "Subtitle shown when the POS staff list can't be loaded."
        )
        static let retry = NSLocalizedString(
            "pos.staffError.retry",
            value: "Try Again",
            comment: "Button label to retry loading the POS staff list."
        )
    }
}

#if DEBUG
#Preview("Staff error") {
    POSStaffErrorView(onRetry: {})
        .padding()
        .background(Color.posSurface)
}
#endif
