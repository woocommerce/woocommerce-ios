import CocoaLumberjackSwift
import SwiftUI

/// A view that displays when the Point of Sale (POS) feature is not available for the current store.
/// Shows the specific reason why POS is ineligible and provides a button to re-check eligibility.
struct POSIneligibleView: View {
    let reason: POSIneligibleReason
    let onRefresh: () async throws -> Void
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.sizeCategory) private var sizeCategory
    @Environment(\.posAnalytics) private var analytics
    @State private var isLoading: Bool = false
    @State private var scrollViewHeight: CGFloat = 0
    @State private var contentHeight: CGFloat = 0

    /// Returns the frame width multiplier for the content view based on accessibility size category.
    private var frameWidthMultiplier: Double {
        if sizeCategory >= .accessibilityMedium {
            return 0.9  // Use more horizontal space for larger accessibility sizes
        } else {
            return 0.5  // Standard multiplier for regular sizes
        }
    }

    /// Returns true if scrolling should be disabled (content fits within scroll view).
    private var shouldDisableScrolling: Bool {
        scrollViewHeight > 0 && contentHeight > 0 && contentHeight <= scrollViewHeight
    }

    var body: some View {
        ScrollView {
            VStack(spacing: POSSpacing.none) {
                Spacer()

                VStack(alignment: .center, spacing: POSSpacing.none) {
                    POSErrorXMark()

                    Spacer()
                        .frame(height: POSSpacing.medium)

                    VStack(spacing: POSSpacing.small) {
                        Text(titleText)
                            .font(POSFontStyle.posHeadingBold.font())
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.posOnSurface)

                        Text(suggestionText)
                            .font(POSFontStyle.posBodyLargeRegular().font())
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.posOnSurface)
                    }
                    .containerRelativeFrame(.horizontal) { length, _ in
                        max(length * frameWidthMultiplier, 300)
                    }

                    Spacer()
                        .frame(height: POSSpacing.large)

                    VStack(spacing: POSSpacing.medium) {
                        Button {
                            Task { @MainActor in
                                do {
                                    isLoading = true
                                    analytics.track(
                                        event: .PointOfSaleIneligibleUI.ineligibleUIRetryTapped(reason: reason)
                                    )
                                    try await onRefresh()
                                    isLoading = false
                                } catch {
                                    DDLogError("Error refreshing eligibility: \(error)")
                                    isLoading = false
                                }
                            }
                        } label: {
                            Text(reason.refreshEligibilityTitle)
                        }
                        .buttonStyle(POSFilledButtonStyle(size: .normal, isLoading: isLoading))
                        .renderedIf(reason.shouldShowRetryButton)

                        Button {
                            if let url = URL(string: Constants.ciabLearnMoreURL) {
                                openURL(url)
                            }
                        } label: {
                            Text(Localization.learnMore)
                        }
                        .buttonStyle(POSFilledButtonStyle(size: .normal))
                        .renderedIf(reason.shouldShowLearnMoreButton)

                        Button {
                            dismiss()
                        } label: {
                            Text(Localization.dismiss)
                        }
                        .buttonStyle(POSOutlinedButtonStyle(size: .normal))
                    }
                    .containerRelativeFrame(.horizontal) { length, _ in
                        max(length * frameWidthMultiplier - 132, 300)
                    }
                }

                Spacer()
            }
            .padding(POSPadding.large)
            .frame(maxWidth: .infinity, minHeight: scrollViewHeight > 0 ? scrollViewHeight : nil)
            .measureHeight { height in
                contentHeight = height
            }
            .onAppear {
                analytics.track(event: .PointOfSaleIneligibleUI.ineligibleUIShown(reason: reason))
            }
            .onChange(of: reason) { _, newReason in
                analytics.track(event: .PointOfSaleIneligibleUI.ineligibleUIShown(reason: newReason))
            }
        }
        .scrollDisabled(shouldDisableScrolling)
        .measureHeight { height in
            scrollViewHeight = height
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var titleText: String {
        switch reason {
        case .ciabPlanUpgradeRequired:
            return Localization.planUpgradeTitle
        default:
            return Localization.title
        }
    }

    private var suggestionText: String {
        switch reason {
        case let .unsupportedWooCommerceVersion(minimumVersion):
            let format = NSLocalizedString("pos.ineligible.suggestion.unsupportedWooCommerceVersion",
                                     value: "Your WooCommerce version is not supported. " +
                                     "The POS system requires WooCommerce version %1$@ or above. Please update WooCommerce to the latest version.",
                                     comment: "Suggestion for unsupported WooCommerce version: update plugin. " +
                                     "%1$@ is a placeholder for the minimum required version.")
            return String.localizedStringWithFormat(format, minimumVersion)
        case .wooCommercePluginNotFound:
            return NSLocalizedString("pos.ineligible.suggestion.wooCommercePluginNotFound.3",
                                     value: "We were unable to load the WooCommerce plugin info. Please make sure the WooCommerce plugin is installed " +
                                     "and activated from your WordPress admin. If there is still an issue, contact support for assistance.",
                                     comment: "Suggestion for missing WooCommerce plugin: install plugin")
        case .featureSwitchDisabled:
            return NSLocalizedString("pos.ineligible.suggestion.featureSwitchDisabled.3",
                                     value: "Point of Sale must be enabled to proceed. " +
                                     "Please enable the POS feature below or from your WordPress admin under WooCommerce settings > Advanced > Features " +
                                     "and try again.",
                                     comment: "Suggestion for disabled feature switch: enable feature in WooCommerce settings")
        case let .unsupportedCurrency(countryCode, supportedCurrencies):
            let currencyList = supportedCurrencies.map { $0.rawValue }
            let formattedCurrencyList = ListFormatter.localizedString(byJoining: currencyList)
            let format = NSLocalizedString(
                "pos.ineligible.suggestion.unsupportedCurrency.1",
                value: "The POS system is not available for your store’s currency. In %1$@, it currently supports only %2$@. " +
                "Please check your store currency settings or contact support for assistance.",
                comment: "Suggestion for unsupported currency with list of supported currencies. " +
                "%1$@ is a placeholder for the localized country name, " +
                "and %2$@ is a placeholder for the localized list of supported currency codes."
            )
            return String.localizedStringWithFormat(format, countryCode.readableCountry, formattedCurrencyList)
        case .siteSettingsNotAvailable:
            return NSLocalizedString("pos.ineligible.suggestion.siteSettingsNotAvailable.1",
                                     value: "We were unable to load the site settings info. Please check your internet connection and try again. " +
                                     "If the issue persists, contact support for assistance.",
                                     comment: "Suggestion for site settings unavailable: check connection or contact support")
        case .selfDeallocated:
            return NSLocalizedString("pos.ineligible.suggestion.selfDeallocated",
                                     value: "Try relaunching the app to resolve this issue.",
                                     comment: "Suggestion for self deallocated: relaunch")
        case .ciabPlanUpgradeRequired:
            return NSLocalizedString("pos.ineligible.suggestion.ciabPlanUpgradeRequired",
                                     value: "Point of Sale is available on the Pro plan. ",
                                     comment: "Suggestion shown when CIAB site does not have a Pro plan for POS access")
        }
    }
}

