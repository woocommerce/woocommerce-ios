import SwiftUI

struct POSIneligibleView: View {
    let reason: POSIneligibleReason
    let onRefresh: () async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.large) {
            HStack {
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Text(Image(systemName: "xmark"))
                        .font(POSFontStyle.posButtonSymbolLarge.font())
                }
                .foregroundColor(Color.posOnSurfaceVariantLowest)
            }

            Spacer()

            VStack(spacing: POSSpacing.medium) {
                Image(PointOfSaleAssets.exclamationMark.imageName)
                    .resizable()
                    .frame(width: POSErrorAndAlertIconSize.large.dimension,
                           height: POSErrorAndAlertIconSize.large.dimension)

                Text(reasonText)
                    .font(POSFontStyle.posHeadingBold.font())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.posOnSurface)

                Button {
                    Task { @MainActor in
                        do {
                            isLoading = true
                            try await onRefresh()
                            isLoading = false
                        } catch {
                            // TODO-jc: handle error if needed, e.g., show an error message
                            print("Error refreshing eligibility: \(error)")
                            isLoading = false
                        }
                    }
                } label: {
                    Text(Localization.refreshEligibility)
                }
                .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))
            }

            Spacer()
        }
        .padding(POSPadding.large)
    }

    private var reasonText: String {
        switch reason {
        case .notTablet:
            return NSLocalizedString("pos.ineligible.reason.notTablet",
                                     value: "POS is only available on iPad.",
                                     comment: "Ineligible reason: not a tablet")
        case .unsupportedIOSVersion:
            return NSLocalizedString("pos.ineligible.reason.unsupportedIOSVersion",
                                     value: "POS requires a newer version of iOS.",
                                     comment: "Ineligible reason: iOS version too low")
        case .unsupportedWooCommerceVersion:
            return NSLocalizedString("pos.ineligible.reason.unsupportedWooCommerceVersion",
                                     value: "Please update WooCommerce to use POS.",
                                     comment: "Ineligible reason: WooCommerce version too low")
        case .systemInformationNotAvailable:
            return NSLocalizedString("pos.ineligible.reason.systemInformationNotAvailable",
                                     value: "System information is not available.",
                                     comment: "Ineligible reason: system info missing")
        case .wooCommercePluginNotFound:
            return NSLocalizedString("pos.ineligible.reason.wooCommercePluginNotFound",
                                     value: "WooCommerce plugin not found.",
                                     comment: "Ineligible reason: plugin missing")
        case .featureSwitchDisabled:
            return NSLocalizedString("pos.ineligible.reason.featureSwitchDisabled",
                                     value: "POS feature is not enabled for your store.",
                                     comment: "Ineligible reason: feature switch off")
        case .featureSwitchSyncFailure:
            return NSLocalizedString("pos.ineligible.reason.featureSwitchSyncFailure",
                                     value: "Could not verify POS feature status.",
                                     comment: "Ineligible reason: feature switch sync failed")
        case .unsupportedCountry:
            return NSLocalizedString("pos.ineligible.reason.unsupportedCountry",
                                     value: "POS is not available in your country.",
                                     comment: "Ineligible reason: country not supported")
        case .unsupportedCurrency:
            return NSLocalizedString("pos.ineligible.reason.unsupportedCurrency",
                                     value: "POS is not available for your store's currency.",
                                     comment: "Ineligible reason: currency not supported")
        case .selfDeallocated:
            return Localization.defaultReason
        }
    }
}

private extension POSIneligibleView {
    enum Localization {
        static let refreshEligibility = NSLocalizedString(
            "pos.ineligible.refresh.button.title",
            value: "Check Eligibility Again",
            comment: "Button title to refresh POS eligibility check"
        )

        /// Default message shown when POS eligibility reason is not available.
        static let defaultReason = NSLocalizedString(
            "pos.ineligible.default.reason",
            value: "Your store is not eligible for POS at this time.",
            comment: "Default message shown when POS eligibility reason is not available"
        )
    }
}

#Preview {
    POSIneligibleView(
        reason: .unsupportedCountry,
        onRefresh: {}
    )
}
