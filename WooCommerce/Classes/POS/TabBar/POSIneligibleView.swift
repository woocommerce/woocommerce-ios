import SwiftUI

/// A view that displays when the Point of Sale (POS) feature is not available for the current store.
/// Shows the specific reason why POS is ineligible and provides a button to re-check eligibility.
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

                Text(suggestionText)
                    .font(POSFontStyle.posCaptionRegular.font())
                    .multilineTextAlignment(.center)
                    .foregroundColor(Color.posOnSurface)

                Button {
                    Task { @MainActor in
                        do {
                            isLoading = true
                            try await onRefresh()
                            isLoading = false
                        } catch {
                            // TODO: WOOMOB-720 - handle error if needed, e.g., show an error message
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
                                     value: "POS requires a newer version of iOS 17 and above.",
                                     comment: "Ineligible reason: iOS version too low")
        case .unsupportedWooCommerceVersion:
            return NSLocalizedString("pos.ineligible.reason.unsupportedWooCommerceVersion",
                                     value: "Please update WooCommerce plugin to use POS.",
                                     comment: "Ineligible reason: WooCommerce version too low")
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
        case .siteSettingsNotAvailable:
            return NSLocalizedString("pos.ineligible.reason.siteSettingsNotAvailable",
                                     value: "Unable to load store settings for POS.",
                                     comment: "Ineligible reason: site settings unavailable")
        case .featureFlagDisabled:
            return NSLocalizedString("pos.ineligible.reason.featureFlagDisabled",
                                     value: "POS feature is currently disabled.",
                                     comment: "Ineligible reason: feature flag disabled")
        case .selfDeallocated:
            return Localization.defaultReason
        }
    }

    private var suggestionText: String {
        switch reason {
        case .notTablet:
            return NSLocalizedString("pos.ineligible.suggestion.notTablet",
                                     value: "Please use an iPad to access POS features.",
                                     comment: "Suggestion for not tablet: use iPad")
        case .unsupportedIOSVersion:
            return NSLocalizedString("pos.ineligible.suggestion.unsupportedIOSVersion",
                                     value: "Update your device to iOS 17 or later in Settings > General > Software Update.",
                                     comment: "Suggestion for unsupported iOS version: update iOS")
        case .unsupportedWooCommerceVersion:
            return NSLocalizedString("pos.ineligible.suggestion.unsupportedWooCommerceVersion",
                                     value: "Go to your WordPress admin and update WooCommerce to the latest version.",
                                     comment: "Suggestion for unsupported WooCommerce version: update plugin")
        case .wooCommercePluginNotFound:
            return NSLocalizedString("pos.ineligible.suggestion.wooCommercePluginNotFound",
                                     value: "Install and activate the WooCommerce plugin from your WordPress admin.",
                                     comment: "Suggestion for missing WooCommerce plugin: install plugin")
        case .featureSwitchDisabled:
            return NSLocalizedString("pos.ineligible.suggestion.featureSwitchDisabled",
                                     value: "Enable the POS feature from your WordPress admin under WooCommerce settings > Advanced > Features.",
                                     comment: "Suggestion for disabled feature switch: enable feature in WooCommerce settings")
        case .featureSwitchSyncFailure:
            return NSLocalizedString("pos.ineligible.suggestion.featureSwitchSyncFailure",
                                     value: "Try relaunching the app or check your internet connection and try again.",
                                     comment: "Suggestion for feature switch sync failure: relaunch or check connection")
        case .unsupportedCountry:
            // TODO: DI countries
            return NSLocalizedString("pos.ineligible.suggestion.unsupportedCountry",
                                     value: "POS is currently only available in select countries. Check back later for availability in your region.",
                                     comment: "Suggestion for unsupported country: check back later")
        case .unsupportedCurrency:
            // TODO: DI currencies
            return NSLocalizedString("pos.ineligible.suggestion.unsupportedCurrency",
                                     value: "Change your store's currency to USD, EUR, GBP, or CAD in WooCommerce settings.",
                                     comment: "Suggestion for unsupported currency: change currency")
        case .siteSettingsNotAvailable:
            return NSLocalizedString("pos.ineligible.suggestion.siteSettingsNotAvailable",
                                     value: "Check your internet connection and try relaunching the app. If the issue persists, please contact support.",
                                     comment: "Suggestion for site settings unavailable: check connection or contact support")
        case .featureFlagDisabled:
            return NSLocalizedString("pos.ineligible.suggestion.featureFlagDisabled",
                                     value: "POS is currently disabled.",
                                     comment: "Suggestion for disabled feature flag: notify that POS is disabled remotely")
        case .selfDeallocated:
            return NSLocalizedString("pos.ineligible.suggestion.selfDeallocated",
                                     value: "Try relaunching the app to resolve this issue.",
                                     comment: "Suggestion for self deallocated: relaunch")
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
        reason: .unsupportedCurrency,
        onRefresh: {}
    )
}