private extension POSIneligibleView {
    enum Constants {
        // TODO: Replace with the actual URL. TBD
        static let ciabLearnMoreURL = "https://woocommerce.com/"
    }

    enum Localization {
        static let title = NSLocalizedString(
            "pos.ineligible.title",
            value: "Unable to load",
            comment: "Title shown in POS ineligible view"
        )

        static let planUpgradeTitle = NSLocalizedString(
            "pos.ineligible.planUpgrade.title",
            value: "Pro plan required",
            comment: "Title shown in POS ineligible view when a CIAB site needs a Pro plan"
        )

        static let learnMore = NSLocalizedString(
            "pos.ineligible.learnMore.button.title",
            value: "Learn More",
            comment: "Button title to learn more about upgrading the plan for POS access"
        )

        static let dismiss = NSLocalizedString(
            "pos.ineligible.dismiss.button.title",
            value: "Exit POS",
            comment: "Button title to dismiss POS ineligible view"
        )
    }
}

private extension POSIneligibleReason {
    var shouldShowRetryButton: Bool {
        switch self {
        case .unsupportedWooCommerceVersion,
                .siteSettingsNotAvailable,
                .wooCommercePluginNotFound,
                .featureSwitchDisabled,
                .unsupportedCurrency,
                .selfDeallocated:
            return true
        case .ciabPlanUpgradeRequired:
            return false
        }
    }

    var shouldShowLearnMoreButton: Bool {
        switch self {
        case .ciabPlanUpgradeRequired:
            return true
        default:
            return false
        }
    }

    var refreshEligibilityTitle: String {
        switch self {
        case .featureSwitchDisabled:
            return NSLocalizedString(
                "pos.ineligible.enable.pos.feature.and.refresh.button.title.1",
                value: "Enable POS feature",
                comment: "Button title to enable the POS feature switch and refresh POS eligibility check"
            )
        case .unsupportedWooCommerceVersion,
                .siteSettingsNotAvailable,
                .wooCommercePluginNotFound,
                .unsupportedCurrency,
                .selfDeallocated:
            return NSLocalizedString(
                "pos.ineligible.refresh.button.title",
                value: "Retry",
                comment: "Button title to refresh POS eligibility check"
            )
        case .ciabPlanUpgradeRequired:
            // Not used, a button is rendered instead
            return ""
        }
    }
}

#if DEBUG

#Preview("Unsupported currency") {
    POSIneligibleView(
        reason: .unsupportedCurrency(countryCode: .US, supportedCurrencies: [.USD]),
        onRefresh: {}
    )
}

#Preview("WooCommerce plugin not found") {
    POSIneligibleView(
        reason: .wooCommercePluginNotFound,
        onRefresh: {}
    )
}

#Preview("Feature switch disabled") {
    POSIneligibleView(
        reason: .featureSwitchDisabled,
        onRefresh: {}
    )
}

#Preview("Site settings unavailable") {
    POSIneligibleView(
        reason: .siteSettingsNotAvailable,
        onRefresh: {}
    )
}

#Preview("Unsupported WooCommerce version") {
    POSIneligibleView(
        reason: .unsupportedWooCommerceVersion(minimumVersion: "9.6.0"),
        onRefresh: {}
    )
}

#Preview("CIAB plan upgrade required") {
    POSIneligibleView(
        reason: .ciabPlanUpgradeRequired,
        onRefresh: {}
    )
}

#endif
