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
                POSErrorXMark()

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
                                ServiceLocator.analytics.track(
                                    event: .PointOfSaleIneligibleUI.ineligibleUIRetryTapped(reason: reason)
                                )
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
                    .renderedIf(reason.shouldShowRetryButton)

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
        .onAppear {
            ServiceLocator.analytics.track(event: .PointOfSaleIneligibleUI.ineligibleUIShown(reason: reason))
        }
        .onChange(of: reason) { newReason in
            ServiceLocator.analytics.track(event: .PointOfSaleIneligibleUI.ineligibleUIShown(reason: newReason))
        }
    }

    private var suggestionText: String {
        switch reason {
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
                                     value: "Check your internet connection and try again. If the issue persists, please contact support.",
                                     comment: "Suggestion for site settings unavailable: check connection or contact support")
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

@available(iOS 17.0, *)
private extension POSIneligibleReason {
    var shouldShowRetryButton: Bool {
        switch self {
        case .unsupportedIOSVersion:
            return false
        case .unsupportedWooCommerceVersion,
                .siteSettingsNotAvailable,
                .wooCommercePluginNotFound,
                .featureSwitchDisabled,
                .unsupportedCurrency,
                .selfDeallocated:
            return true
        }
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

#Preview("Unsupported WooCommerce version") {
    if #available(iOS 17.0, *) {
        POSIneligibleView(
            reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0"),
            onRefresh: {}
        )
    }
}

#endif
