import Foundation

enum OrderListLocalization {
    static let allOrdersHeaderTitle = NSLocalizedString(
        "All Orders",
        value: "All Orders",
        comment: "Header title on the Orders list when no filters are applied."
    )

    static let filteredOrdersHeaderTitle = NSLocalizedString(
        "Filtered Orders",
        value: "Filtered Orders",
        comment: "Header title on the Orders list when one or more filters are applied."
    )

    static let filterButtonTitle = NSLocalizedString(
        "Filter",
        value: "Filter",
        comment: "Title of the button that opens order filters when no filters are applied."
    )

    private static let filterButtonWithCountFormat = NSLocalizedString(
        "Filter (%ld)",
        value: "Filter (%ld)",
        comment: "Title of the button that opens order filters. %ld is the number of active filters."
    )

    private static let lastUpdatedFormat = NSLocalizedString(
        "Last Updated: %@",
        value: "Last Updated: %@",
        comment: "Time when the orders were last updated. %@ is a localized time or date and time."
    )

    static let currencyUnavailableTitle = NSLocalizedString(
        "orderList.currencyUnavailable.banner.title",
        value: "Store currency unavailable",
        comment: "Title of the banner shown on the Orders list when the store's currency couldn't be loaded."
    )

    static let currencyUnavailableInfo = NSLocalizedString(
        "orderList.currencyUnavailable.banner.info",
        value: "We couldn't load your store's currency, so order totals may be shown in the wrong currency.",
        comment: "Message of the banner shown on the Orders list when the store's currency couldn't be loaded."
    )

    static let currencyUnavailableRetry = NSLocalizedString(
        "orderList.currencyUnavailable.banner.retry",
        value: "Retry",
        comment: "Title of the button to retry loading the store's currency on the Orders list warning banner."
    )

    static let errorAccessibilityStatus = NSLocalizedString(
        "orderList.error.banner.accessibilityStatus",
        value: "Error",
        comment: "Accessibility status announced for an error banner on the Orders list."
    )

    static let warningAccessibilityStatus = NSLocalizedString(
        "orderList.warning.banner.accessibilityStatus",
        value: "Warning",
        comment: "Accessibility status announced for a warning banner on the Orders list."
    )

    static let expandedAccessibilityValue = NSLocalizedString(
        "Expanded",
        value: "Expanded",
        comment: "Accessibility value when a banner is expanded"
    )

    static let collapsedAccessibilityValue = NSLocalizedString(
        "Collapsed",
        value: "Collapsed",
        comment: "Accessibility value when a banner is collapsed"
    )

    static let expandAccessibilityHint = NSLocalizedString(
        "Double-tap for more information",
        value: "Double-tap for more information",
        comment: "Accessibility hint to expand a banner"
    )

    static let collapseAccessibilityHint = NSLocalizedString(
        "Double-tap to collapse",
        value: "Double-tap to collapse",
        comment: "Accessibility hint to collapse a banner"
    )

    static func filterButtonTitle(activeFilterCount: Int) -> String {
        guard activeFilterCount > 0 else {
            return filterButtonTitle
        }
        return String.localizedStringWithFormat(filterButtonWithCountFormat, activeFilterCount)
    }

    static func lastUpdatedText(time: String) -> String {
        String.localizedStringWithFormat(lastUpdatedFormat, time)
    }
}
