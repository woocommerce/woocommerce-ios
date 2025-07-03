import SwiftUI

/// A view that displays when the Point of Sale (POS) feature is not available for the current store.
/// Shows the specific reason why POS is ineligible and provides a button to re-check eligibility.
@available(iOS 17.0, *)
struct POSIneligibleView: View {
    let reason: POSIneligibleReason
    let onRefresh: () async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading: Bool = false

    var body: some View {
        VStack(spacing: POSSpacing.none) {
            Spacer()

            VStack(alignment: .center, spacing: POSSpacing.none) {
                Image(PointOfSaleAssets.exclamationMark.imageName)
                    .resizable()
                    .frame(width: POSErrorAndAlertIconSize.large.dimension,
                           height: POSErrorAndAlertIconSize.large.dimension)

                Spacer()
                    .frame(height: POSSpacing.medium)

                VStack(spacing: POSSpacing.small) {
                    Text(Localization.title)
                        .font(POSFontStyle.posHeadingBold.font())
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.posOnSurface)

                    Text(suggestionText)
                        .font(POSFontStyle.posBodyLargeRegular().font())
                        .multilineTextAlignment(.center)
                        .foregroundColor(Color.posOnSurface)
                }
                .containerRelativeFrame(.horizontal) { length, _ in
                    max(length * 0.5, 300)
                }

                Spacer()
                    .frame(height: POSSpacing.large)

                VStack(spacing: POSSpacing.medium) {
                    Button {
                        Task { @MainActor in
                            do {
                                isLoading = true
                                try await onRefresh()
                                isLoading = false
                            } catch {
                                // TODO: WOOMOB-720 - handle error if needed, e.g., show an error message
                                DDLogError("Error refreshing eligibility: \(error)")
                                isLoading = false
                            }
                        }
                    } label: {
                        Text(Localization.refreshEligibility)
                    }
                    .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))

                    Button {
                        dismiss()
                    } label: {
                        Text(Localization.dismiss)
                    }
                    .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                }
                .containerRelativeFrame(.horizontal) { length, _ in
                    max(length * 0.5 - 132, 300)
                }
            }

            Spacer()
        }
        .padding(POSPadding.large)
    }

    private var suggestionText: String {
        switch reason {
        case .notTablet:
            return NSLocalizedString("pos.ineligible.suggestion.notTablet",
                                     value: "Please use a tablet to access POS features.",
                                     comment: "Suggestion for not tablet: use iPad")
        case .unsupportedIOSVersion:
            return NSLocalizedString("pos.ineligible.suggestion.unsupportedIOSVersion",
                                     value: "Point of Sale requires iOS 17 or later. Please update your device to iOS 17+ to use this feature.",
                                     comment: "Suggestion for unsupported iOS version: update iOS")
        case let .unsupportedWooCommerceVersion(minimumVersion):
            let format = NSLocalizedString("pos.ineligible.suggestion.unsupportedWooCommerceVersion",
                                     value: "Your WooCommerce version is not supported. " +
                                     "The POS system requires WooCommerce version %1$@ or above. Please update WooCommerce to the latest version.",
                                     comment: "Suggestion for unsupported WooCommerce version: update plugin. " +
                                     "%1$@ is a placeholder for the minimum required version.")
            return String.localizedStringWithFormat(format, minimumVersion)
        case .wooCommercePluginNotFound:
            return NSLocalizedString("pos.ineligible.suggestion.wooCommercePluginNotFound",
                                     value: "Install and activate the WooCommerce plugin from your WordPress admin.",
                                     comment: "Suggestion for missing WooCommerce plugin: install plugin")
        case .featureSwitchDisabled:
            return NSLocalizedString("pos.ineligible.suggestion.featureSwitchDisabled",
                                     value: "Point of Sale must be enabled to proceed. " +
                                     "Please enable the POS feature from your WordPress admin under WooCommerce settings > Advanced > Features.",
                                     comment: "Suggestion for disabled feature switch: enable feature in WooCommerce settings")
        case .featureSwitchSyncFailure:
            return NSLocalizedString("pos.ineligible.suggestion.featureSwitchSyncFailure",
                                     value: "Try relaunching the app or check your internet connection and try again.",
                                     comment: "Suggestion for feature switch sync failure: relaunch or check connection")
        case let .unsupportedCountry(supportedCountries):
            let countryNames = supportedCountries.map { $0.readableCountry }
            let formattedCountryList = ListFormatter.localizedString(byJoining: countryNames)
            let format = NSLocalizedString(
                "pos.ineligible.suggestion.unsupportedCountry",
                value: "POS is currently only available in %1$@. Check back later for availability in your region.",
                comment: "Suggestion for unsupported country with list of supported countries. " +
                "%1$@ is a placeholder for the localized list of supported country names."
            )
            return String.localizedStringWithFormat(format, formattedCountryList)
        case let .unsupportedCurrency(supportedCurrencies):
            let currencyList = supportedCurrencies.map { $0.rawValue }
            let formattedCurrencyList = ListFormatter.localizedString(byJoining: currencyList)
            let format = NSLocalizedString(
                "pos.ineligible.suggestion.unsupportedCurrency",
                value: "The POS system is not available for your store’s currency. It currently supports only %1$@. " +
                "Please check your store currency settings or contact support for assistance.",
                comment: "Suggestion for unsupported currency with list of supported currencies. " +
                "%1$@ is a placeholder for the localized list of supported currency codes."
            )
            return String.localizedStringWithFormat(format, formattedCurrencyList)
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

@available(iOS 17.0, *)
private extension POSIneligibleView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.ineligible.title",
            value: "Unable to load",
            comment: "Title shown in POS ineligible view"
        )

        static let refreshEligibility = NSLocalizedString(
            "pos.ineligible.refresh.button.title",
            value: "Retry",
            comment: "Button title to refresh POS eligibility check"
        )

        static let dismiss = NSLocalizedString(
            "pos.ineligible.dismiss.button.title",
            value: "Exit POS",
            comment: "Button title to dismiss POS ineligible view"
        )
    }
}

#if DEBUG

#Preview("Unsupported currency") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .unsupportedCurrency(supportedCurrencies: [.USD]),
            onRefresh: {}
        )
    }
}

#Preview("Unsupported country") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .unsupportedCountry(supportedCountries: [.US, .GB]),
            onRefresh: {}
        )
    }
}

#Preview("Not a tablet") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .notTablet,
            onRefresh: {}
        )
    }
}

#Preview("Unsupported iOS version") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .unsupportedIOSVersion,
            onRefresh: {}
        )
    }
}

#Preview("WooCommerce plugin not found") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .wooCommercePluginNotFound,
            onRefresh: {}
        )
    }
}

#Preview("Feature flag disabled") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .featureFlagDisabled,
            onRefresh: {}
        )
    }
}

#Preview("Feature switch disabled") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .featureSwitchDisabled,
            onRefresh: {}
        )
    }
}

#Preview("Site settings unavailable") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .siteSettingsNotAvailable,
            onRefresh: {}
        )
    }
}

#Preview("Feature switch sync failure") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .featureSwitchSyncFailure,
            onRefresh: {}
        )
    }
}

#Preview("Unsupported WooCommerce version") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0"),
            onRefresh: {}
        )
    }
}

#endif
