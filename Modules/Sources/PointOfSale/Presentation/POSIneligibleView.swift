import CocoaLumberjackSwift
import SwiftUI

/// A view that displays when the Point of Sale (POS) feature is not available for the current store.
/// Shows the specific reason why POS is ineligible and provides a button to re-check eligibility.
struct POSIneligibleView: View {
    let reason: POSIneligibleReason
    let onRefresh: () async throws -> Void
    @Environment(\.dismiss) private var dismiss
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
                        Text(Localization.title)
                            .font(POSFontStyle.posHeadingBold.font())
                            .multilineTextAlignment(.center)
                            .foregroundColor(Color.posOnSurface)

                        suggestionBodyText(suggestionText)
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

    private func suggestionBodyText(_ text: String) -> some View {
        Text(text)
            .font(POSFontStyle.posBodyLargeRegular().font())
            .multilineTextAlignment(.center)
            .foregroundColor(Color.posOnSurface)
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
        case .siteSettingsNotAvailable:
            return NSLocalizedString("pos.ineligible.suggestion.siteSettingsNotAvailable.1",
                                     value: "We were unable to load the site settings info. Please check your internet connection and try again. " +
                                     "If the issue persists, contact support for assistance.",
                                     comment: "Suggestion for site settings unavailable: check connection or contact support")
        case .selfDeallocated:
            return NSLocalizedString("pos.ineligible.suggestion.selfDeallocated",
                                     value: "Try relaunching the app to resolve this issue.",
                                     comment: "Suggestion for self deallocated: relaunch")
        }
    }
}

private extension POSIneligibleView {
    enum Localization {
        static let title = NSLocalizedString(
            "pos.ineligible.title",
            value: "Unable to load",
            comment: "Title shown in POS ineligible view"
        )

        static let dismiss = NSLocalizedString(
            "pos.ineligible.dismiss.button.title",
            value: "Exit POS",
            comment: "Button title to dismiss POS ineligible view"
        )
    }
}

private extension POSIneligibleReason {
    var refreshEligibilityTitle: String {
        NSLocalizedString(
            "pos.ineligible.refresh.button.title",
            value: "Retry",
            comment: "Button title to refresh POS eligibility check"
        )
    }
}

#if DEBUG

#Preview("WooCommerce plugin not found") {
    POSIneligibleView(
        reason: .wooCommercePluginNotFound,
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

#endif
