import SwiftUI

struct PrePurchaseUpgradesErrorView: View {

    private let error: PrePurchaseError

    /// Closure invoked when the "Retry" button is tapped
    ///
    var onRetryButtonTapped: (() -> Void)

    init(_ error: PrePurchaseError,
         onRetryButtonTapped: @escaping (() -> Void)) {
        self.error = error
        self.onRetryButtonTapped = onRetryButtonTapped
    }

    var body: some View {
        VStack(alignment: .center, spacing: Layout.spacingBetweenImageAndText) {
            Image("plan-upgrade-error")
                .frame(maxWidth: .infinity, alignment: .center)
                .accessibilityHidden(true)

            VStack(alignment: .center, spacing: Layout.textSpacing) {
                switch error {
                case .fetchError, .entitlementsError:
                    VStack(alignment: .center) {
                        Text(Localization.fetchErrorMessage)
                            .bold()
                            .headlineStyle()
                            .multilineTextAlignment(.center)
                        Button(Localization.retry) {
                            onRetryButtonTapped()
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .fixedSize(horizontal: true, vertical: true)
                    }
                case .maximumSitesUpgraded:
                    Text(Localization.maximumSitesUpgradedErrorMessage)
                        .bold()
                        .headlineStyle()
                        .multilineTextAlignment(.center)
                    Text(Localization.maximumSitesUpgradedErrorSubtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                case .inAppPurchasesNotSupported:
                    Text(Localization.inAppPurchasesNotSupportedErrorMessage)
                        .bold()
                        .headlineStyle()
                        .multilineTextAlignment(.center)
                    Text(Localization.inAppPurchasesNotSupportedErrorSubtitle)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                case .userNotAllowedToUpgrade:
                    Text(Localization.unableToUpgradeText)
                        .bold()
                        .headlineStyle()
                        .multilineTextAlignment(.center)
                    Text(Localization.unableToUpgradeInstructions)
                        .font(.body)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(.horizontal, Layout.horizontalEdgesPadding)
        .padding(.vertical, Layout.verticalEdgesPadding)
        .background {
            RoundedRectangle(cornerSize: .init(width: Layout.cornerRadius, height: Layout.cornerRadius))
                .fill(Color(.secondarySystemGroupedBackground))
        }
    }
}

private extension PrePurchaseUpgradesErrorView {
    enum Layout {
        static let horizontalEdgesPadding: CGFloat = 16
        static let verticalEdgesPadding: CGFloat = 40
        static let cornerRadius: CGFloat = 12
        static let spacingBetweenImageAndText: CGFloat = 32
        static let textSpacing: CGFloat = 16
    }

    enum Localization {
        static let retry = NSLocalizedString(
            "Retry", comment: "Title of the button to attempt a retry when fetching or purchasing plans fails.")

        static let fetchErrorMessage = NSLocalizedString(
            "We encountered an error loading plan information", comment: "Error message displayed when " +
            "we're unable to fetch In-App Purchases plans from the server.")

        static let maximumSitesUpgradedErrorMessage = NSLocalizedString(
            "A WooCommerce app store subscription with your Apple ID already exists",
            comment: "Error message displayed when the merchant already has one store upgraded under the same Apple ID.")

        static let maximumSitesUpgradedErrorSubtitle = NSLocalizedString(
            "An Apple ID can only be used to upgrade one store",
            comment: "Subtitle message displayed when the merchant already has one store upgraded under the same Apple ID.")

        static let cancelUpgradeButtonText = NSLocalizedString(
            "Cancel Upgrade",
            comment: "Title of the button displayed when purchasing a plan fails, so the flow can be cancelled.")

        static let inAppPurchasesNotSupportedErrorMessage = NSLocalizedString(
            "In-App Purchases not supported",
            comment: "Error message displayed when In-App Purchases are not supported.")

        static let inAppPurchasesNotSupportedErrorSubtitle = NSLocalizedString(
            "Please contact support for assistance.",
            comment: "Subtitle message displayed when In-App Purchases are not supported, redirecting to contact support if needed.")

        static let unableToUpgradeText = NSLocalizedString(
            "You can’t upgrade because you are not the store owner",
            comment: "Text describing that is not possible to upgrade the site's plan.")

        static let unableToUpgradeInstructions = NSLocalizedString(
            "Please contact the store owner to upgrade your plan.",
            comment: "Text describing that only the site owner can upgrade the site's plan.")
    }
}
