import SwiftUI

struct PurchaseUpgradeErrorView: View {
    let error: PurchaseUpgradeError
    let primaryAction: (() -> Void)?
    let secondaryAction: (() -> Void)
    let getSupportAction: (() -> Void)

    var body: some View {
        VStack {
            ScrollView(.vertical) {
                VStack(alignment: .leading, spacing: Layout.spacing) {
                    Image(systemName: "exclamationmark.circle")
                        .font(.system(size: Layout.exclamationImageSize))
                        .foregroundColor(.withColorStudio(name: .red, shade: .shade20))
                        .accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: Layout.textSpacing) {
                        Text(error.localizedTitle)
                            .font(.title)
                            .fontWeight(.bold)
                        Text(error.localizedDescription)
                        Text(error.localizedActionDirection)
                            .font(.title3)
                            .fontWeight(.bold)
                        if let actionHint = error.localizedActionHint {
                            Text(actionHint)
                                .font(.footnote)
                        }
                        if let errorCode = error.localizedErrorCode {
                            Text(String(format: Localization.errorCodeFormat, errorCode))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                        Button(action: getSupportAction) {
                            HStack {
                                Image(systemName: "questionmark.circle")
                                    .font(.body.weight(.semibold))
                                    .foregroundColor(.withColorStudio(name: .blue, shade: .shade50))
                                Text(Localization.getSupport)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.withColorStudio(name: .blue, shade: .shade50))
                            }
                        }
                    }
                }
                .padding(.top, Layout.topPadding)
                .padding(.horizontal, Layout.horizontalPadding)
            }

            Spacer()

            if let primaryButtonTitle = error.localizedPrimaryButtonLabel {
                Button(primaryButtonTitle) {
                    primaryAction?()
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, Layout.horizontalPadding)
            }

            Button(error.localizedSecondaryButtonTitle) {
                secondaryAction()
            }
            .buttonStyle(SecondaryButtonStyle())
            .padding(.horizontal, Layout.horizontalPadding)
        }
        .padding(.bottom)
    }
}

private extension PurchaseUpgradeErrorView {
    enum Layout {
        static let exclamationImageSize: CGFloat = 56
        static let horizontalPadding: CGFloat = 16
        static let topPadding: CGFloat = 80
        static let spacing: CGFloat = 40
        static let textSpacing: CGFloat = 16
    }

    enum Localization {
        static let getSupport = NSLocalizedString(
            "Get support",
            comment: "Button title to allow merchants to open the support screens when there's an error with their plan purchase")
        static let errorCodeFormat = NSLocalizedString(
            "Error code %1$@",
            comment: "A string shown on the error screen when there's an issue purchasing a plan, to inform the user " +
            "of the error code for use with Support. %1$@ will be replaced with the error code and must be included " +
            "in the translations.")
    }
}

private extension PurchaseUpgradeError {
    var localizedTitle: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorTitle
        case .planActivationFailed:
            return Localization.activationErrorTitle
        case .unknown:
            return Localization.unknownErrorTitle
        }
    }

    var localizedDescription: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorDescription
        case .planActivationFailed:
            return Localization.activationErrorDescription
        case .unknown:
            return Localization.unknownErrorDescription
        }
    }

    var localizedActionDirection: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorActionDirection
        case .planActivationFailed, .unknown:
            return Localization.errorContactSupportActionDirection
        }
    }

    var localizedActionHint: String? {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.purchaseErrorActionHint
        case .planActivationFailed:
            return nil
        case .unknown:
            return nil
        }
    }

    var localizedErrorCode: String? {
        switch self {
        case .inAppPurchaseFailed(_, let underlyingError), .planActivationFailed(let underlyingError):
            return underlyingError.errorCode
        case .unknown:
            return nil
        }
    }

    var localizedPrimaryButtonLabel: String? {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.retryPaymentButtonText
        case .planActivationFailed:
            return nil
        case .unknown:
            return nil
        }
    }

    var localizedSecondaryButtonTitle: String {
        switch self {
        case .inAppPurchaseFailed:
            return Localization.cancelUpgradeButtonText
        case .planActivationFailed, .unknown:
            return Localization.returnToMyStoreButtonText
        }
    }

    private enum Localization {
        /// Purchase errors
        static let purchaseErrorTitle = NSLocalizedString(
            "Error confirming payment",
            comment: "Error message displayed when a payment fails when attempting to purchase a plan.")

        static let purchaseErrorDescription = NSLocalizedString(
            "We encountered an error confirming your payment.",
            comment: "Error description displayed when a payment fails when attempting to purchase a plan.")

        static let purchaseErrorActionDirection = NSLocalizedString(
            "No payment has been taken",
            comment: "Bolded message confirming that no payment has been taken when the upgrade failed.")

        static let purchaseErrorActionHint = NSLocalizedString(
            "Please try again, or contact support for assistance",
            comment: "Subtitle message displayed when the merchant already has one store upgraded under the same Apple ID.")

        static let retryPaymentButtonText = NSLocalizedString(
            "Try Payment Again",
            comment: "Title of the button displayed when purchasing a plan fails, so the merchant can try again.")

        static let cancelUpgradeButtonText = NSLocalizedString(
            "Cancel Upgrade",
            comment: "Title of the secondary button displayed when purchasing a plan fails, so the merchant can exit the flow.")

        /// Upgrade errors
        static let activationErrorTitle = NSLocalizedString(
            "Error activating plan",
            comment: "Error message displayed when plan activation fails after purchasing a plan.")

        static let activationErrorDescription = NSLocalizedString(
            "Your subscription is active, but there was an error activating the plan on your store.",
            comment: "Error description displayed when plan activation fails after purchasing a plan.")

        static let errorContactSupportActionDirection = NSLocalizedString(
            "Please contact support for assistance.",
            comment: "Bolded message advising the merchant to contact support when the plan activation failed.")

        static let returnToMyStoreButtonText = NSLocalizedString(
            "Return to My Store",
            comment: "Title of the secondary button displayed when activating the purchased plan fails, so the merchant can exit the flow.")

        /// Unknown errors
        static let unknownErrorTitle = NSLocalizedString(
            "Error during purchase",
            comment: "Title of an unknown error after purchasing a plan")

        static let unknownErrorDescription = NSLocalizedString(
            "Something went wrong during your purchase, and we can't tell whether your payment has completed, or your store plan been upgraded.",
            comment: "Description of an unknown error after purchasing a plan")
    }
}
